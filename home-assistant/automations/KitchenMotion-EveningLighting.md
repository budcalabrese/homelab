alias: Kitchen Motion and Evening Lighting
description: Motion-based lighting during day with auto-off and 6pm lighting
triggers:
  - entity_id: binary_sensor.kitchen_motion_sensor_occupancy
    from: "off"
    to: "on"
    id: motion_on
    trigger: state
  - entity_id: binary_sensor.kitchen_motion_sensor_occupancy
    from: "on"
    to: "off"
    for:
      seconds: 180
    id: motion_off
    trigger: state
  - at: "18:00:00"
    id: evening_trigger
    trigger: time
actions:
  - choose:
      - conditions:
          - condition: trigger
            id: motion_on
          - condition: time
            after: "06:00:00"
            before: "18:00:00"
          - condition: state
            entity_id: light.kitchen
            state: "off"
        sequence:
          - choose:
              - conditions:
                  - condition: time
                    after: "06:00:00"
                    before: "08:00:00"
                sequence:
                  - target:
                      entity_id: light.kitchen
                    data:
                      brightness_pct: 40
                      color_temp: 450
                    action: light.turn_on
              - conditions:
                  - condition: time
                    after: "08:00:00"
                    before: "18:00:00"
                sequence:
                  - target:
                      entity_id: light.kitchen
                    data:
                      brightness_pct: 100
                      color_temp: 333
                    action: light.turn_on
      - conditions:
          - condition: trigger
            id: motion_on
          - condition: time
            after: "06:00:00"
            before: "08:00:00"
          - condition: state
            entity_id: light.kitchen
            state: "on"
          - condition: numeric_state
            entity_id: light.kitchen
            attribute: brightness
            below: 102
        sequence:
          - target:
              entity_id: light.kitchen
            data:
              brightness_pct: 40
              color_temp: 450
            action: light.turn_on
      - conditions:
          - condition: trigger
            id: motion_on
          - condition: time
            after: "08:00:00"
            before: "18:00:00"
          - condition: state
            entity_id: light.kitchen
            state: "on"
          - condition: numeric_state
            entity_id: light.kitchen
            attribute: brightness
            below: 255
        sequence:
          - target:
              entity_id: light.kitchen
            data:
              brightness_pct: 100
              color_temp: 333
            action: light.turn_on
      - conditions:
          - condition: trigger
            id: motion_off
          - condition: time
            after: "06:00:00"
            before: "18:00:00"
          - condition: state
            entity_id: light.kitchen
            state: "on"
        sequence:
          - target:
              entity_id: light.kitchen
            action: light.turn_off
            data: {}
      - conditions:
          - condition: trigger
            id: evening_trigger
        sequence:
          - target:
              entity_id: light.kitchen
            data:
              brightness_pct: 100
              color_temp: 333
            action: light.turn_on
mode: single
