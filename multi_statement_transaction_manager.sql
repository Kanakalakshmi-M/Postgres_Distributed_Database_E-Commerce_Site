/*
use case 1: A customer can store multiple addresses and choose any one out it as default address. 
Customer can place order to any address as per choice. There also flexibility for the customer to update the address, 
incase customer adds the same existing address then database will through an error message “Address already exists. Please make use of it.” 
*/

    DO $$ 
    DECLARE
        -- Input parameters
        input_customer_id UUID := '668e5890-517a-4ae1-b909-03f39a3d8e6d';
        input_flat_no INTEGER := 101;  
        input_street VARCHAR(50) := 'Maple lane, Apartment 3C';
        input_city VARCHAR(50) := 'River City';
        input_state VARCHAR(50) := 'Texas';
        input_country VARCHAR(50) := 'USA';
        input_zip_code VARCHAR(10) := '75001';

        -- Variables for data
        get_address_id UUID;
        get_existing_address RECORD;

    BEGIN
        BEGIN
            -- Insert data into the address table
            INSERT INTO address (flat_no, street, city, state, country, zip_code)
            VALUES (input_flat_no, input_street, input_city, input_state, input_country, input_zip_code)
            RETURNING id INTO get_address_id;
            -- Insert data into the customer_address table
            INSERT INTO customer_address (customer_id, address_id, default_address)
            VALUES (input_customer_id, get_address_id, false);
            -- Check if any other address exists for the customer
            FOR get_existing_address IN 
                SELECT addr.* 
                FROM address addr
                JOIN customer_address cust_addr ON addr.id = cust_addr.address_id
                WHERE cust_addr.customer_id = input_customer_id AND addr.id <> get_address_id
            LOOP
                -- Validate with the input
                IF get_existing_address.flat_no = input_flat_no AND
                get_existing_address.street = input_street AND
                get_existing_address.city = input_city AND
                get_existing_address.state = input_state AND
                get_existing_address.country = input_country AND
                get_existing_address.zip_code = input_zip_code THEN
                    RAISE EXCEPTION 'Address already exists. Please make use of it.';
                END IF;
            END LOOP;

        EXCEPTION
            WHEN OTHERS THEN
                -- An error occurred, roll back the transaction
                RAISE NOTICE 'Triggered Error: %', SQLERRM;
                ROLLBACK;
                RETURN;
        END;

        -- Everything went well, commit the transaction
        COMMIT;
        RAISE NOTICE 'Address saved successfully';

    END $$;

/*
Usecase-2: A customer may use a credit card to make purchases up to Rs. 1,000,000 every month. 
He/She is unable to place an order using a credit card after their monthly credit card spending exceeds Rs. 1,00,000. He/She ought to employ different ways to pay.
*/

    DO $$ 
    DECLARE
        -- Input parameters
        input_payment_type VARCHAR(20) := 'Credit Card';  
        input_customer_id UUID := '668e5890-517a-4ae1-b909-03f39a3d8e6d';
        input_product_id UUID := '8893a2e3-e040-4427-9e60-b89d8e0b4482';
        input_product_quantity INTEGER := 1;  
        input_delivery_partner_name VARCHAR(50) := 'Fedx';  
        input_delivery_partner_phone_no VARCHAR(20) := '(980) 426-7190';  
        input_delivery_partner_email VARCHAR(255) := 'Fedx@example.com';  

        -- Variables for data
        v_total_amount_paid INTEGER;
        v_credit_limit INTEGER := 100000;  
        v_remaining_credit INTEGER;
        v_order_amount INTEGER;
        v_order_id UUID;
        v_delivery_partner_id UUID;

    BEGIN
        -- Start the transaction
        BEGIN
            -- Step 1: Check if the product and quantity are available
            PERFORM 1 FROM products WHERE id = input_product_id AND quantity >= input_product_quantity;
            IF NOT FOUND THEN
                RAISE EXCEPTION 'Sorry, the requested product is not available. Please try again later.';
            END IF;

            -- Step 2: Insert data into orders
            INSERT INTO orders (status, order_date, address_id, customer_id) 
            VALUES ('Processing', CURRENT_DATE, 
                    (SELECT address_id FROM customer_address WHERE customer_id = input_customer_id AND default_address = true), 
                    input_customer_id)
            RETURNING id INTO v_order_id;
            RAISE NOTICE 'Inserted into orders table for order_id: %', v_order_id;

            -- Step 3: Calculate order amount (replace this with your own logic)
            v_order_amount := input_product_quantity * (SELECT price FROM products WHERE id = input_product_id);

            -- Step 4: Check if the customer has enough credit limit
            SELECT COALESCE(SUM(total_amount_paid), 0) INTO v_total_amount_paid
            FROM transaction_summary
            WHERE order_id IN (SELECT id FROM orders WHERE customer_id = input_customer_id) AND payment_type = input_payment_type;

            v_remaining_credit := v_credit_limit - v_total_amount_paid - v_order_amount;

            IF v_remaining_credit >= 0 THEN
                -- Update transaction_summary only if all conditions passed
                INSERT INTO transaction_summary (total_amount_paid, payment_type, date_of_payment, order_id)
                VALUES ((SELECT price * input_product_quantity FROM products WHERE id = input_product_id), input_payment_type, CURRENT_DATE, v_order_id);
                RAISE NOTICE 'Inserted into transaction_summary table for customer_id: %', input_customer_id;
            ELSE
                RAISE EXCEPTION 'Customer % has exceeded the credit limit. Please use another payment method.', input_customer_id;
            END IF;

            -- Step 5: Insert data into delivery_partner
            INSERT INTO delivery_partner (name, phone_no, email, order_id)
            VALUES (input_delivery_partner_name, input_delivery_partner_phone_no, input_delivery_partner_email, v_order_id)
            RETURNING id INTO v_delivery_partner_id;
            RAISE NOTICE 'Inserted into delivery_partner table for delivery_partner_id: %', v_delivery_partner_id;

            -- Step 6: Insert data into customer_delivery_partner
            INSERT INTO customer_delivery_partner (customer_id, delivery_partner_id)
            VALUES (input_customer_id, v_delivery_partner_id);
            RAISE NOTICE 'Inserted into customer_delivery_partner table';

            -- Step 7: Insert data into orders_products
            INSERT INTO orders_products (order_id, product_id, quantity)
            VALUES (v_order_id, input_product_id, input_product_quantity);
            RAISE NOTICE 'Inserted into orders_products table';

            -- Step 8: Update product quantity
            UPDATE products SET quantity = quantity - input_product_quantity WHERE id = input_product_id;
            RAISE NOTICE 'Updated product quantity for product_id: %', input_product_id;

        EXCEPTION
            WHEN OTHERS THEN
                -- An error occurred, roll back the transaction
                RAISE NOTICE 'Error occurred: %', SQLERRM;

                -- Log the rollback
                RAISE NOTICE 'Error occurred, rolling back the data';
                
                ROLLBACK;
                RETURN;
        END;

        -- Everything went well, commit the transaction
        COMMIT;
        RAISE NOTICE 'Order placed successfully';

    END $$;

-- validate transactions with "Debit card"

    DO $$ 
DECLARE
    -- Input parameters
    input_payment_type VARCHAR(20) := 'Debit Card';  
    input_customer_id UUID := '668e5890-517a-4ae1-b909-03f39a3d8e6d';
    input_product_id UUID := '8893a2e3-e040-4427-9e60-b89d8e0b4482';
    input_product_quantity INTEGER := 1;  
    input_delivery_partner_name VARCHAR(50) := 'Fedx';  
    input_delivery_partner_phone_no VARCHAR(20) := '(980) 426-7190';  
    input_delivery_partner_email VARCHAR(255) := 'Fedx@example.com';  

    -- Variables for data
    v_total_amount_paid INTEGER;
    v_credit_limit INTEGER := 100000;  
    v_remaining_credit INTEGER;
    v_order_amount INTEGER;
    v_order_id UUID;
    v_delivery_partner_id UUID;

BEGIN
    -- Start the transaction
    BEGIN
        -- Step 1: Check if the product and quantity are available
        PERFORM 1 FROM products WHERE id = input_product_id AND quantity >= input_product_quantity;
        IF NOT FOUND THEN
            RAISE EXCEPTION 'Sorry, the requested product is not available. Please try again later.';
        END IF;

        -- Step 2: Insert data into orders
        INSERT INTO orders (status, order_date, address_id, customer_id) 
        VALUES ('Processing', CURRENT_DATE, 
                (SELECT address_id FROM customer_address WHERE customer_id = input_customer_id AND default_address = true), 
                input_customer_id)
        RETURNING id INTO v_order_id;
        RAISE NOTICE 'Inserted into orders table for order_id: %', v_order_id;

        -- Step 3: Calculate order amount (replace this with your own logic)
        v_order_amount := input_product_quantity * (SELECT price FROM products WHERE id = input_product_id);

        -- Step 4: Check if the customer has enough credit limit
        SELECT COALESCE(SUM(total_amount_paid), 0) INTO v_total_amount_paid
        FROM transaction_summary
        WHERE order_id IN (SELECT id FROM orders WHERE customer_id = input_customer_id) AND payment_type = input_payment_type;

        v_remaining_credit := v_credit_limit - v_total_amount_paid - v_order_amount;

        IF v_remaining_credit >= 0 THEN
            -- Update transaction_summary only if all conditions passed
            INSERT INTO transaction_summary (total_amount_paid, payment_type, date_of_payment, order_id)
            VALUES ((SELECT price * input_product_quantity FROM products WHERE id = input_product_id), input_payment_type, CURRENT_DATE, v_order_id);
            RAISE NOTICE 'Inserted into transaction_summary table for customer_id: %', input_customer_id;
        ELSE
            RAISE EXCEPTION 'Customer % has exceeded the credit limit. Please use another payment method.', input_customer_id;
        END IF;

        -- Step 5: Insert data into delivery_partner
        INSERT INTO delivery_partner (name, phone_no, email, order_id)
        VALUES (input_delivery_partner_name, input_delivery_partner_phone_no, input_delivery_partner_email, v_order_id)
        RETURNING id INTO v_delivery_partner_id;
        RAISE NOTICE 'Inserted into delivery_partner table for delivery_partner_id: %', v_delivery_partner_id;

        -- Step 6: Insert data into customer_delivery_partner
        INSERT INTO customer_delivery_partner (customer_id, delivery_partner_id)
        VALUES (input_customer_id, v_delivery_partner_id);
        RAISE NOTICE 'Inserted into customer_delivery_partner table';

        -- Step 7: Insert data into orders_products
        INSERT INTO orders_products (order_id, product_id, quantity)
        VALUES (v_order_id, input_product_id, input_product_quantity);
        RAISE NOTICE 'Inserted into orders_products table';

        -- Step 8: Update product quantity
        UPDATE products SET quantity = quantity - input_product_quantity WHERE id = input_product_id;
        RAISE NOTICE 'Updated product quantity for product_id: %', input_product_id;

    EXCEPTION
        WHEN OTHERS THEN
            -- An error occurred, roll back the transaction
            RAISE NOTICE 'Error occurred: %', SQLERRM;

            -- Log the rollback
            RAISE NOTICE 'Error occurred, rolling back the data';
            
            ROLLBACK;
            RETURN;
    END;

    -- Everything went well, commit the transaction
    COMMIT;
    RAISE NOTICE 'Order placed successfully';

END $$;


