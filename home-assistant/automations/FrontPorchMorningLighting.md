alias: Front Porch Morning Lighting
description: Turn on porch lights at 6am, turn off 30 minutes after sunrise
triggers:
  - at: "06:00:00"
    trigger: time
    id: morning_on
  - event: sunrise
    offset: "00:30:00"
    id: sunrise_off
    trigger: sun
actions:
  - choose:
      - conditions:
          - condition: trigger
            id: morning_on
        sequence:
          - target:
              entity_id:
                - light.front_porch_1
                - light.front_porch_2
            action: light.turn_on
            data:
              brightness_pct: 100
              color_temp_kelvin: 2203
      - conditions:
          - condition: trigger
            id: sunrise_off
        sequence:
          - target:
              entity_id:
                - light.front_porch_1
                - light.front_porch_2
            action: light.turn_off
            data: {}
mode: single
