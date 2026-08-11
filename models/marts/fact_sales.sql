{{ config(
    materialized='incremental',
    unique_key='order_number',
    incremental_strategy='merge',
    partition_by={
      "field": "order_date",
      "data_type": "date",
      "granularity": "month"
    },
    cluster_by=["customer_key", "product_key"]
) }}

with sd as (
    select * from {{ ref('stg_crm_sales_details') }}
),
pr as (
    select * from {{ ref('dim_products') }}
),
cu as (
    select * from {{ ref('dim_customers') }}
)
select
    sd.sls_ord_num  as order_number,
    coalesce(pr.product_key, convert(nvarchar(32), hashbytes('MD5', 'n/a'), 2))  as product_key,
    coalesce(cu.customer_key, convert(nvarchar(32), hashbytes('MD5', 'n/a'), 2)) as customer_key,
    sd.sls_order_dt as order_date,
    sd.sls_ship_dt  as shipping_date,
    sd.sls_due_dt   as due_date,
    sd.sls_sales    as sales_amount,
    sd.sls_quantity as quantity,
    sd.sls_price    as price,
    sd.dwh_create_date
from sd
left join pr
    on sd.sls_prd_key = pr.product_number
    and sd.sls_order_dt between pr.valid_from and coalesce(pr.valid_to, '9999-12-31')
left join cu
    on sd.sls_cust_id = cu.customer_id

{% if is_incremental() %}
  where sd.dwh_create_date > (select max(dwh_create_date) from {{ this }})
{% endif %}
