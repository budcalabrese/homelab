alias: Sunset Living Room and Porch Lighting
description: Turn on living room and front porch lights 1 hour before sunset
triggers:
  - event: sunset
    offset: "-01:00:00"
    trigger: sun
actions:
  - target:
      entity_id: light.living_room
    data:
      brightness_pct: 100
      color_temp: 333
    action: light.turn_on
  - target:
      entity_id: light.tramp_light
    data:
      brightness_pct: 90
      color_temp: 333
    action: light.turn_on
  - target:
      entity_id: light.leg_lamp
    data:
      brightness_pct: 90
      color_temp: 333
    action: light.turn_on
  - target:
      entity_id: light.front_porch
    data:
      brightness_pct: 100
      color_temp: 454
    action: light.turn_on
  - target:
      entity_id: switch.christmas
    action: switch.turn_on
mode: single
