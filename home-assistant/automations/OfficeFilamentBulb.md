alias: Office Filament Bulb - Scheduled Daily
description: Turn on filament bulb daily from 9am to 9pm at 30% brightness
triggers:
  - at: "09:00:00"
    id: morning_on
    trigger: time
  - at: "21:00:00"
    id: evening_off
    trigger: time
actions:
  - choose:
      - conditions:
          - condition: trigger
            id: morning_on
        sequence:
          - target:
              entity_id: light.hue_filament_bulb_1
            data:
              brightness_pct: 30
            action: light.turn_on
      - conditions:
          - condition: trigger
            id: evening_off
        sequence:
          - target:
              entity_id: light.hue_filament_bulb_1
            action: light.turn_off
mode: single
