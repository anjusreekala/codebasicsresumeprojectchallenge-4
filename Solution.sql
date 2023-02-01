#1
SELECT DISTINCT market FROM dim_customer WHERE region = "APAC" AND customer = "Atliq Exclusive" ORDER BY market;



#2
WITH
		CTE1 (count1, prod1,category) AS (
					SELECT 
							COUNT( fact_sales_monthly.product_code),
                            product,
                            category
					FROM dim_product 
							CROSS JOIN 
						fact_sales_monthly
					ON fact_sales_monthly.product_code = dim_product.product_code 
					WHERE 
						fiscal_year = '2020' 
					GROUP BY product,category),
		CTE2 (count2, prod2, cat2) AS (
					SELECT 
							COUNT(fact_sales_monthly.product_code),
							product,
                            category
					FROM dim_product 
							CROSS JOIN
						 fact_sales_monthly 
					ON fact_sales_monthly.product_code = dim_product.product_code 
					WHERE
						fiscal_year = '2021'
					GROUP BY product,category)
SELECT 
		prod2 AS prod_name,
        cat2,
        count1 AS unique_products_2020,
        count2 AS unique_products_2021,
        ROUND(((count2-count1)/count1) * 100,2) AS percentage_chg 
FROM CTE2 
		LEFT JOIN 
	 CTE1 ON CTE2.prod2 = CTE1.prod1
ORDER BY percentage_chg ;



#3
SELECT 
		segment,
        COUNT(product_code) AS product_count
FROM dim_product 
GROUP BY segment
ORDER BY product_count DESC;

#4
WITH
CTE1 AS (
		SELECT 
			segment,
			COUNT(fact_sales_monthly.product_code) AS product_count_2020
		FROM dim_product 
				CROSS JOIN 
			 fact_sales_monthly
		ON dim_product.product_code = fact_sales_monthly.product_code 
		WHERE fact_sales_monthly.fiscal_year = '2020'
		GROUP BY 
			segment
		ORDER BY 
			product_count_2020 DESC),
CTE2 AS (
		SELECT 
			segment,
			COUNT(fact_sales_monthly.product_code) AS product_count_2021
		FROM dim_product 
				CROSS JOIN 
			 fact_sales_monthly
		ON dim_product.product_code = fact_sales_monthly.product_code 
		WHERE fact_sales_monthly.fiscal_year = '2021'
		GROUP BY 
			segment
		ORDER BY 
			product_count_2021 DESC )
SELECT 
		CTE1.segment,
        product_count_2020,
        product_count_2021,
        (product_count_2021 - product_count_2020) AS difference
FROM CTE1 INNER JOIN CTE2
ON CTE1.segment = CTE2.segment
ORDER BY difference DESC;


#5
SELECT 
    dim_product.product_code AS product_code,
    product,
    manufacturing_cost
FROM
    dim_product
        INNER JOIN
    fact_manufacturing_cost ON dim_product.product_code = fact_manufacturing_cost.product_code
WHERE
    manufacturing_cost = (SELECT 
            MAX(manufacturing_cost)
        FROM
            fact_manufacturing_cost)
        OR manufacturing_cost = (SELECT 
            MIN(manufacturing_cost)
        FROM
            fact_manufacturing_cost);


/*6*/

SELECT 
		fact_pre_invoice_deductions.customer_code,
        dim_customer.customer,
        ROUND(AVG(fact_pre_invoice_deductions.pre_invoice_discount_pct),4) AS avg_discount_percentage
FROM fact_pre_invoice_deductions
			INNER JOIN
	 dim_customer
ON fact_pre_invoice_deductions.customer_code = dim_customer.customer_code
WHERE fiscal_year = '2021' AND dim_customer.market = 'India'
GROUP BY 
		fact_pre_invoice_deductions.customer_code,
        dim_customer.customer
ORDER BY
		avg_discount_percentage DESC
LIMIT 5;


#7

SELECT 
    MONTHNAME(fact_sales_monthly.date) AS Month,
    fact_sales_monthly.fiscal_year AS Year,
    SUM(fact_sales_monthly.sold_quantity * fact_gross_price.gross_price) AS Gross_Sales_Amount
FROM
    fact_sales_monthly
        INNER JOIN
    dim_customer ON fact_sales_monthly.customer_code = dim_customer.customer_code
        INNER JOIN
    fact_gross_price ON fact_sales_monthly.product_code = fact_gross_price.product_code
							AND 
						fact_sales_monthly.fiscal_year = fact_gross_price.fiscal_year
WHERE
    dim_customer.customer = 'Atliq Exclusive'
GROUP BY Month , Year
ORDER BY Gross_Sales_Amount DESC;

#8
SELECT
	CASE
		WHEN MONTH(date) >= 9 AND MONTH(date) <= 11 THEN 1
        WHEN MONTH(date) = 12 OR MONTH(date) <= 2 THEN 2
        WHEN MONTH(date) >= 3 AND MONTH(date) <= 5 THEN 3
        WHEN MONTH(date) >= 6 AND MONTH(date) <= 8 THEN 4
    END AS Quarter,
    SUM(sold_quantity) AS total_sold_quantity
FROM fact_sales_monthly
WHERE fiscal_year = '2020'
GROUP BY Quarter
ORDER BY total_sold_quantity DESC
LIMIT 1;

#9 (a) WITHOUT WINDOWS FUNCTION
WITH 
CTE1 AS (
			SELECT 
					DISTINCT dim_customer.channel AS channel,
					ROUND(SUM(fact_sales_monthly.sold_quantity * fact_gross_price.gross_price)/1000000,2) AS gross_sales_mln
			FROM dim_customer
					INNER JOIN
				 fact_sales_monthly
			ON dim_customer.customer_code = fact_sales_monthly.customer_code
					INNER JOIN
				fact_gross_price
			ON fact_sales_monthly.product_code = fact_gross_price.product_code 
				AND
				fact_sales_monthly.fiscal_year = fact_gross_price.fiscal_year
			WHERE fact_sales_monthly.fiscal_year = '2021'
			GROUP BY dim_customer.channel ),
CTE2 AS (
			SELECT
					ROUND(SUM(fact_sales_monthly.sold_quantity * fact_gross_price.gross_price)/1000000,2) AS total_sales_2021
			FROM fact_sales_monthly
					INNER JOIN
				fact_gross_price
			ON fact_sales_monthly.product_code = fact_gross_price.product_code
				AND
                fact_sales_monthly.fiscal_year = fact_gross_price.fiscal_year
			WHERE fact_sales_monthly.fiscal_year = '2021'
)

SELECT 
		CTE1.channel,
        CTE1.gross_sales_mln, 
        ROUND((CTE1.gross_sales_mln/CTE2.total_sales_2021)*100, 2) AS percentage
FROM CTE1
		CROSS JOIN
	 CTE2
ORDER BY CTE1.gross_sales_mln DESC
LIMIT 1;


#9(b) WITH WINDOWS FUNCTION

WITH
CTE AS (
		SELECT 
					DISTINCT dim_customer.channel AS channel,
					ROUND(SUM(fact_sales_monthly.sold_quantity * fact_gross_price.gross_price)/1000000,2) AS gross_sales_mln
			FROM dim_customer
					INNER JOIN
				 fact_sales_monthly
			ON dim_customer.customer_code = fact_sales_monthly.customer_code
					INNER JOIN
				fact_gross_price
			ON fact_sales_monthly.product_code = fact_gross_price.product_code 
				AND
				fact_sales_monthly.fiscal_year = fact_gross_price.fiscal_year
			WHERE fact_sales_monthly.fiscal_year = '2021'
			GROUP BY dim_customer.channel)
SELECT 
		*,
		(gross_sales_mln*100)/SUM(gross_sales_mln) OVER() AS percentage
FROM CTE 
ORDER BY gross_sales_mln DESC
LIMIT 1;
    
    
#10
WITH
cte1 AS (
			SELECT
				division,
				dim_product.product_code,
				product,
				SUM(sold_quantity) AS total_sold_quantity
			FROM dim_product
				INNER JOIN
				fact_sales_monthly
			WHERE dim_product.product_code = fact_sales_monthly.product_code 
					AND fact_sales_monthly.fiscal_year = '2021'
			GROUP BY division,dim_product.product_code,product),
cte2 AS (
			SELECT
				*,
				DENSE_RANK() OVER(PARTITION BY division ORDER BY total_sold_quantity DESC) AS rank_order 
            FROM cte1)
SELECT 
	*
FROM cte2 
WHERE rank_order <= 3;










       

