with source as (
    select * from {{ source('raw_erp', 'erp_loc_a101') }}
)
select
    replace(cid, '-', '') as cid,
    case
        when trim(cntry) = 'DE' then 'Germany'
        when trim(cntry) in ('US', 'USA') then 'United States'
        when trim(cntry) = '' or cntry is null then 'n/a'
        else trim(cntry)
    end as cntry
from source
