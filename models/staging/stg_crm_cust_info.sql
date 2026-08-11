with source as (
    select * from {{ source('raw_crm', 'crm_cust_info') }}
),
deduped as (
    select
        cst_id,
        cst_key,
        trim(cst_firstname) as cst_firstname,
        trim(cst_lastname) as cst_lastname,
        case 
            when upper(trim(cst_marital_status)) = 'S' then 'Single'
            when upper(trim(cst_marital_status)) = 'M' then 'Married'
            else 'n/a'
        end as cst_marital_status,
        {{ clean_gender('cst_gndr') }} as cst_gndr,
        cst_create_date,
        row_number() over (partition by cst_id order by cst_create_date desc) as rn
    from source
    where cst_id is not null
)
select
    cst_id,
    cst_key,
    cst_firstname,
    cst_lastname,
    cst_marital_status,
    cst_gndr,
    cst_create_date
from deduped
where rn = 1
