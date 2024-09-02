SELECT
	c.country,
	COUNT(DISTINCT c.customerid) AS num_customer,
	ROUND(SUM(od.quantity * unitprice * (od.discount + 1)), 2) AS revenue
FROM customers c
JOIN orders o ON c.customerid = o.customerid
JOIN order_details od ON o.orderid = od.orderid 
GROUP BY c.country
ORDER BY revenue DESC, num_customer DESC
LIMIT 10;

SELECT
	c.customerid,
	c.companyName,
	COUNT(DISTINCT o.orderID) AS num_customer,
	ROUND(SUM(od.quantity * od.unitprice * (od.discount + 1)), 2) AS revenue
FROM customers c
JOIN orders o ON c.customerid = o.customerid
JOIN order_details od ON o.orderid = od.orderid 
GROUP BY c.customerid, c.companyName
ORDER BY revenue DESC, num_customer DESC
LIMIT 10;

SELECT 
    e.employeeID,
    e.employeeName AS employee_name,
    SUM(od.unitPrice * od.quantity * (1 - od.discount)) AS total_sales,
    RANK() OVER (ORDER BY SUM(od.unitPrice * od.quantity * (1 - od.discount)) DESC) AS sales_rank,
    SUM(od.unitPrice * od.quantity * (1 - od.discount)) - 
    FIRST_VALUE(SUM(od.unitPrice * od.quantity * (1 - od.discount))) OVER (ORDER BY SUM(od.unitPrice * od.quantity * (1 - od.discount)) DESC) AS sales_difference_from_top
FROM employees e
JOIN orders o ON e.employeeID = o.employeeID
JOIN order_details od ON o.orderID = od.orderID
GROUP BY e.employeeID, e.employeeName
ORDER BY sales_rank;

SELECT 
    s.shipperid,
    s.companyName,
    COUNT(DISTINCT o.orderid) AS orders_delivered,
    SUM(CASE WHEN o.requireddate >= o.shippeddate THEN 1 ELSE 0 END) AS orders_delivered_on_time,
    ROUND(
        (COUNT(DISTINCT o.orderid) - SUM(CASE WHEN o.requireddate >= o.shippeddate THEN 1 ELSE 0 END))::numeric 
        / COUNT(DISTINCT o.orderid) * 100, 
        2
    ) AS failure_rate
FROM orders o 
JOIN shippers s ON o.shipperid = s.shipperid
GROUP BY s.shipperid
ORDER BY orders_delivered DESC;

SELECT 
    o.shipperID,
    ROUND(AVG(o.shippedDate - o.orderDate), 2) AS average_delivery_days,
    COUNT(o.orderID) AS total_orders
FROM orders o
WHERE o.shippedDate IS NOT NULL AND o.orderDate IS NOT NULL
GROUP BY o.shipperID
ORDER BY average_delivery_days ASC;

SELECT
    p.productid,
    p.productname,
    ROUND(SUM(od.quantity * od.unitprice), 2) AS revenue
FROM products p
JOIN order_details od ON p.productid = od.productid
WHERE p.discontinued = 0
GROUP BY p.productid
ORDER BY revenue DESC
LIMIT 10;

WITH subq AS (
    SELECT 
        p.productid,
        p.productname,
        SUM(
            CASE 
                WHEN EXTRACT(YEAR FROM o.orderdate) = 2013
                THEN od.quantity * od.unitprice
                ELSE 0
            END
        ) AS year_2013_sales,
        SUM(
            CASE 
                WHEN EXTRACT(YEAR FROM o.orderdate) = 2014
                THEN od.quantity * od.unitprice
                ELSE 0
            END
        ) AS year_2014_sales,
        SUM(
            CASE 
                WHEN EXTRACT(YEAR FROM o.orderdate) = 2015
                THEN od.quantity * od.unitprice
                ELSE 0
            END
        ) AS year_2015_sales
    FROM products p
    JOIN order_details od ON p.productid = od.productid
    JOIN orders o ON od.orderid = o.orderid
    GROUP BY p.productid
)
SELECT 
    productid,
    productname,
    year_2013_sales,
    year_2014_sales,
    year_2015_sales,
    CASE 
        WHEN year_2014_sales != 0 
        THEN ROUND((year_2014_sales - year_2013_sales)::numeric / year_2014_sales * 100, 2)
        ELSE NULL
    END AS growth_rate_13_14,
    CASE 
        WHEN year_2015_sales != 0 
        THEN ROUND((year_2015_sales - year_2014_sales)::numeric / year_2015_sales * 100, 2)
        ELSE NULL
    END AS growth_rate_14_15
FROM subq
WHERE year_2015_sales >= year_2014_sales AND year_2014_sales >= year_2013_sales
ORDER BY growth_rate_14_15 DESC, growth_rate_13_14 DESC
LIMIT 10;

SELECT 
    TO_CHAR(o.orderdate, 'YYYY-MM') AS months,
    COUNT(DISTINCT o.orderid) AS total_orders,
    ROUND(AVG(od.quantity * od.unitprice * (1 - od.discount)), 2) AS average_order_value,
    ROUND(AVG(AVG(od.quantity * od.unitprice * (1 - od.discount)))
        OVER (ORDER BY TO_CHAR(o.orderdate, 'YYYY-MM')), 2) AS running_average,
    ROUND(SUM(od.quantity * od.unitprice * (1 - od.discount)), 2) AS total_sales,
    ROUND(SUM(SUM(od.quantity * od.unitprice * (1 - od.discount))) 
        OVER (ORDER BY TO_CHAR(o.orderdate, 'YYYY-MM')), 2) AS running_total
FROM orders o
JOIN order_details od ON o.orderid = od.orderid
GROUP BY months
ORDER BY months DESC;

WITH category_sales AS (
    SELECT 
        cat.categoryID,
        cat.categoryName,
        SUM(od.unitPrice * od.quantity * (1 - od.discount)) AS total_revenue
    FROM categories cat
    JOIN products p ON cat.categoryID = p.categoryID
    JOIN order_details od ON p.productID = od.productID
    GROUP BY cat.categoryID, cat.categoryName
),
total_sales AS (
    SELECT 
        SUM(total_revenue) AS overall_revenue
    FROM category_sales
)
SELECT 
    cs.categoryName,
    cs.total_revenue,
    ROUND((cs.total_revenue / ts.overall_revenue) * 100, 2) AS percentage_of_total_sales
FROM category_sales cs, total_sales ts
ORDER BY cs.total_revenue DESC;

WITH RecentOrderDates AS (
    SELECT 
        customerID,
        MAX(orderdate) AS most_recent_orderdate
    FROM orders
    GROUP BY customerID
),
OrdersInLast6Months AS (
    SELECT 
        c.customerID
    FROM customers c
    JOIN orders o ON c.customerID = o.customerID
    JOIN RecentOrderDates r ON c.customerID = r.customerID
    WHERE o.orderdate > r.most_recent_orderdate - INTERVAL '6 Months'
)
SELECT 
    c.customerID,
    c.companyName
FROM customers c
LEFT JOIN OrdersInLast6Months o ON c.customerID = o.customerID
WHERE o.customerID IS NULL
ORDER BY c.customerID;

SELECT 
    p1.productName AS product_1,
    p2.productName AS product_2,
    COUNT(*) AS times_ordered_together
FROM 
    order_details od1
JOIN 
    order_details od2 ON od1.orderID = od2.orderID AND od1.productID < od2.productID
JOIN 
    products p1 ON od1.productID = p1.productID
JOIN 
    products p2 ON od2.productID = p2.productID
GROUP BY 
    p1.productName, p2.productName
HAVING 
    COUNT(*) >= 5
ORDER BY 
    times_ordered_together DESC
LIMIT 10;

SELECT 
    e.employeeName AS employee_name,
    COUNT(o.orderID) AS total_orders_handled,
    ROUND(AVG(o.shippedDate - o.orderDate), 2) AS average_processing_days,
    RANK() OVER (ORDER BY AVG(o.shippedDate - o.orderDate)) AS efficiency_rank
FROM 
    employees e
JOIN 
    orders o ON e.employeeID = o.employeeID
WHERE 
    o.shippedDate IS NOT NULL
    AND o.orderDate IS NOT NULL
GROUP BY 
    e.employeeName
ORDER BY 
    efficiency_rank;

SELECT 
    c.customerID,
    c.companyName,
    SUM(od.unitPrice * od.quantity) AS total_amount_before_discount,
    ROUND(SUM(od.unitPrice * od.quantity * od.discount), 2) AS total_discount_given
FROM customers c
JOIN orders o ON c.customerID = o.customerID
JOIN order_details od ON o.orderID = od.orderID
GROUP BY c.customerID, c.companyName
ORDER BY total_discount_given DESC;
