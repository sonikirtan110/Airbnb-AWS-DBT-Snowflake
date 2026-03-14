{% set configs = [
    {
        'table' : 'AIRBNB.GOLD.OBT',
        'columns' : 'GOLD_obt.BOOKING_ID,GOLD_obt.HOST_ID,GOLD_obt.LISTING_ID,GOLD_bookings.TOTAL_AMOUNT,GOLD_bookings.SERVICE_FEE,GOLD_bookings.CLEANING_FEE,GOLD_bookings.ACCOMMODATES,GOLD_bookings.BEDROOMS,GOLD_bookings.BATHROOMS,GOLD_bookings.PRICE_PER_NIGHT,GOLD_bookings.RESPONSE_RATE',
        'alias' :'GOLD_bookings'
    },
    {
        'table' : 'AIRBNB.GOLD.GOLD_LISTINGS',
        'columns' : '',
        'alias' :'GOLD_listings',
        'join_condition' : 'GOLD_obt.listing_id = DIM_listings.listing_id'
    },
    {
        'table' : 'AIRBNB.GOLD.GOLD_HOSTS',
        'columns' : '',
        'alias' :'GOLD_hosts',
        'join_condition' : 'GOLD_obt.host_id = DIM_listings.host_id'
    }
]%}

SELECT =
      {{ config[0]['columns'] }}
FROM
    {% for config in configs %}
    {% if loop.first %}
        {{ config['table'] }} AS {{ config['alias'] }}
    {% else %}
        LEFT JOIN {{ config['table'] }} AS {{ config['alias'] }}
        ON {{ config['join_condition'] }}
        {% endif %}
        {% endfor %}