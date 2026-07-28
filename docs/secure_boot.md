# Secure Boot setup

This guide explains how to re-enable Secure Boot after installing the patched kernel and NVIDIA drivers. It assumes you have already successfully booted the patched kernel with Secure Boot **disabled**, and that the NVIDIA drivers are working.

*Credits:* this guide combines two independent procedures, each adapted for this specific setup.
- The kernel signing steps in Part 1 are based on the [CachyOS Kernel for Fedora with Secure Boot gist](https://gist.github.com/mikaeldui/bf3cd9b6932ff3a2d49b924def778ebb) by GitHub user mikaeldui, which itself adapts the certificate generation and signing machinery from the [official Fedora kernel build guide](https://docs.fedoraproject.org/en-US/quick-docs/kernel-build-custom/). The key difference is that the official Fedora guide covers signing a kernel during compilation, whereas mikaeldui's guide applies the same approach to sign and replace a pre-existing unsigned kernel image, which is the relevant scenario here.
- The NVIDIA module signing steps in Part 2 are based on the [RPM Fusion Secure Boot guide](https://rpmfusion.org/Howto/Secure%20Boot), the documentation available at `/usr/share/doc/akmods/README.secureboot`, and the contents of `/usr/sbin/kmodgenca`. These guides document the standard akmods-based signing workflow for third-party kernel modules on Fedora. [This guide by Andrei Nevedomskii](https://blog.monosoul.dev/2022/05/17/automatically-sign-nvidia-kernel-module-in-fedora-36/) was also consulted during development and covers the same steps with additional explanation, making it a useful companion read.

---

## Background
Secure Boot works by ensuring that only software signed with a recognized key is loaded during boot. Fedora ships a Microsoft-signed bootloader called `shim`, which acts as an intermediary; in particular, shim contains a feature that allows you to extend Secure Boot's trust to your own keys without modifying the firmware's built-in key database. This means that, for example, Windows installed on a separate drive continues to boot normally; the UEFI key database is untouched, and will still contain the same factory Microsoft keys.

The mechanism for adding your own keys is called **Machine Owner Key** (*MOK*). Once a key is enrolled as a MOK, `shim` will trust binaries signed with it at boot time. The MOK list is also used to decide which kernel modules to allow - which is relevant since the closed source NVIDIA drivers are not part of the Linux kernel, and are instead loaded externally. Thanks to the `mokutil` command, we can easily import certificates in the `shim` database.

> ***Why this approach?*** An alternative method for enabling Secure Boot on Linux is [`sbctl`](https://github.com/Foxboron/sbctl), which manages keys at the firmware level directly. However, that approach requires putting the firmware into Setup Mode; if not done correctly, this method carries the risk of accidentally clearing the factory keys, which may brick Windows installs. Most importantly, `sbctl` bypasses Fedora's own tooling entirely. The MOK approach used here is the method Fedora itself uses and recommends; it layers on top of the existing firmware keys without touching them, meaning Windows and OEM firmware are guaranteed to continue working as before. Furthermore, thanks to Fedora's tools, we can fully automate the signing of the kernel and its external modules during updates, so that the steps in this guide have to be followed only once.

To enable Secure Boot support, two separate signing operations are needed, each with its own key:
1. *Kernel image signing*: this must be done manually once; it can then be automated on each kernel update via a hook script.
2. *NVIDIA kernel modules signing*: this must also be done manually once, then it will be handled automatically by `akmods` on each kernel/driver update.

> ⚠️ If you dual boot Windows, ***before changing any BIOS setting***, go to https://account.microsoft.com/devices/recoverykey and make sure you have your BitLocker recovery key saved and noted down. Windows will ask for it e.g. after disabling Secure Boot, so make sure you're not locked out.

---

# Secure Boot Signing guide

## Part 1: Kernel signing

1. ***Install the required packages***

```bash
sudo dnf install pesign openssl mokutil keyutils
```
Note that these will already be installed if you compiled the patched kernel yourself using my [self-compile guide](/docs/self_compile.md).

2. ***Authorize the current user to sign kernels using `pesign`***

```bash
echo "$USER" | sudo tee -a /etc/pesign/users
sudo /usr/libexec/pesign/pesign-authorize
```

3. ***Generate a signing key/certificate pair***

```bash
openssl req -new -x509 -newkey rsa:2048 \
    -keyout "key.pem" \
    -outform DER -out "cert.der" \
    -nodes -days 36500 \
    -subj "/CN=Legion Secure Boot/"
```

4. ***Import the key into pesign's certificate database***
You will be prompted for a password when running the command below. This password protects the key file during import, but is never really used anywhere relevant, so it doesn't have to be strong (it's ok to use 123456).

```bash
openssl pkcs12 -export -out key.p12 -inkey key.pem -in cert.der
sudo certutil -A -i cert.der -n "Legion Secure Boot" -d /etc/pki/pesign -t "Pu,Pu,Pu"
sudo pk12util -i key.p12 -d /etc/pki/pesign
```

The key material is now stored in `pesign`'s certificate database at `/etc/pki/pesign/`.
The `key.pem`, `cert.der`, and `key.p12` files in your working directory are no longer needed for day-to-day operation; if these files are needed again after being deleted, you may generate new certificates by repeating the same steps. With that said, in order to avoid needing to create brand new certificates to be enrolled after BIOS updates, it's recommended to keep a backup of the `cert.der` file somewhere safe (see the BIOS update guide below).

5. ***Queue the certificate for MOK enrollment***

When running the next command, you will be prompted to choose an enrollment password; remember it, you'll need it soon for the MOKManager step. Since it will only be used once and doesn't really have to be secure, you can again choose 123456.

```bash
sudo mokutil --import "cert.der"
```

6. ***Sign the currently installed patched kernel***

```bash
KERNEL=$(ls -v /boot | grep vmlinuz.*legion | tail -1)
sudo pesign --certificate "Legion Secure Boot" \
    --in "/boot/$KERNEL" \
    --sign \
    --out "/boot/$KERNEL.signed"
sudo mv "/boot/$KERNEL.signed" "/boot/$KERNEL"
```

If you have [compiled your own kernel](/docs/self_compile.md) and chosen a `buildid` other than `legion`, you'll need to adapt the `grep` part above.

7. ***Reboot and enroll the new MOK***

Reboot your system. Shortly after the manufacturer's logo, a blue **MOKManager** screen will appear; press any key within 10 seconds to access the configuration menu.
Using the arrow keys and Enter:

- Select **Enroll MOK**
- Select **Continue**
- Select **Yes**
- Enter the enrollment password you set in step 5
- Select **OK**, then **Reboot**

> ⚠️ The MOKManager screen maps the keyboard as **US QWERTY** regardless of your layout. If you use a different layout, type your password as if you were on a US QWERTY keyboard.

The system will boot back into Fedora. Do **not** enable Secure Boot yet; the NVIDIA key enrollment in Part 2 requires another reboot cycle first.

8. ***Setup automatic signing for future kernel updates***

When a new patched kernel RPM is installed, the new kernel image will arrive unsigned; fortunately, we can setup a hook script that runs after every kernel install that takes care of signing the new kernel with the key already enrolled in the previous step. This means that you won't have to repeat the steps in this guide after every kernel update.

- Create the post install script:

```bash
sudo mkdir -p /etc/kernel/postinst.d
sudo nano /etc/kernel/postinst.d/00-signing
```

- Paste the following content inside the terminal window:

```bash
#!/bin/sh

set -e

KERNEL_IMAGE="$2"
MOK_KEY_NICKNAME="Legion Secure Boot"

if [ "$#" -ne "2" ] ; then
    echo "Wrong count of command line arguments. This is not meant to be called directly." >&2
    exit 1
fi

if [ ! -x "$(command -v pesign)" ] ; then
    echo "pesign not executable. Bailing." >&2
    exit 1
fi

if [ ! -w "$KERNEL_IMAGE" ] ; then
    echo "Kernel image $KERNEL_IMAGE is not writable." >&2
    exit 1
fi

echo "Signing $KERNEL_IMAGE..."

pesign --certificate "$MOK_KEY_NICKNAME" \
    --in "$KERNEL_IMAGE" \
    --sign \
    --out "$KERNEL_IMAGE.signed"
mv "$KERNEL_IMAGE.signed" "$KERNEL_IMAGE"
```

- Save the script with `CTRL+X`, then `y`, then `ENTER`;

- Set the correct ownership and permissions:

```bash
sudo chown root:root /etc/kernel/postinst.d/00-signing
sudo chmod u+rx /etc/kernel/postinst.d/00-signing
```

---

## Part 2: NVIDIA module signing

`akmods` is Fedora's tool for automatically building and signing third-party kernel modules. Once a signing key is in place, akmods will rebuild and re-sign the NVIDIA modules automatically on every driver update; no manual intervention is needed after the initial setup.

This part of the guide assumes you have already installed the official Fedora NVIDIA drivers through the RPM Fusion nonfree package `akmod-nvidia`; if you used the automated install script or the manual install guide with no changes, this is already taken care of. If instead you are relying on open source drivers or proprietary ones from a different repo, you may have to adapt the steps below.

1. ***Install the required packages***

```bash
sudo dnf install kmodtool akmods mokutil openssl akmod-nvidia
```

These packages should already be installed on your system if you followed part 1 of this guide and installed the `akmod-nvidia` package as recommended.

2. ***Generate the akmods signing key***

Like in part 1, we need to create keys and certificates to sign the drivers with. By default, `akmods` automatically generates them using the `kmodgenca` command on its first invocation (e.g. when the NVIDIA driver was first built), so the keys we need will already be present.

To make sure that this is indeed the case (or to create them if they happen to be missing), run:

```bash
sudo kmodgenca -a
```

If `kmodgenca` reports that keys already exist at `/etc/pki/akmods/`, there is no need to force new ones. You can instead skip straight to the next step to use the ones already defined.

3. ***Queue the certificate for MOK enrollment***

```bash
sudo mokutil --import /etc/pki/akmods/certs/public_key.der
```

You will again be prompted to set an enrollment password for this second certificate. As in step 5 of part 1, remember this password for the MOKManager step below.

4. ***Rebuild the kernel modules with the new key***

```bash
sudo akmods --force
```

5. ***Reboot and enroll the key***

Reboot your system. The blue MOKManager screen will appear again, this time for the akmods certificate. Follow the same steps as in Part 1 step 7, using the password you set in step 3 of this part. 
Once again, remember that the keyboard is set to *US QWERTY*.

**Note on certificate expiry:** The akmods signing certificate has a validity of 10 years from the date it was created, whether generated automatically by akmods or manually via `kmodgenca`. You can check the expiry date at any time with:

```bash
openssl x509 -inform DER \
    -in /etc/pki/akmods/certs/public_key.der \
    -noout -dates
```

If the certificate expires, akmods will no longer be able to sign modules for new kernels, and the NVIDIA driver will stop loading after kernel or driver updates. 

To fix this:
- Temporarily disable Secure Boot in the BIOS;
- Regenerate the akmods certificate with `sudo kmodgenca -f`;
- Repeat steps 3, 4, 5 from Part 2 of this guide;
- Re-enable Secure Boot.

The kernel signing certificate from Part 1 is unaffected, as it was generated with a 100-year validity.

**Note on BIOS updates**: [as explained here](https://rpmfusion.org/Howto/Secure%20Boot), if you update the BIOS (e.g. from a Windows partition), you may have to repeat the `sudo mokutil --import` steps from part 1 and 2 and go through the MOKManager enrollment process again.

---

## Part 3: Enable Secure Boot and verify the setup

### Enable Secure Boot

After both reboot cycles are complete and you are back in Fedora, go into your UEFI firmware settings and enable Secure Boot, then save and reboot. The patched kernel and NVIDIA drivers should load normally.

### Verify the setup

If you're able to reach the Fedora login screen after enabling Secure Boot, it means the setup was successful.

Optionally, you can confirm Secure Boot is active with:

```bash
mokutil --sb-state
```

To confirm both certificates are correctly enrolled:

```bash
mokutil --list-enrolled
mokutil --test-key /etc/pki/akmods/certs/public_key.der
```

To inspect the kernel image signatures:

```bash
pesign -S -i /boot/vmlinuz-$(uname -r)
```

You should see the `Legion Secure Boot` certificate from part 1 of this guide.

To confirm the NVIDIA modules are loaded and signed:

```bash
# Check that nvidia modules are loaded
lsmod | grep -i nvidia

# Check the signer of the nvidia module
modinfo nvidia | grep signer
```

The `signer` field will show the name of the akmods key. This will likely be an auto-generated string like `fedora_<...>` rather than a human-readable name; this is normal, and is the name of the key that was automatically created by akmods on its first use.

---

## Re-enrolling MOK certificates after BIOS updates from a Windows partition

If you update the BIOS from a Windows partition/SSD, two things will happen:

1. The Windows SSD will be put at the highest boot priority (this can be changed by pressing F2 during boot);
2. The MOK certificates enrolled in the `shim` database will be wiped.

As a consequence of point 2, the patched kernel will refuse to boot if Secure Boot is active, returning a "bad shim signature" error. To fix this, you need to re-enroll the same certificates; [as explained in the RPM Fusion Secure Boot guide](https://rpmfusion.org/Howto/Secure%20Boot), this is a known consequence of BIOS updates from Windows.

### Part 1: re-enroll the kernel certificate

If you have the same `cert.der` file used to sign the patched kernel in part 1, simply repeat step 5:

```bash
sudo mokutil --import "cert.der"
```

then enter a password, reboot, and enroll the certificate using that password in the MOK manager as done previously.

If you no longer have the same certificate file, you will need to repeat the entire part 1 guide to generate a new one and re-sign the kernel using the new certificate.

### Part 2: re-enroll the akmods certificate

To re-enroll the NVIDIA module key, since part 2 relies on the automatically generated `akmods` certificates, it suffices to repeat step 3:

```bash
sudo mokutil --import /etc/pki/akmods/certs/public_key.der
```

then enter a password, reboot, and enroll the certificate using that password in the MOK manager as done previously.
