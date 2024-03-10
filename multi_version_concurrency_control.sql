-- Concurrent transaction using MVCC(Multi-Version Concurrancy Control)
/*
Use case 1:
The product should only be assigned to one consumer at a time if two distinct customers are attempting to access it with quantity 1. 
This indicates that the data and the concurrent actions are consistent.
*/

select * from customer; -- To display the list of customers
select * from products; -- To display the list of products

    -- PL/pgSQL code to handle concurrent transactions:
        CREATE OR REPLACE FUNCTION place_order(
        p_product_id UUID,
        p_customer_id UUID,
        p_quantity INTEGER,
        p_delivery_partner_name VARCHAR(50),
        p_delivery_partner_phone_no VARCHAR(20),
        p_delivery_partner_email VARCHAR(255)
    ) RETURNS VOID AS $$
    DECLARE
        v_order_id UUID;
        v_delivery_partner_id UUID;
        v_product_quantity INTEGER;
    BEGIN
        BEGIN
            -- Check if the product is available
            SELECT quantity INTO v_product_quantity FROM products WHERE id = p_product_id FOR UPDATE;
            -- step-1: Check if the requested quantity is available
            IF v_product_quantity < p_quantity THEN
                RAISE EXCEPTION 'Error in place_order: Product not available. Please try again later.';
            END IF;
            -- step 2: Insert data into orders
            INSERT INTO orders (status, order_date, address_id, customer_id) 
            VALUES ('Processing', CURRENT_DATE, (SELECT address_id FROM customer_address WHERE customer_id = p_customer_id AND default_address = true), p_customer_id)
            RETURNING id INTO v_order_id;
            -- Step 3: Update products table
            UPDATE products SET quantity = quantity - p_quantity WHERE id = p_product_id;
            -- Step 4: Insert data into transaction_summary table
            INSERT INTO transaction_summary (total_amount_paid, payment_type, date_of_payment, order_id)
            VALUES ((SELECT price * p_quantity FROM products WHERE id = p_product_id), 'Credit Card', CURRENT_DATE, v_order_id);
            -- Step 5: Insert data into orders_products table
            INSERT INTO orders_products (order_id, product_id, quantity) VALUES (v_order_id, p_product_id, p_quantity);
            -- Step 6: Insert data into delivery_partner table
            INSERT INTO delivery_partner (name, phone_no, email, order_id)
            VALUES (p_delivery_partner_name, p_delivery_partner_phone_no, p_delivery_partner_email, v_order_id)
            RETURNING id INTO v_delivery_partner_id;
            -- Step 7: Insert data into customer_delivery_partner table
            INSERT INTO customer_delivery_partner (customer_id, delivery_partner_id) VALUES (p_customer_id, v_delivery_partner_id);

        EXCEPTION
            WHEN OTHERS THEN
                -- Rollback the transaction in case of an exception
                RAISE EXCEPTION 'Error in place_order: %', SQLERRM;
        END;
    END;
    $$ LANGUAGE plpgsql;

    -- python code to place order by two customers concurrantely
    import psycopg2
    from concurrent.futures import ThreadPoolExecutor

    # connection details
    host = "****" -- provide corresponding host info
    port = 5432
    database = "kl_dpdb_ecommerce_database"
    user = "****" -- provide database username
    password = "*****" -- provide password of database
    def place_order(product_id, customer_id, quantity, delivery_partner_name, phone_no, email):
        try:
            place_order_connection = psycopg2.connect(
                host=host,
                port=port,
                database=database,
                user=user,
                password=password
            )
            place_order_cursor = place_order_connection.cursor()
            place_order_cursor.execute(
                """
                SELECT place_order(
                    %s, %s, %s, %s, %s, %s
                );
                """,
                (product_id, customer_id, quantity, delivery_partner_name, phone_no, email)
            )
            place_order_connection.commit()
            print(f"order Placed for {customer_id}!")
        except psycopg2.Error as e:
            error_message = str(e)
            if "product not available" in error_message.lower():
                print(f"Product not available for {customer_id}! please try again")
            else:
                print(f"Error connecting to PostgreSQL: {e}")
        finally:
            if place_order_cursor:
                place_order_cursor.close()
            if place_order_connection:
                place_order_connection.close()
   
        -- customer details
    if __name__ == "__main__":
        # customer-1
        customer_1_details = ('4d205a90-053f-4db1-a22a-37cc18355798', '52d999b8-de44-489d-8913-7ce999e26c5a', 2, 'robin', '(817) 777-4089', 'robin@example.com')
        # customer-2
        customer_2_details = ('4d205a90-053f-4db1-a22a-37cc18355798', '207397bf-5759-4a51-a44a-3b317971b09a', 2, 'josey', '(978) 717-4389', 'josey1@example.com')

        with ThreadPoolExecutor(max_workers=2) as executor:
            # Trigger the function concurrently with different user inputs
            executor.submit(place_order, *customer_1_details)
            executor.submit(place_order, *customer_2_details)

-- after code execution, verify the data in tables
    select * from products;
    select * from orders;
    select * from transaction_summary;
    select * from orders_products;
    select * from delivery_partner;
    select * from customer_delivery_partner;

    




