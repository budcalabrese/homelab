alias: Bedroom Safe Battery Warning
description: ""
triggers:
  - type: battery_level
    device_id: 6834ad60e0bc179f97531f5e1f6dd391
    entity_id: e70a22f51363b7f9ff840cb3f9cb6ff5
    domain: sensor
    trigger: device
    below: 15
conditions: []
actions:
  - action: notify.mobile_app_iphone
    data:
      message: CHANGE Bedroom Safe Batteries
mode: single
