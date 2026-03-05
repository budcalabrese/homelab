alias: SLZB-06 Zigbee Watchdog
description: Restart SLZB-06 controller when Zigbee devices become unresponsive
triggers:
  - entity_id:
      - binary_sensor.kitchen_motion_sensor_occupancy
      - binary_sensor.bathroom_night_light_occupancy
    to: unavailable
    for:
      minutes: 2
    trigger: state
  - entity_id: binary_sensor.slzb_06_network
    to: "off"
    for:
      minutes: 2
    trigger: state
conditions:
  - condition: template
    value_template: "{{ (now() - state_attr('automation.slzb_06_zigbee_watchdog', 'last_triggered') | default(now() - timedelta(hours=2))).total_seconds() > 3600 }}\n"
actions:
  - data:
      title: Zigbee Controller Issue
      message: SLZB-06 (192.168.0.13) appears unresponsive. Motion sensors unavailable. Attempting restart...
    action: persistent_notification.create
  - target:
      entity_id: button.zigbee2mqtt_bridge_restart
    action: button.press
  - delay:
      minutes: 3
  - data:
      title: Zigbee Restart Complete
      message: SLZB-06 restart completed. Motion sensors should be back online. Check device status in Zigbee2MQTT.
    action: persistent_notification.create
mode: single
