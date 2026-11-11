
1.)SQL CREATE TABLE statements




-- 1. books table
CREATE TABLE books (
    book_id INT PRIMARY KEY,
    title VARCHAR(200),
    genre VARCHAR(100),
    price DECIMAL(6,2),
    stock INT
);

-- 2. customers table
CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    name VARCHAR(150),
    city VARCHAR(100),
    signup_date DATE
);

-- 3. orders table
CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    customer_id INT,
    book_id INT,
    quantity INT,
    order_date DATE,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (book_id) REFERENCES books(book_id)
);

-- 4. marketing_spend table
CREATE TABLE marketing_spend (
    spend_id INT PRIMARY KEY,
    customer_id INT,
    spend_amount DECIMAL(7,2),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);




2.) sample data into all four tables: Books, Customers, Orders and MarketingSpend


-- books
INSERT INTO books VALUES
(1, 'Data Science 101', 'Education', 29.99, 100),
(2, 'The Art of SQL', 'Technology', 34.50, 50),
(3, 'Mystery at the Bookstore', 'Fiction', 15.00, 20),
(4, 'Learn Python the Hard Way', 'Education', 40.00, 30),
(5, 'Fantasy World Chronicles', 'Fantasy', 22.50, 10);

-- customers
INSERT INTO customers VALUES
(1, 'Alice', 'New York', '2023-01-10'),
(2, 'Bob', 'San Francisco', '2023-03-15'),
(3, 'Charlie', 'Austin', '2023-06-20'),
(4, 'Diana', 'New York', '2024-01-10'),
(5, 'Evan', 'Chicago', '2024-04-05');

-- orders
INSERT INTO orders VALUES
(1, 1, 1, 2, '2024-06-01'),
(2, 2, 2, 1, '2024-06-02'),
(3, 1, 3, 1, '2024-06-03'),
(4, 3, 1, 3, '2024-06-04'),
(5, 4, 5, 2, '2024-06-04'),
(6, 5, 2, 2, '2024-06-05'),
(7, 2, 4, 1, '2024-06-05'),
(8, 1, 1, 1, '2024-06-06');

-- marketing_spend
INSERT INTO marketing_spend VALUES
(1, 1, 50.00),
(2, 2, 75.00),
(3, 3, 40.00),
(4, 4, 60.00),
(5, 5, 35.00);



3.) SQL Joins and aggregations to calculate total units sold and total revenue per book

SELECT 
    b.title,
    SUM(o.quantity) AS total_units_sold,
    SUM(o.quantity * b.price) AS total_revenue
FROM orders o
JOIN books b ON o.book_id = b.book_id
GROUP BY b.title
ORDER BY total_revenue DESC;

4.)We need to maintain healthy stock levels to prevent lost sales

SELECT 
    title, stock
FROM books
WHERE stock < 15;

5.)Common Table Expression (CTE) to understand top customers and create segments

WITH customer_metrics AS (
    SELECT
        c.customer_id,
        c.name,
        MAX(order_date) AS last_order,
        COUNT(o.order_id) AS frequency,
        SUM(o.quantity * b.price) AS monetary
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN Books b ON o.book_id = b.book_id
    GROUP BY c.customer_id
)
SELECT *,
       DATEDIFF(DAY, last_order, '2024-07-01') AS recency_days
FROM customer;


6.Compare customer lifetime revenue vs acquisition cost using joins and subqueries.

WITH customer_spend AS (
    SELECT 
        o.customer_id,
        SUM(o.quantity * b.price) AS total_revenue
    FROM orders o
    JOIN books b ON o.book_id = b.book_id
    GROUP BY o.customer_id
)
SELECT 
    c.customer_id,
    c.name,
    ms.spend_amount,
    cs.total_revenue,
    (cs.total_revenue - ms.spend_amount) AS profit
FROM customers c
JOIN marketing_spend ms ON c.customer_id = ms.customer_id
JOIN customer_spend cs ON c.customer_id = cs.customer_id;

7.)tracks how many books were sold and the total revenue generated each month.

SELECT 
    STRFTIME('%Y-%m', order_date) AS month,
    SUM(quantity * b.price) AS total_revenue
FROM orders o
JOIN books b ON o.book_id = b.book_id
GROUP BY month
ORDER BY month;


8.)This query identifies customers who have placed more than one order.

SELECT 
    c.customer_id,
    c.name,
    COUNT(DISTINCT o.order_id) AS total_orders
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id
HAVING total_orders > 1;

9.)This step calculates how much revenue is generated per order on average.

SELECT 
    ROUND(SUM(quantity * b.price) * 1.0 / COUNT(DISTINCT o.order_id), 2) AS avg_order_value
FROM orders o
JOIN books b ON o.book_id = b.book_id;

10.)Identify books that are often purchased by the same customer

SELECT 
    o1.book_id AS book_1,
    o2.book_id AS book_2,
    COUNT(*) AS times_bought_together
FROM orders o1
JOIN orders o2 
  ON o1.customer_id = o2.customer_id AND o1.order_id != o2.order_id
WHERE o1.book_id < o2.book_id
GROUP BY book_1, book_2
ORDER BY times_bought_together DESC
LIMIT 10;

11.)This step detects customers who haven’t made a purchase in the last 365 days, identifying users who may need re-engagement campaigns.
SELECT 
    c.customer_id,
    c.name,
    MAX(o.order_date) AS last_purchase,
    DATEDIFF(DAY, MAX(o.order_date), '2025-07-01') AS days_since_last_purchase
FROM customers c
JOIN orders o 
    ON c.customer_id = o.customer_id
GROUP BY c.customer_id
HAVING DATEDIFF(DAY, MAX(o.order_date), '2025-07-01') > 365;