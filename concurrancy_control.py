import psycopg2
from concurrent.futures import ThreadPoolExecutor

# connection details
host = "localhost"
port = 5432
database = "kl_dpdb_ecommerce_database"
user = "postgres"
password = "******"

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

if __name__ == "__main__":
    # customer-1
    customer_1_details = ('4d205a90-053f-4db1-a22a-37cc18355798', '52d999b8-de44-489d-8913-7ce999e26c5a', 2, 'robin', '(817) 777-4089', 'robin@example.com')
    # customer-2
    customer_2_details = ('4d205a90-053f-4db1-a22a-37cc18355798', '207397bf-5759-4a51-a44a-3b317971b09a', 2, 'josey', '(978) 717-4389', 'josey1@example.com')

    with ThreadPoolExecutor(max_workers=2) as executor:
        # Trigger the function concurrently with different user inputs
        executor.submit(place_order, *customer_1_details)
        executor.submit(place_order, *customer_2_details)
