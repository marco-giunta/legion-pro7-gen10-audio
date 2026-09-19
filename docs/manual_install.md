# Manual installation guide

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

Before opening an issue, verify that your laptop satisfies the requirements described in the [**"Will this patch work on other laptops?"**](../README.md#will-this-patch-work-on-other-laptops) FAQ. In short, you must ensure that:

- it has two dedicated woofers and a Smart Amplifier (as stated on the PSREF website);
- its ACPI tables contain the `AWDZ8399` entry;
- its Windows Realtek audio driver contains the `AWDZ8399.bin` firmware binary file.

More details in that FAQ entry.

If all checks pass, please open an issue following the instructions from the ["support new laptops" guide](./support_new_laptops.md).

Similarly, if you don't get a matching codec SSID *and* your laptop is a model other than one of the supported ones, perform the same basic diagnostics before opening an issue with the same "support new laptops" guide. If you own a Legion 5i/7i 16IAX10, a Legion Pro 5i 16IAX10H, or a Legion Pro 5 16AFR10/16ADR10, you don't need a patched kernel at all; see the [audio guide for other Legion models](./other_legions_guide.md).

1. **Install the firmware**
- Download the [`aw88399_acf.bin` file](../firmware/aw88399/aw88399_acf.bin); alternatively, you can extract the binary yourself from the Windows driver by following the instructions in [this section of the main README](../README.md#step-3-verify-the-windows-audio-driver-contains-the-aw88399-firmware-binary).
- *Optional but recommended:* Download the [`aw88399_acf.bin.sha256`](../firmware/aw88399/aw88399_acf.bin.sha256) file, put it in the same folder as the downloaded `aw88399_acf.bin`, and check the integrity of the binary:
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

  For the Bluetooth file (and the WiFi files if not already present), [download them from this repo](../firmware/mt7927), then verify and install them:
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
- Head to the [releases section](https://github.com/marco-giunta/legion-pro7-gen10-audio/releases) and download the latest kernel available. Alternatively, you can compile your own patched kernel in RPM format using my [self compile guide](./self_compile.md).
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
