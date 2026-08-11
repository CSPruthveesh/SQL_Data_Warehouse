with source as (
    select * from {{ source('raw_erp', 'erp_px_cat_g1v2') }}
)
select
    id,
    cat,
    subcat,
    maintenance
from source
