# E-Commerce_Distributed_Database

**Introduction**

In the current world, online shopping has become an integral part of everyone's life. The E site plays the vital role in delivering certified products in the shortest possible time. E-commerce sites provide customers with seamless shopping experience and give them a comfortable lifestyle. It helps the customers to browse the wide range of products by applying different filters, which makes browsing easy. The payment gateway helps the customers to make the safe and Security transactions.

**Requirements:**

•	The goal of the project is to create an e-commerce platform with a strong database schema. It supports a variety of functionalities, including customer signup, order placement, address management, managing products, shopping cart, handling transactions, supplier information, the option to review and the rate, exciting discounts and gift vouchers, an excellent delivery system, and high security using error handling mechanism.
•	Overall to implement the e-commerce platform used 17 tables. Which is customer, products, product_category, address, cart, orders, transaction_summary, supplier, reviews, gift_vouchers, delivery_partner, customer_address, customer_gift_voucher, customer_delivery_partner, products_cart, order_products, products_suppliers. These tables include relation tables too. Which are the intermediary tables, links between the two entities.

**Assumptions:**

•	A customer can add multiple products to his/her cart as per choice. Whereas in the same way the same product can be added by multiple customers in the cart. It associates the many-to-many to relation between the products and the cart. As the relation is many-to-many an intermediary table formed to link the products and cart table that is products_cart.
•	As mentioned in point (1), in the same way a product can be ordered by many customers and during the product's delivery there can be the same product among the multiple orders. By this the products and orders table form the many-to-many relation. As it's relationship is many-to-many, an intermediary relation table is formed to link the orders and products  table that is products_orders.

•	There will be multiple suppliers who supply the same product and there are few suppliers where they can supply multiple products. For instance, there will multiple suppliers who supply washing machines like Samsung, lg, ifb etc. In the same way a supplier can supply multiple products like fridge, washing machine etc. By this the relation associated with the supplier and the product is many-to-many and there is intermediary table to form the link between them that is the products_suppliers
•	Multiple products can be placed in the location, and they have a specific address to it. By this it forms a many-to-one relation between the products and the address. When the group of products are stored in a particular location (warehouse) it helps the delivery partner to pick and deliver the products to the customer.
•	Group of products have a specific category, in most of the online shopping sites to make searching easier the products are categorized. For instance, dresses, tops, sarees come under clothing section, electronic gadgets like mobiles, power banks have the specific category. So, the relationship between products and the product_category is many-to-one. 
•	Each product has multiple reviews, which helps customers to purchase the product more easily. The relationship between the products and reviews is many-to-one which says that a product can have zero reviews, one or more reviews.
•	Each customer has at most one cart to add the items to purchase. It associates the one-to-one relation between the cart and the customer.
•	A customer can store multiple addresses, where he can order the products to multiple locations as per his/her choice. In the idle case, multiple customers can store the same address as when multiple as working in same company they want to order the products to their office location then the group of customers have the same address. The relationship associated between the customer and the address is many-to-many. There is an intermediary table which links customers and address table, which can also store the default address of the customer.
•	Each customer can have multiple gift vouchers to redeem, and a single gift voucher can be given to multiple customers with the same coupon code. Many-to-Many relation forms between the customers and the gift vouchers.
•	The site provides the leverage to place any number of orders by the customer.  This forms the many-to-one relation between the orders and the customer.
•	Delivery Partner can deliver any number of products to many customers, it makes the work faster and delivery of the products on time to the customers. A customer may contact multiple delivery partners for multiple orders. Thereby it forms the many-to-many relation between the customer and delivery partner. As it's a many-to-many relationship if forms the intermediary table cutomer_delivery_partner.
•	Each order stores the respective transaction details, this ensures that every order placed within the system is associated with a single recorder which summarizes the transaction details of the specific customer. It helps to easily track the customer transactions. This ensures the one-to-one relation between the orders and the transaction summary.
•	Many orders can be placed to a single address, and single order cannot be diverse among the multiple addresses. which ensures a many-to-one relation between the orders and the address. 
•	A single order is delivered by the specific delivery partner. This ensures the relationship between the orders and the delivery partner is one-to-one.
•	On a single order, the customers can provide multiple reviews as per their choice. This forms the many-to-one relationship between the reviews and the order.
•	Each supplier has exactly one address to it and each location is dedicated to a supplier. This ensures to form the one-to-one relationship between the suppliers and the address.
•	A customer can directly place the order, without adding to cart. Sometimes a customer will add multiple products to cart but he/she won’t buy it from cart, he/she can directly place order without using the cart.



