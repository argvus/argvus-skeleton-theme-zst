#!/usr/bin/env bash
# Turns this skeleton into the repository of a new ARGVUS theme.
#
# Usage: tools/sh/new_theme.sh <id> "<Name>" <dark|light> [WALLPAPER]
#   e.g. tools/sh/new_theme.sh ocean-night "Ocean Night" dark ~/Pictures/ocean.jxl
#
# - <id> becomes the theme ID and the package name (argvus-theme-<id>);
# - <Name> is the name shown in the theme menu and the Control Center;
# - dark or light is the category, and sets a starting palette of that kind;
# - WALLPAPER (optional) is an image (.jxl, .png, .jpg or .webp) copied into the
#   package; without it the placeholder wallpaper stays until you replace it.
#
# The script renames every "skeleton" identifier, writes the README of the new
# theme, resets the version, and then removes itself: run it once.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -- "$SCRIPT_DIR/../.." && pwd)"
SELF="$SCRIPT_DIR/${BASH_SOURCE[0]##*/}"
THEMES="src/usr/share/argvus/themes"
WALLPAPERS="src/usr/share/backgrounds/argvus/abstract"

die() {
	printf 'error: %s\n' "$1" >&2
	exit 1
}

usage() {
	printf 'usage: %s <id> "<Name>" <dark|light> [WALLPAPER]\n' "${BASH_SOURCE[0]##*/}" >&2
	exit 2
}

# Escapes the characters that are special in a sed replacement using '|'.
sed_escape() {
	printf '%s' "$1" | sed -e 's/[\\&|]/\\&/g'
}

# Applies sed expressions to a file in place, keeping its mode.
rewrite_file() {
	local file="$1"
	shift
	sed -i "$@" "$file"
}

[[ $# -eq 3 || $# -eq 4 ]] || usage
id="$1"
name="$2"
category="$3"
wallpaper_source="${4:-}"

[[ "$id" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]] || \
	die "invalid ID '$id': use lowercase letters, digits and single hyphens"
[[ "$id" != *-float ]] || die "the ID must not end in -float: Float is a layout of every theme"
[[ "$id" != skeleton ]] || die "choose the ID of your theme, not 'skeleton'"
[[ -n "$name" && "$name" != *$'\n'* && "$name" != *'"'* ]] || \
	die "the name must be a non-empty single line without double quotes"
[[ "$category" == dark || "$category" == light ]] || die "the category must be dark or light"
if [[ -n "$wallpaper_source" ]]; then
	[[ -f "$wallpaper_source" ]] || die "wallpaper not found: $wallpaper_source"
	extension="${wallpaper_source##*.}"
	extension="${extension,,}"
	case "$extension" in
	jxl | png | jpg | jpeg | webp) ;;
	*) die "unsupported wallpaper format '.$extension': use .jxl, .png, .jpg or .webp" ;;
	esac
fi

cd "$ROOT_DIR"
[[ -d "$THEMES/skeleton" ]] || die "this repository is already a theme: no $THEMES/skeleton left"

# The wallpaper: the given image, or the placeholder under its new name.
placeholder="$WALLPAPERS/dark/skeleton-abstract-dark.jxl"
mkdir -p "$WALLPAPERS/$category"
if [[ -n "$wallpaper_source" ]]; then
	wallpaper_file="$WALLPAPERS/$category/$id-abstract-$category.$extension"
	cp -- "$wallpaper_source" "$wallpaper_file"
	rm -f -- "$placeholder"
else
	wallpaper_file="$WALLPAPERS/$category/$id-abstract-$category.jxl"
	mv -- "$placeholder" "$wallpaper_file"
fi
rmdir --ignore-fail-on-non-empty "$WALLPAPERS/dark" 2>/dev/null || true
mv -- "$THEMES/skeleton" "$THEMES/$id"
manifest="$THEMES/$id/theme.toml"

# A light theme starts from a light palette.
if [[ "$category" == light ]]; then
	rewrite_file "$manifest" \
		-e 's|^bg = ".*"|bg = "#F5F6F8"|' \
		-e 's|^fg = ".*"|fg = "#24292F"|' \
		-e 's|^accent = ".*"|accent = "#2F6FB0"|' \
		-e 's|^color0 = ".*"|color0 = "#24292F"|' \
		-e 's|^color7 = ".*"|color7 = "#D0D7DE"|' \
		-e 's|^color8 = ".*"|color8 = "#57606A"|' \
		-e 's|^color15 = ".*"|color15 = "#F5F6F8"|'
fi
rewrite_file "$manifest" \
	-e "s|^category = \".*\"|category = \"$category\"|" \
	-e "s|^wallpaper = \".*\"|wallpaper = \"/${wallpaper_file#src/}\"|"

# The skeleton-only Makefile target goes away with this script.
rewrite_file Makefile -e '/^# >>> skeleton/,/^# <<< skeleton/d'

# Every "skeleton" identifier, in every text file of the repository.
id_sed="$(sed_escape "$id")"
name_sed="$(sed_escape "$name")"
while IFS= read -r -d '' file; do
	[[ "$file" == "./tools/sh/new_theme.sh" ]] && continue
	grep -Iq -e skeleton -e Skeleton -- "$file" || continue
	rewrite_file "$file" \
		-e "s|argvus-theme-skeleton|argvus-theme-${id_sed}|g" \
		-e "s|Skeleton|${name_sed}|g" \
		-e "s|skeleton|${id_sed}|g"
done < <(find . \( -name .git -o -name build \) -prune -o -type f -print0)

# The repository of the theme in the issue templates.
rewrite_file .github/ISSUE_TEMPLATE/config.yml \
	-e '/^# Replace <ORG>\/<REPO>/d' \
	-e "s|<ORG>/<REPO>|argvus/argvus-theme-${id_sed}|g"

for pkgbuild in packaging/arch/local/PKGBUILD packaging/arch/remote/PKGBUILD; do
	rewrite_file "$pkgbuild" -e 's/^pkgver=.*/pkgver=0.1.0/' -e 's/^pkgrel=.*/pkgrel=1/'
done

cat >README.md <<EOF
# ${name} theme for ARGVUS

ARGVUS ${category^} theme, \`${id}\`, with its Sticky and Float layouts.

## Theme identity

| Field | Value |
| --- | --- |
| Theme ID | \`${id}\` |
| Display name | ${name} |
| Mode | \`${category}\` |
| Package | \`argvus-theme-${id}\` |
| Wallpaper | \`/${wallpaper_file#src/}\` |

The theme is \`src/usr/share/argvus/themes/${id}/theme.toml\`: its name,
category, wallpaper and palette. Every component of the desktop renders its
files from that palette when the theme is applied, so the manifest and the
wallpaper are the whole package.

## Working on the theme

\`\`\`sh
make check     # render every component in both layouts and report errors
make try       # install it as your own theme, then: argvus theme apply ${id}
make untry     # remove that copy
make validate  # repository and packaging checks
make build     # build the package into build/dist/
make install   # install the package (sudo pacman -U)
\`\`\`

See [DEVELOPMENT.md](DEVELOPMENT.md) for the build and release details.

## License

GPL-3.0-only. See [LICENSE](LICENSE).
EOF

rm -f -- "$SELF"

printf 'Theme "%s" (%s, %s) created.\n\n' "$name" "$id" "$category"
printf 'Next steps:\n'
printf '  1. Edit the palette in %s\n' "$manifest"
[[ -n "$wallpaper_source" ]] || printf '  2. Replace the placeholder wallpaper %s\n' "$wallpaper_file"
printf '  3. make try, then: argvus theme apply %s\n' "$id"
printf '  4. make validate && make build\n'
