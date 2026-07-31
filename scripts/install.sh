#!/usr/bin/env bash
# =============================================================================
# install.sh - Legion Pro 7/7i Gen 10 patched kernel installer
#
# What this script does:
#   1. Installs (i.e. copies) the needed firmware files in /lib/firmware
#      (aw88399 audio firmware on models that use the AW88399 smart amp;
#      mt7927 Wi-Fi+BT firmware on AMD Pro 7 models only)
#   2. Sets up the akmod-nvidia driver builder (via RPM Fusion)
#   3. Downloads the latest release tarball from GitHub, verifies its sha256,
#      then installs the patched kernel RPMs with dnf
#   4. Triggers the NVIDIA driver module build via akmods
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/marco-giunta/legion-pro7-gen10-audio/legion_audio/scripts/install.sh | sudo sh
#   Alternatively, download the script and use:
#   sudo sh install.sh
# =============================================================================

set -euo pipefail

# Colors & github

RED='\033[0;31m'; YELLOW='\033[1;33m'; GREEN='\033[0;32m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

info()    { echo -e "${CYAN}${BOLD}[INFO]${RESET}  $*"; }
ok()      { echo -e "${GREEN}${BOLD}[ OK ]${RESET}  $*"; }
warn()    { echo -e "${YELLOW}${BOLD}[WARN]${RESET}  $*"; }
die()     { echo -e "${RED}${BOLD}[ERR ]${RESET}  $*" >&2; exit 1; }
heading() { echo -e "\n${BOLD}===  $*  ===${RESET}"; }

GITHUB_REPO="marco-giunta/legion-pro7-gen10-audio"
GITHUB_API="https://api.github.com/repos/${GITHUB_REPO}/releases"
RAW_BASE="https://raw.githubusercontent.com/${GITHUB_REPO}/legion_audio"

# Firmware paths
AW_FW_DEST="/lib/firmware/aw88399_acf.bin"
AW_FW_SRC_URL="${RAW_BASE}/firmware/aw88399/aw88399_acf.bin"
AW_FW_SHA_URL="${RAW_BASE}/firmware/aw88399/aw88399_acf.bin.sha256"

MT_FW_DIR_WIFI="/lib/firmware/mediatek/mt7927"
MT_FW_DIR_BT="/lib/firmware/mediatek/mt7927"
MT_FW_FILES=(
    "WIFI_MT6639_PATCH_MCU_2_1_hdr.bin:${MT_FW_DIR_WIFI}"
    "WIFI_RAM_CODE_MT6639_2_1.bin:${MT_FW_DIR_WIFI}"
    "BT_RAM_CODE_MT6639_2_1_hdr.bin:${MT_FW_DIR_BT}"
)
MT_FW_BASE_URL="${RAW_BASE}/firmware/mt7927"

# Helpers
# mt7927 detection for the AMD model (BT USB ID 0489:e0fa)
is_amd_model() {
    lsusb 2>/dev/null | grep -q "0489:e0fa"
}

# Check if the AW88399 smart amp is referenced in the ACPI table
has_aw88399_acpi() {
    sudo strings /sys/firmware/acpi/tables/DSDT 2>/dev/null | grep -q "AWDZ8399"
}

# Prerequisites helpers
SUPPORTED_SSIDS=("17aa3906" "17aa3907" "17aa3927" "17aa3928" "17aa3938" "17aa3939")

# Detected SSID, set by require_supported_device and reused later
DEVICE_SSID=""

require_supported_device() {
    # Check manufacturer
    [[ "$(cat /sys/class/dmi/id/sys_vendor 2>/dev/null)" == "LENOVO" ]] \
        || die "This script is only for Lenovo laptops!"

    # Find Realtek codec SSID
    codec=$(grep -l "Codec: Realtek" /proc/asound/card*/codec#* 2>/dev/null | head -1)
    [[ -z "${codec}" ]] && die "No Realtek audio codec found; unsupported device, automated install aborted."

    DEVICE_SSID=$(grep -i "Subsystem Id" "${codec}" | grep -oP '0x\K[0-9a-f]+')

    for supported in "${SUPPORTED_SSIDS[@]}"; do
        if [[ "${DEVICE_SSID}" == "${supported}" ]]; then
            ok "Supported device detected (Subsystem ID: 0x${DEVICE_SSID})"
            return 0
        fi
    done

    # SSID not in supported list -> gather diagnostics before dying
    product_family=$(cat /sys/class/dmi/id/product_family 2>/dev/null)
    warn "Detected device  : ${product_family}"
    warn "Detected SSID    : 0x${DEVICE_SSID}"
    warn ""
    if has_aw88399_acpi; then
        warn "Your device references the AW88399 smart amp in its ACPI table,"
        warn "which means it likely has the same audio hardware as the supported"
        warn "Legion Pro 7/7i models, but with an SSID not yet in the patch."
        warn "Please follow the instructions from the README of"
        warn "https://github.com/${GITHUB_REPO}"
        warn "to confirm your laptop does have the AW88399 smart amp;"
        warn "if all the checks are passed, please open an issue in the same repo"
        warn "using the instructions from the 'support new laptops' guide."
    else
        warn "Your device does not use the AW88399 smart amp."
        warn "If your laptop's woofers don't work on Linux, it may be tempting to try"
        warn "this patch, but broken woofers can have many causes, and this patch"
        warn "only fixes one specific hardware configuration."
        warn ""
        warn "Having said that, you may not need a patched kernel at all to fix audio."
        warn "To troubleshoot, see the 'Other Legions guide' in the docs folder of"
        warn "https://github.com/${GITHUB_REPO}"
    fi
    die "Unsupported device -> automated install aborted."
}

is_fedora_derivative() {
    [[ "$(lsb_release -si)" != "Fedora" ]]
}

require_fedora() {
    # Check for RPM-based system as minimum requirement
    command -v dnf &>/dev/null || die "This script requires a dnf-based Linux system (Fedora and derivatives)!"
    if is_fedora_derivative; then
        warn "This distro does not appear to be vanilla Fedora."
        warn "The script will proceed but the NVIDIA driver installation step will be skipped."
        warn "Please ensure your NVIDIA drivers support the patched kernel manually."
    fi
}

require_root() {
    [[ "${EUID}" -eq 0 ]] || die "This script must be run with sudo!"
}

require_cmd() {
    command -v "$1" &>/dev/null || die "'$1' is not installed. Please install it and re-run."
}

# File managing helpers
download() {
    # download <url> <dest_dir>
    local filename
    filename=$(basename "$1")
    curl -fL --progress-bar "$1" -o "$2/$filename"
}

cleanup() {
    if [[ ${#CLEANUP_FILES[@]} -gt 0 ]]; then
        info "Cleaning up temporary files..."
        rm -f "${CLEANUP_FILES[@]}" 2>/dev/null || true
    fi
    rm -rf /tmp/legion-rpms 2>/dev/null || true
}
CLEANUP_FILES=()
trap cleanup EXIT

# ─────────────────────────────────────────────────────────────────────────── #
heading "Legion Pro 7/7i Gen 10 - patched kernel installer"
echo    "Repository : ${GITHUB_REPO}"
echo

require_supported_device
require_cmd lsb_release
require_fedora
require_root
require_cmd curl
require_cmd lsusb

# Step 1: Install firmware
heading "Step 1: Install the firmware"

if [[ -f "${AW_FW_DEST}" ]]; then
    ok "aw88399 firmware already present at ${AW_FW_DEST} - skipping."
else
    info "Downloading aw88399 audio firmware..."
    download "${AW_FW_SRC_URL}" /tmp
    download "${AW_FW_SHA_URL}" /tmp
    CLEANUP_FILES+=("/tmp/aw88399_acf.bin" "/tmp/aw88399_acf.bin.sha256")

    info "Verifying sha256 checksum..."
    ( cd /tmp && sha256sum -c aw88399_acf.bin.sha256 ) || die "aw88399 firmware checksum mismatch."

    info "Installing the aw88399_acf.bin firmware..."
    sudo cp -f /tmp/aw88399_acf.bin "${AW_FW_DEST}"
    ok "aw88399 firmware installed to ${AW_FW_DEST}"
fi

# mt7927 Wi-Fi + BT firmware (AMD model only)
if is_amd_model; then
    info "MT7927 WiFi/BT card detected (BT USB ID 0489:e0fa) - installing mt7927 firmware..."

    for entry in "${MT_FW_FILES[@]}"; do
        FNAME="${entry%%:*}"
        DEST_DIR="${entry##*:}"
        DEST="${DEST_DIR}/${FNAME}"

        if [[ -f "${DEST}.xz" ]]; then
            # Official compressed firmware is present - prefer it
            if [[ -f "${DEST}" ]]; then
                info "Switching ${FNAME} to official firmware package - removing previously installed copy..."
                sudo rm -f "${DEST}"
                ok "Removed ${DEST} (official compressed version available at ${DEST}.xz)"
            else
                ok "${FNAME}: official firmware already present as ${FNAME}.xz - skipping."
            fi
            continue
        fi

        if [[ -f "${DEST}" ]]; then
            ok "${FNAME} already present - skipping."
            continue
        fi

        info "Downloading ${FNAME}..."
        download "${MT_FW_BASE_URL}/${FNAME}" /tmp
        download "${MT_FW_BASE_URL}/${FNAME}.sha256" /tmp
        CLEANUP_FILES+=("/tmp/${FNAME}" "/tmp/${FNAME}.sha256")

        info "Verifying ${FNAME} sha256 checksum..."
        ( cd /tmp && sha256sum -c "${FNAME}.sha256" ) || die "${FNAME} firmware checksum mismatch."

        info "Installing the ${FNAME} firmware..."
        sudo mkdir -p "${DEST_DIR}"
        sudo cp -f "/tmp/${FNAME}" "${DEST}"
        ok "${FNAME} firmware installed to ${DEST}"
    done
else
    info "MT7927 WiFi/BT card not detected (BT USB ID 0489:e0fa not found) - skipping mt7927 firmware install."
fi

# Step 2: akmod-nvidia
heading "Step 2: Install the NVIDIA driver builder (akmod-nvidia)"

if is_fedora_derivative; then
    warn "Skipping akmod-nvidia install on non-vanilla Fedora."
    warn "Your distro likely manages NVIDIA drivers separately."
    warn "After rebooting into the patched kernel, verify your NVIDIA drivers"
    warn "still work and rebuild them if needed."
elif rpm -q akmod-nvidia &>/dev/null; then
    ok "akmod-nvidia is already installed - skipping."
else
    info "Enabling RPM Fusion free + nonfree repositories..."
    sudo dnf install -y https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
    sudo dnf install -y https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

    info "Installing akmod-nvidia..."
    sudo dnf install -y akmod-nvidia
    ok "akmod-nvidia installed."
fi

# Step 3: Download & install the patched kernel RPMs
heading "Step 3: Download and install the patched kernel RPMs"
FEDORA_VER=$(rpm -E '%fedora')
info "Fetching latest release metadata from GitHub for Fedora ${FEDORA_VER}..."
TARBALL_URL=$(curl -fsSL "${GITHUB_API}" \
    | grep -oP '"browser_download_url": *"\K[^"]+\.tar\.gz(?=")' \
    | grep "fc${FEDORA_VER}" \
    | grep -v '\.sha256' \
    | head -1)
SHA_URL="${TARBALL_URL}.sha256"

[[ -n "${TARBALL_URL}" ]] || die "No release found for Fedora ${FEDORA_VER}. Check the releases page at https://github.com/${GITHUB_REPO}/releases"

TARBALL_NAME=$(basename "${TARBALL_URL}")
info "Latest release: ${TARBALL_NAME}"

echo "Downloading RPM tarball..."
download "${TARBALL_URL}" /tmp
echo "Downloading sha256 checksum..."
download "${SHA_URL}"     /tmp
CLEANUP_FILES+=("/tmp/${TARBALL_NAME}" "/tmp/${TARBALL_NAME}.sha256")

info "Verifying sha256 checksum..."
( cd /tmp && sha256sum -c "${TARBALL_NAME}.sha256" ) \
    || die "Tarball checksum mismatch - aborting install."
ok "Checksum verified."

info "Extracting RPMs..."
mkdir -p /tmp/legion-rpms
tar xzf "/tmp/${TARBALL_NAME}" -C /tmp/legion-rpms

info "Installing patched kernel RPMs..."
sudo dnf install --nogpgcheck -y \
    /tmp/legion-rpms/kernel-[0-9]*.rpm    \
    /tmp/legion-rpms/kernel-core-*.rpm    \
    /tmp/legion-rpms/kernel-modules-*.rpm \
    /tmp/legion-rpms/kernel-devel-*.rpm
ok "Kernel RPMs installed."

# Step 4: Build the NVIDIA driver module
heading "Step 4: Build the NVIDIA driver module"

if is_fedora_derivative; then
    warn "Skipping akmods build on non-vanilla Fedora."
    warn "Please ensure your NVIDIA drivers are rebuilt for the patched kernel"
    warn "using whatever method your distro provides before rebooting."
else
    info "Triggering akmods build for the new kernel..."
    sudo akmods --force || warn "akmods --force exited non-zero; the build may still be in progress."
fi

heading "Installation complete"
echo
echo -e "  ${GREEN}${BOLD}All done!${RESET} The patched kernel has been installed."
echo
echo -e "  ${BOLD}Next steps:${RESET}"
echo    "    1. Reboot your system. After booting, run:  uname -r"
echo    "       You should see a string containing 'legion'."
echo    "    2. If the patched kernel doesn't boot automatically, quickly press ESC"
echo    "       repeatedly during boot to open the GRUB menu and select the entry"
echo    "       containing 'legion' in its name. Then check again with uname -r"
echo    "    3. In your OS sound settings, select the"
echo    "       'Analog stereo duplex' profile."
echo
echo -e "  ${BOLD}Further improvements:${RESET}"
echo    "  See the 'Optional Post-installation Steps' section of the README for"
echo    "  instructions on how to:"
echo    "    - Set the patched kernel as the persistent default boot entry."
echo    "    - Re-enable Secure Boot by signing the kernel with your own MOK."
echo    "    - Fix echo on the headphone jack when audio playback and microphone"
echo    "      recording are active simultaneously (e.g. during discord calls while gaming)."
echo    "    - Improve speaker loudness."
echo    "  These fixes are not mandatory, but they are recommended."
echo
echo    "  If anything went wrong, you can always boot the stock kernel from"
echo    "  the GRUB menu - do NOT remove it."
echo
