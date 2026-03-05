alias: Turn Off Porch Light at Midnight
description: Automatically turn off front porch light at midnight
triggers:
  - at: "00:00:00"
    trigger: time
actions:
  - target:
      entity_id: light.front_porch
    action: light.turn_off
    data: {}
mode: single
