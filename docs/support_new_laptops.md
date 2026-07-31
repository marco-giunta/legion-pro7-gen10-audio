# How to open an issue to add support for new IDs

If your laptop passes the three checks described in the README, open an issue using the steps below.

I can then try adding support for your machine by including its codec ID, but I make no promises it will work.

---

## Required basic information

Your issue *must* include the following basic information:

- The results of the 3 checks from the "How to tell whether this patch applies to your laptop" section of the main readme;

- Whether the `AWDZ8399.bin` binary you found has a matching checksum with the one contained in this repo, and where you downloaded the `.exe` file from;

- Your laptop manufacturer and model, which you can confirm by running:

```bash
cat /sys/class/dmi/id/sys_vendor
cat /sys/class/dmi/id/product_family
cat /sys/class/dmi/id/product_name
```

- Your subsystem ID, which you can find by running:

```bash
grep -l "Codec: Realtek" /proc/asound/card*/codec#* | xargs grep -i "Subsystem Id"
```

- The Linux audio codec dump, obtained by copying the *full* output of this command:

```bash
cat $(grep -l "Codec: Realtek" /proc/asound/card*/codec#*)
```

- Which Linux distro you're running;

- Which Linux kernel you're running:

```bash
uname -r
```

- The *full* output of the last of these commands (this requires the `iasl` package):
```sh
sudo cp /sys/firmware/acpi/tables/DSDT /tmp/dsdt.dat
sudo iasl -d /tmp/dsdt.dat
grep -B5 -A85 'Name (_HID, "AWDZ8399")' /tmp/dsdt.dsl
```

- Whether you already separately patched the kernel with the patch files from this repo.

---

## Microphone calibration test
On the currently supported Legion Pro 7/7i models, the internal microphone requires calibration fixes to prevent distorted recordings at higher volume levels. To check whether your model behaves the same way, follow the steps below.

- Inspect the output of the `cat $(grep -l "Codec: Realtek" /proc/asound/card*/codec#*)` command you collected in the previous section. In there, look for a row containing the string `name="Internal Mic Boost Volume"`, and take note of the value of the corresponding `Node`. For example, on the supported Legion Pro 7/7i models, the corresponding one is `Node 0x12`. If you do not find this node, look instead for `name="Mic Boost Volume"`, clearly stating this fact.

- Unplug all external audio devices (microphones, headphones, etc.).

- Open a terminal and run:

```bash
# Replace 0x12 with the node value you found above
watch -n 0.2 'cat $(grep -l "Codec: Realtek" /proc/asound/card*/codec#*) | grep -A5 "Node 0x12" | grep "Amp-In vals"'
```

- This `watch <...>` command will continuously display a line like `Amp-In vals: 0x00 0x00`. While this is running, slowly raise the internal microphone volume slider in your OS sound settings from 0% to 100%; the numbers shown should react to volume changes. Take note of the OS volume percentage at which the value changes - first from `0x00` to `0x01`, then from `0x01` to `0x02`, and finally from `0x02` to `0x03`. Note that further levels (>0x03) may be present.
For example, on the supported Legion Pro 7/7i models, on the *unpatched* kernel this variable equals 0x00 in the [0%, 46%] range, 0x01 in [47%, 68%], 0x02 in [69%, 99%], and 0x03 at 100%.

- You can then leave this screen with `CTRL+C`, or simply by closing the terminal window.

- Record a short clip of yourself speaking *at each boost level* and check whether it sounds normal or distorted:

```bash
arecord -d 5 -f cd -t wav /tmp/mic_test.wav && aplay /tmp/mic_test.wav
```

- If you were not able to identify a "mic boost volume" node whose `Amp-In Vals` respond to you moving the OS mic slider, simply perform this recording quality test in 1/4 increments: 25%, 50%, 75%, and 100% mic levels.

Notice that, instead of the `arecord` and `aplay` terminal commands, you can also use a recorder app, but please only use *simple* ones like the GNOME recorder or KRecord; live monitoring apps like Audacity or Reaper may invalidate the test's results because they can trigger the [screaming speakers issue](../README.md#screaming-speakers-issue), a hardware limitation present on some models for which a software fix is currently unavailable.

In your issue, report:
- The OS volume percentages at which each boost level transition occurs
- Which levels (if any) produce distorted recordings

---

## Windows codec dump (optional but helpful)
If you have access to Windows on your machine (e.g. on a separate drive), please consider including the text file obtained using the following steps.

0. Ensure that you are using the factory Windows 11 install, or more generally that you have the official manufacturer audio driver for your model installed on your machine.
1. Download the `RtHDDump_V236.zip` file from [this repo](https://github.com/ChimeraOS/reverse-engineering-tools) and extract it.
2. Make sure all external audio devices (headphones, microphones, etc.) are unplugged; then, ensure that both the speakers and microphone sliders are set to 100% in the Windows settings.
3. Run the `.exe` from the extracted folder. If Windows shows popups warning about memory access (this is a known cosmetic issue with this tool on Windows 11, not an actual security threat), know that it's safe to simply close them.
4. Wait for a few seconds, until a new window pops up informing you that the codec dump was completed. You can then close the tool and grab the newly created `.txt` file you'll find with the same name as the `.exe` and in the same folder. Attach this file to your issue.

---

## Testing the updated patch
Once I receive the above information, I will add the IDs of your laptop and provide you with an extended patch to try. If you're a Fedora user and need help with kernel compilation, I can compile the new RPMs for you - in which case, kindly ask for this in your first post in the issue, specifying which Fedora version you're running.

Once you're running the patched kernel, you must perform the following diagnostics:

1. Check that audio works as expected;
2. Check that the speakers' left/right channels are correctly set and not swapped;
3. Copy the output of these commands:
```bash
sudo dmesg | grep -i aw88399
sudo dmesg | grep -i AWDZ8399
sudo dmesg | grep -i alc269
# run the following 2 commands while some music is playing on the speakers
sudo cat /sys/kernel/debug/regmap/i2c-AWDZ8399:00-aw88399-hda.0/registers
sudo cat /sys/kernel/debug/regmap/i2c-AWDZ8399:00-aw88399-hda.1/registers
```

Then upload this information in your reply in the issue.
