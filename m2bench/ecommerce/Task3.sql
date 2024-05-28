DROP TABLE IF EXISTS A;
DROP TABLE IF EXISTS B;

INSTALL json;
LOAD json;

.timer on

CREATE TABLE A AS (
        SELECT person_id
        FROM Customer
        WHERE customer_id = (
                SELECT customer_id
                FROM (
                        SELECT customer_id AS customer_id, SUM(total_price) AS order_price
                        FROM "order"
                        WHERE order_date = '2018-07-07'
                        GROUP BY customer_id
                        ORDER BY order_price DESC
                        LIMIT 1
                ) AS cid
        )
);

CREATE TEMPORARY TABLE B AS (
    SELECT "p1.person_id" AS person_id
    FROM cypher (
        'MATCH (p2:Person)<-[:follows*2]-(p1:Person) WHERE p2.person_id IN sql(SELECT person_id FROM A) RETURN p1.person_id'
    )
);

CREATE TEMPORARY TABLE btemp AS (
    SELECT *
    FROM cypher (
        'MATCH (p1:Person)-[:follows]->(p2:Person) RETURN p1.person_id'
    )
);
SELECT COUNT(*) FROM btemp;

CREATE TEMPORARY TABLE C AS (
        SELECT temp.customer_id AS cid,
               Product.product_id AS pid,
               Product.brand_id AS brand_id
        FROM (
                SELECT Customer.customer_id, UNNEST(order_line).product_id AS product_id
                FROM B, Customer, "order"
                WHERE "order".customer_id = Customer.customer_id
                AND Customer.person_id = B.person_id
        ) AS temp,
        Product
        WHERE Product.product_id = temp.product_id::CHARACTER(11)
);

SELECT Brand.industry, COUNT(*) AS customer_count
FROM C, Brand
WHERE C.brand_id = Brand.brand_id
GROUP BY Brand.industry;