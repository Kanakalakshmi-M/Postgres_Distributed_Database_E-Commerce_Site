-- PL/pgSQL code Customer sign up with required details
    CREATE OR REPLACE FUNCTION create_customer(
        p_first_name VARCHAR(20),
        p_last_name VARCHAR(20),
        p_phone_no VARCHAR(20),
        p_email_id VARCHAR(255),
        p_dob DATE,
        p_flat_no INTEGER,
        p_street VARCHAR(50),
        p_city VARCHAR(50),
        p_state VARCHAR(50),
        p_country VARCHAR(50),
        p_zip_code VARCHAR(10)
    ) RETURNS VOID AS $$
    DECLARE
        v_customer_id UUID;
        v_address_id UUID;
    BEGIN
        -- Insert into customer table
        INSERT INTO customer (id, first_name, last_name, phone_no, email_id, dob, type)
        VALUES (uuid_generate_v4(), p_first_name, p_last_name, p_phone_no, p_email_id, p_dob, 'regular')
        RETURNING id INTO v_customer_id;

        -- Insert into address table
        INSERT INTO address (id, flat_no, street, city, state, country, zip_code)
        VALUES (uuid_generate_v4(), p_flat_no, p_street, p_city, p_state, p_country, p_zip_code)
        RETURNING id INTO v_address_id;

        -- Insert into customer_address table
        INSERT INTO customer_address (customer_id, address_id, default_address)
        VALUES (v_customer_id, v_address_id, true);
    END;
    $$ LANGUAGE plpgsql PARALLEL SAFE;

-- input data to signup:
    SELECT create_customer(
                'Jack',
                'Teresa',
                '(910) 436-7890',
                'jack.teresa@example.com',
                '1990-01-01',
                401,
                'Main Street',
                'Tampa',
                'Florida',
                'USA',
                '65341'
            );

-- PL/pgSQL code to place order by customer:
    CREATE OR REPLACE FUNCTION place_order_by_customer(
    p_customer_id UUID,
    p_product_id UUID,
    p_product_quantity INTEGER,
    p_delivery_partner_name VARCHAR(50),
    p_delivery_partner_phone_no VARCHAR(20),
    p_delivery_partner_email VARCHAR(255)
    ) RETURNS VOID AS $$
    DECLARE
    v_order_id UUID;
    v_address_id UUID;
    v_delivery_partner_id UUID;
    BEGIN
    -- Step 1: Check if the product and quantity are available
    PERFORM 1 FROM products WHERE id = p_product_id AND quantity >= p_product_quantity;
    IF NOT FOUND THEN
    RAISE EXCEPTION 'Customer %, sorry, the requested product is not available. Please try again later.', p_customer_id;
    END IF;
    -- Step 2: Insert data into orders
    INSERT INTO orders (status, address_id, customer_id) 
    VALUES ('Processing', (SELECT address_id FROM customer_address WHERE customer_id = p_customer_id AND default_address = true), p_customer_id)
    RETURNING id INTO v_order_id;
    -- Step 3: Insert data into transaction_summary
    INSERT INTO transaction_summary (total_amount_paid, payment_type, order_id)
    VALUES ((SELECT price * p_product_quantity FROM products WHERE id = p_product_id), 'Credit Card', v_order_id);
    -- Step 4: Insert data into delivery_partner
    INSERT INTO delivery_partner (name, phone_no, email, order_id)
    VALUES (p_delivery_partner_name, p_delivery_partner_phone_no, p_delivery_partner_email, v_order_id)
    RETURNING id INTO v_delivery_partner_id;
    -- Step 5: Insert data into customer_delivery_partner
    INSERT INTO customer_delivery_partner (customer_id, delivery_partner_id)
    VALUES (p_customer_id, v_delivery_partner_id);
    -- Step 6: Insert data into orders_products
    INSERT INTO orders_products (order_id, product_id, quantity)
    VALUES (v_order_id, p_product_id, p_product_quantity);
    -- Step 7: Update product quantity
    UPDATE products SET quantity = quantity - p_product_quantity WHERE id = p_product_id;
    EXCEPTION
    WHEN OTHERS THEN
    -- Rollback the transaction in case of an exception
    RAISE EXCEPTION 'Error in place_order_by_customer: %', SQLERRM;
    END;
    $$ LANGUAGE plpgsql;

-- Input data to place the order by customer:
DO $$ 
BEGIN
PERFORM place_order_by_customer(
'668e5890-517a-4ae1-b909-03f39a3d8e6d', -- customer_id
'f5148b50-d8f4-45a7-a5aa-03cf6e047627', -- product_id
2,                                      -- product_quantity
'John Doe',                             -- delivery_partner_name
'(973) 456-7890',                       -- delivery_partner_phone_no
'john.doe@example.com'                  -- delivery_partner_email
);
END $$;

/* 
usecase: use multiple tables such as customer products, orders, transaction_summary 
and get the successfully ordered products paid more than their average total.
*/

    SELECT prod.id AS product_id, prod.name AS product_name, ord.id AS order_id, ord.status AS order_status,
        ts.total_amount_paid, ts.payment_type, ts.date_of_payment
    FROM products prod
    JOIN orders_products ord_prod ON prod.id = ord_prod.product_id
    JOIN orders ord ON ord_prod.order_id = ord.id
    JOIN transaction_summary ts ON ord.id = ts.order_id
    JOIN product_category pc ON prod.product_category_id = pc.id
    WHERE ord.customer_id = '668e5890-517a-4ae1-b909-03f39a3d8e6d'
        AND pc.section = 'Electronics' 
        AND ts.total_amount_paid > (
            SELECT AVG(total_amount_paid)
            FROM transaction_summary
            WHERE order_id IN (
                SELECT id
                FROM orders
                WHERE customer_id = '668e5890-517a-4ae1-b909-03f39a3d8e6d')
        );

-- Analyze the performance of query:
EXPLAIN
SELECT prod.id AS product_id, prod.name AS product_name, ord.id AS order_id, ord.status AS order_status, ts.total_amount_paid, ts.payment_type, ts.date_of_payment
FROM products prod
JOIN orders_products ord_prod ON prod.id = ord_prod.product_id  
JOIN orders ord ON ord_prod.order_id = ord.id
JOIN transaction_summary ts ON ord.id = ts.order_id
JOIN product_category pc ON prod.product_category_id = pc.id
WHERE ord.customer_id = '668e5890-517a-4ae1-b909-03f39a3d8e6d'AND pc.section = 'Electronics'AND ts.total_amount_paid > (
 	SELECT AVG(total_amount_paid)
       FROM transaction_summary
       WHERE order_id IN (
       	SELECT id
              FROM orders
              WHERE customer_id = '668e5890-517a-4ae1-b909-03f39a3d8e6d')
       );

-- Implement parallel execution on the query for better performance.
SET max_parallel_workers = 4;
EXPLAIN
SELECT prod.id AS product_id, prod.name AS product_name, ord.id AS order_id, ord.status AS order_status,
ts.total_amount_paid, ts.payment_type, ts.date_of_payment
FROM products prod
JOIN orders_products ord_prod ON prod.id = ord_prod.product_id  -- Corrected alias from 'ord' to 'ord_prod'
JOIN orders ord ON ord_prod.order_id = ord.id  -- Corrected alias from 'o' to 'ord'
JOIN transaction_summary ts ON ord.id = ts.order_id
JOIN product_category pc ON prod.product_category_id = pc.id
WHERE ord.customer_id = '668e5890-517a-4ae1-b909-03f39a3d8e6d'AND pc.section = 'Electronics'AND ts.total_amount_paid > (
                SELECT AVG(total_amount_paid)
                FROM transaction_summary
                WHERE order_id IN (
                    SELECT id
                    FROM orders
                    WHERE customer_id = '668e5890-517a-4ae1-b909-03f39a3d8e6d'
                )
            );




            




