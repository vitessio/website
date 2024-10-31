SELECT c.id                             AS customer_id,
       c.name                           AS customer_name,
       SUM(oi.quantity * oi.unit_price) AS total_spent
FROM customers c
         JOIN
     orders o ON c.id = o.customer_id
         JOIN
     order_items oi ON o.id = oi.order_id
WHERE o.status = 'Completed'
GROUP BY c.id, c.name
ORDER BY total_spent DESC;

SELECT p.category,
       AVG(oi.quantity * oi.unit_price) AS avg_order_amount
FROM products p
         JOIN
     order_items oi ON p.id = oi.product_id
         JOIN
     orders o ON oi.order_id = o.id
WHERE o.status IN ('Completed', 'Shipped')
GROUP BY p.category
ORDER BY avg_order_amount DESC;

SELECT c.id        AS customer_id,
       c.name      AS customer_name,
       COUNT(o.id) AS total_orders
FROM customers c
         JOIN
     orders o ON c.id = o.customer_id
GROUP BY c.id, c.name
HAVING COUNT(o.id) > 1
ORDER BY total_orders DESC;

SELECT p.id                             AS product_id,
       p.name                           AS product_name,
       SUM(oi.quantity * oi.unit_price) AS total_revenue
FROM products p
         JOIN
     order_items oi ON p.id = oi.product_id
GROUP BY p.id, p.name
ORDER BY total_revenue DESC LIMIT 1;

SELECT customer_id,
       customer_name,
       total_spent
FROM (SELECT c.id                             AS customer_id,
             c.name                           AS customer_name,
             SUM(oi.quantity * oi.unit_price) AS total_spent
      FROM customers c
               JOIN
           orders o ON c.id = o.customer_id
               JOIN
           order_items oi ON o.id = oi.order_id
      WHERE o.status = 'Completed'
      GROUP BY c.id, c.name) AS spending_summary
ORDER BY total_spent DESC LIMIT 3;

SELECT p.category,
       COALESCE(SUM(oi.quantity), 0) AS total_quantity_sold
FROM products p
         LEFT JOIN
     order_items oi ON p.id = oi.product_id
GROUP BY p.category
ORDER BY total_quantity_sold DESC;

SELECT o.id                          AS order_id,
       COUNT(DISTINCT oi.product_id) AS distinct_product_count
FROM orders o
         JOIN
     order_items oi ON o.id = oi.order_id
GROUP BY o.id
ORDER BY distinct_product_count DESC LIMIT 1;

SELECT DISTINCT c.id   AS customer_id,
                c.name AS customer_name
FROM customers c
         JOIN
     orders o ON c.id = o.customer_id
         JOIN
     order_items oi ON o.id = oi.order_id
         JOIN
     products p ON oi.product_id = p.id
WHERE p.price > (SELECT AVG(price) FROM products)
ORDER BY c.name;

SELECT c.id                                          AS customer_id,
       c.name                                        AS customer_name,
       COALESCE(SUM(oi.quantity * oi.unit_price), 0) AS total_revenue
FROM customers c
         LEFT JOIN
     orders o ON c.id = o.customer_id AND o.status = 'Completed'
         LEFT JOIN
     order_items oi ON o.id = oi.order_id
GROUP BY c.id, c.name
ORDER BY total_revenue DESC;

SELECT o.id AS order_id
FROM orders o
         JOIN
     order_items oi ON o.id = oi.order_id
         JOIN
     products p ON oi.product_id = p.id
GROUP BY o.id
HAVING COUNT(DISTINCT p.category) = 1
   AND MAX(p.category) = 'Gadgets';

SELECT c.id                                                    AS customer_id,
       c.name                                                  AS customer_name,
       SUM(CASE WHEN o.status = 'Completed' THEN 1 ELSE 0 END) AS completed_orders,
       SUM(CASE WHEN o.status = 'Pending' THEN 1 ELSE 0 END)   AS pending_orders
FROM customers c
         LEFT JOIN
     orders o ON c.id = o.customer_id
GROUP BY c.id, c.name
ORDER BY completed_orders DESC, pending_orders DESC;
