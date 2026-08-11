/*
===============================================================================
DDL Script: Create Gold Views
===============================================================================
Script Purpose:
    This script creates views for the Gold layer in the data warehouse. 
    The Gold layer represents the final dimension and fact tables (Star Schema)

    Each view performs transformations and combines data from the Silver layer 
    to produce a clean, enriched, and business-ready dataset.

Usage:
    - These views can be queried directly for analytics and reporting.
===============================================================================
*/

-- =============================================================================
-- Create Dimension: gold.dim_customers
-- =============================================================================
IF OBJECT_ID('gold.dim_customers', 'V') IS NOT NULL
    DROP VIEW gold.dim_customers;
GO

CREATE VIEW gold.dim_customers AS
SELECT
    CONVERT(NVARCHAR(32), HASHBYTES('MD5', CONCAT(UPPER(TRIM(ci.cst_key)), '||')), 2) AS customer_key, -- Deterministic surrogate key
    ci.cst_id                          AS customer_id,
    ci.cst_key                         AS customer_number,
    ci.cst_firstname                   AS first_name,
    ci.cst_lastname                    AS last_name,
    la.cntry                           AS country,
    ci.cst_marital_status              AS marital_status,
    CASE 
        WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr -- CRM is the primary source for gender
        ELSE COALESCE(ca.gen, 'n/a')  			   -- Fallback to ERP data
    END                                AS gender,
    ca.bdate                           AS birthdate,
    ci.cst_create_date                 AS create_date
FROM silver.crm_cust_info ci
LEFT JOIN silver.erp_cust_az12 ca
    ON ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 la
    ON ci.cst_key = la.cid
UNION ALL
SELECT
    CONVERT(NVARCHAR(32), HASHBYTES('MD5', 'n/a'), 2) AS customer_key,
    -1                                 AS customer_id,
    'n/a'                              AS customer_number,
    'Unknown'                          AS first_name,
    'Unknown'                          AS last_name,
    'n/a'                              AS country,
    'n/a'                              AS marital_status,
    'n/a'                              AS gender,
    NULL                               AS birthdate,
    NULL                               AS create_date;
GO

-- =============================================================================
-- Create Dimension: gold.dim_products
-- =============================================================================
IF OBJECT_ID('gold.dim_products', 'V') IS NOT NULL
    DROP VIEW gold.dim_products;
GO

CREATE VIEW gold.dim_products AS
SELECT
    CONVERT(NVARCHAR(32), HASHBYTES('MD5', CONCAT(UPPER(TRIM(pn.prd_key)), '||', CAST(pn.prd_start_dt AS VARCHAR))), 2) AS product_key, -- Unique key per version
    pn.prd_id       AS product_id,
    pn.prd_key      AS product_number,
    pn.prd_nm       AS product_name,
    pn.cat_id       AS category_id,
    pc.cat          AS category,
    pc.subcat       AS subcategory,
    pc.maintenance  AS maintenance,
    pn.prd_cost     AS cost,
    pn.prd_line     AS product_line,
    pn.prd_start_dt AS valid_from,
    pn.prd_end_dt   AS valid_to,
    CASE WHEN pn.prd_end_dt IS NULL THEN 1 ELSE 0 END AS is_current
FROM silver.crm_prd_info pn
LEFT JOIN silver.erp_px_cat_g1v2 pc
    ON pn.cat_id = pc.id
UNION ALL
SELECT
    CONVERT(NVARCHAR(32), HASHBYTES('MD5', 'n/a'), 2) AS product_key,
    -1              AS product_id,
    'n/a'           AS product_number,
    'Unknown'       AS product_name,
    'n/a'           AS category_id,
    'n/a'           AS category,
    'n/a'           AS subcategory,
    'n/a'           AS maintenance,
    0               AS cost,
    'n/a'           AS product_line,
    '1900-01-01'    AS valid_from,
    NULL            AS valid_to,
    1               AS is_current;
GO

-- =============================================================================
-- Create Fact Table: gold.fact_sales
-- =============================================================================
IF OBJECT_ID('gold.fact_sales', 'V') IS NOT NULL
    DROP VIEW gold.fact_sales;
GO

CREATE VIEW gold.fact_sales AS
SELECT
    sd.sls_ord_num  AS order_number,
    COALESCE(pr.product_key, CONVERT(NVARCHAR(32), HASHBYTES('MD5', 'n/a'), 2))  AS product_key,
    COALESCE(cu.customer_key, CONVERT(NVARCHAR(32), HASHBYTES('MD5', 'n/a'), 2)) AS customer_key,
    sd.sls_order_dt AS order_date,
    sd.sls_ship_dt  AS shipping_date,
    sd.sls_due_dt   AS due_date,
    sd.sls_sales    AS sales_amount,
    sd.sls_quantity AS quantity,
    sd.sls_price    AS price
FROM silver.crm_sales_details sd
LEFT JOIN gold.dim_products pr
    ON sd.sls_prd_key = pr.product_number
    AND sd.sls_order_dt BETWEEN pr.valid_from AND COALESCE(pr.valid_to, '9999-12-31')
LEFT JOIN gold.dim_customers cu
    ON sd.sls_cust_id = cu.customer_id;
GO
