alias: Safe Monitoring Alerts
description: Combined alerts for safe humidity, temperature, and trend monitoring
triggers:
  - entity_id:
      - sensor.bedroom_safe_temp_humidity
      - sensor.office_safe_temp_humidity
    above: 55
    for:
      minutes: 10
    trigger: numeric_state
    id: high_humidity
  - entity_id:
      - sensor.bedroom_safe_temp_temperature
      - sensor.office_safe_temp_temperature
    above: 80
    for:
      minutes: 15
    trigger: numeric_state
    id: high_temperature
  - trigger: time_pattern
    minutes: 0
    id: trend_check
actions:
  - choose:
      - conditions:
          - condition: trigger
            id: high_humidity
        sequence:
          - data:
              title: ⚠️ High Safe Humidity
              message: "{{ trigger.to_state.attributes.friendly_name }} humidity is {{ trigger.to_state.state }}%  (Target: <50%). Check for moisture issues or consider dehumidification.\n"
            action: persistent_notification.create
      - conditions:
          - condition: trigger
            id: high_temperature
        sequence:
          - data:
              title: 🌡️ High Safe Temperature
              message: "{{ trigger.to_state.attributes.friendly_name }} temperature is {{ trigger.to_state.state }}°F  (Target: <75°F). Check HVAC system or safe ventilation.\n"
            action: persistent_notification.create
      - conditions:
          - condition: trigger
            id: trend_check
          - condition: time
            after: "08:00:00"
            before: "20:00:00"
        sequence:
          - choose:
              - conditions:
                  - condition: template
                    value_template: "{% set bedroom_current = states('sensor.bedroom_safe_temp_humidity') | float %} {% set bedroom_3h_ago = state_attr('sensor.bedroom_safe_temp_humidity', 'mean') | float %} {% set office_current = states('sensor.office_safe_temp_humidity') | float %} {% set office_3h_ago = state_attr('sensor.office_safe_temp_humidity', 'mean') | float %} {{ (bedroom_current > bedroom_3h_ago + 5) or (office_current > office_3h_ago + 5) }}\n"
                sequence:
                  - data:
                      title: 📈 Safe Humidity Trending Up
                      message: "Safe humidity levels have increased significantly over the past 3 hours.  Monitor conditions closely and check for moisture sources.\n"
                    action: persistent_notification.create
              - conditions:
                  - condition: template
                    value_template: "{% set bedroom_current = states('sensor.bedroom_safe_temp_temperature') | float %} {% set bedroom_3h_ago = state_attr('sensor.bedroom_safe_temp_temperature', 'mean') | float %} {% set office_current = states('sensor.office_safe_temp_temperature') | float %} {% set office_3h_ago = state_attr('sensor.office_safe_temp_temperature', 'mean') | float %} {{ (bedroom_current > bedroom_3h_ago + 3) or (office_current > office_3h_ago + 3) }}\n"
                sequence:
                  - data:
                      title: 📈 Safe Temperature Trending Up
                      message: "Safe temperature levels have increased significantly over the past 3 hours.  Check HVAC system or room conditions.\n"
                    action: persistent_notification.create
mode: queued
