alias: Office Motion Lighting - Sunset Activated
description: Motion-based office lighting starting at sunset with 2 min auto-off
triggers:
  - event: sunset
    id: sunset_trigger
    trigger: sun
  - entity_id: binary_sensor.apollo_msr_2_f99c28_radar_moving_target
    from: "off"
    to: "on"
    id: motion_detected
    trigger: state
  - entity_id: binary_sensor.apollo_msr_2_f99c28_radar_moving_target
    from: "on"
    to: "off"
    for:
      minutes: 2
    id: no_motion
    trigger: state
actions:
  - choose:
      - conditions:
          - condition: trigger
            id: sunset_trigger
        sequence:
          - target:
              entity_id: light.office
            data:
              brightness_pct: 80
              color_temp: 333
            action: light.turn_on
      - conditions:
          - condition: trigger
            id: motion_detected
          - condition: sun
            after: sunset
        sequence:
          - target:
              entity_id: light.office
            data:
              brightness_pct: 80
              color_temp: 333
            action: light.turn_on
      - conditions:
          - condition: trigger
            id: no_motion
          - condition: sun
            after: sunset
        sequence:
          - target:
              entity_id: light.office
            action: light.turn_off
mode: restart
