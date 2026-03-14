{{
  config(
    materialized = ' incremental ',
    )
}}
SELECT * FROM {{ source('staging', 'hosts') }}

{% if is_incremental() %}
    WHERE {{ incremental_col }} > (SELECT COALESCE(MAX({{ incremental_col }}),'1900-01-01') FROM {{ this }})
{% endif %}