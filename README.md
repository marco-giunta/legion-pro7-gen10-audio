# Legion Pro 7/7i Gen 10 Linux Audio Driver

> Patched Linux audio drivers for Lenovo Legion Pro 7/7i Gen 10 (AMD & Intel). Includes Fedora RPM packages and installation automation. [mt7927 community patch](https://github.com/jetm/mediatek-mt7927-dkms) also included to enable Wi-Fi and Bluetooth on the AMD model.

Recent Lenovo Legion laptops use the AW88399 Smart Amp, which has incomplete support in the mainline Linux kernel. With the stock kernel only tweeters work (no bass, quiet audio); this repository provides kernel patches and pre-built RPM packages to restore full audio functionality.

**Supported Models**
- Legion Pro 7i Gen 10 (16IAX10H) - Intel
- Legion Pro 7 Gen 10 (16AFR10H) - AMD

**Credits & Attributions**
This work builds upon the [original Intel audio fix](https://github.com/nadimkobeissi/16iax10h-linux-sound-saga) by **Lyapsus**, **Nadim Kobeissi**, and contributors. Their incredible work made this project possible.

**What's new in this fork:**
- **Full AMD platform support** (16AFR10H)
- **Automated Fedora RPM builds** via GitHub Actions
- **Installation wizards** and automation scripts
- **Comprehensive self-compile guide** for Fedora
- **[mt7927 community patch](https://github.com/jetm/mediatek-mt7927-dkms)** to enable Wi-Fi and Bluetooth on the AMD model
- **easyeffects profile to tackle the echoing jack**

***AI disclaimer:*** Especially in the earlier stages of this project, I relied on claude.ai for help with things I didn't fully understand. As I learned more about Linux and audio, I became more confident and less reliant on those tools. I can attest that all the code I added to the original patch was written by myself based on preexisting Linux code and documentation. Likewise, the guides and tools in this repo were written and tested by myself.
I do still use AI for brainstorming or assistance with bugs.

***Responsibility disclaimer:*** Although I tested everything on my own hardware and at my own risk, and can attest everything works, this software is provided *as is*. Use it at your own risk; I take no responsibility for any damage or issues that may occur.

---

## Quick start
***Patch compatibility:*** this section assumes you are a Fedora Linux user who wishes to install the patched kernel prepackaged as an RPM. If you use a different Linux distro or do not wish to use Fedora's tools, please check the FAQ section below for instructions on how to patch the Linux kernel yourself.

### Automated Installation
The easiest way to install the patched kernel is to run the automated wizard:
```bash
curl -fsSL https://raw.githubusercontent.com/marco-giunta/legion-pro7-gen10-audio/legion_audio/scripts/install.sh | sudo sh
```
You can also manually download the [install script](scripts/install.sh) and run it using `sudo sh install.sh`.

This script will guide you through installing the required firmware, setting up the NVIDIA drivers, and installing the patched kernel's RPMs.

After the script is done, reboot; your system should automatically boot the patched kernel. You can confirm this by running `uname -r`; if you see a string containing the word `legion`, you're good to go. Otherwise, reboot your computer and repeatedly press the ESC key during boot to access the grub menu. You'll find an entry labeled `<...>.legion<...>.fc<...>.x86_64`; select it with the up/down keys, then press enter.

***Post-install:*** after you successfully installed the patched kernel, go to your OS sound settings, and ensure the *Analog stereo duplex* sound profile is selected (any other will disable the mic or some/all speakers).

If you read [the original guide](https://github.com/nadimkobeissi/16iax10h-linux-sound-saga), you'll see its post-install instructions involve setting a certain kernel boot parameter and copying some `ucm2` files. This is *not* needed here (and won't work on the AMD model anyway)! I take a different approach with my patch, aimed at making it work out of the box. The only required post install step is ensuring you select the correct profile, as stated above.

### Manual installation
1. **Install the firmware**
- [Download the `aw88399_acf.bin` file from this repo's `firmware` folder](firmware/aw88399/aw88399_acf.bin); alternatively, you can extract the binary yourself from the Windows driver by following the instructions in the [firmware extraction guide](docs/firmware_extraction.md).
- *Optional but recommended:* [Download the `aw88399_acf.bin.sha256` file from this repo's `firmware` folder](firmware/aw88399/aw88399_acf.bin.sha256), put it in the same folder as the downloaded `aw88399_acf.bin`, and check the integrity of the binary:
```bash
# run this in the folder containing both the .bin and the .bin.sha256 files
sha256sum -c aw88399_acf.bin.sha256
```
If this doesn't return "OK", it means either file got corrupted in the download.
- Install the firmware by copying the `aw88399_acf.bin` file to `/lib/firmware/aw88399_acf.bin`:
```bash
sudo cp -f aw88399_acf.bin /lib/firmware/aw88399_acf.bin
```
- If you own the AMD model and wish to enable Wi-Fi and Bluetooth using jetm's [mt7927 patch](https://github.com/jetm/mediatek-mt7927-dkms), repeat the above steps with [BT_RAM_CODE_MT6639_2_1_hdr.bin](firmware/mt7927/BT_RAM_CODE_MT6639_2_1_hdr.bin), [WIFI_MT6639_PATCH_MCU_2_1_hdr.bin](firmware/mt7927/WIFI_MT6639_PATCH_MCU_2_1_hdr.bin), and [WIFI_RAM_CODE_MT6639_2_1.bin](firmware/mt7927/WIFI_RAM_CODE_MT6639_2_1.bin) (but mind the different install location):
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
```

```bash
# install bt firmware
sudo mkdir -p /lib/firmware/mediatek/mt6639
sudo cp -f BT_RAM_CODE_MT6639_2_1_hdr.bin /lib/firmware/mediatek/mt6639
```


2. **Install the NVIDIA driver builder**
The `akmod-nvidia` package is needed to automatically build the NVIDIA driver for the patched kernel.
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
- Head to the [releases section](link) and download the latest kernel available. Alternatively, you can compile your own patched kernel in RPM format using my [self compile guide](docs/self_compile.md).
- *Optional but recommended:* download the corresponding sha256 checksum and check the integrity of the downloaded file:
```bash
sha256sum -c legion-pro7-audio-*.tar.gz.sha256
```
- Unpack the archive and install the RPMs:
```bash
tar xzf legion-pro7-audio-*.tar.gz
cd ...
sudo dnf install --nogpgcheck kernel-*.rpm
```
The patched kernel will now be available in the grub menu. Before rebooting, run
```bash
sudo akmods --force
```
and wait for it to confirm that the NVIDIA driver for the patched kernel has been built successfully.

4. **Post install**
After rebooting, verify the installation:
```bash
# Check kernel version
uname -r
# Should contain the word "legion"

# List installed custom kernels
rpm -qa | grep legion

# Test audio
speaker-test -c 2 -t wav
```
The same rule stated in the previous section applies: ensure you select the analog stereo duplex profile, and you're good to go! No boot parameters or ucm2 configuration files needed.

### Echoing jack issue fix
While headphones are plugged in the jack port, if both music is playing and the mic is recording (e.g. you are on a discord call while playing a game), if the output volume is high enough, the mic will pick up a quieter copy of the signal being played, causing an annoying echo (quiet but audible). [Based on my findings](link), this is a hardware limitation that Windows fixes with clever proprietary software that cannot be easily replicated 1:1 under Linux. To fix this issue, you have two options:
- Use a jack to usb adapter, as the usb ports use different electronics and are unaffected by this issue;
- Install easyeffects and import my [echo canceling profile](easyeffects/echo_canceling.json), which is designed to approximate what I think Windows is doing. Although I think I did a decent job, please be aware that results may vary, especially if the easyeffects profile is being stacked on top of other software with independent signal processing (e.g. discord's default noise canceling/autogain settings); you're welcome to experiment with different easyeffects settings (if you find a better solution, please open an issue and let me know), but if the performance isn't up to par, it's probably easier to just rely on a usb adapter.

If you want to use easyeffects, I recommend using the flatpak version, as it already comes with all the necessary plugins and is guaranteed to be up to date (e.g. Fedora still ships the old GTK version). 
While easyeffects is running, you will see devices called "Easy Effects Sink" and "Easy Effects Source" pop up in your sound settings; do *not* select them, as easyeffects is designed to automatically hijack the default devices.
Also, if you want to make the speakers a bit louder (to make perceived volume closer to Windows), you can import my [loudness profile](easyeffects/loudness.json) (it's a simple boost, designed to make lower volume levels more usable).

### Screaming speakers issue
If you use live monitoring applications like reaper or audacity with the headphones unplugged, and have both the speakers and the internal mic active, as long as either volume is high enough, the speakers will start emitting an annoying high pitch sound due to a feedback loop of echoing signals. As for the above point, this is a hardware limitation that Windows solves using proprietary software. It's possible that this may be fixed using another easyeffects profile (e.g. a notch filter), but given that is quite a niche scenario, I'd recommend just using headphones if this is your use-case; this will remove the spurious signal and completely solve the issue.

## FAQ
### Can I use this on other Linux distros?
The prepackaged RPMs are Fedora-specific. For other distros, follow the steps in [the original repo](https://github.com/nadimkobeissi/16iax10h-linux-sound-saga) to compile the Linux kernel without relying on Fedora specific tools. A few caveats:
- If you use the patches in my repo instead of the original, the boot parameter/ucm files step is no longer necessary on the Intel model (and won't do anything on the AMD one).
- If you have the AMD model, use my patches, otherwise volume controls and mic quality will be broken.
- If you have the AMD model, the same
```
CONFIG_SND_HDA_SCODEC_AW88399=m
CONFIG_SND_HDA_SCODEC_AW88399_I2C=m
CONFIG_SND_SOC_AW88399=m
```
config parameters as for the Intel models are needed, but not the Intel-specific ones; use the AMD specific ones instead. The ones used by Fedora are shown in the table below; however, given that a) not all of them are actually used, b) you also need other audio related parameters (e.g. the alc269 codec), and c) most distros build their kernels with ever config already included to maximize broad hardware compatibility, I recommend you just use the same parameters used to compile the kernel you already have. In practice, this means going to `/boot`, copying the appropriate `config-<kernel version>` file, and appending the `CONFIG_SND_HDA_SCODEC_AW88399=m` and `CONFIG_SND_HDA_SCODEC_AW88399_I2C=m` parameters (`CONFIG_SND_SOC_AW88399=m` will realistically already be there, as well as everything else you need for both the Intel and AMD models).
<details>
<summary>AMD audio config parameters</summary>

```bash
CONFIG_SND_SOC_AMD_ACP=m
CONFIG_SND_SOC_AMD_CZ_DA7219MX98357_MACH=m
CONFIG_SND_SOC_AMD_CZ_RT5645_MACH=m
CONFIG_SND_SOC_AMD_ST_ES8336_MACH=m
CONFIG_SND_SOC_AMD_ACP3x=m
CONFIG_SND_SOC_AMD_RV_RT5682_MACH=m
CONFIG_SND_SOC_AMD_RENOIR=m
CONFIG_SND_SOC_AMD_RENOIR_MACH=m
CONFIG_SND_SOC_AMD_ACP5x=m
CONFIG_SND_SOC_AMD_VANGOGH_MACH=m
CONFIG_SND_SOC_AMD_ACP6x=m
CONFIG_SND_SOC_AMD_YC_MACH=m
CONFIG_SND_AMD_ACP_CONFIG=m
CONFIG_SND_SOC_AMD_ACP_COMMON=m
CONFIG_SND_SOC_ACPI_AMD_MATCH=m
CONFIG_SND_SOC_AMD_ACP_PDM=m
CONFIG_SND_SOC_AMD_ACP_LEGACY_COMMON=m
CONFIG_SND_SOC_AMD_ACP_I2S=m
CONFIG_SND_SOC_AMD_ACPI_MACH=m
CONFIG_SND_SOC_AMD_ACP_PCM=m
CONFIG_SND_SOC_AMD_ACP_PCI=m
CONFIG_SND_AMD_ASOC_RENOIR=m
CONFIG_SND_AMD_ASOC_REMBRANDT=m
CONFIG_SND_AMD_ASOC_ACP63=m
CONFIG_SND_AMD_ASOC_ACP70=m
CONFIG_SND_SOC_AMD_MACH_COMMON=m
CONFIG_SND_SOC_AMD_LEGACY_MACH=m
CONFIG_SND_SOC_AMD_SOF_MACH=m
CONFIG_SND_SOC_AMD_SDW_MACH_COMMON=m
CONFIG_SND_SOC_AMD_SOF_SDW_MACH=m
CONFIG_SND_SOC_AMD_LEGACY_SDW_MACH=m
CONFIG_SND_AMD_SOUNDWIRE_ACPI=m
CONFIG_SND_SOC_AMD_RPL_ACP6x=m
CONFIG_SND_SOC_AMD_ACP63_TOPLEVEL=m
CONFIG_SND_SOC_AMD_SOUNDWIRE_LINK_BASELINE=m
CONFIG_SND_SOC_AMD_SOUNDWIRE=m
CONFIG_SND_SOC_AMD_PS=m
CONFIG_SND_SOC_AMD_PS_MACH=m
```

</details>

If you wish to compile your own kernel under Fedora Linux, I recommend using my [Fedora specific self-compile guide](docs/self_compile.md) over the original, as it will make the process much easier: thanks to `fedpkg`, there is no need to manually pick kernel parameters, setup NVIDIA drivers, generate the initramfs, update the grub menu, or copy the files needed to install the patched kernel. Online you can find multiple ways to compile the Linux kernel under Fedora (many based on older methods); I recommend my approach because it's the most up to date, high level, and noob-friendly, as well as being based on the latest official method recommended by the Fedora docs themselves (see the guide for fedora docs sources).

### Will this overwrite the stock kernel?
No. The original kernel remains installed unless you manually remove it, *which you never should*; it's recommended to always keep a backup. You can select which kernel to boot from the GRUB menu (quickly press ESC repeatedly during boot).

### How do I update to a newer kernel version?
Simply download and install the new kernel package using `dnf`, using the same steps. The old custom kernel will remain installed as a fallback; you can remove it by using `dnf remove` on all the RPM packages, or by using `dnf history undo` on the original transaction. Alternatively, you can do nothing at all: by default, Fedora keeps around three kernels, so when you install a new one, the oldest will be removed.

### Do I need to reinstall after Fedora updates?
Regular Fedora updates won't affect the custom kernel. However, when new kernel versions are released, you may want to install updated versions from this repository for the latest features and security fixes.

### Where does the firmware come from?
See the [Firmware Extraction Guide](docs/firmware_extraction.md) for details on how aw88399_acf.bin was extracted from the Windows driver, and how you can extract it yourself if you wish to do so.

### How do I know this is safe?
- All builds are automated via [this GitHub Actions pipeline](.github/workflows/build_kernel.yml); the RPMs available here were *not* uploaded manually by me.
- Patches are publicly visible in [`patches/`](patches/).
- You can [build the patched kernel yourself](docs/self_compile.md) to verify.

### Secure Boot
This kernel is unsigned, meaning that the OS won't boot with Secure Boot enabled. This means you have these options:
1. Disable Secure Boot in BIOS settings (recommended)
2. Compile and sign the kernel yourself with your own MOK (see the [self-compile guide](docs/self-compile.md)). Please be aware that I did not try this; if you do try and succeed, please open an issue and let me know!
3. Disable Secure Boot, install the patched kernel (either by downloading the precompiled RPMs from this repo, or by compiling the patched kernel yourself using the self-compile guide), sign the kernel from inside the OS using e.g. [sbctl](https://github.com/Foxboron/sbctl), then re-enable Secure Boot. This will require you to temporarily switch Secure Boot to setup mode in the BIOS. Again, please note that I did not test, so I cannot guarantee this will work; if you try, please let me know by opening an issue!

Personally, I recommend option 1 unless you need to dual boot Windows *and* need to run software that refuses to start without secure boot (Windows itself will try to scare you into submission every time you change a bios setting by forcing you to input the bitlocker key, but after that will boot just fine with secure boot disabled). Alternatively, use option 3; option 2 will work for the kernel itself, but in order to use the proprietary NVIDIA drivers (which are loaded in user space), you will need to sign them separately either way, as even an appropriately signed kernel will not boot with the proprietary NVIDIA drivers.

### Fedora Atomic/Immutable Fedora-based distros
I believe it should be possible to install the same patched kernel RPMs on immutable distros as well, using `rpm-ostree` in place of `dnf`. Similarly it's likely that the steps detailed in the [self-compile guide](docs/self-compile.md) will work if performed in a container. As I only tested everything in Fedora 43 KDE I cannot be sure; if you are e.g. a Bazzite user, please try and open an issue if you succeed!

## Credits

This project builds upon the Intel audio driver work by Lyapsus, Nadim Kobeissi and others at [nadimkobeissi/16iax10h-linux-sound-saga](https://github.com/nadimkobeissi/16iax10h-linux-sound-saga). I worked on porting the patch to the AMD model, fixing the broken bass volume controls, the distorted internal mic, the echoing jack, extending parts of the patch, reverse engineering parts of the Windows driver, and automating the process of building the patched kernel using Fedora's tools.

<details>
<summary>Full credits from Nadim Kobeissi's repository</summary>

> Fixing this issue required weeks of intensive work from multiple people.

> Approximately 95% of the engineering work was done by [Lyapsus](https://github.com/Lyapsus). Lyapsus improved an incomplete kernel driver, wrote new kernel codecs and side-codecs, and contributed much more. I want to emphasize his incredible kindness and dedication to solving this issue. He is the primary force behind this fix, and without him, it would never have been possible.

> I ([Nadim Kobeissi](https://nadim.computer)) conducted the initial investigation that identified the missing components needed for audio to work on the 16IAX10H on Linux. Building on what I learned from Lyapsus's work, I helped debug and clean up his kernel code, tested it, and made minor improvements. I also contributed the solution to the volume control issue documented in Step 8, and wrote this guide.

> Gergo K. showed me how to extract the AW88399 firmware from the Windows driver package and install it on Linux, as documented in Step 1.

> [Richard Garber](https://github.com/rgarber11) graciously contributed [the fix](https://github.com/nadimkobeissi/16iax10h-linux-sound-saga/issues/19#issuecomment-3594367397) for making the internal microphone work.

> Sincere thanks to everyone who [pledged](https://github.com/nadimkobeissi/16iax10h-linux-sound-saga/blob/main/PLEDGE.md) a reward for solving this problem.
</details>