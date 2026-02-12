alias: Air Quality Fan Control
description: Adjust air filter speeds based on PM2.5 levels
triggers:
  - entity_id: sensor.office_air_filter_pm2_5
    above: 15
    for:
      minutes: 5
    trigger: numeric_state
    id: office_pm25_moderate
  - entity_id: sensor.office_air_filter_pm2_5
    above: 35
    for:
      minutes: 5
    trigger: numeric_state
    id: office_pm25_poor
  - entity_id: sensor.office_air_filter_pm2_5
    below: 12
    for:
      minutes: 10
    trigger: numeric_state
    id: office_pm25_good
  - entity_id: sensor.bedroom_filter_pm2_5
    above: 15
    for:
      minutes: 5
    trigger: numeric_state
    id: bedroom_pm25_moderate
  - entity_id: sensor.bedroom_filter_pm2_5
    above: 35
    for:
      minutes: 5
    trigger: numeric_state
    id: bedroom_pm25_poor
  - entity_id: sensor.bedroom_filter_pm2_5
    below: 12
    for:
      minutes: 10
    trigger: numeric_state
    id: bedroom_pm25_good
  - entity_id: sensor.living_room_air_filter_pm2_5
    above: 15
    for:
      minutes: 5
    trigger: numeric_state
    id: living_room_pm25_moderate
  - entity_id: sensor.living_room_air_filter_pm2_5
    above: 35
    for:
      minutes: 5
    trigger: numeric_state
    id: living_room_pm25_poor
  - entity_id: sensor.living_room_air_filter_pm2_5
    below: 12
    for:
      minutes: 10
    trigger: numeric_state
    id: living_room_pm25_good
actions:
  - choose:
      - conditions:
          - condition: trigger
            id: office_pm25_moderate
        sequence:
          - target:
              entity_id: fan.office_filter
            data:
              percentage: 70
            action: fan.set_percentage
          - target:
              entity_id: switch.office_air_filter_display
            action: switch.turn_off
      - conditions:
          - condition: trigger
            id: office_pm25_poor
        sequence:
          - target:
              entity_id: fan.office_filter
            data:
              percentage: 100
            action: fan.set_percentage
          - target:
              entity_id: switch.office_air_filter_display
            action: switch.turn_off
      - conditions:
          - condition: trigger
            id: office_pm25_good
        sequence:
          - target:
              entity_id: fan.office_filter
            data:
              preset_mode: auto
            action: fan.set_preset_mode
          - target:
              entity_id: switch.office_air_filter_display
            action: switch.turn_off
      - conditions:
          - condition: trigger
            id: bedroom_pm25_moderate
        sequence:
          - target:
              entity_id: fan.bedroom_filter
            data:
              percentage: 70
            action: fan.set_percentage
          - target:
              entity_id: switch.master_bedroom_air_filter_display
            action: switch.turn_off
      - conditions:
          - condition: trigger
            id: bedroom_pm25_poor
        sequence:
          - target:
              entity_id: fan.bedroom_filter
            data:
              percentage: 100
            action: fan.set_percentage
          - target:
              entity_id: switch.master_bedroom_air_filter_display
            action: switch.turn_off
      - conditions:
          - condition: trigger
            id: bedroom_pm25_good
        sequence:
          - target:
              entity_id: fan.bedroom_filter
            data:
              preset_mode: auto
            action: fan.set_preset_mode
          - target:
              entity_id: switch.master_bedroom_air_filter_display
            action: switch.turn_off
      - conditions:
          - condition: trigger
            id: living_room_pm25_moderate
        sequence:
          - target:
              entity_id: fan.living_room_air_filter
            data:
              percentage: 70
            action: fan.set_percentage
          - target:
              entity_id: switch.living_room_air_filter_display
            action: switch.turn_off
      - conditions:
          - condition: trigger
            id: living_room_pm25_poor
        sequence:
          - target:
              entity_id: fan.living_room_air_filter
            data:
              percentage: 100
            action: fan.set_percentage
          - target:
              entity_id: switch.living_room_air_filter_display
            action: switch.turn_on
      - conditions:
          - condition: trigger
            id: living_room_pm25_good
        sequence:
          - target:
              entity_id: fan.living_room_air_filter
            data:
              preset_mode: auto
            action: fan.set_preset_mode
          - target:
              entity_id: switch.living_room_air_filter_display
            action: switch.turn_off
mode: queued
