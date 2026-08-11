with pn as (
    select * from {{ ref('stg_crm_prd_info') }}
),
pc as (
    select * from {{ ref('stg_erp_px_cat_g1v2') }}
)
select
    convert(nvarchar(32), hashbytes('MD5', concat(upper(trim(pn.prd_key)), '||', cast(pn.prd_start_dt as varchar))), 2) as product_key,
    pn.prd_id       as product_id,
    pn.prd_key      as product_number,
    pn.prd_nm       as product_name,
    pn.cat_id       as category_id,
    pc.cat          as category,
    pc.subcat       as subcategory,
    pn.prd_cost     as cost,
    pn.prd_line     as product_line,
    pn.prd_start_dt as valid_from,
    pn.prd_end_dt   as valid_to,
    case when pn.prd_end_dt is null then 1 else 0 end as is_current
from pn
left join pc on pn.cat_id = pc.id
union all
select
    convert(nvarchar(32), hashbytes('MD5', 'n/a'), 2) as product_key,
    -1              as product_id,
    'n/a'           as product_number,
    'Unknown'       as product_name,
    'n/a'           as category_id,
    'n/a'           as category,
    'n/a'           as subcategory,
    0               as cost,
    'n/a'           as product_line,
    '1900-01-01'    as valid_from,
    null            as valid_to,
    1               as is_current
