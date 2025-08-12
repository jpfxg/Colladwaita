#!/usr/bin/env bash

set -eo pipefail

ROOT_UID=0
DEST_DIR=

# Destination directory
if [ "$UID" -eq "$ROOT_UID" ]; then
  DEST_DIR="/usr/share/icons"
else
  DEST_DIR="$HOME/.local/share/icons"
fi

SRC_DIR="$(cd "$(dirname "$0")" && pwd)"

THEME_NAME=Colladwaita
THEME_VARIANTS=('' '-Purple' '-Pink' '-Red' '-Orange' '-Yellow' '-Green' '-Teal' '-Grey')
SCHEME_VARIANTS=('' '-Nord' '-Dracula' '-Gruvbox' '-Everforest' '-Catppuccin')
COLOR_VARIANTS=('-Light' '-Dark' '')

themes=()
schemes=()
colors=()

usage() {
cat << EOF
Usage: $0 [OPTION]...

OPTIONS:
  -d, --dest DIR          Specify destination directory (Default: $DEST_DIR)
  -n, --name NAME         Specify theme name (Default: $THEME_NAME)
  -s, --scheme VARIANTS   Specify colorscheme variant(s) [default|nord|dracula|gruvbox|everforest|catppuccin|all]
  -t, --theme VARIANTS    Specify color theme variant(s) [default|purple|pink|red|orange|yellow|green|teal|grey|all]
  -b, --bold              Install bolder panel icons version
  -r, --remove            Remove/uninstall icon themes
  -h, --help              Show help
EOF
}

install() {
  local dest=${1}
  local name=${2}
  local theme=${3}
  local scheme=${4}
  local color=${5}

  local THEME_DIR="${dest}/${name}${theme}${scheme}${color}"

  [[ -d "${THEME_DIR}" ]] && rm -rf "${THEME_DIR}"
  echo "Installing '${THEME_DIR}'..."

  mkdir -p "${THEME_DIR}"
  cp -r "${SRC_DIR}"/src/index.theme "${THEME_DIR}"
  sed -i "s/Colloid/${name}${theme}${scheme}${color}/g" "${THEME_DIR}"/index.theme

  # Install core system icons
  if [[ "${color}" == '-Light' ]]; then
    cp -r "${SRC_DIR}"/src/{apps,categories,devices,mimetypes} "${THEME_DIR}"
    [[ ${bold:-} == 'true' ]] && cp -r "${SRC_DIR}"/bold/* "${THEME_DIR}"
  elif [[ "${color}" == '-Dark' ]]; then
    mkdir -p "${THEME_DIR}"/{apps,categories,devices,mimetypes}
    cp -r "${SRC_DIR}"/src/apps/22 "${THEME_DIR}"/apps
    cp -r "${SRC_DIR}"/src/categories/22 "${THEME_DIR}"/categories
    cp -r "${SRC_DIR}"/src/devices/{16,22,24,32} "${THEME_DIR}"/devices
    cp -r "${SRC_DIR}"/src/mimetypes/scalable "${THEME_DIR}"/mimetypes
  fi

  # Create basic @2x symlinks
  (
    cd "${THEME_DIR}"
    ln -sf apps apps@2x
    ln -sf categories categories@2x
    ln -sf devices devices@2x
    ln -sf mimetypes mimetypes@2x
  )

  gtk-update-icon-cache "${THEME_DIR}"
}

while [[ "$#" -gt 0 ]]; do
  case "${1:-}" in
    -d|--dest)
      dest="$2"
      mkdir -p "$dest"
      shift 2
      ;;
    -n|--name)
      name="${2}"
      shift 2
      ;;
    -r|--remove)
      remove='true'
      echo -e "\nUninstalling icon themes...\n"
      shift
      ;;
    -b|--bold)
      bold='true'
      echo -e "\nInstalling 'bold' version..."
      shift
      ;;
    -s|--scheme)
      shift
      for scheme in "${@}"; do
        case "${scheme}" in
          default) schemes+=("${SCHEME_VARIANTS[0]}"); shift ;;
          nord) schemes+=("${SCHEME_VARIANTS[1]}"); shift ;;
          dracula) schemes+=("${SCHEME_VARIANTS[2]}"); shift ;;
          gruvbox) schemes+=("${SCHEME_VARIANTS[3]}"); shift ;;
          everforest) schemes+=("${SCHEME_VARIANTS[4]}"); shift ;;
          catppuccin) schemes+=("${SCHEME_VARIANTS[5]}"); shift ;;
          all) schemes+=("${SCHEME_VARIANTS[@]}"); shift ;;
          *) echo "ERROR: Unrecognized scheme '$1'"; exit 1 ;;
        esac
      done
      ;;
    -t|--theme)
      shift
      for theme in "${@}"; do
        case "${theme}" in
          default) themes+=("${THEME_VARIANTS[0]}"); shift ;;
          purple) themes+=("${THEME_VARIANTS[1]}"); shift ;;
          pink) themes+=("${THEME_VARIANTS[2]}"); shift ;;
          red) themes+=("${THEME_VARIANTS[3]}"); shift ;;
          orange) themes+=("${THEME_VARIANTS[4]}"); shift ;;
          yellow) themes+=("${THEME_VARIANTS[5]}"); shift ;;
          green) themes+=("${THEME_VARIANTS[6]}"); shift ;;
          teal) themes+=("${THEME_VARIANTS[7]}"); shift ;;
          grey) themes+=("${THEME_VARIANTS[8]}"); shift ;;
          all) themes+=("${THEME_VARIANTS[@]}"); shift ;;
          *) echo "ERROR: Unrecognized theme '$1'"; exit 1 ;;
        esac
      done
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "ERROR: Unrecognized option '$1'"
      usage
      exit 1
      ;;
  esac
done

# Set defaults if no variants specified
[[ "${#themes[@]}" -eq 0 ]] && themes=("${THEME_VARIANTS[0]}")
[[ "${#schemes[@]}" -eq 0 ]] && schemes=("${SCHEME_VARIANTS[0]}")
[[ "${#colors[@]}" -eq 0 ]] && colors=("${COLOR_VARIANTS[@]}")

remove_theme() {
  for theme in "${THEME_VARIANTS[@]}"; do
    for scheme in "${SCHEME_VARIANTS[@]}"; do
      for color in "${COLOR_VARIANTS[@]}"; do
        local THEME_DIR="${DEST_DIR}/${THEME_NAME}${theme}${scheme}${color}"
        [[ -d "$THEME_DIR" ]] && echo "Removing $THEME_DIR" && rm -rf "$THEME_DIR"
      done
    done
  done
}

install_theme() {
  for theme in "${themes[@]}"; do
    for scheme in "${schemes[@]}"; do
      for color in "${colors[@]}"; do
        install "${dest:-${DEST_DIR}}" "${name:-${THEME_NAME}}" "${theme}" "${scheme}" "${color}"
      done
    done
  done
}

if [[ "${remove}" == 'true' ]]; then
  remove_theme
else
  install_theme
fi

echo -e "\nInstallation complete!\n"
