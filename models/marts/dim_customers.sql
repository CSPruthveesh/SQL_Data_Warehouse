with ci as (
    select * from {{ ref('stg_crm_cust_info') }}
),
ca as (
    select * from {{ ref('stg_erp_cust_az12') }}
),
la as (
    select * from {{ ref('stg_erp_loc_a101') }}
)
select
    convert(nvarchar(32), hashbytes('MD5', concat(upper(trim(ci.cst_key)), '||')), 2) AS customer_key,
    ci.cst_id                          AS customer_id,
    ci.cst_key                         AS customer_number,
    ci.cst_firstname                   AS first_name,
    ci.cst_lastname                    AS last_name,
    la.cntry                           AS country,
    ci.cst_marital_status              AS marital_status,
    case 
        when ci.cst_gndr != 'n/a' then ci.cst_gndr
        else coalesce(ca.gen, 'n/a')
    end                                AS gender,
    ca.bdate                           AS birthdate,
    ci.cst_create_date                 AS create_date
from ci
left join ca on ci.cst_key = ca.cid
left join la on ci.cst_key = la.cid
union all
select
    convert(nvarchar(32), hashbytes('MD5', 'n/a'), 2) as customer_key,
    -1                                 as customer_id,
    'n/a'                              as customer_number,
    'Unknown'                          as first_name,
    'Unknown'                          as last_name,
    'n/a'                              as country,
    'n/a'                              as marital_status,
    'n/a'                              as gender,
    null                               as birthdate,
    null                               as create_date
