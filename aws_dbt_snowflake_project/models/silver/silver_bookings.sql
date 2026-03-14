{{
  config(
    materialized = 'incremental',
    keys='BOOKINGS_ID'
    )
}}

SELECT 
    BOOKING_ID,
    LISTING_ID,
    BOOKING_DATE,
    {{ multiply('NIGHTS_BOOKED','BOOKING_AMOUNTS',2) }}  AS TOTAL_AMOUNT,
    CLEANING_FEE,
    SERVICE_FEE,
    BOOKING_STATUS,
    CREATED_AT
FROM
    {{ ref('bronze_bookings') }}