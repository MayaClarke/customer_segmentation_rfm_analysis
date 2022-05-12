/*

Covid 19 Data Exploration 

Skills used: CTE's, Windows Functions, Aggregate Functions, XML Path Function 

*/

--Inspecting data

SELECT *
 FROM `bold-vial-345717.sales_data_sample.sales_data` 

--Checking unique values

SELECT DISTINCT STATUS FROM `bold-vial-345717.sales_data_sample.sales_data` --Good one to plot
SELECT DISTINCT YEAR_ID FROM `bold-vial-345717.sales_data_sample.sales_data` --2003-2005
SELECT DISTINCT PRODUCTLINE FROM `bold-vial-345717.sales_data_sample.sales_data` --Good one to plot
SELECT DISTINCT COUNTRY FROM `bold-vial-345717.sales_data_sample.sales_data` --Good one to plot
SELECT DISTINCT DEALSIZE FROM `bold-vial-345717.sales_data_sample.sales_data` --Good one to plot
SELECT DISTINCT TERRITORY FROM `bold-vial-345717.sales_data_sample.sales_data` --Good one to plot

--ANALYSIS
--Let's start by grouping sales by productline

SELECT PRODUCTLINE, sum(sales) Revenue
FROM `bold-vial-345717.sales_data_sample.sales_data`
GROUP BY PRODUCTLINE
ORDER BY 2 DESC

SELECT YEAR_ID, sum(sales) Revenue
FROM `bold-vial-345717.sales_data_sample.sales_data`
GROUP BY YEAR_ID
ORDER BY 2 DESC

SELECT DEALSIZE, sum(sales) Revenue
FROM `bold-vial-345717.sales_data_sample.sales_data`
GROUP BY DEALSIZE
ORDER BY 2 DESC

--What was the best month for sales in a specific year? How much was eared that month?

SELECT MONTH_ID, SUM(sales) Revenue, COUNT(ORDERNUMBER) Frequency
FROM `bold-vial-345717.sales_data_sample.sales_data`
WHERE YEAR_ID = 2004 --Change year to see the rest
GROUP BY MONTH_ID
ORDER BY 2 DESC
--November has the highest sales

--November seems to be the month with the highest sales, what product do they sell in November?

SELECT MONTH_ID, PRODUCTLINE, SUM(sales) Revenue, COUNT(ORDERNUMBER) 
FROM `bold-vial-345717.sales_data_sample.sales_data`
WHERE YEAR_ID = 2004 AND MONTH_ID = 11 --Change year to see the rest
GROUP BY MONTH_ID, PRODUCTLINE
ORDER BY 3 DESC

--Who is our best customer? 

WITH rfm AS
(
	SELECT 
		CUSTOMERNAME, 
	SUM(sales) MonetaryValue,
		AVG(sales) AvgMonetaryValue,
		COUNT(ORDERNUMBER) Frequency,
		MAX(ORDERDATE) last_order_date,
		(SELECT MAX(ORDERDATE) FROM`bold-vial-345717.sales_data_sample.sales_data`) max_order_date,
		ABS(DATE_DIFF( MAX(ORDERDATE), (SELECT MAX(ORDERDATE) FROM`bold-vial-345717.sales_data_sample.sales_data`),day)) Recency
	FROM `bold-vial-345717.sales_data_sample.sales_data`
	GROUP BY CUSTOMERNAME
),
rfm_calc AS
(
SELECT rfm. *,
NTILE(4) OVER (ORDER BY Recency DESC) rfm_recency,
NTILE(4) OVER (ORDER BY Frequency) rfm_frequency,
NTILE(4) OVER (ORDER BY MonetaryValue) rfm_monetary
 FROM rfm
)
SELECT rfm_calc.*,rfm_recency + rfm_frequency + rfm_monetary as rfm_cell,
 CONCAT(rfm_recency,rfm_frequency,rfm_monetary) AS rfm_cell_string,
FROM rfm_calc

select CUSTOMERNAME, rfm_recency, rfm_frequency, rfm_monetary,
	case 
		when rfm_cell_string in ('111', '112' , '121', '122', '123', '132', '211', '212', '114', '141') then 'lost_customers'  --lost customers
		when rfm_cell_string in ('133', '134', '143', '244', '334', '343', '344', '144') then 'slipping away, cannot lose' -- (Big spenders who haven’t purchased lately) slipping away
		when rfm_cell_string in ('311', '411', '331') then 'new customers'
		when rfm_cell_string in ('222', '223', '233', '322') then 'potential churners'
		when rfm_cell_string in ('323', '333','321', '422', '332', '432') then 'active' --(Customers who buy often & recently, but at low price points)
		when rfm_cell_string in ('433', '434', '443', '444') then 'loyal'
	end rfm_segment
from `bold-vial-345717.sales_data_sample.rfm`

--What products are most often sold together?

--SELECT * FROM `bold-vial-345717.sales_data_sample.sales_data` WHERE ORDERNUMBER = 10411
select distinct OrderNumber,
 CONCAT(SUBSTR( (select ',1,(' + PRODUCTCODE 
 from `bold-vial-345717.sales_data_sample.sales_data` p 
 where ORDERNUMBER 
 in( select ORDERNUMBER 
 from( select ORDERNUMBER, count(*) rn 
 FROM `bold-vial-345717.sales_data_sample.sales_data` 
 where STATUS = 'Shipped' 
 group by ORDERNUMBER 
 )m 
 where rn = 3 
 ) 
 and p.ORDERNUMBER = s.ORDERNUMBER for  STRING path('')) -1)), 1, '',SUBSTR( (select ',(' + PRODUCTCODE 
 from `bold-vial-345717.sales_data_sample.sales_data` p 
 where ORDERNUMBER 
 in( select ORDERNUMBER 
 from( select ORDERNUMBER, count(*) rn
  FROM `bold-vial-345717.sales_data_sample.sales_data` 
  where STATUS = 'Shipped' 
  group by ORDERNUMBER 
  )m 
  where rn = 3 ) and p.ORDERNUMBER = s.ORDERNUMBER for  STRING path('')) + 1))) ProductCodes

from `bold-vial-345717.sales_data_sample.sales_data` s
order by 2 desc

select distinct OrderNumber, Count (*) rn,
STRING_AGG(PRODUCTCODE) AS PRODUCTCODE
	from `bold-vial-345717.sales_data_sample.sales_data` p
  	group by ORDERNUMBER
HAVING COUNT(*) = 3
order by 2 desc

--Which city has the highest number of sales in the USA?

SELECT CITY, SALES, COUNTRY
FROM `bold-vial-345717.sales_data_sample.sales_data`
WHERE COUNTRY = 'USA'
ORDER BY 2 DESC
--San Jose has the most sales with 14,082.8

--What is the best product in the USA?

SELECT COUNTRY, YEAR_ID, PRODUCTLINE, ROUND(SUM(SALES)) Revenue
FROM `bold-vial-345717.sales_data_sample.sales_data`
WHERE COUNTRY = 'USA'
GROUP BY COUNTRY, YEAR_ID, PRODUCTLINE
ORDER BY 4 DESC
--Classic Cars are the best product in the USA