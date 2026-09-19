# Will this patch work on other laptops?
The AW88399 patch has two components:

1. *AW88399 HDA side codec driver:* The AW88399 is a smart amplifier used to drive the woofers on the supported Legions; in particular, this happens via I2C bus as side codecs to a Realtek ALC287 HDA codec, and this setup requires a driver that is currently missing from the mainline Linux kernel. This part of the patch adds that missing driver, and is in principle useful for any laptop using this chip in this configuration, regardless of manufacturer or model.

2. *codec subsystem ID quirk:* The kernel needs to know which laptops use this setup in order to load the right driver and firmware at boot. This is done via a quirk entry specific to each laptop model, identified by its codec subsystem ID. This is the part that must be added on a per-model basis, and is what determines whether a given laptop is "supported" by this patch: without the correct quirk entry, even a laptop that would benefit from the new driver will never use it, because the kernel doesn't know that it is supposed to load it on that specific model.

If your laptop's woofers don't work on Linux, it may be tempting to try this patch, but broken woofers can have many causes, and this patch only fixes these specific hardware configurations.

For example, other Legions in the Gen 10 family only need some easyeffects software magic, as explained in [this guide](./other_legions_guide.md).

Having said that, if your laptop uses the same AW88399 smart amp in the same configuration, there is a real chance it could benefit from this patch once a quirk entry is added for your model.

## How to tell whether this patch applies to your laptop

This patch is **not** for every laptop with poor speaker quality. It only applies to laptops that:

1. have dedicated woofers driven by a Smart Amplifier,
2. use an AW88399 Smart Amplifier.

To determine whether these conditions hold for your laptop, perform the checks below.
These checks answer different questions, and all of them are required.

### Step 1: Verify the speaker configuration

Start by looking up your exact model on Lenovo's [PSREF website](https://psref.lenovo.com/) (for laptops exclusive to markets other than western ones, you may need to locate a different website).

Your laptop *must* have dedicated woofers and a smart amplifier. For example, a potentially compatible configuration looks like:

> 4 stereo speakers, 2W x2 (woofers), 2W x2 (tweeters), optimized with Nahimic Audio, Smart Amplifier (AMP)

Instead, a configuration like

> Stereo speakers, 2W x2, optimized with Nahimic Audio

is **not** compatible with this patch.

### Step 2: Check for an AW88399 ACPI entry

Run

```bash
sudo strings /sys/firmware/acpi/tables/DSDT | grep AWDZ8399
```

If this returns output, the BIOS advertises an AW88399 device through ACPI.

If it does not, your laptop either has no smart amplifier or uses a different one, and this patch does not apply.

### Step 3: Verify the Windows audio driver contains the AW88399 firmware binary
Go to the [PC support website](https://pcsupport.lenovo.com) (once again, you may need to locate the website specific to your region, e.g. [this one is specific to China](https://newsupport.lenovo.com.cn/)), then download the Windows audio driver for your device in `.exe` format. Then, install the `innoextract` package and run:
```sh
innoextract <windows audio driver.exe>
```
This will create a folder called `code$GetExtractPath$`, inside which there will be a `Source` folder. Inside, there *must* be a folder whose name contains the word `Awinic` (or something related to the AW88399 chip, e.g. a string like `AW883XX`), and this folder *must* contain a file called `AWDZ8399.bin`.

The AW88399 requires a model-specific firmware binary (`AWDZ8399.bin`) to initialize. If the Windows audio driver for your laptop does not contain this file, the AW88399 cannot be present, as Windows would have no firmware to load onto it.

## Why are all these checks necessary?

None of these checks alone is sufficient.

- The PSREF website confirms that the laptop actually has dedicated woofers driven by a Smart Amplifier. However, Lenovo uses Smart Amplifiers from multiple manufacturers, so this alone does not tell us which chip is present.

- The ACPI `AWDZ8399` check confirms that the BIOS contains an ACPI entry for an AW88399. However, some Lenovo models share the same BIOS image, so the ACPI tables may advertise an AW88399 even on models where the corresponding hardware is not populated.

- The Windows driver check confirms that Lenovo ships the model-specific AW88399 firmware (`AWDZ8399.bin`) required to initialize the chip on that laptop. However, Lenovo sometimes ships a common Windows audio driver package for multiple laptop models, so the presence of this file alone does not guarantee that the firmware is actually used on your particular laptop.

Only when **all three** checks agree should the laptop be considered a candidate for this patch.
If your laptop passes all the above checks, please open an issue using [this guide](./support_new_laptops.md).
If instead any of the checks fail, this patch almost certainly does not apply to your laptop.

I can then try adding support for your device by adding its ID, but be aware that more work than this may be needed. To be more precise: adding the ID may not be enough, as the Legion Pro 7 models currently supported by this patch also require specific tweaks regarding both the realtek and awinic codec sides, and other fixes may apply to your model. The guide linked above contains information to collect diagnostics on whether the same quirks apply or not.

> [!NOTE]
> The driver is structured to make it possible to extend support beyond the currently known hardware configurations. For example, a future device might use additional AW88399 addresses to drive more than 2 woofers, or require new codec quirks. Supporting these configurations would be more substantial changes than simply adding another ID, and would make for interesting future work.
>
> Therefore, if your diagnostics reveal an AW88399 configuration that doesn't quite match the ones described here, please open an issue anyway. In particular, the relevant details can often be visible in the ACPI tables and codec dumps, so don't assume that a slightly different hardware configuration means the device cannot be supported. I'd be happy to investigate and, if feasible, extend the driver and submit the changes upstream.
