alias: Snake Plant Watering Alert
description: Alert when snake plant soil moisture drops to 15% or below
triggers:
  - entity_id: sensor.gw1200b_soil_moisture_1
    below: 15
    for:
      minutes: 10
    trigger: numeric_state
actions:
  - data:
      title: 🌱 Snake Plant Needs Water
      message: "Your office snake plant soil moisture is {{ states('sensor.gw1200b_soil_moisture_1') }}%. Time to water your plant!"
      notification_id: snake_plant_water
    action: persistent_notification.create
mode: single
