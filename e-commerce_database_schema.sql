-- Create the uuid-ossp extension if not already installed
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- create tables for ecommerce site

    -- Create the address table
    CREATE TABLE address (
        id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        flat_no INTEGER NOT NULL,
        street VARCHAR(50) NOT NULL,
        city VARCHAR(50) NOT NULL,
        state VARCHAR(50) NOT NULL,
        country VARCHAR(50) NOT NULL,
        zip_code VARCHAR(10) NOT NULL
    );

    -- create product_category table
    CREATE TABLE product_category (
        id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        section VARCHAR(20) NOT NULL,
        audience_segment VARCHAR(20) NOT NULL
    );

    -- create Products table
    CREATE TABLE products (
        id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        name VARCHAR(50) NOT NULL,
        description VARCHAR(200) NOT NULL,
        price INTEGER NOT NULL,
        quantity INTEGER NOT NULL,
        discount INTEGER,
        brandname VARCHAR(20) NOT NULL,
        address_id UUID NOT NULL REFERENCES address(id),
        product_category_id UUID NOT NULL REFERENCES product_category(id)
    );

    -- create customer table
    CREATE TABLE customer (
        id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        first_name VARCHAR(20) NOT NULL,
        last_name VARCHAR(20) NOT NULL,
        phone_no VARCHAR(20) NOT NULL,
        email_id VARCHAR(255) NOT NULL,
        dob DATE NOT NULL,
        type VARCHAR(20) NOT NULL,
        CONSTRAINT invalid_customer_phone CHECK (phone_no ~ '^\(\d{3}\) \d{3}-\d{4}$'),
        CONSTRAINT invalid_customer_email CHECK (email_id ~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
        UNIQUE (phone_no),
        UNIQUE (email_id)
    );

    -- create cart table
    CREATE TABLE cart (
        id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        customer_id UUID NOT NULL REFERENCES customer(id),
        quantity INTEGER NOT NULL
    );

    -- create orders table
    CREATE TABLE orders (
        id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        status VARCHAR(20) NOT NULL,
        order_date DATE NOT NULL,
        address_id UUID NOT NULL REFERENCES address(id),
        customer_id UUID NOT NULL REFERENCES customer(id)
    );

    -- create transaction_summary table
    CREATE TABLE transaction_summary (
        id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        total_amount_paid INTEGER NOT NULL,
        payment_type VARCHAR(20) NOT NULL,
        date_of_payment DATE NOT NULL,
        order_id UUID NOT NULL REFERENCES orders(id)
    );

    -- create supplier table
    CREATE TABLE supplier (
        id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        name VARCHAR(50) NOT NULL,
        phone_no VARCHAR(20) NOT NULL UNIQUE CONSTRAINT invalid_supplier_phone_no CHECK (phone_no ~ '^\(\d{3}\) \d{3}-\d{4}$'),
        email VARCHAR(255) NOT NULL UNIQUE CONSTRAINT invalid_supplier_email CHECK (email ~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
        rating INTEGER,
        address_id UUID NOT NULL REFERENCES address(id)
    );

    -- create reviews table
    CREATE TABLE reviews (
        id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        rating INTEGER,
        comments VARCHAR(150),
        product_id UUID REFERENCES products(id),
        order_id UUID REFERENCES orders(id),
        customer_id UUID REFERENCES customer(id)
    );

    -- create gift_vouchers table
    CREATE TABLE gift_vouchers (
        id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        name VARCHAR(50),
        number INTEGER,
        amount INTEGER,
        expiry_date DATE
    );

    -- create delivery_partner table
    CREATE TABLE delivery_partner (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(50) NOT NULL,
    phone_no VARCHAR(20) NOT NULL CONSTRAINT invalid_delivery_partner_phone_no CHECK (phone_no ~ '^\(\d{3}\) \d{3}-\d{4}$'),
    email VARCHAR(255) NOT NULL CONSTRAINT invalid_delivery_partner_email CHECK (email ~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
    order_id UUID NOT NULL REFERENCES orders(id)
    );

    -- create customer_address table
    CREATE TABLE customer_address (
        customer_id UUID NOT NULL,
        address_id UUID NOT NULL,
        default_address BOOLEAN NOT NULL,
        PRIMARY KEY (customer_id, address_id),
        FOREIGN KEY (customer_id) REFERENCES customer(id),
        FOREIGN KEY (address_id) REFERENCES address(id)
    );

    -- create customer_gift_voucher table
    CREATE TABLE customer_gift_voucher (
        customer_id UUID NOT NULL,
        gift_voucher_id UUID NOT NULL,
        count INTEGER NOT NULL,
        PRIMARY KEY (customer_id, gift_voucher_id),
        FOREIGN KEY (customer_id) REFERENCES customer(id),
        FOREIGN KEY (gift_voucher_id) REFERENCES gift_vouchers(id)
    );

    -- create customer_delivery_partner table
    CREATE TABLE customer_delivery_partner (
        customer_id UUID NOT NULL,
        delivery_partner_id UUID NOT NULL,
        PRIMARY KEY (customer_id, delivery_partner_id),
        FOREIGN KEY (customer_id) REFERENCES customer(id),
        FOREIGN KEY (delivery_partner_id) REFERENCES delivery_partner(id)
    );

    -- create products_cart table
    CREATE TABLE products_cart (
        product_id UUID NOT NULL,
        cart_id UUID NOT NULL,
        count INTEGER NOT NULL,
        PRIMARY KEY (product_id, cart_id),
        FOREIGN KEY (product_id) REFERENCES products(id),
        FOREIGN KEY (cart_id) REFERENCES cart(id)
    );

    -- create orders_products table
    CREATE TABLE orders_products (
        order_id UUID NOT NULL,
        product_id UUID NOT NULL,
        quantity INTEGER NOT NULL,
        PRIMARY KEY (order_id, product_id),
        FOREIGN KEY (order_id) REFERENCES orders(id),
        FOREIGN KEY (product_id) REFERENCES products(id)
    );

    -- create products_suppliers table
    CREATE TABLE products_suppliers (
        product_id UUID NOT NULL,
        supplier_id UUID NOT NULL,
        quantity INTEGER NOT NULL,
        PRIMARY KEY (product_id, supplier_id),
        FOREIGN KEY (product_id) REFERENCES products(id),
        FOREIGN KEY (supplier_id) REFERENCES supplier(id)
    );

    -- display list of table
    command: \d
