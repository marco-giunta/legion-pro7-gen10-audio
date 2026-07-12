# Folder structure

- `series/`: Individual iterations of the patch series (see changelog below). Each subfolder (e.g. `v0.1/`, `v0.2/`) contains the multi-file patch set for that version (including commit messages and cover letters).
- `combined/`: Single-file versions of each series iteration. These are combined patches applied to a specific kernel release (e.g., v6.19.14), to make it easy to test the series with `git apply` or `patch -p1`.

# Changelog

# v0.4.5

- Removed a few includes that are no longer used after the cleanup in the previous version.
- Fixed inconsistent styling between the comment headers of the main and i2c drivers.

# v0.4.4

This version introduces yet another round of unused code removal from the main driver. It also introduces changes aimed at making it more compact and targeted, following a comparison with the other cirrus HDA side codec driver (cs35l56) and a revised analysis of the cs35l41 driver.

- Merged property driver into main driver: removed `aw88399_hda_property.c`, `aw88399_hda_property.h`, and the corresponding `Makefile` entry; the quirk table and matching loop are now inline in `aw88399_hda.c`. This "compression" is done because, regarding ACPI SSID quirk matching, our use-case is overall more similar to the cs35l56 driver (which has the same single-file approach) than the cs35l41 (which has a large, dedicated property driver file). In particular, the former driver has a small table of quirks (in fact, just 1 device) and very simple per-device quirks, like our driver; the latter, instead, contains many devices and complex logic to perform specialized ad-hoc overrides of the `_DSD` properties read from the ACPI firmware tables.
- Consistently with this merge, added `#include <linux/string.h>` to the main driver, reworked patch 9 to add the quirk functions (channel swap, BSTS bypass, legion quirks) and SSID table in `aw88399_hda.c` instead of the deleted property driver, and updated the commit message to reference per-model quirks in `aw88399_hda.c` instead of `aw88399_hda_property.c`.
- Removed ACPI companion block, as it never fires for SMI-instantiated devices, which by construction break the natural 1:1 mapping between and ACPI device and its corresponding physical device, as also pointed out by comments in the cs35l56 driver and confirmed by tester logs.
Indeed, the cs35l56 driver restores this connection manually by explicitly creating the appropriate ACPI companion link (i.e. pointer), which is then used to read the necessary `_DSD` properties; the cs35l41 driver, instead, simply creates an independent physical device after obtaining the original ACPI device, matched by HID. My approach is the latter, but even when using the first, simply checking if an ACPI companion exists (without doing something to create it) will always result in an empty return.
- Removed `_DSD` property parsing: `aw88399_hda_try_dsd_index`, `aw88399_hda_parse_speaker_props`, all three `AW88399_ACPI_PROP_*` defines. No `_DSD` properties exist in DSDT or SSDT tables for the Legion, so this code can never fire in practice (said in another way, only the binary firmware is actually used in practice, so we can remove logic to parse ACPI firmware for anything other than the ACPI SSID, used to match quirks).
- Removed code regarding ACPI notifications, as the ACPI firmware doesn't support it (notification methods are missing from the DSDT table like the `_DSD` properties mentioned above), and as the only function that was using these was simply printing a debug message.
- Correspondingly, removed unused struct fields from `aw88399_hda` in `aw88399_hda.h`: `codec`, `adev`, `speaker_pos`, `speaker_id`, `speaker_pos_valid`, `speaker_id_valid`, `acpi_notify_supported`, as well as unused includes and deprecated `#include "aw88399_hda_property.h"`. Likewise, simplified channel assignment in init and ACPI probe functions, by removing the `speaker_pos`/`speaker_pos_valid` indirection.
- Removed author lines from header comment, instead relying only on `MODULE_AUTHOR` metadata at the end of the file.
- Added `MODULE_AUTHOR("Marco Giunta <marco_giunta@outlook.it>")` at the end of the main driver, following the merge with the property driver.

## v0.4.3

Similarly to the previous entry, this version's goal is to polish the main driver by removing some unused features and better matching the other HDA side codec drivers.

- Removed the separate `aw88399_hda_regmap_i2c` struct, as its contents are identical to the preexisting `aw88399_remap_config` struct from the original asoc driver.
- Moved `aw88399_remap_config` to the shared library to ensure both drivers can use it (consequently, added an export statement and its corresponding declaration in `include/sound/aw88399.h`).
- Changed `aw88399_hda_probe` signature: removed unused `device_name`, `id`, `irq` parameters; added `struct regmap *regmap` parameter.
- Moved `devm_regmap_init_i2c(clt, &aw88399_remap_config)` to i2c driver, and this struct is now passed as an argument to the above function instead of being defined in its body. This change is done to follow the convention of the other HDA side codec drivers (cs35l41, tas2781, etc.). Correspondingly, moved `#include <linux/regmap.h>` from main driver to i2c driver (and removed unused `#include <linux/regulator/consumer.h>`).
- Removed unused `bool suspended` field and corresponding assignments in main driver/header.
- Replaced some `dev_err` + `return` patterns with `dev_err_probe`, better matching the cs35l41 side codec and original asoc drivers.
- Added early error returns in `aw88399_hda_acpi_probe` for missing ACPI device and physical node, following more closely the cirrus driver (consequently, reworked the corresponding logic slightly).
- Removed some not-strictly-necessary comments from the main driver.
- Rebased on commit `f9355bbae61af59e136cc840c0fb3110e676946b` from `tiwai/sound`.

## v0.4.2

The changes in this version are mostly aimed at cleaning up the i2c driver, with the intent of removing deprecated functionality and ensuring a closer match to the conventions of the cs35l41 and tas2781 i2c drivers. As such, they mostly target patch 8/9.

- Removed unused includes from i2c driver (`<linux/acpi.h>`, `<sound/hda_codec.h>`), so that we now only have 
```c
#include <linux/module.h>
#include <linux/i2c.h>
#include "aw88399_hda.h"
```
fully matching the cirrus driver (after the removal of `#include <linux/mod_devicetable.h>` in commit `995832b2cebe6969d1b42635db698803ee31294d`).
- Removed `MODULE_DEVICE_TABLE(i2c, aw88399_hda_i2c_id)` after the definition of `static const struct i2c_device_id aw88399_hda_i2c_id[]`, as it's redundant with `MODULE_DEVICE_TABLE(acpi, aw88399_acpi_hda_match)`: before the i2c driver is triggered, the ACPI match table "reacts" to the ACPI HID and creates i2c devices via the SMI driver, i.e. we don't need an independent module autoload from i2c alone without ACPI having already done so. This also fully matches the cs35l41 and tas2781 precedents.
- Removed matching of manual and SMI devices from `aw88399_hda_i2c_probe`; the former is likely a leftover from the early debugging days (and never used in practice anymore), while the latter is fully redundant with the ACPI match, similarly to the previous point. Once again, this matches the corresponding cs35l41 and tas2781 functions fully, with the exception that, since we don't have to worry about multiple chip versions (i.e. ACPI HIDs in practice), the function can be simplified by dropping `const char *device_name` and inverting the if.
- In `static const struct i2c_device_id aw88399_hda_i2c_id[]`: removed matching of `aw88399` since only `aw88399-hda` is actually used as per the two i2c devices created by the SMI driver. This also avoids any potential confusion with the i2c driver of the original ASoC aw88399 driver, whose i2c name field is indeed `"aw88399"`.
- In `static const struct i2c_device_id aw88399_hda_i2c_id[]`: added explicit `.name` field and removed default-valued `driver_data` field (0), to match the conventions of the cs35l41 and tas2781 i2c drivers, as well as many other devices (see commit `910714d4e79ba654d8a4e8103bb624d4f62e57f8`).
- As per the same `910714d4e79b` commit, fixed the spacing convention in the `{ }` terminator at the end of the `aw88399_hda_i2c_id` struct.
- Fixed the order of the metadata lines (module description, author, etc.) at the end of the i2c driver.
- Removed file names from the comments at the top of the new drivers, and added Lyapsus' author lines to match the cs35l41 convention (my author line in the property driver was already there).
- In patch 1, slightly edited the top comment to better match the convention of the original ASoC driver.

## v0.4.1

- Changed some `dev_dbg` and `dev_warn` calls to standardize argument usage to better match the cs35l41 convention. When the `aw88399_hda` struct is passed as an argument or obtained via `dev_get_drvdata(dev)` with device `dev` passed as argument, `aw88399->dev` is used to print messages. If `struct device *dev = aw88399->dev;` is declared as a local variable for convenience from a `aw88399_hda` struct passed as an argument (i.e. when this `dev` is needed multiple times), `dev` is also used directly in the print messages. This change is purely cosmetic, as these variables are identical in content, but it helps to clean things up.
- Made the string printed by the `dev_info` in `aw88399_hda_bind` a bit shorter and more closely aligned to the cs35l41 convention.
- Rebased on commit `9dbbdc09418344c150c75a41f349a6441d81dd71` from `tiwai/sound`.

## v0.4

- Added a new patch 6/9 to the series to introduce a channel setter function to the shared library (`aw88399_dev_set_channel`). This allows for the removal of the last remaining cross-directory dependency on ASoC-internal headers from the HDA driver (`#include "../../soc/codecs/aw88395/aw88395_device.h"`) by replacing `core->aw_pa->channel = aw88399->channel` with its opaque handler equivalent `aw88399_dev_set_channel(core, aw88399->channel)`.
- Reduced `dmesg` verbosity by turning a bunch of `dev_info` calls in the HDA and property drivers into `dev_dbg`. The "downgraded" messages are those related to ACPI, codec remove and unbind, and the application of quirk functions (as well as the "missing DT properties" message). `dev_info` calls are left for the success messages that are relevant to the user and appear only once (following the cs35l41 pattern):
```c
dev_info(dev, "AW88399 HDA side codec registered successfully\n");
dev_info(aw88399->dev,
		 "AW88399 Bound - channel %d, AWDZ8399 ACPI SSID %s\n",
		 aw88399->channel, aw88399->acpi_subsystem_id);
dev_info(aw88399->dev, "AW88399: Picked up properties for ACPI SSID %s\n",
		 aw88399->acpi_subsystem_id);
```
- Slightly changed the string printed by the property driver's `dev_info` call.
- Modified the comment about the R9000P's shared PCI ID to match the preexisting conventions in `alc269.c` for devices with one shared PCI ID and multiple unique codec IDs (`"Yoga Pro 7 14IMH9"`, `Yoga Pro 7 14IRH8`).
- Removed `dev_dbg(aw_dev->dev, "DT channel value: %d\n", channel_value);` after the I2C fallback as adding diagnostics for the ASoC driver is out of scope (that line is harmless but not strictly needed).
- Slightly reworded parts of the cover letter.
- Rebased on commit `bcb8896e30a3cd684af57a16df0111f4ab4baf59` from `tiwai/sound`.

## v0.3.3

- Removed the generic aw88399 fixup from the `alc269_fixup_models` table to match the conventions of the cs35l41 and tas2781.
- Rebased on commit `d765dc14b9ebff5f1155aaf1eedffc576ee5a596` from `tiwai/sound`.

## v0.3.2

- Moved printing of the `AWDZ8399` ACPI SSID to the "bound to HDA codec" message in the HDA bind function.
- Changed device to `aw88399->dev` and print message to more closely match the cs35l41 hda side codec driver:
```c
dev_info(aw88399->dev,
		 "AW88399 Bound - channel %d, AWDZ8399 ACPI SSID %s\n",
		 aw88399->channel, aw88399->acpi_subsystem_id);
```
- Removed ACPI SSID print redundant with the above from the property driver.
- Rebased on commit `c784d0e6a62abbd2af58bbbe2d20f88dd550e3eb` from `tiwai/sound`.

## v0.3.1

- Added ~~experimental~~ support for Legion R9000P ADR10 (asian variant of the Pro 5 AMD that includes the aw88399 smart amp driving separate woofers, unlike the western variant which has only 2 speakers).
This is done by enabling the same realtek/property driver quirks as done for the Pro 7 models currently supported, but with a small twist: the PCI SSID of this device is `0x17aa:38bb`, which is already present in `alc269.c` (`"Yoga S780-14.5 Air AMD quad AAC"`). Therefore, the codec SSID (`0x17aa:3927/3928`) is used via `HDA_CODEC_QUIRK`, and put before `38bb` (an exception to the usual sorting of this table) to prevent matching the wrong quirk before the right one is reached by the loop in `snd_hda_pick_fixup`.
- Reworked quirk matching for all other devices. Before, `SND_PCI_QUIRK` was used for every legion.
For the AMD models, this was slightly improper, because the codec SSID were passed, but it still worked in practice because there were no matches to the PCI SSID of these devices in `alc269.c` (`17aa:38c6`), so the `q = hda_quirk_lookup_id(codec_vendor, codec_device, quirk);` fallback in `snd_hda_pick_fixup` faced no problems.
For the Intel models, since both the codec SSIDs (`3906,3907`) and the PCI SSID (`3d6c`) were included, the for loop in `snd_hda_pick_fixup` was only matching the PCI SSID, so that the codec SSIDs were basically dead code.
Clean up this confusion by only matching the HDA codec IDs via `HDA_CODEC_QUIRK` (consistently with the R9000P above) and removing the Intel model's PCI SSID.
- Rebased on commit `ef807cc07dec16edc7863d437e9250e20cb73741` from `tiwai/sound`.

## v0.3

See [here](https://github.com/nadimkobeissi/16iax10h-linux-sound-saga/issues/55#issuecomment-4508214865) for more informations.

- Added a new patch to the series (5/8) to introduce a firmware reload flag (`fw_needs_reload`) for system resume. After system sleep, the smart amp's SRAM loses its DSP firmware configuration (previously loaded at initialization).
In v<0.3 series, this would cause the first playback after system resume to fail a CRC check; the retry mechanism in `aw88399_start_pa` would then be triggered, re-uploading the firmware on the second attempt and finally succeeding. This sequence produces misleading error-level log messages, and while in practice capable of consistently self-correcting this failure, is technically an improper hijacking of a self-correct mechanism designed for a different purpose.
The new flag is set by the HDA driver during system suspend and checked by `aw88399_start` in the shared library, causing a proactive full firmware upload on the next playback start. This eliminates the spurious CRC failures and retry cycles after resume without affecting ASoC behavior.
- Slightly reworded the commit messages of patches 1 and 3 to make them more accurate.
- Rebased on commit `9b14f636834630e5473ee5020c8289823a481a7` from `tiwai/sound`.

## v0.2.4

- Reverted the addition of the Pro 5i ID 3908, as that should likely be sent as a separate patch.
- Added another entry in `alc269_fixup_models` to allow for testing of the aw88399 side codec driver decoupled from the realtek quirks:
```c
{.id = ALC287_FIXUP_AW88399_I2C_2, .name = "aw88399-i2c-2"},
```
- Added `Tested-by: Munzir Taha <munzirtaha@gmail.com>`.
- Rebased on commit `c19fcfd33d37d7979781ebe6cacc3c3da9ea0f2e` from `tiwai/sound`.

## v0.2.3

- Added another pincfg override in the realtek fixup: `{ 0x17, 0x90170111 }`. This is needed on the Pro 5 to enable the woofers, as the corresponding pin complex is wrongly reported as unconnected (`Pin Default 0x411111f0`, as reported by tester logs). This matches the pattern of `alc245_fixup_hp_spectre_x360_eu0xxx`, `alc245_fixup_hp_spectre_x360_eu0xxx`, and `alc287_fixup_yoga9_14iap7_bass_spk_pin`. Association `11` ensures no conflicts happen with speakerbar/tweeters node `0x14` (default association `10` on both pro 5 and 7) and headphones node `0x21` (`20` on pro 5, `1f` on pro 7).
- Added legion aw88399 entry in `alc269_fixup_models` to help debug new devices in the future:
```c
{.id = ALC287_FIXUP_LENOVO_LEGION_AW88399, .name = "alc287-lenovo-legion-aw88399"},
```
- Updated commit messages to match these changes, plus some slight rewording here and there.
- Matched `dev_info` string convention in property driver quirks.

## v0.2.2

- Added experimental support for Legion Pro 5 16IAX10H `0x17aa3908` (same realtek and property driver quirks as the Pro 7, `17AA3908` SSID in property driver).
- Changed name of `0x17aa3d6c` quirk to `"Legion Pro 7i 16IAX10H / Y9000P IAX10"`.
- Rebased on commit `b8dc547edf9e41474d8ce2dcf344e8e75b17781a` from `tiwai/sound`.

## v0.2.1
See [here](https://github.com/nadimkobeissi/16iax10h-linux-sound-saga/issues/55#issuecomment-4410686082) for more informations.

- In `alc269.c`, separated the `SND_PCI_QUIRK` entry for the Lenovo Legion Y9000P IAX10 (realtek PCI SSID `0x3d6c`) from the Legion Pro 7i 16IAX10H (`0x3907`). Tester logs confirmed that the Y9000P uses PCI SSID `0x3d6c` but ACPI SSID `17AA3907` for the AW88399, so the realtek quirk table needs a separate entry while the property table does not. This also fixes checkpatch line-length warning caused by the previous combined quirk table entry.
- Removed `17AA3D6C` from the AW88399 property table, as no machine has actually been observed to use it as an ACPI subsystem ID.
- Added `Tested-by: Xia Yun'an <imitoy@imitoy.top>` (Lenovo Legion Y9000P IAX10, kernel 7.0.3, Arch Linux).
- Consistent include guard style in `aw88399_hda_property.h` (fixed missing double underscores). Also backported to v0.2.
- Changed include guard in `include/sound/aw88399.h` to `__SOUND_AW88399_H`.
- In `aw88399-lib.c`, changed `MODULE_DESCRIPTION` from `AW88399 library` to `AW88399 common device library`.
- In `aw88399-lib.c`, changed `MODULE_LICENSE` from the original `"GPL v2"` to `"GPL"` to fix warning from `scripts/checkpatch.pl`.
- Rebased on commit `b8dc547edf9e41474d8ce2dcf344e8e75b17781a` from `tiwai/sound`.

## v0.2
See [here](https://github.com/nadimkobeissi/16iax10h-linux-sound-saga/issues/55#issuecomment-4381559698) for more informations.

- Reworked patch 1 to introduce a common header at `include/sound/aw88399.h`. This file includes all the definitions from the original `sound/soc/codecs/aw88399.h` not strictly related to ASoC. As a result, `sound/soc/codecs/aw88399-lib.h` has been removed, `sound/soc/codecs/aw88399.h` heavily depleted, and most of the ugly imports in `sound/hda/codecs/side-codecs/aw88399_hda.c` have been removed in favor of a single `#include <sound/aw88399.h>` in `sound/hda/codecs/side-codecs/aw88399_hda.h`.
- Added `Tested-by: Nadim Kobeissi <nadim@symbolic.software>`.
- Rebased the patch series on commit `fac9a31701803e4e41fdb7b5c71582c65cf47176` from `tiwai/sound`.

## v0.1
Original patch series proposal, based on commit `876c495d412ef67bd4d0bdc4b74b0bd3d9f4e890` from `tiwai/sound`.

See [here](https://github.com/nadimkobeissi/16iax10h-linux-sound-saga/issues/55#issue-4343077194) for more informations.

1. **ASoC: aw88399: extract shared device library** - pure code movement, no logic changes
2. **ASoC: aw88399: check return values in aw_dev_check_sram** - proper error handling for DSP access calls (bugfix)
3. **ASoC: aw88399: derive channel from I2C address on ACPI systems**
4. **ASoC: aw88399: add per-instance BSTS status bypass flag**
5. **ACPI/platform: add AWDZ8399 to serial-multi-instantiate**
6. **ALSA: hda/scodec: add AW88399 HDA side codec driver** - the new driver
7. **ALSA: hda/realtek: enable AW88399 on Lenovo Legion Pro 7** - property driver and realtek quirks
