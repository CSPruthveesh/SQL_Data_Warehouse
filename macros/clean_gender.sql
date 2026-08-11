{% macro clean_gender(column_name) %}
    case 
        when upper(trim({{ column_name }})) in ('F', 'FEMALE') then 'Female'
        when upper(trim({{ column_name }})) in ('M', 'MALE') then 'Male'
        else 'n/a'
    end
{% endmacro %}
