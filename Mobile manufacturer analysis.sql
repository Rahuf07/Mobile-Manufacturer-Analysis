--SQL Advance Case Study

USE db_SQLCaseStudies

--Q1--BEGIN 
--1. List all the states in which we have customers who have bought cellphones from 2005 till today.	

SELECT DISTINCT T2.Country,State AS SATAE_NAME 
FROM FACT_TRANSACTIONS T1 
LEFT JOIN  DIM_LOCATION T2
ON T1.IDLocation = T2.IDLocation
LEFT JOIN DIM_DATE T3
ON T1.Date = T3.DATE
WHERE T3.YEAR >= '2005';


--Q1--END

--Q2--BEGIN
--2. What state in the US is buying the most 'Samsung' cell phones?
SELECT TOP 1 T2.State ,  COUNT(T1.Quantity) AS NO_OF_PHONES
FROM FACT_TRANSACTIONS T1
LEFT JOIN DIM_LOCATION T2
ON T1.IDLocation = T2.IDLocation
LEFT JOIN  DIM_MODEL T3
ON T1.IDModel = T3.IDModel
LEFT JOIN DIM_MANUFACTURER T4
ON T3.IDManufacturer = T4.IDManufacturer
WHERE T4.Manufacturer_Name = 'Samsung' AND T2.Country = 'US'
GROUP BY T2.State
ORDER BY COUNT(T1.Quantity) DESC;


--Q2--END

--Q3--BEGIN      
	
--3. Show the number of transactions for each model per zip code per state.

SELECT T2.State AS STATE, T2.ZipCode AS ZIPCODE ,T3.Model_Name AS MODEL,COUNT(T1.IDCustomer) AS TRANSACTIONS
FROM FACT_TRANSACTIONS T1
LEFT JOIN DIM_LOCATION T2
ON T1.IDLocation = T2.IDLocation
LEFT JOIN DIM_MODEL T3
ON T1.IDModel= T3.IDModel
GROUP BY T2.State, T2.ZipCode,T3.Model_Name
ORDER BY COUNT(T1.IDCustomer) DESC;


--Q3--END

--Q4--BEGIN

--4. Show the cheapest cellphone (Output should contain the price also)

SELECT TOP 1 T2.Manufacturer_Name AS MANUFACTURER, T1.Model_Name AS MODEL, T1.Unit_price AS PRICE
FROM DIM_MODEL T1
LEFT JOIN DIM_MANUFACTURER T2
ON T1.IDManufacturer = T2.IDManufacturer
ORDER BY T1.Unit_price ASC;

--Q4--END

--Q5--BEGIN

--5 Find out the average price for each model in the top5 manufacturers in terms of sales quantity and order by average price. 

SELECT T3.Manufacturer_Name AS MANUFACTURER, T2.Model_Name AS MODEL,AVG(T1.TotalPrice) AS AVG_PRICE
FROM FACT_TRANSACTIONS T1 
LEFT JOIN DIM_MODEL T2
ON T1.IDModel = T2.IDModel
LEFT JOIN DIM_MANUFACTURER T3
ON T2.IDManufacturer = T3.IDManufacturer
WHERE T3.Manufacturer_Name IN
(SELECT TOP 5 T3.Manufacturer_Name
FROM FACT_TRANSACTIONS T1
LEFT JOIN DIM_MODEL T2
ON T1.IDModel = T2.IDModel
LEFT JOIN DIM_MANUFACTURER T3
ON T2.IDManufacturer = T3.IDManufacturer
GROUP BY T3.Manufacturer_Name
ORDER BY SUM(T1.Quantity) DESC)
GROUP BY T3.Manufacturer_Name,T2.Model_Name
ORDER BY AVG(T1.TotalPrice) DESC

--Q5--END

--Q6--BEGIN

--6. List the names of the customers and the average amount spent in 2009, where the average is higher than  500

 SELECT T1.IDCustomer,Customer_Name, AVG(T1.TotalPrice) AS AVG_AMOUNT
 FROM FACT_TRANSACTIONS T1
 LEFT JOIN  DIM_CUSTOMER T2
 ON T1.IDCustomer = T2.IDCustomer
 LEFT JOIN DIM_DATE T3
 ON T1.Date = T3.DATE
 WHERE T3.YEAR = '2009'
 GROUP BY T2.Customer_Name, T1.IDCustomer
 HAVING AVG(T1.TotalPrice) > 500 
 ORDER BY AVG(T1.TotalPrice) DESC


--Q6--END
	
--Q7--BEGIN  

--7. List if there is any model that was in the top 5 in terms of quantity,simultaneously in 2008, 2009 and 2010 

SELECT*
FROM DIM_MODEL
WHERE IDMODEL IN (
( SELECT  TOP 5 T2.IDModel
FROM DIM_MODEL T1
LEFT JOIN FACT_TRANSACTIONS T2
ON T1.IDModel = T2.IDModel
GROUP BY T2.IDModel
ORDER BY  SUM(Quantity) DESC )
INTERSECT
(SELECT DISTINCT IDModel
FROM FACT_TRANSACTIONS
WHERE YEAR(DATE) = 2008) 
INTERSECT
(SELECT DISTINCT IDModel
FROM FACT_TRANSACTIONS
WHERE YEAR(DATE) = 2009) 
INTERSECT
(SELECT DISTINCT IDModel
FROM FACT_TRANSACTIONS
WHERE YEAR(DATE) = 2010) )


--Q7--END	

--Q8--BEGIN

--8. Show the manufacturer with the 2nd top sales in the year of 2009 and the manufacturer with the 2nd top sales in the year of 2010. 


WITH RANK_TABLE AS
 (SELECT T1.IDManufacturer,T1.Manufacturer_Name, YEAR(DATE) AS YEAR,SUM(T3.Quantity) AS TOTAL_SALE, RANK() OVER(ORDER BY SUM(T3.Quantity) DESC) AS RANK_
 FROM DIM_MANUFACTURER T1 LEFT JOIN DIM_MODEL T2
 ON T1.IDManufacturer = T2.IDManufacturer
 LEFT JOIN FACT_TRANSACTIONS T3
 ON T3.IDModel = T2.IDModel
 WHERE YEAR(DATE) = 2009
 GROUP BY T1.IDManufacturer,T1.Manufacturer_Name, YEAR(DATE)
 UNION ALL
 SELECT T1.IDManufacturer,T1.Manufacturer_Name, YEAR(DATE) AS YEAR ,SUM(T3.Quantity) AS TOTAL_SALE, RANK() OVER(ORDER BY SUM(T3.Quantity) DESC) AS RANK_
 FROM DIM_MANUFACTURER T1 LEFT JOIN DIM_MODEL T2
 ON T1.IDManufacturer = T2.IDManufacturer
 LEFT JOIN FACT_TRANSACTIONS T3
 ON T3.IDModel = T2.IDModel
 WHERE YEAR(DATE) = 2010
 GROUP BY T1.IDManufacturer,T1.Manufacturer_Name, YEAR(DATE))
 SELECT*
 FROM RANK_TABLE
 WHERE RANK_ = 2


--Q8--END

--Q9--BEGIN

--9. Show the manufacturers that sold cellphones in 2010 but did not in 2009. 	

 (SELECT  T1.IDManufacturer,T1.Manufacturer_Name
 FROM DIM_MANUFACTURER T1 LEFT JOIN DIM_MODEL T2
 ON T1.IDManufacturer = T2.IDManufacturer
 LEFT JOIN FACT_TRANSACTIONS T3
 ON T3.IDModel = T2.IDModel
 WHERE YEAR(DATE) = 2010)
 EXCEPT
 (SELECT   T1.IDManufacturer,T1.Manufacturer_Name 
 FROM DIM_MANUFACTURER T1 LEFT JOIN DIM_MODEL T2
 ON T1.IDManufacturer = T2.IDManufacturer
 LEFT JOIN FACT_TRANSACTIONS T3
 ON T3.IDModel = T2.IDModel
 WHERE YEAR(DATE) = 2009)


--Q9--END

--Q10--BEGIN

--10. Find top 100 customers and their average spend, average quantity by each year. Also find the percentage of change in their spend. 	

WITH SAMPLE_TABLE  AS (SELECT T1.IDCustomer, T2.Customer_Name, YEAR(DATE) AS YEAR, AVG(T1.Quantity) AS AVG_QTY,AVG(T1.TotalPrice) AS AVG_SPEND,
LAG(SUM(T1.TotalPrice),1) OVER (PARTITION BY T1.IDCustomer ORDER BY  YEAR(DATE) ASC ) CHANGE_IN_YEAR,SUM(T1.TotalPrice) AS TOTAL_SPEND
FROM FACT_TRANSACTIONS T1 LEFT JOIN DIM_CUSTOMER T2
ON T1.IDCustomer = T2.IDCustomer
 GROUP BY T1.IDCustomer, T2.Customer_Name, YEAR(DATE))
 SELECT IDCustomer, Customer_Name,YEAR,AVG_QTY,AVG_SPEND, TOTAL_SPEND,(((TOTAL_SPEND - CHANGE_IN_YEAR)/CHANGE_IN_YEAR)* 100) AS '%_CHANGE_YOY'
 FROM SAMPLE_TABLE


--Q10--END
	