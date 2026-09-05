# Legion Pro 7/7i Gen 10 Linux Audio Driver
[![Build Patched Kernel RPMs](https://github.com/marco-giunta/legion-pro7-gen10-audio/actions/workflows/build_kernel.yml/badge.svg?event=workflow_dispatch)](https://github.com/marco-giunta/legion-pro7-gen10-audio/actions/workflows/build_kernel.yml)
![GitHub Downloads (all assets, all releases)](https://img.shields.io/github/downloads/marco-giunta/legion-pro7-gen10-audio/total?&logo=github&logoColor=white&label=Downloads&labelColor=%231a1a2e&color=%232196f3)

> Patched Linux audio drivers for Lenovo Legion Pro 7/7i Gen 10 (AMD & Intel). Includes Fedora RPM packages and installation automation. [mt7927 community patch](https://github.com/jetm/mediatek-mt7927-dkms) also included to enable Wi-Fi and Bluetooth on the AMD model.

> [!NOTE]
> **The AW88399 HDA side codec driver has been [merged into the Linux kernel](https://github.com/torvalds/linux/commit/e5c91aac491def6ab3f90c4cc246e3fcb0f8f058) and [is now shipping starting with 7.3-rc1](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/diff/sound/hda/codecs/side-codecs/aw88399_hda.c?id=v7.3-rc1&id2=v7.2).** Once the final 7.3 kernel is released, users will only need the firmware file installed, no custom kernel required. Until then, this repository will continue to provide patched kernels for 7.1 and 7.2. See [the upstream tracking issue](https://github.com/nadimkobeissi/16iax10h-linux-sound-saga/issues/65) and the [upstream folder](/upstream/README.md) for historical info about the upstream submission.

> [!IMPORTANT]
> **Firmware note:** The firmware file (`aw88399_acf.bin`) is not yet in the `linux-firmware` repository. Even on kernel 7.3, users will need to install it manually. We are actively working with Lenovo and AWINIC to get the firmware submitted upstream for full out-of-the-box support. See [here](https://github.com/nadimkobeissi/16iax10h-linux-sound-saga/issues/65#issuecomment-5130273339) and [here](/upstream-fw/README.md) for more info.

Recent Lenovo Legion laptops drive their woofers using the AW88399 Smart Amp via I2C bus as side codecs to a Realtek ALC287 HDA codec, in a setup that requires a driver which currently doesn't exist in the mainline Linux kernel. Due to this, on the current stock Linux kernel, the woofers don't work, and as a result the speakers lack bass and overall sound quiet and tinny.

Other Legion models have simpler issues such as needing a mic boost calibration quirk or simply some software EQ rather than a kernel fix.

This repository provides kernel patches and pre-built RPM packages for the models that need a custom kernel, and documentation for those that don't.

**Supported Models** *(AW88399 smart amp fix)*
- Lenovo Legion Pro 7i Gen 10 (16IAX10H) - Intel
- Lenovo Legion Pro 7 Gen 10 (16AFR10H) - AMD
- Lenovo Legion Y9000P 2025 (IAX10) - Intel
- Lenovo Legion R9000P 2025 (ADR10) - AMD
- Lenovo Legion R9000P 2025 (ADR10H) - AMD

**Models potentially supported**
- Legion R9000P (AFR10) - shares a BIOS update package with the supported Legion Pro 7 16AFR10H
- Legion Y9000P (IAX10H) - shares a BIOS update package with the supported Legion Pro 7i 16IAX10H / Y9000P IAX10
- Legion Pro 7 (16ADR10H) - shares the same Windows audio driver package as the supported Legion Pro 7 16AFR10H, including an identical `AWDZ8399.bin` firmware file

If you own one of these models and your woofers are broken on Linux, you are likely a candidate for this patch. Please verify that your laptop passes the checks described [in this section](#will-this-patch-work-on-other-laptops), then open an issue using the ["support new laptops" guide](/docs/support_new_laptops.md).

If you try the current patch and it already works out of the box, please let me know via an issue. This would mean your device shares codec/ACPI SSIDs with an already supported one, which would be useful to share to make the documentation more accurate.

**Other models with separate, simpler fixes**

These models do *not* need a patched kernel, only some software tweaks; see the ["Other Legions" guide](docs/other_legions_guide.md).
- Legion Pro 5i Gen 10 (16IAX10H) - Intel
- Legion Pro 5 Gen 10 (16AFR10) - AMD
- Legion Pro 5 Gen 9 (16ADR10) - AMD
- Legion 5i/7i Gen 10 (16IAX10) - Intel

> *Note on the 7i 16IAX10*: Almost all the models above have no smart amplifier hardware at all (verifiable on [Lenovo's PSREF](https://psref.lenovo.com)), so the patch doesn't apply because there is no dedicated hardware to drive at the kernel level. Furthermore, all these laptops only have 2 speakers, unlike the 4 separate tweeters/woofers pair as the supported Pro 7 models.
>
> The Legion 7i 16IAX10 is an exception: while it also has only 2 speakers, it does use a Cirrus CS35L56 smart amp, but its driver and firmware are already upstream. Therefore, though once again no patched kernel is needed, things like outdated firmware packages can break audio beyond what easyeffects can fix; see e.g. [here](https://forums.linuxmint.com/viewtopic.php?t=455596). So if audio is broken (and not simply quiet or lacking bass) you may need to diagnose further.

Other Legion models may also benefit from this patch despite being currently unsupported.
To determine whether your laptop is a candidate for this driver, see **Step 0** of the manual installation guide or the [**"Will this patch work on other laptops?"**](#will-this-patch-work-on-other-laptops) FAQ. In short, the laptop must have dedicated woofers driven by an AW88399 Smart Amplifier. The FAQ below explains how to verify this using the speaker specifications, ACPI tables, and the official Lenovo Windows audio driver for your machine.

**Credits & Attributions**

*Audio patch*: This work builds upon the [original Intel audio fix](https://github.com/nadimkobeissi/16iax10h-linux-sound-saga) by **Lyapsus**, **Nadim Kobeissi**, and contributors. Their incredible work made this project possible.

*mt7927 patch*: all credit goes to [jetm and contributors](https://github.com/jetm/mediatek-mt7927-dkms).

More detailed credits are available at the bottom of this page.

**What's new in this fork:**
- **Automated Fedora RPM builds** via GitHub Actions
- **Installation wizards** and automation scripts
- **Comprehensive self-compile guide** for Fedora
- **[mt7927 community patch](https://github.com/jetm/mediatek-mt7927-dkms)** to enable Wi-Fi and Bluetooth on the AMD model
- **easyeffects profiles** to restore some Windows-like features

The actual patch development is now shared between this fork and the original repo, as I now maintain both.

***AI disclaimer:*** Especially in the earlier stages of this project, I relied on claude.ai for help with things I didn't fully understand; as I learned more about Linux and audio, I became more confident and less reliant on those tools. I can attest that ***all the code I added to the original patch was written by me, based on existing Linux code and documentation*** (see e.g. [here](https://github.com/nadimkobeissi/16iax10h-linux-sound-saga/issues/30#issuecomment-4176726805) and [here](https://github.com/nadimkobeissi/16iax10h-linux-sound-saga/issues/55)). Likewise, ***the guides and tools in this repo were written and tested by me, based on official Fedora documentation***.
I still use AI for brainstorming or assistance with bugs; for example, Claude helped me fix or improve some parts of the GitHub Actions pipeline and the install script. These changes were limited to bugfixes or minor improvements; the overall logic and design are my own. Most importantly, it had no role in writing the actual kernel patch code.
More generally, Claude was part of how I learned (alongside reading documentation and experimenting on my hardware), but the end result reflects my own understanding and work. Therefore, while everything distributed in this repository is human-written, I think it's only fair to acknowledge the role LLMs played in getting there.

***Responsibility disclaimer:*** Although I tested everything on my own hardware and at my own risk, and can attest everything works, this software is provided *as is*. Use it at your own risk; I take no responsibility for any damage or issues that may occur.

---

# Install guide
## Before You Begin
### Patched kernel RPMs compatibility
The install instructions below assume you're using Fedora and installing the patched kernel using the prebuilt RPMs from this repo. If you're on a different Linux distro or prefer to compile your own kernel RPMs, see the FAQ for manual patching instructions.

The automated install script supports stock Fedora. On Fedora derivatives (such as Nobara), the script will still install the patched kernel and the aw88399 firmware, but will skip the NVIDIA driver step, as derivatives typically manage their own driver stack. In that case, you may need to rebuild your NVIDIA drivers manually after rebooting into the patched kernel.

Alternatively, for Fedora derivatives, the manual install instructions should still work, but you may need to adapt the steps.

### Secure Boot 
The precompiled kernel distributed in this repo is unsigned, unlike the stock Fedora one. If Secure Boot is enabled, attempting to boot the patched kernel from GRUB will result in a black screen. 
The same applies to NVIDIA drivers: since they are not part of the kernel and are unsigned by default, they will also be blocked by Secure Boot and cause the same issue.

Because of this, Secure Boot must either be disabled or properly configured before the patched kernel or NVIDIA drivers can be used.

*Recommended approach*:
1. Disable Secure Boot in the BIOS;
2. Install the patched kernel and NVIDIA drivers, and verify that the system boots correctly;
3. Optionally, sign the kernel and drivers, then re-enable Secure Boot (see the [Secure Boot guide](docs/secure_boot.md) for instructions).

> [!WARNING]
> If you dual boot Windows, ***before changing any BIOS setting***, go to https://account.microsoft.com/devices/recoverykey and make sure you have your BitLocker recovery key saved and noted down. Windows will ask for it e.g. after disabling Secure Boot, so make sure you're not locked out.

## Installation guides
There are two main ways to install the patched kernel on Fedora.
### Automated Installation
The easiest method is to run the automated wizard:
```bash
curl -fsSL https://raw.githubusercontent.com/marco-giunta/legion-pro7-gen10-audio/legion_audio/scripts/install.sh | sudo sh
```

This script will guide you through installing the required firmware, the NVIDIA drivers from the RPM Fusion nonfree repo, and the patched kernel's RPMs.
If you wish to customize the install (for example, to install the proprietary NVIDIA driver from a different repo, or to use open source ones instead), please refer to the "manual installation" section below.

> [!TIP]
> As with any script you run with elevated privileges, you are encouraged to [read it](scripts/install.sh) before running it. The script is short, commented, and does only what is described above.

After the script is done, reboot; your system should automatically boot the patched kernel. You can confirm this by running `uname -r`; if you see a string containing the word `legion`, you're good to go. Otherwise, reboot your computer and repeatedly press the ESC key during boot to access the grub menu. You'll find an entry labeled `<...>.legion<...>.fc<...>.x86_64`; select it with the up/down keys, then press enter.

### Manual installation
If you'd rather not run an automated script, follow the steps below to install everything manually; these are functionally equivalent to the install wizard.

0. **Verify your device is supported**

Check your SSID:
```bash
grep -l "Codec: Realtek" /proc/asound/card*/codec#* | xargs grep -i "Subsystem Id"
```
You should see a line like `Subsystem Id: 0x17aa<...>`, where `<...>` equals 4 characters. These are the IDs currently supported by the patch:
- `0x17aa3906`, `0x17aa3907` - Legion Pro 7i Gen 10 / Y9000P 2025 (16IAX10H / IAX10, Intel)
- `0x17aa3927`, `0x17aa3928` - Legion R9000P 2025 (ADR10, AMD)
- `0x17aa3936`, `0x17aa3937` - Legion R9000P 2025 (ADR10H, AMD)
- `0x17aa3938`, `0x17aa3939` - Legion Pro 7 Gen 10 (16AFR10H, AMD)

If your ID matches one of these, proceed to step 1.

If your ID is not listed, but your laptop is one of the supported models, it may simply be an undiscovered hardware revision.

Before opening an issue, verify that your laptop satisfies the requirements described in the [**"Will this patch work on other laptops?"**](#will-this-patch-work-on-other-laptops) FAQ. In short, you must ensure that:

- it has two dedicated woofers and a Smart Amplifier (as stated on the PSREF website);
- its ACPI tables contain the `AWDZ8399` entry;
- its Windows Realtek audio driver contains the `AWDZ8399.bin` firmware binary file.

More details in that FAQ entry.

If all checks pass, please open an issue following the instructions from the ["support new laptops" guide](docs/support_new_laptops.md).

Similarly, if you don't get a matching codec SSID *and* your laptop is a model other than one of the supported ones, perform the same basic diagnostics before opening an issue with the same "support new laptops" guide. If you own a Legion 5i/7i 16IAX10, a Legion Pro 5i 16IAX10H, or a Legion Pro 5 16AFR10/16ADR10, you don't need a patched kernel at all; see the [audio guide for other Legion models](docs/other_legions_guide.md).

1. **Install the firmware**
- Download the [`aw88399_acf.bin` file](firmware/aw88399/aw88399_acf.bin); alternatively, you can extract the binary yourself from the Windows driver by following the instructions in [this section](#step-3-verify-the-windows-audio-driver-contains-the-aw88399-firmware-binary).
- *Optional but recommended:* Download the [`aw88399_acf.bin.sha256`](firmware/aw88399/aw88399_acf.bin.sha256) file, put it in the same folder as the downloaded `aw88399_acf.bin`, and check the integrity of the binary:
```bash
# run this in the folder containing both the .bin and the .bin.sha256 files
sha256sum -c aw88399_acf.bin.sha256
```
If this doesn't return "OK", it means either file got corrupted in the download.
- Install the firmware by copying the `aw88399_acf.bin` file to `/lib/firmware/aw88399_acf.bin`:
```bash
sudo cp -f aw88399_acf.bin /lib/firmware/aw88399_acf.bin
```
- If you own the AMD model and wish to enable Wi-Fi and Bluetooth using jetm's [mt7927 patch](https://github.com/jetm/mediatek-mt7927-dkms), you will also need the MediaTek WiFi/BT firmware binaries. These files have been submitted to the `linux-firmware` repository alongside jetm's kernel submission:
  - **WiFi firmware** (`WIFI_MT6639_PATCH_MCU_2_1_hdr.bin`, `WIFI_RAM_CODE_MT6639_2_1.bin`): [accepted upstream](https://gitlab.com/kernel-firmware/linux-firmware/-/merge_requests/1055) and already shipped by Fedora's `linux-firmware` package as `.bin.xz` files. Check if you already have `/lib/firmware/mediatek/mt7927/WIFI_MT6639_PATCH_MCU_2_1_hdr.bin.xz` and `/lib/firmware/mediatek/mt7927/WIFI_RAM_CODE_MT6639_2_1.bin.xz` (running `dnf update` may be needed first); if you do, you don't need to install these files manually.
  - **Bluetooth firmware** (`BT_RAM_CODE_MT6639_2_1_hdr.bin`): [not yet accepted upstream](https://gitlab.com/kernel-firmware/linux-firmware/-/merge_requests/946), so this still needs to be installed manually.

  For the Bluetooth file (and the WiFi files if not already present), [download them from this repo](firmware/mt7927), then verify and install them:
```bash
# check sha256 checksums
sha256sum -c BT_RAM_CODE_MT6639_2_1_hdr.bin.sha256
sha256sum -c WIFI_RAM_CODE_MT6639_2_1.bin.sha256
sha256sum -c WIFI_MT6639_PATCH_MCU_2_1_hdr.bin.sha256
```

```bash
# install wifi firmware
sudo mkdir -p /lib/firmware/mediatek/mt7927
sudo cp -f WIFI_MT6639_PATCH_MCU_2_1_hdr.bin /lib/firmware/mediatek/mt7927
sudo cp -f WIFI_RAM_CODE_MT6639_2_1.bin /lib/firmware/mediatek/mt7927
# install bt firmware
sudo cp -f BT_RAM_CODE_MT6639_2_1_hdr.bin /lib/firmware/mediatek/mt7927
```
To obtain your own copy of these Mediatek binaries from official Windows drivers, you can use the scripts in [jetm](https://github.com/jetm/mediatek-mt7927-dkms)'s repo.


2. **Install the NVIDIA driver builder**

The `akmod-nvidia` package is needed to automatically build the NVIDIA driver for the patched kernel. This package builds the driver as distributed in the nonfree RPM Fusion repo, and is [the standard approach on Fedora](https://rpmfusion.org/Howto/NVIDIA) and what this guide assumes.

> [!NOTE]
> Skip this step if you prefer the open source Mesa/NVK driver, want to obtain the proprietary driver from a different repo, or are on a Fedora derivative that already manages the NVIDIA driver for you. Since the patch only touches audio (and optionally WiFi/BT on the AMD model), there's no fundamental reason why a different graphics setup shouldn't work; however, alternative paths are untested, so you're on your own. Feel free to open an issue if you run into anything useful to share. If you're unsure, just follow the steps below.


Run the following command:
```bash
rpm -qa | grep akmod-nvidia
```
If you see `akmod-nvidia-<...>.x86-64` the package is already installed and you can skip to step 3; otherwise:
- Enable the free and nonfree RPM Fusion repositories if you haven't already:
```bash
sudo dnf install https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
sudo dnf install https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
```
- install the `akmod-nvidia` package:
```bash
sudo dnf install akmod-nvidia
```
3. **Obtain the kernel RPMs**
- Head to the [releases section](https://github.com/marco-giunta/legion-pro7-gen10-audio/releases) and download the latest kernel available. Alternatively, you can compile your own patched kernel in RPM format using my [self compile guide](docs/self_compile.md).
- *Optional but recommended:* download the corresponding sha256 checksum and check the integrity of the downloaded file:
```bash
sha256sum -c legion-pro7-audio-*.tar.gz.sha256
```
- Unpack the archive and install the RPMs:
```bash
tar xzf legion-pro7-audio-*.tar.gz
sudo dnf install --nogpgcheck kernel-*.rpm
```
The patched kernel will now be available in the grub menu. If you installed the `akmod-nvidia` package in step 2, before rebooting, run
```bash
sudo akmods --force
```
and wait for it to confirm that the NVIDIA driver for the patched kernel has been built successfully.

4. **Post install**
- After rebooting, verify the installation:
```bash
# Check kernel version
uname -r
# Should contain the word "legion"

# List installed custom kernels
rpm -qa | grep legion

# Test audio
speaker-test -c 2 -t wav
```
The same rule stated in the previous section applies: ensure you select the analog stereo duplex profile (or enable the boot parameter on the Intel model), and you're good to go!

## Optional Post-installation Steps

### Secure Boot
Once the patched kernel and NVIDIA drivers are working, you can optionally re-enable Secure Boot by signing the kernel and modules with your own Machine Owner Key (MOK). See the [Secure Boot guide](docs/secure_boot.md) for full step-by-step instructions.

### Set the patched kernel as persistent default
If you keep both the patched and stock kernels installed (recommended), every time Fedora ships a kernel update, the stock kernel will silently reclaim the default GRUB boot entry. Because of this, the patched kernel will no longer automatically boot, and you'll have to select it manually from the GRUB boot menu on every startup. The fix below automatically re-asserts the patched kernel as default after every kernel install.

[All credit for this fix goes to GitHub user mikaeldui.](https://gist.github.com/mikaeldui/bf3cd9b6932ff3a2d49b924def778ebb)

1. Create the post-install script:
```bash
sudo mkdir -p /etc/kernel/postinst.d
sudo nano /etc/kernel/postinst.d/99-default
```

2. Paste the following inside the terminal:
```bash
#!/bin/sh

set -e

grubby --set-default=/boot/$(ls -v /boot | grep vmlinuz.*legion | tail -1)
```
Save the script with `CTRL+X`, followed by `y`, then `ENTER`.

3. Set the correct ownership and permissions:
```bash
sudo chown root:root /etc/kernel/postinst.d/99-default
sudo chmod u+rx /etc/kernel/postinst.d/99-default
```

These steps have to be performed only once. You can verify the default kernel at any time by running `sudo grubby --default-kernel`; the output should contain the word `legion`.

### Echoing jack issue fix
While headphones are plugged in the jack port, if both music is playing and the mic is recording (e.g. you are on a discord call while playing a game), if the output volume is high enough, the mic will pick up a quieter copy of the signal being played, causing an annoying echo (quiet but audible). [Based on my findings](https://github.com/nadimkobeissi/16iax10h-linux-sound-saga/issues/34#issuecomment-4176480130), this is a hardware limitation that Windows fixes with clever proprietary software that cannot be easily replicated 1:1 under Linux. To fix this issue, you have two options:
- Use a jack to usb adapter, as the usb ports use different electronics and are unaffected by this issue;
- Install easyeffects and import my [echo canceling profile](easyeffects/echo_canceling.json), which is designed to approximate what I think Windows is doing. On one hand, this profile completely kills off the echo, but on the other, voice clarity and words intellegibility decrease compared to when there is no sound being played during the recording. In simple scenarios, the overall performance should be acceptable; however, please be aware that results may vary, especially if the easyeffects profile is being stacked on top of other software with independent signal processing (e.g. discord's default noise canceling/autogain settings). You're welcome to experiment with different easyeffects settings (if you find a better solution, please open an issue and let me know), but if the performance isn't up to par for your use case, it's probably easier to just rely on a usb adapter.

If you want to use easyeffects, I recommend using the flatpak version, as it already comes with all the necessary plugins and is guaranteed to be up to date (the Fedora package, instead, tends to lag behind). 
While easyeffects is running, you will see devices called "Easy Effects Sink" and "Easy Effects Source" pop up in your sound settings; do *not* select them, as easyeffects is designed to automatically hijack the default devices.

### Improved speakers loudness
If you want to make the speakers a bit louder, you can import my [loudness profile](easyeffects/loudness.json); this is useful to make perceived volume closer to Windows. 
This profile simply applies a slight boost, designed to make lower volume levels more usable. Feel free to increase the boost amount, but don't overdo it to avoid damaging the speakers.

### Screaming speakers issue
If you use live monitoring applications (like reaper or audacity) with the headphones unplugged, and have both the speakers and the internal mic active, as long as either volume is high enough, the speakers will start emitting an annoying high pitch sound due to a feedback loop of echoing signals. Just like the echoing jack issue, this is a hardware limitation that Windows solves using proprietary software. It's possible that this may be fixed using another easyeffects profile (e.g. a notch filter), but given that is quite a niche scenario, I'd recommend just using headphones if this is your use-case; this will remove the spurious signal and completely solve the issue.

---
# FAQ
### Can I use this on other Linux distros?
The prepackaged RPMs are Fedora-specific. For other distros, follow the steps in [Nadim's repo](https://github.com/nadimkobeissi/16iax10h-linux-sound-saga) to compile the Linux kernel without relying on Fedora specific tools.

The two new config parameters introduced by this patch (which you must add to your configuration file) are:
```
CONFIG_SND_HDA_SCODEC_AW88399=m
CONFIG_SND_HDA_SCODEC_AW88399_I2C=m
```
These apply to both Intel and AMD models. For everything else, it's recommended you use your existing distro kernel config as a base by copying `/boot/config-$(uname -r)` and appending the two lines above, as described in Nadim's main guide (the one that relies on the kernel's `make` utilities directly). If your distro offers higher-level build tooling (similar to Fedora's `fedpkg`), you may be able to pass these parameters directly rather than editing the config file manually; check your distro's documentation. For more details on the differences between these build methods, see Nadim's repo.

### Can I build my own kernel RPMs on Fedora?
If you wish to compile your own kernel under Fedora Linux, I recommend using my [Fedora specific self-compile guide](docs/self_compile.md) over the [original](https://github.com/nadimkobeissi/16iax10h-linux-sound-saga), as it will make the process much easier: thanks to `fedpkg`, there is no need to manually pick kernel parameters, setup NVIDIA drivers, generate the initramfs, update the grub menu, or copy the files needed to install the patched kernel.

There exist multiple ways to compile the Linux kernel under Fedora (with some guides you can find online based on older methods); I recommend the approach detailed in my guide because it's the most up to date, high level, and beginner-friendly, as well as being based on the latest official method recommended by the Fedora docs themselves (see the guide for Fedora docs sources).

### Will this overwrite the stock kernel?
No. The original kernel remains installed unless you manually remove it, *which you never should*; it's recommended to always keep a backup. You can select which kernel to boot from the GRUB menu (quickly press ESC repeatedly during boot).

### How do I update to a newer kernel version?
Simply re-run the install script; it will automatically download and install the latest kernel built by GitHub Actions, while skipping the pre- and post- install steps that have been already completed.

Alternatively, download and extract the updated tarball, then run the same `dnf install --nogpgcheck` command detailed in the "manual install" section above; anything else (like installing the firmware, installing the NVIDIA package, and setting the correct audio profile) has to be done only once, no need to repeat those steps.

### How do I remove an older version of the patched kernel?
The recommended way to uninstall old kernel builds is to do nothing at all: by default, Fedora keeps around three kernels as fallback, so when you install a new one, the oldest will be removed.

To manually remove a kernel, you can use `dnf remove` on all the RPM packages that were installed by the wizard or you, which you can find using `rpm -qa | grep legion`. Another (slightly faster) way to remove all these packages is by using `dnf history undo` on the original transaction (check which number you need using `dnf history list`). 
Keep in mind that `dnf` prevents the user from removing the kernel currently in use for obvious reasons, so if you want to remove an older install, ensure you do this after booting another kernel from the grub boot menu.

### Do I need to reinstall after Fedora updates?
Regular Fedora updates won't affect the custom kernel. However, when new kernel versions are released, you may want to install updated versions from this repository for the latest features and security fixes.

### Where does the firmware come from?
See [this section](#step-3-verify-the-windows-audio-driver-contains-the-aw88399-firmware-binary) for details on how `aw88399_acf.bin` was extracted from the Windows driver, and how you can extract it yourself if you wish to do so.

### How do I know the prebuilt RPMs and install scripts are safe?
The automated install script downloads and installs prebuilt kernel RPMs from this repository's [releases page](https://github.com/marco-giunta/legion-pro7-gen10-audio/releases). There are several layers of verifiability:
- The RPMs are built automatically by the [GitHub Actions workflow](.github/workflows/build_kernel.yml) from the patch files in this repository, with a public build log for every release (see [here](https://github.com/marco-giunta/legion-pro7-gen10-audio/actions)). These files were *not* uploaded manually by me, and the workflow that generated them is short and auditable. SHA-256 checksums are generated and verified during installation, so you can confirm the files were not corrupted or tampered with in transit.
- The install script itself is [readable here](scripts/install.sh). It downloads the RPMs, verifies their checksums, copies the required firmware files to `/lib/firmware`, and sets up the NVIDIA driver builder via RPM Fusion. Piping scripts from the internet directly into a root shell is a pattern I personally find a bit sketchy (despite it being quite common), so I actively encourage you to read the script rather than just taking my word for it. If you prefer, download it first, inspect it, and run it manually. A more official (but also more expensive to maintain) distribution method like a COPR repository was never set up because this repo was always intended as a temporary stopgap until the upstream kernel merge was complete, which has now happened.
- The kernel patches are publicly visible in [`patches/`](patches/).
- You can [build the patched kernel yourself](docs/self_compile.md) to verify.

In short: the build process is transparent and auditable, the downloads are checksum-verified, and the script itself is short and readable. You are not being asked to trust a black box.

### Black screen issues
If you see a black screen with a cursor or bar in the top left corner after selecting the patched kernel in the GRUB boot menu, the most likely cause is Secure Boot preventing the patched kernel from loading, as it is unsigned (unlike the stock Fedora kernel).
A black screen can also indicate a GPU driver initialization failure. 

To find out which is it, follow these steps in order.

> [!WARNING]
> If you dual boot Windows, ***before changing any BIOS setting***, go to https://account.microsoft.com/devices/recoverykey and make sure you have your BitLocker recovery key saved and noted down. Windows will ask for it e.g. after disabling Secure Boot, so make sure you're not locked out.

1. Check if Secure Boot is enabled in the BIOS settings (it will be if your machine came with Windows and you haven't disabled SB yet); if so, disable SB and try booting the patched kernel. If this works, Secure Boot was the issue.
2. If the above doesn't fix the black screen, the issue is likely GPU driver related. With Secure Boot still disabled, try the following:
- Access the GRUB menu by quickly and repeatedly pressing `ESC` during boot;
- Highlight with the arrow keys the patched kernel, then press `e`;
- Add `nomodeset` to the end of the line starting with `linux`, then save by pressing `CTRL+X` or `F10`.

These steps disable GPU mode setting entirely. If the OS boots with this parameter, the issue is driver related. In this case, boot back into the stock kernel and run `sudo akmods --force` to check whether the NVIDIA driver built correctly for the patched kernel, then reboot and try starting the patched kernel from the GRUB menu again.
Please note that changes to the boot parameters made using the steps above are temporary and are reset at every reboot, so to test if rebuilding the driver worked, you don't have to manually remove the `nomodeset` parameter; booting normally suffices.

### Fedora derivatives
On mutable Fedora derivatives such as Nobara, the automated install script will work for the kernel and firmware steps but will skip the NVIDIA driver installation, as these distros typically ship their own driver stack. At least one user has [successfully installed the patch on Nobara 43](https://github.com/nadimkobeissi/16iax10h-linux-sound-saga/issues/55#issuecomment-4416042264); if you try it on a derivative and it works, please open an issue and share what you did.

### Immutable Fedora spins and derivatives
It should be possible to use the patched kernel on immutable distributions by installing the RPMs with `rpm-ostree` instead of `dnf`. However, a proper setup will likely require rebasing your image to include both the patched kernel and the necessary firmware binaries. While the former is likely achievable with `rpm-ostree`, the latter is less straightforward and not something I have explored. Similarly, the steps in the [self-compile guide](docs/self_compile.md) should work if performed inside a container. If you're on a distro like Bazzite, feel free to try it out, and if you do get it working, please open an issue and share what you did so I can update the main guide!

### Will this patch work on other laptops?
The aw88399 patch has two components:

1. *AW88399 HDA side codec driver:* The AW88399 is a smart amplifier used to drive the woofers on the supported Legions; in particular, this happens via I2C bus as side codecs to a Realtek ALC287 HDA codec, and this setup requires a driver that is currently missing from the mainline Linux kernel. This part of the patch adds that missing driver, and is in principle useful for any laptop using this chip in this configuration, regardless of manufacturer or model.

2. *codec subsystem ID quirk:* The kernel needs to know which laptops use this setup in order to load the right driver and firmware at boot. This is done via a quirk entry specific to each laptop model, identified by its codec subsystem ID. This is the part that must be added on a per-model basis, and is what determines whether a given laptop is "supported" by this patch: without the correct quirk entry, even a laptop that would benefit from the new driver will never use it, because the kernel doesn't know that it is supposed to load it on that specific model.

If your laptop's woofers don't work on Linux, it may be tempting to try this patch, but broken woofers can have many causes, and this patch only fixes these specific hardware configurations.

For example, other Legions in the Gen 10 family only need some easyeffects software magic, as explained in [this guide](docs/other_legions_guide.md).

Having said that, if your laptop uses the same AW88399 smart amp in the same configuration, there is a real chance it could benefit from this patch once a quirk entry is added for your model.

#### How to tell whether this patch applies to your laptop

This patch is **not** for every laptop with poor speaker quality. It only applies to laptops that:

1. have dedicated woofers driven by a Smart Amplifier,
2. use an AW88399 Smart Amplifier.

To determine whether these conditions hold for your laptop, perform the checks below.
These checks answer different questions, and all of them are required.

#### Step 1: Verify the speaker configuration

Start by looking up your exact model on Lenovo's [PSREF website](https://psref.lenovo.com/) (for laptops exclusive to markets other than western ones, you may need to locate a different website).

Your laptop *must* have dedicated woofers and a smart amplifier. For example, a potentially compatible configuration looks like:

> 4 stereo speakers, 2W x2 (woofers), 2W x2 (tweeters), optimized with Nahimic Audio, Smart Amplifier (AMP)

Instead, a configuration like

> Stereo speakers, 2W x2, optimized with Nahimic Audio

is **not** compatible with this patch.

#### Step 2: Check for an AW88399 ACPI entry

Run

```bash
sudo strings /sys/firmware/acpi/tables/DSDT | grep AWDZ8399
```

If this returns output, the BIOS advertises an AW88399 device through ACPI.

If it does not, your laptop either has no smart amplifier or uses a different one, and this patch does not apply.

#### Step 3: Verify the Windows audio driver contains the AW88399 firmware binary
Go to the [PC support website](https://pcsupport.lenovo.com) (once again, you may need to locate the website specific to your region, e.g. [this one is specific to China](https://newsupport.lenovo.com.cn/)), then download the Windows audio driver for your device in `.exe` format. Then, install the `innoextract` package and run:
```sh
innoextract <windows audio driver.exe>
```
This will create a folder called `code$GetExtractPath$`, inside which there will be a `Source` folder. Inside, there *must* be a folder whose name contains the word `Awinic` (or something related to the AW88399 chip, e.g. a string like `AW883XX`), and this folder *must* contain a file called `AWDZ8399.bin`.

The AW88399 requires a model-specific firmware binary (`AWDZ8399.bin`) to initialize. If the Windows audio driver for your laptop does not contain this file, the AW88399 cannot be present, as Windows would have no firmware to load onto it.

#### Why are all these checks necessary?

None of these checks alone is sufficient.

- The PSREF website confirms that the laptop actually has dedicated woofers driven by a Smart Amplifier. However, Lenovo uses Smart Amplifiers from multiple manufacturers, so this alone does not tell us which chip is present.

- The ACPI `AWDZ8399` check confirms that the BIOS contains an ACPI entry for an AW88399. However, some Lenovo models share the same BIOS image, so the ACPI tables may advertise an AW88399 even on models where the corresponding hardware is not populated.

- The Windows driver check confirms that Lenovo ships the model-specific AW88399 firmware (`AWDZ8399.bin`) required to initialize the chip on that laptop. However, Lenovo sometimes ships a common Windows audio driver package for multiple laptop models, so the presence of this file alone does not guarantee that the firmware is actually used on your particular laptop.

Only when **all three** checks agree should the laptop be considered a candidate for this patch.
If your laptop passes all the above checks, please open an issue using [this guide](docs/support_new_laptops.md).
If instead any of the checks fail, this patch almost certainly does not apply to your laptop.

I can then try adding support for your device by adding its ID, but be aware that more work than this may be needed. To be more precise: adding the ID may not be enough, as the Legion Pro 7 models currently supported by this patch also require specific tweaks regarding both the realtek and awinic codec sides, and other fixes may apply to your model. The guide linked above contains information to collect diagnostics on whether the same quirks apply or not.

> [!NOTE]
> The driver is structured to make it possible to extend support beyond the currently known hardware configurations. For example, a future device might use additional AW88399 addresses to drive more than 2 woofers, or require new codec quirks. Supporting these configurations would be more substantial changes than simply adding another ID, and would make for interesting future work.
>
> Therefore, if your diagnostics reveal an AW88399 configuration that doesn't quite match the ones described here, please open an issue anyway. In particular, the relevant details can often be visible in the ACPI tables and codec dumps, so don't assume that a slightly different hardware configuration means the device cannot be supported. I'd be happy to investigate and, if feasible, extend the driver and submit the changes upstream.

---
## Credits

### Audio patch

This project would not exist without the contributions of many people.

The original Intel audio driver work was done by **Yakov Till (Lyapsus)** and **Nadim Kobeissi** at [nadimkobeissi/16iax10h-linux-sound-saga](https://github.com/nadimkobeissi/16iax10h-linux-sound-saga). Lyapsus wrote the initial working prototype that proved the HDA side codec approach, and Nadim organized the bounty effort that brought the community together.

Building on their work, I (**Marco Giunta**) reworked the patch into an upstream-ready driver: porting to the AMD platform (by fixing volume controls at the correct legacy HDA kernel level, replacing the original Intel-only forced SOF mode + userspace pipewire workarounds), extracting a shared library from the existing ASoC driver, fixing volume controls via DAC rerouting, fixing internal mic calibration, adding per-model quirk infrastructure with ACPI subsystem ID matching, removing unused code, and navigating the upstream submission process through to acceptance into the Linux kernel by multiple maintainers.

Regarding userspace level, I explored the cause of the bleeding jack issue by reverse engineering parts of the Windows driver, built Fedora-specific automation tools for this repo specifically, and wrote extensive documentation for this repo as well as Nadim's.

For some historical references, see issues [#30](https://github.com/nadimkobeissi/16iax10h-linux-sound-saga/issues/30#issuecomment-4176726805), [#34](https://github.com/nadimkobeissi/16iax10h-linux-sound-saga/issues/34), [#55](https://github.com/nadimkobeissi/16iax10h-linux-sound-saga/issues/55), [#65](https://github.com/nadimkobeissi/16iax10h-linux-sound-saga/issues/65), as well as the [upstream folder's readme](upstream/README.md).

The upstream patches can be viewed on the lore archives:
- [v1 (ASoC library, patches 1-5)](https://lore.kernel.org/linux-sound/DS7PR19MB77247D9AD698CF0FF37DB58BFCC62@DS7PR19MB7724.namprd19.prod.outlook.com/T/#t)
- [v2 (HDA driver + realtek fixups + SMI I2C entries, patches 6-8)](https://lore.kernel.org/linux-sound/DS7PR19MB7724AB9AA5096BF2F00014B0FCCA2@DS7PR19MB7724.namprd19.prod.outlook.com/T/#t)

#### Individual contributions

This project would have never happened without the help of several amazing people. I am personally indebted especially to these awesome people (in approximately chronological order):

- Nadim Kobeissi ([@nadimkobeissi](https://github.com/nadimkobeissi)): started this project, conducted the initial investigation, organized the bounty effort, and tested on the original 16IAX10H. I am especially thankful to Nadim for trusting me with the keys of this kingdom.
- Yakov Till ([@Lyapsus](https://github.com/Lyapsus)): wrote the initial working prototype driver that proved the approach and provided the foundation for everything that followed. Without his work, none of this would have been possible. I am also thankful for the fruitful discussions.
- [@philstopford](https://github.com/philstopford) and [@gluceri](https://github.com/gluceri): helped add AMD support, tested volume controls fix, reported the mic calibration issue and tested the fix, and were the first people to test my contributions (and more generally to believe in me).
- [@msteele](https://github.com/msteele): reported the second AMD codec SSID early
- Xia Yun'an ([@imitoy](https://github.com/imitoy)): helped add Y9000P support, extensively tested all iterations of the upstream patch series, and is actively helping contact AWINIC for firmware upstream submission
- Munzir Taha ([@munzirtaha](https://github.com/munzirtaha)): reported the firmware reload bug and SOF/mic profile issues, tested the upstream patch series, and provided consistently detailed diagnostic reports (most eagle-eyed tester ever).
- [@ZephyrSober](https://github.com/ZephyrSober), [@bash-shabash](https://github.com/bash-shabash), [@tduck1equack](https://github.com/tduck1equack): helped add R9000P ADR10 support by reporting the PCI SSID collision and testing the fix
- [@287433](https://github.com/287433): helped add support for the R9000P ADR10H by reporting its IDs
- Finally, I extend my thanks to everyone who contributed time, energy, logs, codec dumps, money to the bounty, or simply reported their experience (especially those who did so before I joined the project)

If you helped me personally but I forgot to mention you by name, please know it's not for lack of gratitude; this project had many hands, and every contribution mattered. I may simply be misremembering something from the past ~8 months.

It's been an amazing journey; I learned a lot, got to meet and collaborate with many wonderful people, and I'm grateful to everyone who made it possible. If in the future we need to fix something, add support for new devices, or extend the driver to new hardware configurations, please don't hesitate to contact me. In the meantime, I will keep supporting the combined patch for kernels 7.1 and 7.2 until 7.3 ships with the driver built in.

<details>
<summary>Original credits from Nadim Kobeissi's repository</summary>

> Fixing this issue required weeks of intensive work from multiple people.

> Virtually all engineering groundwork was done by [Lyapsus](https://github.com/Lyapsus). Lyapsus improved an incomplete kernel driver, wrote new kernel codecs and side-codecs, and contributed much more. I want to emphasize his incredible kindness and dedication to solving this issue. He is the primary force behind this fix, and without him, it would never have been possible.

> I ([Nadim Kobeissi](https://nadim.computer)) conducted the initial investigation that identified the missing components needed for audio to work on the 16IAX10H on Linux. Building on what I learned from Lyapsus's work, I helped debug and clean up his kernel code, tested it, and made minor improvements. I also contributed the solution to the volume control issue documented in Step 8, and wrote this guide.

> Gergo K. showed me how to extract the AW88399 firmware from the Windows driver package and install it on Linux, as documented in Step 1.

> [Richard Garber](https://github.com/rgarber11) graciously contributed [the fix](https://github.com/nadimkobeissi/16iax10h-linux-sound-saga/issues/19#issuecomment-3594367397) for making the internal microphone work.

> [Marco Giunta's fork](https://github.com/marco-giunta/legion-pro7-gen10-audio) reworked all of the above engineering effort into a much more mature patch, and was reintegrated into this repository as of Linux 6.19.10.

> Sincere thanks to everyone who [pledged](https://github.com/nadimkobeissi/16iax10h-linux-sound-saga/blob/main/PLEDGE.md) a reward for solving this problem.
</details>

### mt7927 patch
All credit goes to [jetm and contributors](https://github.com/jetm/mediatek-mt7927-dkms); I haven't made any meaningful changes to their work. The only difference between their repo and the contents of my [patches/mt7927](patches/mt7927) folder is that I repackaged the split patches in a single file, since this repo is focused on building a patched kernel rather than upstream review or DKMS packaging.

---
## License
Licensed under the GNU General Public License v2.0 only. See [LICENSE](LICENSE).
