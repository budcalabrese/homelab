alias: Turn Off Office Smart Plug at 3 AM
description: Turn off left outlet of office smart plug daily at 3 AM
triggers:
  - at: "03:00:00"
    trigger: time
actions:
  - target:
      entity_id: switch.office_smart_plug_left
    action: switch.turn_off
mode: single
