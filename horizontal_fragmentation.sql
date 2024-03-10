-- Requirement-3:
INSERT INTO customer (id, first_name, last_name, phone_no, email_id, dob, type) VALUES ('5aec2394-4bb8-4dc2-afbf-590f03cd0414', 'tdLmVeuWfq', 'jHgTMhnFTV', '(787) 510-9892', 'tscep@example.com', '1984-11-17', 'regular');
INSERT INTO customer (id, first_name, last_name, phone_no, email_id, dob, type) VALUES ('82faf519-d1eb-42dc-8406-311d9029dea6', 'uSbvAUfwED', 'xMbqoYjGHo', '(825) 801-7814', 'hioze@example.com', '1973-11-22', 'regular');
INSERT INTO customer (id, first_name, last_name, phone_no, email_id, dob, type) VALUES ('47580a39-1b9d-472b-a2b6-6b1bf46d1b6c', 'sfNcUcAYai', 'LCJqrPCVIv', '(463) 662-8591', 'omqwo@example.com', '1964-05-18', 'VIP');
INSERT INTO customer (id, first_name, last_name, phone_no, email_id, dob, type) VALUES ('c7d39a92-9d22-4ddf-9e0f-3a11860634c2', 'XLLQslUxVc', 'dkNCFcWpOG', '(354) 220-6490', 'dawge@example.com', '1979-12-18', 'platinum');
INSERT INTO customer (id, first_name, last_name, phone_no, email_id, dob, type) VALUES ('8af26586-806e-4b2f-aed6-ccb2b16940d2', 'RaAucZvezh', 'bOJNnbhStw', '(871) 622-1957', 'asnee@example.com', '1985-04-27', 'premium');
INSERT INTO customer (id, first_name, last_name, phone_no, email_id, dob, type) VALUES ('b46cec8a-5872-4834-944e-d4e2b01c9449', 'JzaOsctUGS', 'ZjBDWimhmC', '(607) 150-1947', 'dkmha@example.com', '1954-10-06', 'premium');
INSERT INTO customer (id, first_name, last_name, phone_no, email_id, dob, type) VALUES ('f9528413-3a68-42af-adcd-412849d32003', 'MDGHLvKSIy', 'ldLzvymnSL', '(765) 591-2862', 'docmj@example.com', '1956-05-10', 'premium');
.
.
.
1200 records.

    -- Horizontal Fragmentation:
        SELECT count(*) from customer;
        EXPLAIN ANALYZE SELECT * FROM customer WHERE dob BETWEEN '1980-01-01' AND '1990-01-01';
        select version() -- to find the currect version of postgres
        create extension pgstattuple -- to create pgstattuple extension
        select * from pgstattuple('customer'); 
        select pg_size_pretty(pg_total_relation_size('customer')) "Table_Size", count(*) from customer;

        Fragmentation:
        CREATE TABLE customer_1950_1970 AS SELECT * FROM customer WHERE dob BETWEEN '1950-01-01' AND '1970-12-31';
        CREATE TABLE customer_1971_1990 AS SELECT * FROM customer WHERE dob BETWEEN '1971-01-01' AND '1990-12-31';
        CREATE TABLE customer_1991_2000 AS SELECT * FROM customer WHERE dob BETWEEN '1991-01-01' AND '2000-12-31';

        CREATE INDEX idx_dob ON customer (dob);
        SELECT * FROM pg_indexes WHERE tablename = 'customer' AND indexname = 'idx_dob'

        select pg_size_pretty(pg_total_relation_size('customer')) "Table_Size", count(*) from customer;
        VACCUM full customer;
        select pg_size_pretty(pg_total_relation_size('customer')) "Table_Size", count(*) from customer;

        EXPLAIN ANALYZE SELECT * FROM customer WHERE dob BETWEEN '1980-01-01' AND '1990-01-01';
        EXPLAIN ANALYZE SELECT * FROM customer_1950_1970 WHERE dob BETWEEN '1980-01-01' AND '1990-01-01';
        EXPLAIN ANALYZE SELECT * FROM customer_1971_1990 WHERE dob BETWEEN '1980-01-01' AND '1990-01-01';
        EXPLAIN ANALYZE SELECT * FROM customer_1991_2000 WHERE dob BETWEEN '1980-01-01' AND '1990-01-01';

    -- Correctness of Horizontal Fragmenattion
        -- completeness:
            Reviewing the fragment tables-
            \d customer_1950_1970
            \d customer_1971_1990
            \d customer_1991_2000

            SELECT MIN(dob), MAX(dob) FROM customer_1950_1970;
            SELECT MIN(dob), MAX(dob) FROM customer_1971_1990;
            SELECT MIN(dob), MAX(dob) FROM customer_1991_2000;

            SELECT count(*) FROM customer;
            SELECT count(*) FROM customer_1950_1970;
            SELECT count(*) FROM customer_1971_1990;
            SELECT count(*) FROM customer_1991_2000;

        -- Reconstruction:
            SELECT SUM(count) AS total_customers_count FROM (
                SELECT count(*) FROM customer_1950_1970
                UNION
                SELECT count(*) FROM customer_1971_1990
                UNION
                SELECT count(*) FROM customer_1991_2000
            ) AS fragments_count;   


        -- Disjointness
            SELECT id, COUNT(*) AS disjointness_count
            FROM (
                SELECT id FROM customer_1950_1970
                UNION ALL
                SELECT id FROM customer_1971_1990
                UNION ALL
                SELECT id FROM customer_1991_2000
            ) AS all_fragments_customers
            GROUP BY id
            HAVING COUNT(*) > 1;