<?php

return [
    'nearby_default_km' => env('COOKSHARE_NEARBY_DEFAULT_KM', 5),
    'map_pin_ttl_hours' => env('COOKSHARE_MAP_PIN_TTL_HOURS', 24),
    'story_ttl_hours' => env('COOKSHARE_STORY_TTL_HOURS', 24),
    'aws_location_map_name' => env('AWS_LOCATION_MAP_NAME', 'CookShareMap'),
];
