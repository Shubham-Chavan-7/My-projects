-- Task-1 – Database & Tables

CREATE DATABASE SupplyChainFinanceManagement;
GO

USE SupplyChainFinanceManagement;
GO

/*===============================================================
 Dimension Tables
================================================================*/

-- 1. dim_customer
CREATE TABLE dim_customer (
    customer_code   INT          NOT NULL PRIMARY KEY,
    customer        VARCHAR(255) NOT NULL,
    platform        VARCHAR(50)  NOT NULL,   -- e.g. 'Brick & Mortar', 'E-Commerce'
    channel         VARCHAR(50)  NOT NULL,   -- e.g. 'Retail', 'Direct', 'Distributor'
    market          VARCHAR(100) NOT NULL,   -- e.g. 'India', 'Germany'
    region          VARCHAR(100) NOT NULL,   -- e.g. 'APAC', 'EU'
    sub_region      VARCHAR(100) NULL,
    country         VARCHAR(100) NOT NULL,
    inventory_qty   INT          NULL        -- for triggers in Task-5 & 8/12
);

-- 2. dim_product
CREATE TABLE dim_product (
    product_code VARCHAR(20)   NOT NULL PRIMARY KEY,
    division     VARCHAR(100)  NOT NULL,     -- e.g. 'P & A'
    category     VARCHAR(100)  NOT NULL,     -- e.g. 'Accessories'
    segment      VARCHAR(100)  NOT NULL,     -- e.g. 'Mouse', 'Keyboard'
    product      VARCHAR(255)  NOT NULL,     -- product name
    variant      VARCHAR(100)  NOT NULL,
    inventory_qty INT          NULL          -- current stock, used later in triggers
);

/*===============================================================
 Fact Tables
================================================================*/

-- 3. fact_gross_price
CREATE TABLE fact_gross_price (
    product_code VARCHAR(20)   NOT NULL,
    fiscal_year  INT           NOT NULL,
    gross_price  DECIMAL(10,4) NOT NULL,
    CONSTRAINT PK_fact_gross_price 
        PRIMARY KEY (product_code, fiscal_year),
    CONSTRAINT FK_fg_product 
        FOREIGN KEY (product_code) REFERENCES dim_product(product_code)
);

-- 4. fact_pre_invoice_deductions
CREATE TABLE fact_pre_invoice_deductions (
    customer_code             INT           NOT NULL,
    fiscal_year               INT           NOT NULL,
    pre_invoice_discount_pct  DECIMAL(10,4) NOT NULL,
    CONSTRAINT PK_fact_pre_invoice_deductions 
        PRIMARY KEY (customer_code, fiscal_year),
    CONSTRAINT FK_preinv_customer 
        FOREIGN KEY (customer_code) REFERENCES dim_customer(customer_code)
);

-- 5. fact_post_invoice_deductions
CREATE TABLE fact_post_invoice_deductions (
    customer_code        INT           NOT NULL,
    product_code         VARCHAR(20)   NOT NULL,
    [date]               DATE          NOT NULL,
    discounts_pct        DECIMAL(10,4) NOT NULL,
    other_deductions_pct DECIMAL(10,4) NOT NULL,
    CONSTRAINT PK_fact_post_invoice_deductions 
        PRIMARY KEY (customer_code, product_code, [date]),
    CONSTRAINT FK_postinv_customer 
        FOREIGN KEY (customer_code) REFERENCES dim_customer(customer_code),
    CONSTRAINT FK_postinv_product 
        FOREIGN KEY (product_code)  REFERENCES dim_product(product_code)
);

-- 6. fact_sales_monthly
CREATE TABLE fact_sales_monthly (
    [date]        DATE        NOT NULL,
    product_code  VARCHAR(20) NOT NULL,
    customer_code INT         NOT NULL,
    sold_quantity INT         NOT NULL,
    CONSTRAINT PK_fact_sales_monthly 
        PRIMARY KEY ([date], product_code, customer_code),
    CONSTRAINT FK_sales_customer 
        FOREIGN KEY (customer_code) REFERENCES dim_customer(customer_code),
    CONSTRAINT FK_sales_product  
        FOREIGN KEY (product_code)  REFERENCES dim_product(product_code)
);

-- 7. fact_forecast_monthly
CREATE TABLE fact_forecast_monthly (
    [date]             DATE        NOT NULL,
    fiscal_year        INT         NOT NULL,
    product_code       VARCHAR(20) NOT NULL,
    customer_code      INT         NOT NULL,
    forecast_quantity  INT         NOT NULL,
    CONSTRAINT PK_fact_forecast_monthly 
        PRIMARY KEY ([date], product_code, customer_code),
    CONSTRAINT FK_ff_product 
        FOREIGN KEY (product_code)  REFERENCES dim_product(product_code),
    CONSTRAINT FK_ff_customer 
        FOREIGN KEY (customer_code) REFERENCES dim_customer(customer_code)
);

-- 8. fact_manufacturing_cost
CREATE TABLE fact_manufacturing_cost (
    product_code       VARCHAR(20)   NOT NULL,
    cost_year          INT           NOT NULL,
    manufacturing_cost DECIMAL(10,4) NOT NULL,
    CONSTRAINT PK_fact_manufacturing_cost 
        PRIMARY KEY (product_code, cost_year),
    CONSTRAINT FK_mc_product 
        FOREIGN KEY (product_code) REFERENCES dim_product(product_code)
);

-- 9. fact_freight_cost
CREATE TABLE fact_freight_cost (
    market         VARCHAR(100)  NOT NULL,
    fiscal_year    INT           NOT NULL,
    freight_pct    DECIMAL(10,4) NOT NULL,
    other_cost_pct DECIMAL(10,4) NOT NULL,
    CONSTRAINT PK_fact_freight_cost 
        PRIMARY KEY (market, fiscal_year)
    -- Could add FK to dim_customer.market if desired
);
GO

select * from dim_customer
select * from dim_product
select * from fact_forecast_monthly
select * from fact_freight_cost
select * from fact_gross_price
select* from fact_manufacturing_cost
select * from fact_post_invoice_deductions
select * from fact_pre_invoice_deductions
select * from fact_sales_monthly
---------------------------------------------------
Task-2 – Insert the Sample Records


/*===============================================================
 Task-2 – Sample INSERT templates
================================================================*/

USE SupplyChainFinanceManagement;
GO

---------------------------
INSERT INTO dim_product
    (product_code, division, category, segment, product, variant, inventory_qty)
VALUES
    ('A0191054005', 'P & A', 'Peripherals', 'MotherBoard', 'AQ MB Lite 01', 'Plus 2', NULL),
    ('A0191054009', 'P & A', 'Peripherals', 'MotherBoard', 'AQ MB Lite 02', 'Plus 2', NULL),
    ('A0118150101', 'P & A', 'Accessories', 'Mouse', 'AQ Master wired x1 MS', 'Standard 1', NULL),
    ('A2118150105', 'P & A', 'Accessories', 'Mouse', 'AQ Master wired x1 MS', 'Premium 1', NULL);
    


---------------------------
INSERT INTO fact_freight_cost
    (market, fiscal_year, freight_pct, other_cost_pct)
VALUES
    ('Germany', 2020, 0.0226, 0.0600),
    ('Germany', 2019, 0.0226, 0.0860),
    ('Germany', 2018, 0.0224, 0.0640),
    ('India',   2019, 0.0219, 0.0075),
    ('India',   2020, 0.0239, 0.0099),
    ('India',   2021, 0.0230, 0.0029),
    ('Indonesia', 2022, 0.0420, 0.0053);
   

---------------------------
-- fact_forecast_monthly
---------------------------
INSERT INTO fact_forecast_monthly
    ([date], fiscal_year, product_code, customer_code, forecast_quantity)
VALUES
    ('2017-09-01', 2018, 'A0118150101', 70002017, 20),
    ('2017-09-01', 2018, 'A0118150101', 70002018, 11),
    ('2017-09-01', 2018, 'A0118150101', 70003181, 8);
  

---------------------------
-- fact_manufacturing_cost 
---------------------------
INSERT INTO fact_manufacturing_cost
    (product_code, cost_year, manufacturing_cost)
VALUES
    ('A0118150101', 2018, 4.6190),
    ('A0118150101', 2019, 4.2033),
    ('A0118150101', 2020, 5.0207),
    ('A0118150101', 2021, 5.5172),
    ('A0118150101', 2022, 5.6036),
    ('A0118150102', 2019, 5.3235),
    ('A0118150102', 2020, 5.3479),
    ('A0118150102', 2021, 8.2635),
    ('A0118150103', 2018, 3.9469),
    ('A0118150103', 2019, 5.5306),
    ('A0118150103', 2020, 6.3264);
  

---------------------------
-- fact_post_invoice_deductions 
INSERT INTO fact_post_invoice_deductions
    (customer_code, product_code, [date], discounts_pct, other_deductions_pct)
VALUES
    (70002017, 'A0118150101', '2018-01-01', 0.0719, 0.0549),
    (70002017, 'A0118150101', '2018-04-01', 0.0729, 0.0550),
    (70002017, 'A0118150101', '2018-07-01', 0.0739, 0.0551),
    (70002017, 'A0118150101', '2018-10-01', 0.0739, 0.1542);
   

---------------------------
-- fact_pre_invoice_deductions 
---------------------------
INSERT INTO fact_pre_invoice_deductions
    (customer_code, fiscal_year, pre_invoice_discount_pct)
VALUES
    (70002017, 2018, 0.0824),
    (70002019, 2019, 0.0777),
    (70002017, 2020, 0.0735),
    (70002017, 2021, 0.0703),
    (70002017, 2022, 0.1057),
    (70002018, 2018, 0.2050),
    (70002018, 2019, 0.2577),
    (70002018, 2020, 0.2255),
    (70002018, 2021, 0.2651),
    (70003181, 2018, 0.0536);
   

---------------------------
-- fact_sales_monthly 
---------------------------
INSERT INTO fact_sales_monthly
    ([date], product_code, customer_code, sold_quantity)
VALUES
    ('2017-09-01', 'A0118150101', 70002017, 51),
    ('2017-09-01', 'A0118150101', 70002018, 77),
    ('2017-09-01', 'A0118150101', 70003181, 17),
    ('2017-09-01', 'A0118150101', 70003182, 6),
    ('2017-09-01', 'A0118150101', 70001857, 5),
    ('2017-09-01', 'A0118150101', 70001860, 29),
    ('2017-09-01', 'A0118150101', 70001799, 34),
    ('2017-09-01', 'A0118150101', 70002025, 18),
    ('2017-09-01', 'A0118150101', 70001870, 5),
    ('2017-09-01', 'A0118150101', 70001993, 10);
    
GO
…

/*===============================================================
 Fiscal Year Function
================================================================*/
CREATE FUNCTION dbo.get_fiscal_year (@calendar_date DATE)
RETURNS INT
AS
BEGIN
    DECLARE @y INT = YEAR(@calendar_date);
    DECLARE @m INT = MONTH(@calendar_date);

    -- Fiscal year = calendar year + 1 for Sep-Dec, else same year
    RETURN CASE WHEN @m >= 9 THEN @y + 1
                ELSE @y
           END;
END;
GO
-----------------------------------------------------------------
Task-3 Q1 – What does it return for 2023-07-15?
SELECT dbo.get_fiscal_year('2023-07-15') AS fiscal_year;


Result: 2023, because July is before September, so it falls into fiscal year 2023 (Sept-2022 to Aug-2023).

Task-3 Q2 – Monthly Product Transactions Report
/*===============================================================
 Task-3 Q2 – Monthly product transactions report
   Parameters: @p_customer_code, @p_fiscal_year
================================================================*/
DECLARE @p_customer_code INT = 70002017;   -- example
DECLARE @p_fiscal_year   INT = 2018;       -- example

SELECT
    sm.[date],
    sm.product_code,
    p.product,
    p.variant,
    sm.sold_quantity,
    gp.gross_price,
    sm.sold_quantity * gp.gross_price AS gross_price_total
FROM fact_sales_monthly AS sm
JOIN dim_product        AS p  ON sm.product_code = p.product_code
JOIN fact_gross_price   AS gp ON gp.product_code = sm.product_code
                              AND gp.fiscal_year = dbo.get_fiscal_year(sm.[date])
WHERE sm.customer_code = @p_customer_code
  AND dbo.get_fiscal_year(sm.[date]) = @p_fiscal_year
ORDER BY sm.[date], sm.product_code;
GO

Task-4 – Analytical Queries

Below are queries you can run directly. Adjust WHERE filters as needed.

1. Sales Trend Analysis (monthly trend per product)
SELECT
    dbo.get_fiscal_year(sm.[date]) AS fiscal_year,
    FORMAT(sm.[date], 'yyyy-MM')   AS year_month,
    sm.product_code,
    p.product,
    SUM(sm.sold_quantity)          AS total_qty
FROM fact_sales_monthly sm
JOIN dim_product p ON sm.product_code = p.product_code
GROUP BY dbo.get_fiscal_year(sm.[date]), FORMAT(sm.[date], 'yyyy-MM'),
         sm.product_code, p.product
ORDER BY fiscal_year, year_month, product_code;

2. Customer Segmentation – contribution to revenue
SELECT
    c.customer_code,
    c.customer,
    c.channel,
    c.market,
    SUM(sm.sold_quantity * gp.gross_price) AS revenue
FROM fact_sales_monthly sm
JOIN dim_customer      c  ON sm.customer_code = c.customer_code
JOIN fact_gross_price  gp ON gp.product_code = sm.product_code
                          AND gp.fiscal_year = dbo.get_fiscal_year(sm.[date])
GROUP BY c.customer_code, c.customer, c.channel, c.market
ORDER BY revenue DESC;

3. Product Performance Comparison
SELECT
    p.product_code,
    p.product,
    p.segment,
    SUM(sm.sold_quantity)                     AS total_qty,
    SUM(sm.sold_quantity * gp.gross_price)    AS total_revenue
FROM fact_sales_monthly sm
JOIN dim_product       p  ON sm.product_code = p.product_code
JOIN fact_gross_price  gp ON gp.product_code = sm.product_code
                          AND gp.fiscal_year = dbo.get_fiscal_year(sm.[date])
GROUP BY p.product_code, p.product, p.segment
ORDER BY total_revenue DESC;

4. Market Expansion Opportunities (from forecast)
SELECT
    c.market,
    ff.fiscal_year,
    SUM(ff.forecast_quantity) AS forecast_qty
FROM fact_forecast_monthly ff
JOIN dim_customer c ON ff.customer_code = c.customer_code
GROUP BY c.market, ff.fiscal_year
ORDER BY ff.fiscal_year, forecast_qty DESC;

5. Cost Analysis – Profitability by Product
WITH sales_cost AS (
    SELECT
        sm.product_code,
        dbo.get_fiscal_year(sm.[date]) AS fiscal_year,
        SUM(sm.sold_quantity)          AS sold_qty
    FROM fact_sales_monthly sm
    GROUP BY sm.product_code, dbo.get_fiscal_year(sm.[date])
)
SELECT
    p.product_code,
    p.product,
    s.fiscal_year,
    s.sold_qty,
    gp.gross_price,
    mc.manufacturing_cost,
    (gp.gross_price - mc.manufacturing_cost)          AS margin_per_unit,
    (gp.gross_price - mc.manufacturing_cost) * s.sold_qty AS total_margin
FROM sales_cost s
JOIN dim_product           p  ON s.product_code = p.product_code
JOIN fact_gross_price      gp ON gp.product_code = s.product_code
                              AND gp.fiscal_year = s.fiscal_year
JOIN fact_manufacturing_cost mc ON mc.product_code = s.product_code
                                AND mc.cost_year   = s.fiscal_year
ORDER BY total_margin DESC;

6. Discount Impact Analysis – Pre-invoice discounts vs revenue
SELECT
    c.customer_code,
    c.customer,
    pid.fiscal_year,
    pid.pre_invoice_discount_pct,
    SUM(sm.sold_quantity * gp.gross_price) AS gross_revenue,
    SUM(sm.sold_quantity * gp.gross_price * 
        (1 - pid.pre_invoice_discount_pct)) AS net_revenue_est
FROM fact_pre_invoice_deductions pid
JOIN dim_customer        c  ON pid.customer_code = c.customer_code
JOIN fact_sales_monthly  sm ON sm.customer_code  = c.customer_code
                            AND dbo.get_fiscal_year(sm.[date]) = pid.fiscal_year
JOIN fact_gross_price    gp ON gp.product_code   = sm.product_code
                            AND gp.fiscal_year   = pid.fiscal_year
GROUP BY c.customer_code, c.customer, pid.fiscal_year, pid.pre_invoice_discount_pct
ORDER BY pid.fiscal_year, net_revenue_est DESC;

7. Market-specific Freight Costs
SELECT
    market,
    fiscal_year,
    AVG(freight_pct)    AS avg_freight_pct,
    AVG(other_cost_pct) AS avg_other_cost_pct
FROM fact_freight_cost
GROUP BY market, fiscal_year
ORDER BY market, fiscal_year;

8. Seasonal Sales Patterns
SELECT
    dbo.get_fiscal_year(sm.[date]) AS fiscal_year,
    MONTH(sm.[date])               AS month_no,
    DATENAME(MONTH, sm.[date])     AS month_name,
    SUM(sm.sold_quantity)          AS total_qty
FROM fact_sales_monthly sm
GROUP BY dbo.get_fiscal_year(sm.[date]), MONTH(sm.[date]), DATENAME(MONTH, sm.[date])
ORDER BY fiscal_year, month_no;

9. Customer Loyalty – Purchase frequency
SELECT
    c.customer_code,
    c.customer,
    COUNT(DISTINCT dbo.get_fiscal_year(sm.[date])) AS active_fiscal_years,
    COUNT(DISTINCT FORMAT(sm.[date],'yyyy-MM'))    AS active_months,
    SUM(sm.sold_quantity)                          AS total_qty
FROM fact_sales_monthly sm
JOIN dim_customer c ON sm.customer_code = c.customer_code
GROUP BY c.customer_code, c.customer
ORDER BY active_months DESC, total_qty DESC;

10. Forecast Accuracy Evaluation
WITH actuals AS (
    SELECT
        dbo.get_fiscal_year(sm.[date]) AS fiscal_year,
        FORMAT(sm.[date], 'yyyy-MM')   AS year_month,
        sm.product_code,
        sm.customer_code,
        SUM(sm.sold_quantity)          AS actual_qty
    FROM fact_sales_monthly sm
    GROUP BY dbo.get_fiscal_year(sm.[date]), FORMAT(sm.[date], 'yyyy-MM'),
             sm.product_code, sm.customer_code
),
forecasts AS (
    SELECT
        ff.fiscal_year,
        FORMAT(ff.[date], 'yyyy-MM')   AS year_month,
        ff.product_code,
        ff.customer_code,
        SUM(ff.forecast_quantity)      AS forecast_qty
    FROM fact_forecast_monthly ff
    GROUP BY ff.fiscal_year, FORMAT(ff.[date], 'yyyy-MM'),
             ff.product_code, ff.customer_code
)
SELECT
    a.fiscal_year,
    a.year_month,
    a.product_code,
    a.customer_code,
    a.actual_qty,
    f.forecast_qty,
    CASE WHEN f.forecast_qty = 0 THEN NULL
         ELSE CAST(a.actual_qty AS DECIMAL(10,2)) / f.forecast_qty
    END AS forecast_accuracy
FROM actuals a
LEFT JOIN forecasts f
    ON a.fiscal_year   = f.fiscal_year
   AND a.year_month    = f.year_month
   AND a.product_code  = f.product_code
   AND a.customer_code = f.customer_code;


---------------------------------------------------------------------------
Task-5 – Functions, Stored Procedures, Triggers, Window Queries
1. UDF – Total Forecasted Quantity for a Product & Fiscal Year
CREATE FUNCTION dbo.ufn_total_forecast_for_product
(
    @product_code VARCHAR(20),
    @fiscal_year  INT
)
RETURNS INT
AS
BEGIN
    DECLARE @result INT;

    SELECT @result = ISNULL(SUM(forecast_quantity),0)
    FROM fact_forecast_monthly
    WHERE product_code = @product_code
      AND fiscal_year  = @fiscal_year;

    RETURN @result;
END;
GO

2. Customers whose monthly purchases exceed average monthly sales
WITH monthly_sales AS (
    SELECT
        dbo.get_fiscal_year([date]) AS fiscal_year,
        FORMAT([date],'yyyy-MM')    AS year_month,
        customer_code,
        SUM(sold_quantity)          AS qty
    FROM fact_sales_monthly
    GROUP BY dbo.get_fiscal_year([date]), FORMAT([date],'yyyy-MM'), customer_code
),
overall_avg AS (
    SELECT
        fiscal_year,
        AVG(qty * 1.0) AS avg_monthly_qty
    FROM monthly_sales
    GROUP BY fiscal_year
)
SELECT DISTINCT
    ms.customer_code,
    c.customer,
    ms.fiscal_year
FROM monthly_sales ms
JOIN overall_avg oa 
  ON ms.fiscal_year = oa.fiscal_year
JOIN dim_customer c 
  ON ms.customer_code = c.customer_code
WHERE ms.qty > oa.avg_monthly_qty
ORDER BY ms.fiscal_year, ms.customer_code;

3. Stored Procedure – Update Gross Price
CREATE PROCEDURE dbo.usp_update_gross_price
    @product_code VARCHAR(20),
    @fiscal_year  INT,
    @new_gross_price DECIMAL(10,4)
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM fact_gross_price 
               WHERE product_code = @product_code
                 AND fiscal_year  = @fiscal_year)
    BEGIN
        UPDATE fact_gross_price
        SET gross_price = @new_gross_price
        WHERE product_code = @product_code
          AND fiscal_year  = @fiscal_year;
    END
    ELSE
    BEGIN
        INSERT INTO fact_gross_price (product_code, fiscal_year, gross_price)
        VALUES (@product_code, @fiscal_year, @new_gross_price);
    END
END;
GO
----------------------------------------------------------------------------------
4. Trigger – Audit Log on Insert into Sales Table

First create audit log table:

CREATE TABLE fact_sales_audit_log (
    audit_id       INT IDENTITY(1,1) PRIMARY KEY,
    inserted_at    DATETIME2      NOT NULL DEFAULT SYSUTCDATETIME(),
    [date]         DATE           NOT NULL,
    product_code   VARCHAR(20)    NOT NULL,
    customer_code  INT            NOT NULL,
    sold_quantity  INT            NOT NULL,
    inserted_by    VARCHAR(128)   NULL
);
GO


Trigger:

CREATE TRIGGER trg_fact_sales_monthly_insert_audit
ON fact_sales_monthly
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO fact_sales_audit_log
        ([date], product_code, customer_code, sold_quantity, inserted_by)
    SELECT
        i.[date], i.product_code, i.customer_code, i.sold_quantity, SUSER_SNAME()
    FROM inserted i;
END;
GO

5. Window Function – Rank Products by Monthly Sales Quantity
SELECT
    dbo.get_fiscal_year([date]) AS fiscal_year,
    FORMAT([date],'yyyy-MM')    AS year_month,
    product_code,
    SUM(sold_quantity)          AS total_qty,
    RANK() OVER (
        PARTITION BY dbo.get_fiscal_year([date]), FORMAT([date],'yyyy-MM')
        ORDER BY SUM(sold_quantity) DESC
    ) AS sales_rank
FROM fact_sales_monthly
GROUP BY dbo.get_fiscal_year([date]), FORMAT([date],'yyyy-MM'), product_code
ORDER BY fiscal_year, year_month, sales_rank;

6. STRING_AGG – Names of Customers who bought a Product in a Timeframe
DECLARE @p_product_code VARCHAR(20) = 'A0118150101';
DECLARE @p_start_date   DATE        = '2017-09-01';
DECLARE @p_end_date     DATE        = '2017-12-31';

SELECT
    @p_product_code AS product_code,
    STRING_AGG(DISTINCT c.customer, ', ') AS customer_list
FROM fact_sales_monthly sm
JOIN dim_customer c ON sm.customer_code = c.customer_code
WHERE sm.product_code = @p_product_code
  AND sm.[date] BETWEEN @p_start_date AND @p_end_date;

7. UDF – Total Manufacturing Cost Over Range of Years
CREATE FUNCTION dbo.ufn_total_manufacturing_cost_range
(
    @product_code VARCHAR(20),
    @start_year   INT,
    @end_year     INT
)
RETURNS DECIMAL(18,4)
AS
BEGIN
    DECLARE @total DECIMAL(18,4);

    SELECT @total = ISNULL(SUM(manufacturing_cost), 0)
    FROM fact_manufacturing_cost
    WHERE product_code = @product_code
      AND cost_year BETWEEN @start_year AND @end_year;

    RETURN @total;
END;
GO

8. Stored Procedure + Trigger – Insert Sales & Enforce Quantity ≤ Inventory

Assumption: dim_product.inventory_qty holds available inventory.

Stored procedure:

CREATE PROCEDURE dbo.usp_insert_sales
    @date          DATE,
    @product_code  VARCHAR(20),
    @customer_code INT,
    @sold_quantity INT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO fact_sales_monthly ([date], product_code, customer_code, sold_quantity)
    VALUES (@date, @product_code, @customer_code, @sold_quantity);
END;
GO


Trigger to enforce inventory:

CREATE TRIGGER trg_fact_sales_monthly_check_inventory
ON fact_sales_monthly
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN dim_product p ON i.product_code = p.product_code
        WHERE i.sold_quantity > ISNULL(p.inventory_qty, 0)
    )
    BEGIN
        RAISERROR ('Sold quantity exceeds available inventory.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;
END;
GO

9. LEAD/LAG – Compare Monthly Sales of a Product with Previous Month
DECLARE @p_product_code2 VARCHAR(20) = 'A0118150101';

WITH monthly AS (
    SELECT
        FORMAT([date],'yyyy-MM') AS year_month,
        SUM(sold_quantity)       AS total_qty
    FROM fact_sales_monthly
    WHERE product_code = @p_product_code2
    GROUP BY FORMAT([date],'yyyy-MM')
)
SELECT
    year_month,
    total_qty,
    LAG(total_qty)  OVER (ORDER BY year_month) AS prev_month_qty,
    total_qty - LAG(total_qty) OVER (ORDER BY year_month) AS diff_from_prev
FROM monthly
ORDER BY year_month;

10. Top-selling Products in Each Market
WITH product_market AS (
    SELECT
        c.market,
        sm.product_code,
        SUM(sm.sold_quantity) AS total_qty
    FROM fact_sales_monthly sm
    JOIN dim_customer c ON sm.customer_code = c.customer_code
    GROUP BY c.market, sm.product_code
),
ranked AS (
    SELECT
        market,
        product_code,
        total_qty,
        RANK() OVER (PARTITION BY market ORDER BY total_qty DESC) AS rnk
    FROM product_market
)
SELECT *
FROM ranked
WHERE rnk = 1
ORDER BY market;

11. UDF + Procedure – Total Freight Cost for a Product

Assumption: Freight is calculated as gross_price * freight_pct per unit, averaged across markets where it sells.

CREATE FUNCTION dbo.ufn_total_freight_cost_product
(
    @product_code VARCHAR(20),
    @market       VARCHAR(100),
    @fiscal_year  INT
)
RETURNS DECIMAL(18,4)
AS
BEGIN
    DECLARE @freight_pct DECIMAL(18,4);
    DECLARE @gross_price DECIMAL(18,4);
    DECLARE @sold_qty    INT;
    DECLARE @total_cost  DECIMAL(18,4);

    SELECT @freight_pct = freight_pct
    FROM fact_freight_cost
    WHERE market = @market
      AND fiscal_year = @fiscal_year;

    SELECT @gross_price = gross_price
    FROM fact_gross_price
    WHERE product_code = @product_code
      AND fiscal_year  = @fiscal_year;

    SELECT @sold_qty = ISNULL(SUM(sold_quantity),0)
    FROM fact_sales_monthly sm
    JOIN dim_customer c ON sm.customer_code = c.customer_code
    WHERE sm.product_code = @product_code
      AND dbo.get_fiscal_year(sm.[date]) = @fiscal_year
      AND c.market = @market;

    SET @total_cost = ISNULL(@sold_qty,0) * ISNULL(@gross_price,0) * ISNULL(@freight_pct,0);

    RETURN @total_cost;
END;
GO


Stored procedure that uses it and updates an “overall cost” table/column (example: update an extra column in fact_manufacturing_cost – add column first):

ALTER TABLE fact_manufacturing_cost
ADD overall_cost DECIMAL(18,4) NULL;
GO

CREATE PROCEDURE dbo.usp_update_overall_cost
    @product_code VARCHAR(20),
    @market       VARCHAR(100),
    @fiscal_year  INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @freight_cost DECIMAL(18,4);

    SET @freight_cost = dbo.ufn_total_freight_cost_product(@product_code, @market, @fiscal_year);

    UPDATE fact_manufacturing_cost
    SET overall_cost = manufacturing_cost + @freight_cost
    WHERE product_code = @product_code
      AND cost_year    = @fiscal_year;
END;
GO

12. Trigger – Update Inventory Count in Product Table on New Sale
CREATE TRIGGER trg_fact_sales_monthly_update_inventory
ON fact_sales_monthly
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE p
    SET p.inventory_qty = ISNULL(p.inventory_qty,0) - i.sold_quantity
    FROM dim_product p
    JOIN inserted   i ON p.product_code = i.product_code;
END;
GO

13. Trigger – Enforce Referential Integrity via Trigger

(Although a foreign key is better, this shows the requested trigger.)

CREATE TRIGGER trg_fact_sales_monthly_product_exists
ON fact_sales_monthly
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM inserted i
        LEFT JOIN dim_product p ON i.product_code = p.product_code
        WHERE p.product_code IS NULL
    )
    BEGIN
        RAISERROR('Product does not exist in dim_product.',16,1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;
END;
GO

14. Procedure – Month-over-Month Growth Rate per Product
CREATE PROCEDURE dbo.usp_product_mom_growth
AS
BEGIN
    SET NOCOUNT ON;

    WITH monthly AS (
        SELECT
            dbo.get_fiscal_year([date]) AS fiscal_year,
            FORMAT([date],'yyyy-MM')    AS year_month,
            product_code,
            SUM(sold_quantity)          AS qty
        FROM fact_sales_monthly
        GROUP BY dbo.get_fiscal_year([date]), FORMAT([date],'yyyy-MM'), product_code
    )
    SELECT
        fiscal_year,
        product_code,
        year_month,
        qty,
        LAG(qty) OVER (PARTITION BY fiscal_year, product_code ORDER BY year_month) AS prev_qty,
        CASE 
            WHEN LAG(qty) OVER (PARTITION BY fiscal_year, product_code ORDER BY year_month) = 0 
                THEN NULL
            ELSE (qty - LAG(qty) OVER (PARTITION BY fiscal_year, product_code ORDER BY year_month))
                 * 1.0 / LAG(qty) OVER (PARTITION BY fiscal_year, product_code ORDER BY year_month)
        END AS mom_growth_rate
    FROM monthly
    ORDER BY fiscal_year, product_code, year_month;
END;
GO

15. UDF – Average Discount Percentage for a Product

Combining post-invoice discounts; you can extend to include pre-invoice if desired.

CREATE FUNCTION dbo.ufn_average_discount_for_product
(
    @product_code VARCHAR(20)
)
RETURNS DECIMAL(10,4)
AS
BEGIN
    DECLARE @avg DECIMAL(10,4);

    SELECT @avg = AVG(discounts_pct)
    FROM fact_post_invoice_deductions
    WHERE product_code = @product_code;

    RETURN @avg;
END;
GO

16. Customers with Highest Total Purchases in Each Region
WITH customer_region AS (
    SELECT
        c.region,
        c.customer_code,
        c.customer,
        SUM(sm.sold_quantity * gp.gross_price) AS revenue
    FROM fact_sales_monthly sm
    JOIN dim_customer c ON sm.customer_code = c.customer_code
    JOIN fact_gross_price gp ON gp.product_code = sm.product_code
                             AND gp.fiscal_year = dbo.get_fiscal_year(sm.[date])
    GROUP BY c.region, c.customer_code, c.customer
),
ranked AS (
    SELECT
        region,
        customer_code,
        customer,
        revenue,
        RANK() OVER (PARTITION BY region ORDER BY revenue DESC) AS rnk
    FROM customer_region
)
SELECT *
FROM ranked
WHERE rnk = 1
ORDER BY region;

17. Stored Procedure – Total Revenue for a Given Period
CREATE PROCEDURE dbo.usp_total_revenue_for_period
    @start_date DATE,
    @end_date   DATE
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        @start_date AS start_date,
        @end_date   AS end_date,
        SUM(sm.sold_quantity * gp.gross_price) AS total_revenue
    FROM fact_sales_monthly sm
    JOIN fact_gross_price gp ON gp.product_code = sm.product_code
                             AND gp.fiscal_year = dbo.get_fiscal_year(sm.[date])
    WHERE sm.[date] BETWEEN @start_date AND @end_date;
END;
GO

18. Trigger – Update Forecasted Quantity When New Product Added

Assumption: we have a UDF to estimate default forecast; here we’ll simply set 0.

CREATE TRIGGER trg_dim_product_insert_default_forecast
ON dim_product
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO fact_forecast_monthly ([date], fiscal_year, product_code, customer_code, forecast_quantity)
    SELECT
        CAST(CONCAT(YEAR(GETDATE()),'-09-01') AS DATE) AS [date],
        dbo.get_fiscal_year(CAST(CONCAT(YEAR(GETDATE()),'-09-01') AS DATE)) AS fiscal_year,
        i.product_code,
        c.customer_code,
        0 AS forecast_quantity
    FROM inserted i
    CROSS JOIN dim_customer c;  -- default zero forecast for all customers
END;
GO


(You can adjust logic and quantity as needed.)

19. Trigger – Flag Outliers in Monthly Sales

Create a table to store outlier flags:

CREATE TABLE fact_sales_outliers (
    outlier_id     INT IDENTITY(1,1) PRIMARY KEY,
    [date]         DATE        NOT NULL,
    product_code   VARCHAR(20) NOT NULL,
    customer_code  INT         NOT NULL,
    sold_quantity  INT         NOT NULL,
    created_at     DATETIME2   NOT NULL DEFAULT SYSUTCDATETIME()
);
GO


Trigger: define outliers as rows where quantity > 3× the average for that product in that month.

CREATE TRIGGER trg_fact_sales_monthly_outlier
ON fact_sales_monthly
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO fact_sales_outliers ([date], product_code, customer_code, sold_quantity)
    SELECT i.[date], i.product_code, i.customer_code, i.sold_quantity
    FROM inserted i
    CROSS APPLY (
        SELECT AVG(sold_quantity * 1.0) AS avg_qty
        FROM fact_sales_monthly s
        WHERE s.product_code = i.product_code
          AND FORMAT(s.[date],'yyyy-MM') = FORMAT(i.[date],'yyyy-MM')
    ) a
    WHERE i.sold_quantity > 3 * a.avg_qty;
END;
GO

20. Query – Products with Highest Average Gross Price Across Fiscal Years
SELECT TOP (10)
    product_code,
    AVG(gross_price) AS avg_gross_price
FROM fact_gross_price
GROUP BY product_code
ORDER BY avg_gross_price DESC;

Task-6 – Forecast Accuracy with Pivot

Example: for a specific product over multiple fiscal years, using a pivot to show forecast vs actual per month.

DECLARE @p_product_code VARCHAR(20) = 'A0118150101';

WITH actuals AS (
    SELECT
        dbo.get_fiscal_year(sm.[date]) AS fiscal_year,
        MONTH(sm.[date])               AS month_no,
        SUM(sm.sold_quantity)          AS actual_qty
    FROM fact_sales_monthly sm
    WHERE sm.product_code = @p_product_code
    GROUP BY dbo.get_fiscal_year(sm.[date]), MONTH(sm.[date])
),
forecasts AS (
    SELECT
        ff.fiscal_year,
        MONTH(ff.[date])               AS month_no,
        SUM(ff.forecast_quantity)      AS forecast_qty
    FROM fact_forecast_monthly ff
    WHERE ff.product_code = @p_product_code
    GROUP BY ff.fiscal_year, MONTH(ff.[date])
),
combined AS (
    SELECT
        COALESCE(a.fiscal_year,f.fiscal_year) AS fiscal_year,
        COALESCE(a.month_no, f.month_no)      AS month_no,
        ISNULL(a.actual_qty,0)               AS actual_qty,
        ISNULL(f.forecast_qty,0)             AS forecast_qty,
        CASE WHEN ISNULL(f.forecast_qty,0) = 0 THEN NULL
             ELSE CAST(ISNULL(a.actual_qty,0) AS DECIMAL(10,2)) /
                  NULLIF(f.forecast_qty,0)
        END AS forecast_accuracy
    FROM actuals a
    FULL OUTER JOIN forecasts f
      ON a.fiscal_year = f.fiscal_year
     AND a.month_no    = f.month_no
)
SELECT
    fiscal_year,
    month_no,
    actual_qty,
    forecast_qty,
    forecast_accuracy
FROM combined
ORDER BY fiscal_year, month_no;