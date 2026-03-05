alias: Office Safe Battery Warning
description: ""
triggers:
  - type: battery_level
    device_id: ea2e1182729881844783525dcc9154f4
    entity_id: cdf553319059be8631b39b4a69ace5de
    domain: sensor
    trigger: device
    below: 15
conditions: []
actions:
  - action: notify.mobile_app_iphone
    data:
      message: CHANGE Office Safe Batteries
mode: single
