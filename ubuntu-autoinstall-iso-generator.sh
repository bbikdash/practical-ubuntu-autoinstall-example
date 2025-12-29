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
Usage: $(basename "${BASH_SOURCE[0]}") [-h] [-v] [-a|-u|--autoinstall|--user-data autoinstall-yaml] [-s source-iso-file] [-d destination-iso-file]

This script

Available options:

-h, --help          Print this help and exit
-v, --verbose       Print script debug info
-a, -u, --autoinstall, --user-data    
                    Path to user-data file. Required 
-s, --source        Source ISO file. Expects a valid Ubuntu ISO file on disk (24.04 and later for Desktop, 22.04 and later for Server) 
                    and saved as ${script_dir}/ubuntu-original-$today.iso
                    That file will be used by default if it already exists.
-d, --destination       Destination ISO file. By default ${script_dir}/ubuntu-autoinstall-$today.iso will be
                        created, overwriting any existing file.
--unattended, --hands-free  
--dry-run           

EOF
    exit
}

parse_params() {
    # Defaults
    user_data_file=""
    source_iso=""
    destination_iso="./custom.iso"
    dry_run=false
    unattended=false

    while :; do
        case "${1-}" in
            -h|--help) usage ;;
            -v|--verbose) ;;
            -s|--source)
                source_iso="${2-}"
                shift
                ;;
            -d|--destination)
                destination_iso="${2-}"
                shift
                ;;
            -a|-u|--autoinstall|--user-data)
                user_data_file="${2-}"
                shift
                ;;
            --unattended)
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
    [[ -n "${user_data_file}" ]] && user_data_file=$(realpath -- "${user_data_file}") || die "Invalid user-data path"
    [[ -n "${source_iso}" ]] && source_iso=$(realpath -- "${source_iso}") || die "Invalid source ISO path"

    # Validate required parameters
    [[ -z "${user_data_file}" ]] && die "user-data file was not specified"
    [[ ! -f "${user_data_file}" ]] && die "user data: '${user_data_file}': No such file or directory"

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
    autoinstall:        $user_data_file
    source_iso:         $source_iso
    destination_iso:    $destination_iso
"

if $dry_run; then
    die "[dry-run] $*" 0
fi

logger.info "Extracting source ISO image to $tmpdir"
xorriso -osirrox on -indev "${source_iso}" -extract / "$tmpdir"
chmod -R u+w "$tmpdir"
log "Extracted to $tmpdir"

# 1) Copies user specified
logger.info "Copying ${user_data_file} to ISO media root $tmpdir/autoinstall.yaml"
cp "$user_data_file" "$tmpdir/autoinstall.yaml"

# 2) Add `autoinstall` to menu entry 
# sed -i -e 's/ ---/  autoinstall ds=nocloud;s=\/cdrom\/nocloud\/ ---/g' "$tmpdir/boot/grub/grub.cfg"
# sed -i -e 's/ ---/  autoinstall ds=nocloud;s=\/cdrom\/nocloud\/ ---/g' "$tmpdir/boot/grub/loopback.cfg"
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

logger.info "Repackaging modified ISO from $tmpdir to $destination_iso"
cd "$tmpdir"
xorriso -as mkisofs \
  -r \
  -V "ubuntu-autoinstall-${today}" \
  -o "${destination_iso}" \
  -J -l \
  -b boot/grub/i386-pc/eltorito.img \
    -no-emul-boot \
    -boot-load-size 4 \
    -boot-info-table \
  -eltorito-alt-boot \
  -e EFI/boot/bootx64.efi \
    -no-emul-boot \
  "${tmpdir}"

cd $script_dir
logger.info "Custom ISO successfully built to $destination_iso"
logger.success "done"
