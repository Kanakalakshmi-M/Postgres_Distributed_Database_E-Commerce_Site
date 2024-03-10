-- Create 3 users: super user, administrator, and customer.
-- Create Users:
    -- Create superuser
    CREATE USER superuser WITH PASSWORD 'password_superuser' SUPERUSER;
    -- Create customers user
    CREATE USER customer WITH PASSWORD 'password_customer' NOCREATEDB NOCREATEROLE;
    -- Create administrators user
    CREATE USER administrators WITH PASSWORD 'password_administrators' CREATEDB CREATEROLE;
    -- list of users
    SELECT usename FROM pg_user;

-- Grant Access to Users:

    -- Super User
    GRANT ALL PRIVILEGES ON DATABASE kl_dpdb_ecommerce_database TO SUPERUSER;
    GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO superuser;
    --Cross check the previliges
    SELECT table_name, grantee, privilege_type
    FROM information_schema.table_privileges
    WHERE table_catalog = 'kl_dpdb_ecommerce_database' AND grantee = 'superuser';

    --Administrator
    CREATE OR REPLACE FUNCTION grant_privileges_to_administrator() RETURNS VOID AS $$
    BEGIN
    -- Granting privileges on the 'Products' table
    EXECUTE 'GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE Products TO administrator';
    -- Granting privileges on the 'Customer' table
    EXECUTE 'GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE Customer TO administrator';
    -- Granting privileges on the 'cart' table
    EXECUTE 'GRANT SELECT, UPDATE, DELETE ON TABLE cart TO administrator';
    -- Granting privileges on the 'orders' table
    EXECUTE 'GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE orders TO administrator';
    -- Granting privileges on the 'Transaction summary' table
    EXECUTE 'GRANT SELECT ON TABLE "transaction_summary" TO administrator';
    -- Granting privileges on the 'supplier' table
    EXECUTE 'GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE supplier TO administrator';
    -- Granting privileges on the 'Address' table
    EXECUTE 'GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE Address TO administrator';
    -- Granting privileges on the 'product_category' table
    EXECUTE 'GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE product_category TO administrator';
    -- Granting privileges on the 'Reviews' table
    EXECUTE 'GRANT SELECT, DELETE ON TABLE Reviews TO administrator';
    -- Granting privileges on the 'gift_vouchers' table
    EXECUTE 'GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE gift_vouchers TO administrator';
    -- Granting privileges on the 'delivery_partner' table
    EXECUTE 'GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE delivery_partner TO administrator';
    END;
    $$ LANGUAGE plpgsql;

    -- Execute the function to grant privileges
    SELECT grant_privileges_to_administrator();

    SELECT table_name, grantee, privilege_type
    FROM information_schema.table_privileges
    WHERE table_catalog = 'kl_dpdb_ecommerce_database' AND grantee = 'administrator';

    -- For Customer on customer table
    -- Granting SELECT, INSERT, UPDATE privileges on specified columns
    GRANT SELECT (first_name, last_name, phone_no, email_id, dob),
    INSERT (first_name, last_name, phone_no, email_id, dob),
    UPDATE (first_name, last_name, phone_no, email_id, dob)
    ON TABLE customer TO customer;
    -- Granting SELECT, UPDATE privileges on specified columns
    GRANT SELECT (id, type) ON TABLE customer TO customer;
    -- cross check the preveligies
    SELECT table_name, grantee, privilege_type,column_name
    FROM information_schema.column_privileges
    WHERE table_catalog = 'kl_dpdb_ecommerce_database'AND table_name = 'customer'AND grantee = 'customer';

    --For customer on remaining table
    CREATE OR REPLACE FUNCTION grant_privileges_to_customer() RETURNS VOID AS $$
    BEGIN
    -- Granting privileges on the 'Products' table
    EXECUTE 'GRANT SELECT ON TABLE Products TO customer';
    -- Granting privileges on the 'cart' table
    EXECUTE 'GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE cart TO customer';
    -- Granting privileges on the 'orders' table
    EXECUTE 'GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE orders TO customer';
    -- Granting privileges on the 'transaction_summary' table
    EXECUTE 'GRANT SELECT ON TABLE transaction_summary TO customer';
    -- Granting privileges on the 'address' table
    EXECUTE 'GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE address TO customer';
    -- Granting privileges on the 'product_category' table
    EXECUTE 'GRANT SELECT ON TABLE product_category TO customer';
    -- Granting privileges on the 'Reviews' table
    EXECUTE 'GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE Reviews TO customer';
    -- Granting privileges on the 'gift_vouchers' table
    EXECUTE 'GRANT SELECT ON TABLE gift_vouchers TO customer';
    END;
    $$ LANGUAGE plpgsql;

    -- Execute the function to grant privileges
    SELECT grant_privileges_to_customer();
    SELECT table_name, grantee, privilege_type
    FROM information_schema.table_privileges
    WHERE table_catalog = 'kl_dpdb_ecommerce_database' AND grantee = 'customer';

    -- Cross Validation
    psql -U customer -d kl_dpdb_ecommerce_database
    select * from products;
    delete from products where id='b136c1cf-d1e8-483f-9064-1c866f25195f';





