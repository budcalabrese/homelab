# Home Assistant Automations

This directory contains Home Assistant automation configurations.

## Automation Files

### Office Automations

#### [OfficeLights.md](automations/OfficeLights.md)
**Motion-based office lighting with automatic shutoff**

**Lights controlled:**
- `light.hue_color_lamp_1`
- `light.hue_color_lamp_2`
- `light.hue_color_lamp_3`

**Behavior:**
- Turns on at sunset at 80% brightness (333 color temp)
- Motion-activated from sunset until 10pm
- 2-minute auto-off when no motion detected
- **Automatic shutoff at 10pm** regardless of motion
- Can be manually turned on after 10pm if needed

**Triggers:**
- Sunset event
- Motion sensor: `binary_sensor.apollo_msr_2_f99c28_radar_moving_target`
- Time: 10:00 PM

---

#### [OfficeFilamentBulb.md](automations/OfficeFilamentBulb.md)
**Time-based ambient lighting**

**Light controlled:**
- `light.hue_filament_bulb_1`

**Behavior:**
- Turns on daily at 9:00 AM at 30% brightness
- Turns off daily at 9:00 PM
- No motion detection - simple scheduled operation
- Independent from main office lights

**Triggers:**
- Time: 9:00 AM (on)
- Time: 9:00 PM (off)

---

### Kitchen Automations

#### [KitchenMotion-EveningLighting.md](automations/KitchenMotion-EveningLighting.md)
Motion-based kitchen lighting for evening hours.

---

### Living Room Automations

#### [SunsetLivingRoom-PorchLighting.md](automations/SunsetLivingRoom-PorchLighting.md)
Sunset-activated living room and porch lighting.

---

## Deployment

These automation files are in markdown format for easy editing and version control. To deploy to Home Assistant:

1. Copy the YAML content from the markdown files
2. Add to Home Assistant via:
   - UI: Settings → Automations & Scenes → Create Automation → Edit in YAML
   - Or add to `automations.yaml` file directly

## Motion Sensor

**Apollo MSR-2**: `binary_sensor.apollo_msr_2_f99c28_radar_moving_target`
- Radar-based motion detection
- Used for office lighting automation
- 2-minute timeout before considering "no motion"

## Notes

- All office lights use warm color temperature (333 mired / ~3003K)
- Office lights are motion-controlled only from sunset to 10pm
- Filament bulb operates independently on fixed schedule
- Restart mode allows automations to reset if triggered again while running
