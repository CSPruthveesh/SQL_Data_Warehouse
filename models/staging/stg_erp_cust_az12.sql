with source as (
    select * from {{ source('raw_erp', 'erp_cust_az12') }}
)
select
    case
        when cid like 'NAS%' then substring(cid, 4, len(cid))
        else cid
    end as cid,
    case
        when bdate > getdate() then null
        else bdate
    end as bdate,
    {{ clean_gender('gen') }} as gen
from source
