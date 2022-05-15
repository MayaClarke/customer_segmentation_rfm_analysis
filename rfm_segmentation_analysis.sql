/*

RFM Sales Analysis

Skills used: CTE's, Windows Functions, Aggregate Functions, XML Path Function 

*/

-- Inspecting Data
SELECT *
  FROM [tempdb].[dbo].[sales_data_sample]

-- Checking unique values
SELECT DISTINCT status FROM [tempdb].[dbo].[sales_data_sample] -- Good one to plot
SELECT DISTINCT year_id FROM [tempdb].[dbo].[sales_data_sample]
SELECT DISTINCT productline FROM [tempdb].[dbo].[sales_data_sample] -- Good one to plot
SELECT DISTINCT country FROM [tempdb].[dbo].[sales_data_sample] -- Good one to plot
SELECT DISTINCT territory FROM [tempdb].[dbo].[sales_data_sample] -- Good on to plot

-- ANALYSIS
-- Let's start by grouping sales by productline
SELECT productline, sum (sales) Revenue
FROM [dbo].[sales_data_sample]
GROUP BY productline
ORDER BY 2 DESC
-- Classic Cars is the best productline 

-- Let's group by year
SELECT year_id, sum (sales) Revenue
FROM [dbo].[sales_data_sample]
GROUP BY year_id
ORDER BY 2 DESC
-- 2004 had the most sales
-- 2005 had the least sales

-- Looking at how many months they operated in 2005
SELECT DISTINCT month_id 
FROM [dbo].[sales_data_sample]
WHERE year_id = 2005
-- They only operated for five months in 2005

-- Let's group by dealsize
SELECT dealsize, sum (sales) Revenue
FROM [dbo].[sales_data_sample]
GROUP BY dealsize
ORDER BY 2 DESC
-- Medium dealsizes brought in the most revenue

-- What was the best month for sales in a specific year? How much was earned that month?
SELECT month_id, sum (sales) Revenue, count(ordernumber) Frequency
FROM [dbo].[sales_data_sample]
WHERE year_id = 2004 --2005 --2003
GROUP BY month_id
ORDER BY 2 DESC
-- November generated the most revenue $1089048

-- November is the best month, what prouduct do the sell in November?
SELECT month_id, productline, sum (sales) Revenue, count(ordernumber) Frequency
FROM [dbo].[sales_data_sample]
WHERE year_id = 2003
GROUP BY month_id, productline
ORDER BY 3 DESC
-- Classic cars were the best selling in november

-- RFM ANALYSIS
-- Recency - last order date
-- Frequency - count of total orders
-- Monetary value - total spend

-- Who is our best customer?
DROP TABLE IF EXISTS #rfm
;WITH rfm as 
(
SELECT 
		CUSTOMERNAME, 
		SUM(sales) MonetaryValue,
		AVG(sales) AvgMonetaryValue,
		COUNT(ORDERNUMBER) Frequency,
		MAX(ORDERDATE) last_order_date,
		(SELECT MAX(ORDERDATE) FROM [dbo].[sales_data_sample]) max_order_date,
		DATEDIFF(DD, max(ORDERDATE), (SELECt max(ORDERDATE) FROM [dbo].[sales_data_sample])) Recency
	FROM [dbo].[sales_data_sample]
	GROUP BY CUSTOMERNAME
),
rfm_calc as 
(
    SELECT r.*,
            NTILE(4) OVER (ORDER BY Recency DESC) rfm_recency,
            NTILE(4) OVER (ORDER BY Frequency) rfm_frequency,
            NTILE(4) OVER (ORDER BY MonetaryValue) rfm_monetary
        FROM rfm r
)
SELECT
	c.*, rfm_recency+ rfm_frequency+ rfm_monetary as rfm_cell,
	cast(rfm_recency as varchar) + cast(rfm_frequency as varchar) + cast(rfm_monetary  as varchar)rfm_cell_string
INTO  #rfm -- Creating temp table to view results
FROM rfm_calc c

-- Creating case statement for customer segmentation
SELECT customername , rfm_recency, rfm_frequency, rfm_monetary,
	case 
		when rfm_cell_string in (111, 112 , 121, 122, 123, 132, 211, 212, 114, 141) then 'lost_customers'  --lost customers
		when rfm_cell_string in (133, 134, 143, 244, 334, 343, 344, 144) then 'slipping away, cannot lose' -- (Big spenders who haven’t purchased lately) slipping away
		when rfm_cell_string in (311, 411, 331) then 'new customers' --Customers who have only made a couple purchases
		when rfm_cell_string in (222, 223, 233, 322) then 'potential churners'
		when rfm_cell_string in (323, 333,321, 422, 332, 432) then 'active' --(Customers who buy often & recently, but at low price points)
		when rfm_cell_string in (433, 434, 443, 444) then 'loyal'
	end rfm_segment

FROM #rfm

-- What products are most often sold together? 

SELECT DISTINCT ordernumber, stuff(

	(SELECT ',' + PRODUCTCODE
	FROM [dbo].[sales_data_sample] p
	WHERE ordernumber in 
		(

			SELECT ordernumber
			FROM (
				SELECT ordernumber, count(*) rn
				FROM [dbo].[sales_data_sample]
				WHERE status = 'Shipped'
				GROUP BY ordernumber
			)m
			WHERE rn = 3
		)
		AND p.ordernumber = s.ordernumber
		for xml path (''))

		, 1, 1, '') ProductCodes

FROM [dbo].[sales_data_sample] s
ORDER BY 2 DESC

-- What city has the highest number of sales in a specific country?
select city, sum (sales) Revenue
from [dbo].[sales_data_sample]
where country = 'USA'
group by city
order by 2 desc
-- San Rafael has the highest number of sales in the US



--- What is the best product in United States?
select country, YEAR_ID, PRODUCTLINE, sum(sales) Revenue
from [dbo].[sales_data_sample]
where country = 'USA'
group by  country, YEAR_ID, PRODUCTLINE
order by 4 desc
-- Classic Cars are the best selling products in the US

-- What coutnry has the highest number of sales?
select country, sum (sales) Revenue
from [dbo].[sales_data_sample]
group by country
order by 2 desc
-- The US has the highest revenue
