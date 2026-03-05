alias: Bedroom Safe Humidity Warning
description: ""
triggers:
  - type: humidity
    device_id: 6834ad60e0bc179f97531f5e1f6dd391
    entity_id: 4979d2c2e8fb65572c435e526d3710d4
    domain: sensor
    trigger: device
    above: 48
conditions: []
actions:
  - action: notify.mobile_app_iphone
    data:
      message: RECHARGE Bedroom Safe Dehumidifier
mode: single
