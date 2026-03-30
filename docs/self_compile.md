# Patched Kernel RPM Self Compile Guide
This guide will show you how to compile the patched kernel as a set of RPMs on systems running Fedora Linux using `fedpkg`. There are many benefits to this:
- being able to (un)install the patched kernel using `dnf`;
- circumventing the need to manually choose kernel config options;
- avoiding to have to manually setup `dracut`, grub config or NVIDIA drivers.

This guide is based on [these official Fedora docs instructions](https://docs.fedoraproject.org/en-US/quick-docs/kernel-build-custom/); I simply added some more context and tailored them to the Legion audio patch. Please refer to that document if needed.

## Step 1: Obtain the kernel source
First compare the latest available patch with the latest stable kernel for your Fedora install by checking [this page](https://packages.fedoraproject.org/pkgs/kernel/kernel/). If they match, download the latest kernel using `fedpkg` (option A); if they don't, or if you need a different kernel version, use `koji` instead (option B).

### A) Download the latest stable kernel with `fedpkg`
- Install `fedpkg`:
```bash
sudo dnf install fedpkg
```

- Download the build dependencies:
```bash
fedpkg clone -a kernel
```
This will create a folder called `kernel` with the files needed to build the RPMs.

- Navigate to the `kernel` folder, then switch to the branch corresponding to your Fedora install. For example, for Fedora 43, type:
```bash
fedpkg switch-branch f43
```
In spite of what the original guide says, do *not* use `git switch`, as that can cause some mismatches between files.

### B) Download a specific version with `koji`
- Install `koji`:
```bash
sudo dnf install koji
```
- List available kernels for a certain Fedora version:
```bash
koji list-builds --package=kernel --state=COMPLETE | grep fc<VERSION>
```
For example, for Fedora 43 type:
```bash
koji list-builds --package=kernel --state=COMPLETE | grep fc43
```
Take note of the complete package name of the kernel version you want to download, which will look like `kernel-<kernel_version>.fc<fedora_version>`, then download it with `koji`. For example, to obtain `kernel-6.17.12-300.fc43`, type:
```bash
koji download-build --arch=src kernel-6.17.12-300.fc43
```
This will download a file called `kernel-6.17.12-300.fc43.src.rpm`.

- Extract that file by opening it as a compressed archive using e.g. KDE's Ark or similar, then copy all the files to a new folder called `kernel`. Alternatively, you can use
```bash
rpm -ivh kernel-<...>.src.rpm
```
This will create a folder called `rpmbuild` in your home folder. Create a new folder called `kernel`, and copy the contents of both `rpmbuild/SOURCES` and `rpmbuild/SPECS` to the `kernel` folder.

## Step 2: Install the dependencies
Before proceeding, ensure the `kernel` folder from the previous step is in your `/home/<user>` folder, as otherwise the build process using `fedpkg` may throw some errors about not being able to find the required files.
### Kernel build dependencies
Navigate to the `kernel` folder, then type:
```bash
sudo dnf builddep kernel.spec
```
This will install a large number of packages. If you wish to remove these in the future, you can type `dnf history list`, locate the above `dnf builddep` transaction, take note of the number on its left, then do `sudo dnf history undo xy` (where `xy` is the relevant number from `dnf history list`).

### NVIDIA driver
- Enable the free and nonfree RPMFusion repositories if you haven't already (see details [here](rpmfusion.org/Configuration)):
```bash
sudo dnf install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
```
- Install the `akmod-nvidia` package if you haven't already:
```bash
sudo dnf install akmod-nvidia
```
This package will automatically build the NVIDIA driver kernel module for the patched kernel.

## Step 3: Configure the build process
### Copying the patch
Inside the `kernel` folder, locate and open the file called `linux-kernel-test.patch`; copy paste here the contents of the relevant `.patch` file downloaded from this repo, based on the kernel version you downloaded using `fedpkg`/`koji`. If you own the AMD model and wish to include [jetm's mt7927 patch](https://github.com/jetm/mediatek-mt7927-dkms) to enable Wi-Fi and Bluetooth, also paste the mediatek patch after the audio one in the same `linux-kernel-test.patch` file.

### Setting up kernel config parameters
Inside the `kernel` folder, locate and open the file called `kernel-local`; copy paste there the following lines (you can safely ignore the comment lines starting with `#` at the top of the file):
```
CONFIG_SND_HDA_SCODEC_AW88399=m
CONFIG_SND_HDA_SCODEC_AW88399_I2C=m
```
Please note that you do *not* have to add either `CONFIG_SND_SOC_AW88399=m` or any of the Intel/AMD specific parameters from the original guide, as these are *already included by default by Fedora*. Feel free to inspect `kernel/kernel-x86_64-fedora.config`; you'll see e.g. that `CONFIG_SND_SOC_AW88399=m` is already there. Indeed, the above 2 lines are simply the two new config parameters added by Lyapsus; `fedpkg` will take the contents of `kernel-local` and add it to the preexisting default Fedora configs.

### Defining the `buildid`
Before starting the build process, it's important to choose a meaningful custom build id for the patched kernel; this string will be used to name the RPM packages, how they show up in `dnf`, and how the patched kernel is named in the grub boot menu. Despite this feature being disabled by default, I recommend using it, as it will allow you to easily tell the patched kernel from the stock one, allowing both of them to coexist without issues - which is a good idea, so you can keep around the default Fedora kernel for backup.

Inside the `kernel` folder, locate and open the file called `kernel.spec`. Locate the following line:
```
# define buildid .local
```
and replace it with:
```
%define buildid .<your_custom_id_here>
```
For example, to name the custom kernel `legion`, use:
```
%define buildid .legion
```
Mind the dot before the name you choose, and be sure to use a single word (no spaces).


## Step 4: Compile the kernel
To build the kernel, navigate to the `kernel` folder, then type:
```bash
fedpkg local --without debug
```
I recommend using the `--without debug` option above because otherwise fedpkg will build both the standard kernel and the debug one, which has extra tools not needed unless you're doing kernel development. Furthermore, building the debug kernel alongside the one we actually need will double the build time; finally, given Fedora's default partition settings, you're likely not going to have enough space in your boot partition to install the debug kernel either way.

If you plan on recompiling the kernel multiple times, I recommend installing the `ccache` package (`sudo dnf install ccache`), and instead running
```bash
fedpkg local --without debug --with ccache
```
The first time you build the kernel this will cache a few gigabytes in `~/.cache/ccache`; further recompilations will then be sped up by recycling what hasn't changed from the last time.

By using these parameters, you can cut the compilation time from ~50-60 minutes to ~20-30 minutes (during which all your CPU cores will be used).

## Step 5: Install the patched kernel
Once the build process finished with no errors, you will see a new `x86_64` folder inside the `kernel` folder, full of a large number of RPMs. Do *not* install them all; we don't need most of them, and a blanket install will likely fail either way because of insufficient space in your boot partition. 
Instead, navigate to the `kernel` directory, then use:
```bash
sudo dnf install --nogpgcheck ./x86_64/kernel-6*.rpm ./x86_64/kernel-core-*.rpm ./x86_64/kernel-modules-*.rpm ./x86_64/kernel-devel-*.rpm
```
If you recompiled a the same kernel version with the same buildid and want to force a reinstall, you can instead use:
```bash
sudo rpm -ivh --force ./x86_64/kernel-6*.rpm ./x86_64/kernel-core-*.rpm ./x86_64/kernel-modules-*.rpm ./x86_64/kernel-devel-*.rpm
```

*Why only these packages are necessary:*
- The `kernel-core-*.rpm` is the base kernel, needed for obvious reasons.
- The `kernel-modules-*.rpm` files are needed because the core kernel doesn't contain the drivers that are built as separate modules; without these RPMs, fairly basic things like brightness up/down will be broken.
- The `kernel-devel-*.rpm` files are needed by `akmod-nvidia` to build the NVIDIA driver for the kernel.
- The `kernel-*.rpm` is mostly small dnf metadata. It's technically optional, but it's best to include it because dnf expects it to be there.

All the other RPMs are needed for debugging and profiling purposes, which we don't need to just fix the Legion's audio.

## Step 6: Build the NVIDIA driver
After installing the kernel via dnf, `akmod-nvidia` will automatically start building the NVIDIA driver. To check on it, use `sudo akmods --force`; once an "OK" appears next to the patched kernel's name, you can reboot safely. If you reboot before this process is finished, you may be stuck on a black screen after the grub boot menu; to fix this, you can either use the `nomodeset` boot parameter to temporarily disable the NVIDIA driver, or boot an older kernel and force `akmods` using the previous command. However, building/checking the driver on the Legion should only take a few seconds, so if you encounter these issues something else has probably gone wrong.

This is it! The beauty of this approach is that `fedpkg` easily automates the process of choosing and setting up custom config parameters and building the kernel, `dnf` takes care of setting up dracut and the grub entries, and `akmod-nvidia` automatically builds the NVIDIA driver.

I strongly recommend using this approach over the more general one described in the original repo. Also, online you may find different Fedora-specific guides (e.g. using `rpmbuild`, or variations of the steps here); I suggest sticking to `fedpkg` as described here, as it's probably the easiest, most high-level way of building the kernel.
