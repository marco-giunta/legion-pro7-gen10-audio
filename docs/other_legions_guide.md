# Audio guide for other Legion Gen 10 models

If you own a Legion model not listed in the main supported models section, you likely do not need a custom kernel to fix audio. The patched kernel in this repo specifically targets models with an AW88399 smart amplifier driving dedicated woofers; if your laptop doesn't have that hardware, installing the patch won't improve anything.

In particular, these models from the Gen 10 family are confirmed to lack smart amp chips (based on hardware investigation and/or official Lenovo specsheets):

- Legion Pro 5i 16IAX10H
- Legion 5i/7i 16IAX10
- Legion Pro 5 16AFR10

*Note on the 7i*: the Legion 7i Gen 10 (16IAX10, DMI 83KY, codec SSID 17aa:392c) is a partial exception to the above. It does have a smart amplifier (Cirrus CS35L56), but unlike the AW88399 its driver and firmware are already upstream. If audio is broken on this model, outdated firmware packages are the most likely cause rather than a missing driver. If audio is broken, rather than simply quiet/lacking bass, see e.g. [this thread](https://forums.linuxmint.com/viewtopic.php?t=455596) to diagnose further.

## Improving speaker quality with easyeffects

The stock Linux audio for these laptops can sound thin compared to Windows, but this is because the Windows driver applies Nahimic DSP processing by default; it's not because Linux needs a patched kernel driver.

To fix this, install easyeffects and import these presets:
- The [loudness boost from this repo](easyeffects/loudness.json);
- The [profiles from JackHack96's repo](https://github.com/JackHack96/EasyEffects-Presets/);
- The [thinkpad unsuck profile from sebastian-de's repo](https://github.com/sebastian-de/easyeffects-thinkpad-unsuck).

Try them all, and customize them if needed. Good starting points should be my loudness profile and the "bass enhancing + perfect EQ + low latency" preset from JackHack96.
With this method, you should be able to match the sound quality from Windows.

## Distorted microphone at high volume

Some models in this family (confirmed on the Legion Pro 5i 16IAX10H; may apply to others) produce distorted microphone recordings at higher boost levels. If you experience this, the easiest fix is to keep the microphone volume below 47% in your OS sound settings (the specific number may change depending on the model; you can try the microphone test in the ["support new laptops" guide](docs/support_new_laptops.md) to find out exactly what applies to your hardware).

If you prefer to implement the proper fix, which will allow you to set the microphone to 100% with no distortion, you can apply the upstream mic boost limit without a custom kernel with one of two methods.

1. Find the card number of the realtek codec:
```bash
grep -l "Codec: Realtek" /proc/asound/card*/codec#*
```
This is important because your device will have at least 2 audio cards (one for audio through the HDMI, one for the laptop's speakers/mic/jack/etc.). You can see all the audio cards using `cat /proc/asound/cards` and then inspect the corresponding `codec#0` file to figure out which one is the realtek codec, or just use the command above.

Typically, Lenovo laptops have card 0 = HDMI and card 1 = realtek codec. For example, on the AMD Pro 7 Gen 10 the above command outputs:
```
/proc/asound/card1/codec#0
```

2. Enable the limit mic boost quirk. Note that in the commands below, anytime you see `model=,limit-mic-boost`, the number of commas after the equal sign must match the card number (0 commas for card 0, 1 comma for card 1, etc.).

There are 2 ways to do this:

- By adding this boot parameter to grub:
```
snd_hda_intel.model=,limit-mic-boost
```
You can do this temporarily by quickly and repeatedly pressing ESC during boot, pressing `e`, finding the line that starts with `linux`, and adding the above at the end (remember that the keyboard will be set to US QWERTY). If this works for the current boot, you can make this permanent e.g. by using `grubby` (or whatever method your distro uses):
```bash
sudo grubby --update-kernel=ALL --args=snd_hda_intel.model=,limit-mic-boost
```

- Alternatively, by creating `/etc/modprobe.d/alsa-model.conf` and copy paste:
```
options snd-hda-intel model=,limit-mic-boost
```
Then rebooting.

Either option applies the `ALC269_FIXUP_LIMIT_INT_MIC_BOOST` quirk, which limits the microphone boost to usable levels. This fix has been confirmed on the Legion Pro 5i 16IAX10H (as well as all Pro 7 variants with the aw88399) and may work on related models, but is untested on others; your mileage may vary.

## Checking if your model has the AW88399 smart amp

If you're curious whether your model could benefit from the full patch, run:
```bash
sudo strings /sys/firmware/acpi/tables/DSDT | grep AWDZ8399
```
If this returns output, your laptop has the same smart amp hardware as the supported Pro 7 models. In that case, see the FAQ entry "Will this patch work on other laptops?" and consider opening an issue.


## Credits
The section above on overriding audio quirks has been adapted from [this guide by github user mike-echo-oscar-whiskey](https://gist.github.com/mike-echo-oscar-whiskey/f24410d0fb81740ecf8def54c6f03949).
