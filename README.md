# gsMyBuffReminder

A Retail WoW addon that displays the real spell icons for buffs you are missing and can play a warning sound when reminders appear.

All buff matching uses numeric SpellIDs (or weapon-enchant IDs for temporary weapon enchants), never localized names. Names are used only for labels and tooltips.

When Midnight marks an aura as restricted, the addon reports it as `unknown (restricted)` in `/gsb status` rather than falsely treating it as present. Blizzard does not permit addons to determine a restricted aura's active state.

Initial defaults:

- Druid: Mark of the Wild on every spec.
- Enhancement Shaman: Lightning Shield, Windfury Weapon, Flametongue Weapon, and Earth Shield when that talent/spell is known.
- Holy/Protection Paladin: an active Devotion, Crusader, Retribution, or Concentration Aura.
- Retribution Paladin: Devotion Aura.

Sounds play only when a reminder newly becomes missing; clearing a reminder is silent. Choose the alert sound (or None) in the addon settings; selecting an option previews it.

The settings panel can also apply a smooth fade pulse to missing icons. The animation runs only while missing icons are visible.

Use `/gsb` to open the settings panel. It includes toggles for visuals, sound, out-of-combat-only operation, and toy buffs. Add custom aura spell IDs from the same panel; each entry is automatically scoped to the current class, specialization, and race. Optionally associate a toy ID, so the reminder is only relevant when that toy is collected.

The reminder is registered with Blizzard Edit Mode through the installed `LibEditMode` addon. Enter Edit Mode, select **gsMyBuffReminder**, and drag it to the desired place; each Blizzard Edit Mode layout stores its own position.

For diagnostics, use `/gsb status`. It prints the detected class/specification ID and the apply/available/satisfied state of each built-in rule for your current class. `/gsb refresh` forces an immediate check. The addon listens for aura, spellbook, specialization, and inventory updates, including temporary weapon-enchant changes.

Default rules are intentionally data-only and live in `Rules.lua`. Add a new table entry there for class/spec/race-specific built-in reminders. `classes`, `specs`, and `races` are optional sets; see the existing entries for examples.

Weapon enchants are checked with `GetWeaponEnchantInfo()` because they are temporary weapon enchants rather than dependable normal player auras. Enhancement's default rules validate the specific Windfury (main hand) and Flametongue (off hand) enchant IDs; the visual still uses the configured spell icon.
