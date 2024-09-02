SELECT
	c.country,
	COUNT(DISTINCT c.customerid) AS num_customer,
	ROUND(SUM(od.quantity * (od.discount + 1)), 2) AS revenue
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
	ROUND(SUM(od.quantity * (od.discount + 1)), 2) AS revenue
FROM customers c
JOIN orders o ON c.customerid = o.customerid
JOIN order_details od ON o.orderid = od.orderid 
GROUP BY c.customerid, c.companyName
ORDER BY revenue DESC, num_customer DESC
LIMIT 10;

SELECT 
    e.employeeid,
    e.employeename,
    e.title,
    COUNT(DISTINCT o.orderID) AS num_customer,
	ROUND(SUM(od.quantity * (od.discount + 1)), 2) AS revenue
FROM employees e 
JOIN orders o ON e.employeeid = o.employeeid
JOIN order_details od ON o.orderid = od.orderid
GROUP BY e.employeeid
ORDER BY revenue DESC, num_customer DESC;

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
