#!/bin/bash
set -Eeuo pipefail

function cleanup() {
    trap - SIGINT SIGTERM ERR EXIT
    if [ -n "${tmpdir+x}" ]; then
        rm -rf "$tmpdir"
        logger.info "Deleted temporary working directory $tmpdir"
    fi
}

trap cleanup SIGINT SIGTERM ERR EXIT
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)
[[ ! -x "$(command -v date)" ]] && echo "date command not found." && exit 1
today=$(date +"%Y-%m-%d")


setup_colors() {
    if [[ -t 2 ]] && [[ -z "${NO_COLOR-}" ]] && [[ "${TERM-}" != "dumb" ]]; then
        RESET='\033[0m' NOFORMAT='\033[0m' BLACK='\033[0;30m' RED='\033[0;31m' GREEN='\033[0;32m' YELLOW='\033[0;33m' BLUE='\033[0;34m' PURPLE='\033[0;35m' CYAN='\033[0;36m' WHITE='\033[0;37m' BOLD_BLACK='\033[1;30m' BOLD_RED='\033[1;31m' BOLD_GREEN='\033[1;32m' BOLD_YELLOW='\033[1;33m' BOLD_BLUE='\033[1;34m' BOLD_PURPLE='\033[1;35m' BOLD_CYAN='\033[1;36m' BOLD_WHITE='\033[1;37m' UNDERLINE_BLACK='\033[4;30m' UNDERLINE_RED='\033[4;31m' UNDERLINE_GREEN='\033[4;32m' UNDERLINE_YELLOW='\033[4;33m' UNDERLINE_BLUE='\033[4;34m' UNDERLINE_PURPLE='\033[4;35m' UNDERLINE_CYAN='\033[4;36m' UNDERLINE_WHITE='\033[4;37m' BG_BLACK='\033[40m' BG_RED='\033[41m' BG_GREEN='\033[42m' BG_YELLOW='\033[43m' BG_BLUE='\033[44m' BG_PURPLE='\033[45m' BG_CYAN='\033[46m' BG_WHITE='\033[47m' HI_BLACK='\033[0;90m' HI_RED='\033[0;91m' HI_GREEN='\033[0;92m' HI_YELLOW='\033[0;93m' HI_BLUE='\033[0;94m' HI_PURPLE='\033[0;95m' HI_CYAN='\033[0;96m' HI_WHITE='\033[0;97m' BOLD_HI_BLACK='\033[1;90m' BOLD_HI_RED='\033[1;91m' BOLD_HI_GREEN='\033[1;92m' BOLD_HI_YELLOW='\033[1;93m' BOLD_HI_BLUE='\033[1;94m' BOLD_HI_PURPLE='\033[1;95m' BOLD_HI_CYAN='\033[1;96m' BOLD_HI_WHITE='\033[1;97m' BG_HI_BLACK='\033[0;100m' BG_HI_RED='\033[0;101m' BG_HI_GREEN='\033[0;102m' BG_HI_YELLOW='\033[0;103m' BG_HI_BLUE='\033[0;104m' BG_HI_PURPLE='\033[0;105m' BG_HI_CYAN='\033[0;106m' BG_HI_WHITE='\033[0;107m'
    else
        RESET='' NOFORMAT='' BLACK='' RED='' GREEN='' YELLOW='' BLUE='' PURPLE='' CYAN='' WHITE='' BOLD_BLACK='' BOLD_RED='' BOLD_GREEN='' BOLD_YELLOW='' BOLD_BLUE='' BOLD_PURPLE='' BOLD_CYAN='' BOLD_WHITE='' UNDERLINE_BLACK='' UNDERLINE_RED='' UNDERLINE_GREEN='' UNDERLINE_YELLOW='' UNDERLINE_BLUE='' UNDERLINE_PURPLE='' UNDERLINE_CYAN='' UNDERLINE_WHITE='' BG_BLACK='' BG_RED='' BG_GREEN='' BG_YELLOW='' BG_BLUE='' BG_PURPLE='' BG_CYAN='' BG_WHITE='' HI_BLACK='' HI_RED='' HI_GREEN='' HI_YELLOW='' HI_BLUE='' HI_PURPLE='' HI_CYAN='' HI_WHITE='' BOLD_HI_BLACK='' BOLD_HI_RED='' BOLD_HI_GREEN='' BOLD_HI_YELLOW='' BOLD_HI_BLUE='' BOLD_HI_PURPLE='' BOLD_HI_CYAN='' BOLD_HI_WHITE='' BG_HI_BLACK='' BG_HI_RED='' BG_HI_GREEN='' BG_HI_YELLOW='' BG_HI_BLUE='' BG_HI_PURPLE='' BG_HI_CYAN='' BG_HI_WHITE=''
    fi
}

function logger.info() {
    echo >&2 -e "[$(date +"%Y-%m-%d %H:%M:%S")] ${BOLD_WHITE}INFO | ${1-}$RESET"
}

function logger.error() {
    echo >&2 -e "[$(date +"%Y-%m-%d %H:%M:%S")] ${BOLD_RED}SUCCESS | ${1-}$RESET"
}

function logger.warning() {
    echo >&2 -e "[$(date +"%Y-%m-%d %H:%M:%S")] ${BOLD_YELLOW}WARNING | ${1-}$RESET"
}

function logger.success() {
    echo >&2 -e "[$(date +"%Y-%m-%d %H:%M:%S")] ${BOLD_GREEN}SUCCESS | ${1-}$RESET"
}

function log() {
    echo >&2 -e "[$(date +"%Y-%m-%d %H:%M:%S")] ${1-}"
}

function die() {
    local msg=$1
    local code=${2-1} # Bash parameter expansion - default exit status 1. See https://wiki.bash-hackers.org/syntax/pe#use_a_default_value
    echo "$msg"
    exit "$code"
}

usage() {
    cat <<EOF
Usage:
  $(basename "${BASH_SOURCE[0]}") [OPTIONS]

Summary:
  Create a custom Ubuntu Desktop or Server ISO with an embedded autoinstall
  configuration. The resulting ISO will automatically provision a system
  using Subiquity when booted.

  This script supports Ubuntu:
    - Desktop 24.04 and newer
    - Server 22.04 and newer (24.04+ recommended)

Required options:
  -a, -u, --autoinstall, --user-data FILE
        Path to an autoinstall-compatible cloud-init user-data file.
        This file will be copied into the ISO root as:
            /autoinstall.yaml

  -s, --source FILE
        Path to the original Ubuntu ISO (Desktop or Server).
        The ISO is extracted, modified, and repackaged.

Optional options:
  -d, --destination FILE
        Output path for the generated ISO.
        Defaults to:
            ./custom.iso
        Existing files will be overwritten.

  --unattended, --hands-free
        Modify GRUB boot entries to automatically start autoinstall
        without requiring user interaction at the boot menu.

        Without this flag:
          - Subiquity will detect autoinstall.yaml
          - A confirmation prompt may still appear

        With this flag:
          - Autoinstall starts immediately on boot

  --dry-run
        Perform input validation and print planned actions,
        but do not extract the ISO, modify files, or repackage.
        Exits successfully without side effects.

  -h, --help
        Show this help text and exit.

Behavior notes:
  - The autoinstall file is embedded directly at the ISO root.
    No NoCloud seed directory is required.
  - The resulting ISO boots in both BIOS and UEFI modes.
  - This script is suitable for imaging physical machines and VMs.

Examples:
  Build a custom unattended ISO:
    $(basename "${BASH_SOURCE[0]}") \\
      --source ubuntu-24.04-live-server-amd64.iso \\
      --autoinstall autoinstall.yaml \\
      --destination ubuntu-autoinstall.iso \\
      --unattended

  Validate inputs without modifying anything:
    $(basename "${BASH_SOURCE[0]}") \\
      --source ubuntu-24.04-desktop-amd64.iso \\
      --autoinstall autoinstall.yaml \\
      --dry-run

EOF
    exit 0
}

parse_params() {
    # Defaults
    autoinstall_file=""
    source_iso=""
    destination_iso="./custom.iso"
    dry_run=false
    unattended=false

    while :; do
        case "${1-}" in
            -h|--help) usage ;;
            -s|--source)
                source_iso="${2-}"
                shift
                ;;
            -d|--destination)
                destination_iso="${2-}"
                shift
                ;;
            -a|-u|--autoinstall|--user-data)
                autoinstall_file="${2-}"
                shift
                ;;
            --unattended|--hands-free)
                unattended=true
                ;;
            --dry-run)
                dry_run=true
                ;;
            -?*) die "Unknown option: $1" ;;
            *) break ;;
        esac
        shift
    done

    # Resolve paths early (loud fail if invalid)
    [[ -n "${autoinstall_file}" ]] && autoinstall_file=$(realpath -- "${autoinstall_file}") || die "Invalid user-data path"
    [[ -n "${source_iso}" ]] && source_iso=$(realpath -- "${source_iso}") || die "Invalid source ISO path"

    # Validate required parameters
    [[ -z "${autoinstall_file}" ]] && die "user-data file was not specified"
    [[ ! -f "${autoinstall_file}" ]] && die "user data: '${autoinstall_file}': No such file or directory"

    [[ -z "${source_iso}" ]] && die "source ISO file was not specified"
    [[ ! -f "${source_iso}" ]] && die "source iso: '${source_iso}': No such file or directory"

    # Optional parameters: validate only if provided
    # [[ -n "${destination_iso}" && ! -f "${destination_iso}" ]] && die "destination ISO file does not exist: ${destination_iso}"

    destination_iso=$(realpath -- "${destination_iso}")

    return 0
}

setup_colors
parse_params "$@"

tmpdir=$(mktemp -d)

if [[ ! "$tmpdir" || ! -d "$tmpdir" ]]; then
    die "Could not create temporary working directory."
else
    log "Created temporary working directory $tmpdir"
fi

logger.warning "Detected inputs to be processed:
    autoinstall:        $autoinstall_file
    source_iso:         $source_iso
    destination_iso:    $destination_iso
"

if $dry_run; then
    die "[dry-run] $*" 0
fi

logger.info "Extracting source ISO image to $tmpdir"
# xorriso -osirrox on -indev "${source_iso}" -extract / 
7z -y x ${source_iso} -o"$tmpdir"
chmod -R u+w "$tmpdir"
log "Extracted to $tmpdir"

logger.info "Renaming $tmpdir/[BOOT] to $tmpdir/BOOT" 
mv "$tmpdir/[BOOT]" "$tmpdir/BOOT"
ls $tmpdir

# 1) Copies user specified
logger.info "Copying ${autoinstall_file} to ISO media root $tmpdir/autoinstall.yaml"
cp "$autoinstall_file" "$tmpdir/autoinstall.yaml"

# 2) Add `autoinstall` to menu entry 
if $unattended; then
    logger.warning "Adding autoinstall flag to grub boot menu option (disables yes/no prompt when subiquity detects autoinstall.yaml)"
    sed -i -e 's/ ---/ autoinstall ---/g' "$tmpdir/boot/grub/grub.cfg"
    sed -i -e 's/ ---/ autoinstall ---/g' "$tmpdir/boot/grub/loopback.cfg"
fi

echo >&2 -e "${BOLD_WHITE}${tmpdir}/boot/grub/grub.cfg${RESET}"
cat "$tmpdir/boot/grub/grub.cfg"
echo "---------------------------------------------------------------------------------------------"

echo >&2 -e "${BOLD_WHITE}${tmpdir}/boot/grub/loopback.cfg${RESET}"
cat "$tmpdir/boot/grub/loopback.cfg"
echo "---------------------------------------------------------------------------------------------"


# Forming a proper USB-compatible ISO image is the tricky part here. If you don't get the flags right it won't work on real hardware
# The easiest way is to essentially take a working example, i.e. the Canonical provided Ubuntu Server/desktop images, and use the
# flags that they used to construct a GOOD bootable image.
# Forunately, you can find this information out with the following command:
# xorriso -indev <path to ISO> -report_el_torito as_mkisofs
# The command below was created by copying the results of that command and modifying the input and output to create a custom ISO
# exactly like Canonical would
# logger.info "Repackaging modified ISO from $tmpdir to $destination_iso"
# cd "$tmpdir"
# xorriso -as mkisofs \
#     -r -V "ubuntu-autoinstall-${today}" \
#     -o "${destination_iso}" \
#     --modification-date='2025080523540700' \
#     --grub2-mbr BOOT/1-Boot-NoEmul.img \
#     --protective-msdos-label \
#     -partition_cyl_align off \
#     -partition_offset 16 \
#     --mbr-force-bootable \
#     -append_partition 2 28732ac11ff8d211ba4b00a0c93ec93b BOOT/2-Boot-NoEmul.img \
#     -appended_part_as_gpt \
#     -iso_mbr_part_type a2a0d0ebe5b9334487c068b6b72699c7 \
#     -c '/boot.catalog' \
#     -b '/boot/grub/i386-pc/eltorito.img' \
#     -no-emul-boot \
#     -boot-load-size 4 \
#     -boot-info-table \
#     --grub2-boot-info \
#     -eltorito-alt-boot \
#     -e '--interval:appended_partition_2_start_1610304s_size_10160d:all::' \
#     -no-emul-boot \
#     -boot-load-size 10160 \
#     "${tmpdir}"

##################################################################################################
#
###################################################################################################
logger.info "Repackaging modified ISO from $tmpdir to $destination_iso"
cd "$tmpdir"

logger.info "Extracting boot structure flags from source ISO"
mapfile -t iso_boot_flags < <(
    xorriso -indev "$source_iso" -report_el_torito as_mkisofs 2>/dev/null \
    | awk 'BEGIN{p=0} /^[[:space:]]*-V /{p=1} p'
)
if ((${#iso_boot_flags[@]} == 0)); then
    die "Failed to parse boot flags from source ISO"
fi

# Now iso_boot_flags contains lines like:
# -V 'Ubuntu-Server 24.04.3 LTS amd64'
# --modification-date='2025080523540700'
# --grub2-mbr --interval:local_fs:0s-15s:zero_mbrpt,zero_gpt:'./ubuntu.iso'
# ...
# -boot-load-size 10160

filtered_flags=()

for line in "${iso_boot_flags[@]}"; do
    trimmed="$(sed 's/^[[:space:]]*//' <<< "$line")"

    case "$trimmed" in
        -V\ *)
            continue
            ;;

        --grub2-mbr\ --interval:local_fs:*)
            filtered_flags+=(--grub2-mbr BOOT/1-Boot-NoEmul.img)
            ;;

        -append_partition\ 2\ *)
            part_guid=$(awk '{print $3}' <<< "$trimmed")
            filtered_flags+=(-append_partition 2 "$part_guid" BOOT/2-Boot-NoEmul.img)
            ;;

        *)
            # Properly split the original mkisofs-style line into argv tokens
            # This safely handles quoted paths like '/boot.catalog'
            eval "set -- $trimmed"
            filtered_flags+=("$@")
            ;;
    esac
done

{
    echo "================ ORIGINAL FLAGS FROM ISO ================"
    for line in "${iso_boot_flags[@]}"; do
        printf '  %s\n' "$line"
    done

    echo
    echo "================ TRANSFORMED FLAGS USED FOR BUILD ========"
    for line in "${filtered_flags[@]}"; do
        printf '  %s\n' "$line"
    done
    echo "=========================================================="
} >&2


echo "Inferred xorriso reconstruction command:"
printf 'xorriso -as mkisofs -r -V %q -o %q' "ubuntu-autoinstall-${today}" "$destination_iso"
printf ' %q' "${filtered_flags[@]}"
printf ' %q\n' "$tmpdir"
# {
#     printf 'xorriso -as mkisofs \\\n'
#     printf '    -r -V %q \\\n' "ubuntu-autoinstall-${today}"
#     printf '    -o %q \\\n' "$destination_iso"

#     for arg in "${filtered_flags[@]}"; do
#         printf '    %q \\\n' "$arg"
#     done

#     printf '    %q\n' "$tmpdir"
# }

xorriso -as mkisofs \
    -r -V "ubuntu-autoinstall-${today}" \
    -o "$destination_iso" \
    "${filtered_flags[@]}" \
    "${tmpdir}"

###################################################################################################

cd $script_dir
logger.info "Custom ISO successfully built to $destination_iso"
logger.success "done"
