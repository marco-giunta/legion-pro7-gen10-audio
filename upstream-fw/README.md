# Firmware follow-up patch series

## Status

[AWINIC has submitted the required firmware on behalf of Lenovo to the linux-firmware repo; the MR is currently pending for review.](https://lore.kernel.org/linux-firmware/4b70e056-89d9-4d92-8ecb-ecb4c7d48c8a@app.fastmail.com/T/#t)

## Folder structure

- `series/`: Individual iterations of the patch series. Each subfolder contains the multi-file patch set for that version (including commit messages and cover letters).
- `combined/`: Single-file versions of each series iteration, applied to a specific kernel release, for easy testing with `git apply` or `patch -p1`.

## Overview

The series currently consists of 2 patches:

1. **ASoC: aw88399: pass firmware name as argument**: modifies the shared library's `aw88399_request_firmware_file()` to accept the firmware filename as a parameter instead of using the hardcoded `AW88399_ACF_FILE` constant (`"aw88399_acf.bin"`). Both existing callers (ASoC and HDA) pass `AW88399_ACF_FILE` to preserve current behavior.

2. **ALSA: hda: aw88399: use SSID-specific firmware name**: modifies the HDA side codec driver to construct a per-model firmware filename using the ACPI subsystem ID (e.g. `"awinic/aw88399_acf_17aa3938.bin"`) instead of the generic `"aw88399_acf.bin"`.

## Testing instructions

### Prerequisites

- A supported Lenovo Legion laptop with working AW88399 audio (i.e. you are already running the patched kernel from this repository or kernel 7.3-rc1+).
- The `aw88399_acf.bin` firmware file you are currently using.

### Steps

1. **Find your ACPI subsystem ID.** Check your dmesg for the SSID that the driver reports:

   ```bash
   sudo dmesg | grep -i "Applying properties for SSID"
   ```

   You should see something like:

   ```
   aw88399-hda i2c-AWDZ8399:00-aw88399-hda.0: Applying properties for SSID 17AA3938
   ```

   The SSID in this example is `17AA3938`. 
   
> [!TIP]
> It is important to determine the exact SSID for your laptop, as each supported model can have one of two possible values depending on the board revision (see main README). Therefore, it is not possible to know in advance which SSID applies to a particular device.

2. **Copy and rename the firmware file.** Create the `awinic/` directory under `/lib/firmware/` and copy your existing firmware file with the SSID-specific name *in lowercase*:

   ```bash
   sudo mkdir -p /lib/firmware/awinic
   sudo cp /lib/firmware/aw88399_acf.bin /lib/firmware/awinic/aw88399_acf_17aa3938.bin
   ```

   Replace `17aa3938` with your own SSID.

3. **Apply the patch and rebuild the kernel.** Follow the same process you used to install the original patched kernel, but using the combined patch from this folder instead for kernel 7.2. Alternatively, individually apply the patches from the `series/` folder to any 7.3-rc1+ source.

4. **Reboot and verify.** Check dmesg for the new firmware loading message:

   ```bash
   sudo dmesg | grep -i aw88399
   ```

   You should see the SSID-specific firmware path in the output, e.g.:

   ```
   aw88399-hda i2c-AWDZ8399:00-aw88399-hda.0: Loaded firmware awinic/aw88399_acf_17aa3938.bin
   ```

   If the driver loads and audio works as before, the patch is working correctly.

## Reporting results

If you've tested this and want to share results, provide feedback on the code, or give me your Tested-by tag beforehand, feel free to email me directly (address in the git commits).

## Changelog

### v0.3
- Updated cover letter with references to the awinic firmware submission.
- Rebased combined patch on the latest driver version.
- Added imitoy's Tested-by tag.
- Rebased series on commit `bde6bed34104463c3c2e8109a5a0212ea9e2cc30` from `tiwai/sound`.

### v0.2
- Removed the ASoC error log cleanups, as they would be better submitted as part of a separate series. Here they conflate unrelated stuff. Only the addition of the missing newlines is left in.
- Moved the successful firmware loading log to the HDA driver where it belongs (the ASoC firmware behavior is unchanged, so there is no reason to promote its `dev_dbg` into `dev_info` as well).
- Removed the separate `kfree` call in favor of an automated cleanup via `__free(kfree)`.
- Slightly reworded the cover letter and commit messages.
- Rebased on commit `41df0a8ef1b8c80b57f8fcb55ae4ee4e6378cb62` from `tiwai/sound`.

### v0.1

Initial version. Based on `tiwai/sound`, commit `282222edb8487e0d064ab65766865c2d8e08a9be`.
