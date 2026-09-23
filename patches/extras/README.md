# Extra patches

This folder contains patches for kernel subsystems other than audio and WiFi/BT that are included in the prebuilt RPMs. They are applied automatically by the GitHub Actions build script after the audio and mt7927 patches.

All patches here were written by me and submitted to the appropriate upstream kernel mailing lists. They are included here because they fix Legion-specific behavior and are pending upstream inclusion or have been accepted but not yet reached the Fedora kernel.


## Smart Connect hotkey (F11) mapping
**Status:** [accepted upstream in `platform-drivers-x86`](https://git.kernel.org/pub/scm/linux/kernel/git/pdx86/platform-drivers-x86.git/commit/?id=bc39af8c2c43b493ae914245a3092128424ceb62)

On the Legion Pro 7 16AFR10H and similar 2025 Lenovo laptops, the F11 key (marked with a laptop/tablet/phone icon) triggers the Lenovo Smart Connect app under Windows. Without this patch, the key is reported as `KEY_UNKNOWN` under Linux; the patch maps it to `KEY_LINK_PHONE`, consistent with how the `thinkpad_acpi` driver handles the equivalent Microsoft Phone Link and Intel Unison keys.

This may already be enough to make it possible to remap this key via your DE's settings, but this is DE dependent (and requires Wayland); for example, KDE's keyboard shortcut settings will still refuse to react to this key. This is due to QT (their upstream project) having yet to add support for certain post-X11 hotkey events.

For KDE specifically, the following method can be used to fix this issue.

Create `~/.config/xkb/symbols/inet` and paste:
```
xkb_symbols "evdev" {
    include "%S/inet(evdev)"
    key <I455> { [ F20 ] };
};
```
where the above will map the `KEY_LINK_PHONE` event to F20; feel free to change this.

After logging out and back in, the Smart Connect key will appear as F20 in KDE's keyboard shortcut settings, allowing you to remap it.

> [!NOTE]
> The F20 key above is chosen as an example because the F13-24 keys don't physically exist on most keyboard, and therefore their codes are useful for programming custom combos, but precisely for this reasons certain DEs/distros may already use them to open certain apps, thus creating conflicts with custom keybinds.
> Under KDE plasma, in order to be able to use such a remapping, go to Settings->Keyboard->Key Bindings (top right corner)->Function keys->Use F13-F24 as usual function keys.

> [!NOTE]
> The above 455 magic number comes from `/usr/share/X11/xkb/keycodes/evdev`:
> ```
> 	<I455> = 455;		// #define KEY_LINK_PHONE          447
>```
> In general, it will be the corresponding scancode +8 for historical X11-related reasons.
> The actual kernel-level codes [are defined here](https://github.com/torvalds/linux/blob/master/include/uapi/linux/input-event-codes.h)

> [!NOTE]
> You can use the same method to remap the Smart Connect key even without this patch installed, by using the `<I248>` code to remap the `KEY_UNKNOWN` event itself:
> ```
> key <I248> { [ F20 ] };
> ```
> However, without the patch, toggling the camera privacy switch will also emit a `KEY_UNKNOWN` event (see below), therefore causing the privacy camera switch to trigger the same key combo as the Smart Connnect key.

> [!TIP]
> In order to be able to remap the Copilot key under KDE Plasma, in the same file as above in a newline under `include "%S/inet(evdev)"`, add this: `key <FK23>   {      [ XF86TouchpadOff, F23 ], type[Group1] = "PC_SHIFT_SUPER_LEVEL2" };`.
> Alternatively, a Copilot-remap-only configuration looks like this:
> ```
> partial alphanumeric_keys
> xkb_symbols "evdev" {
>     include "%S/inet(evdev)"
>     key <FK23>   {      [ XF86TouchpadOff, F23 ], type[Group1] = "PC_SHIFT_SUPER_LEVEL2" };
> };
> ```
> Credit for this trick: [user g_squared in the KDE discuss forums](https://discuss.kde.org/t/how-to-get-system-settings-to-recognize-the-f23-part-of-copilot-key-combo/38701/21).
> Note that this will cause KDE's keyboard shortcut settings to interpret the Copilot key as Meta+Shift+F23, meaning that you *need* to enable "Use F13-F24 as usual function keys" as explained above for this to work at all.


## Camera switch reporting
**Status:** [submitted upstream, v3 soon to be sent in collaboration with a lenovo driver maintainer](https://lore.kernel.org/platform-driver-x86/SN6PR19MB23039910DD1918BEE3825BAFFC862@SN6PR19MB2303.namprd19.prod.outlook.com/T/#u)

On the Legion Pro 7 16AFR10H and similar 2025 Lenovo laptops, a physical switch on the side disables the camera at the firmware level. Without this patch the corresponding WMI events are reported as `KEY_UNKNOWN`; the patch reports them as `SW_CAMERA_LENS_COVER`, consistent with how `lenovo-wmi-camera` handles the equivalent switch on other Lenovo laptops.

Your DE may be able to take advantage of this information e.g. to display a popup notification whenever the camera gets disabled with this switch (but for example KDE Plasma currently doesn't react to this information). In general, the user won't necessarily benefit directly from this patch, it's mostly to map an otherwise undefined behavior into the correct one.

The main benefit to this patch is that, if you're using the `<I248>` trick above to workaround keys that are currently emitting `KEY_UNKNOWN`, the privacy switch won't cause spurious activation of the same custom keybind.
