# ARGVUS theme skeleton

The starting point of a new [ARGVUS](https://github.com/argvus) theme. Clone
it, give the theme a name, choose its colours and its wallpaper, and you have
a theme you can use on your own desktop and publish as the Arch Linux package
`argvus-theme-<id>`, with the same layout as the official themes.

- [What a theme is](#what-a-theme-is)
- [Requirements](#requirements)
- [1. Get the skeleton](#1-get-the-skeleton)
- [2. Create your theme](#2-create-your-theme)
- [3. Choose the colours](#3-choose-the-colours)
- [4. Set the wallpaper](#4-set-the-wallpaper)
- [5. Check the theme](#5-check-the-theme)
- [6. Try it on your desktop](#6-try-it-on-your-desktop)
- [7. Build and install the package](#7-build-and-install-the-package)
- [8. Publish it](#8-publish-it)
- [Going further](#going-further)
- [Reference](#reference)
- [Troubleshooting](#troubleshooting)

## What a theme is

An ARGVUS theme is data, not a set of configuration files. The whole theme is
one manifest and a wallpaper:

```text
src/usr/share/argvus/themes/<id>/theme.toml        the theme: name, category,
                                                   wallpaper and colour palette
src/usr/share/argvus/themes/<id>/overrides/        optional files of the theme
src/usr/share/backgrounds/argvus/abstract/...      its wallpaper
```

When the theme is applied, every component of the desktop renders its own
files from the palette: the taskbar and the telemetry widget, the Control
Panel, the Hyprland borders, the launcher, the notifications, the lock screen,
the terminal, btop, yazi, superfile, Qt and GTK applications, the calendar and
the removable-devices panel. You do not write any of those files.

- **Only three colours are required**: the background (`bg`), the text (`fg`)
  and the highlight (`accent`). Every other colour has a default derived from
  them; you set one only to change it.
- **Sticky and Float are layouts**, not variants of the theme: both come from
  the same palette, with no extra work.
- **The highlight colour the user picks** in the Control Center replaces
  `accent` and every colour derived from it.
- **Switching is instant**: no splash, no restart of the desktop.

## Requirements

- An ARGVUS desktop, to check and try the theme (`argvus` must be installed).
- For packaging: an Arch Linux system with the build tools:

  ```sh
  sudo pacman -S --needed base-devel git shellcheck make
  ```

## 1. Get the skeleton

Clone it into the directory of your theme. The convention for the directory
and the repository is `argvus-theme-<id>`:

```sh
git clone https://github.com/argvus/argvus-skeleton-theme.git argvus-theme-ocean-night
cd argvus-theme-ocean-night
```

To start your own history instead of the skeleton's, re-create the git
repository:

```sh
rm -rf .git
git init
```

## 2. Create your theme

Choose three things:

| What | Rules | Example |
| --- | --- | --- |
| ID | lowercase letters, digits and single hyphens; not ending in `-float` | `ocean-night` |
| Name | shown in the theme menu and the Control Center | `Ocean Night` |
| Category | `dark` or `light` | `dark` |

Then run, once:

```sh
make new ID=ocean-night NAME="Ocean Night" CATEGORY=dark
```

You can give the wallpaper now (`.jxl`, `.png`, `.jpg` or `.webp`):

```sh
make new ID=ocean-night NAME="Ocean Night" CATEGORY=dark WALLPAPER=~/Pictures/ocean.png
```

`make new` (`tools/sh/new_theme.sh`):

- renames every `skeleton` identifier: the theme directory, the manifest, the
  package name (`argvus-theme-ocean-night`) and its description;
- sets the category, and starts a light theme from a light palette;
- puts the wallpaper in place (or the placeholder under its new name);
- resets the package version to `0.1.0` and writes the README of your theme;
- removes itself, so it runs only once.

From here on, the theme is `src/usr/share/argvus/themes/<id>/theme.toml`.

## 3. Choose the colours

Open the manifest. The `[palette]` table holds the colours; a colour is
`"#RGB"`, `"#RRGGBB"` or `"#RRGGBBAA"` (with transparency):

```toml
[palette]
bg = "#0F1A24"
fg = "#D5E2EC"
accent = "#4FB3C9"
```

That is enough for a complete theme. To refine it, set any other token. These
are the ones that change the look the most:

| Token | Where it shows | Default |
| --- | --- | --- |
| `danger`, `ok`, `warn` | errors, success, warnings everywhere | red, green, yellow |
| `fg_dim`, `fg_subtle`, `fg_faint` | secondary, muted and disabled text | `fg` mixed with `bg` |
| `bg_panel` | the Control Panel background | `bg`, translucent |
| `bg_card`, `bg_card_alt`, `bg_header` | cards and headers of the panels | `bg` lightened, translucent |
| `bg_item`, `bg_item_hover` | rows and their hover state | `fg` over `bg`, light |
| `border_subtle` | separators and quiet borders | `bg` mixed with `fg` |

A token can also be an **expression** over other tokens, written
`"@token | filter(...)"`, so a colour follows the others when you change them:

```toml
fg_dim = "@fg | mix(@bg, 0.3)"        # 30% of the way from fg to bg
bg_card = "@bg | lighten(0.06)"       # bg, 6% towards white
border_subtle = "@accent | alpha(0.3)" # the accent, 30% opaque
```

| Filter | Effect |
| --- | --- |
| `alpha(x)` | sets the opacity, `0` to `1` |
| `mix(@other, x)` | blends towards another colour, `0` to `1` |
| `lighten(x)`, `darken(x)` | blends towards white or black |
| `contrast` | black or white, whichever reads on the colour |

Each component has its own tokens with defaults, named after it: `bar_*`
(taskbar), `telemetry_*`, `launcher_*`, `notify_*`, `lock_*`, `hypr_*`
(window borders), `toolkit_*` (Hyprland toolkit apps), `qt_*`, `tui_*`
(Control Center), `calendar_*`, `storage_*` (removable devices), `btop_*`,
`term_*`, `spf_*` (superfile), `yazi_*` and `syntax_*`. Their full list, with
the default of each one, is in the `[palette]` tables of
`/usr/share/argvus/theme/consumers.d/*.toml` on an ARGVUS system:

```sh
grep -h -A200 '^\[palette\]' /usr/share/argvus/theme/consumers.d/taskbar.toml
```

**Terminal colours.** The `[ansi]` table holds the 16 terminal colours (black,
red, green, yellow, blue, magenta, cyan and white, then the bright versions).
`overrides/terminal.conf` reads them; adjust them to your palette.

**Light themes.** Keep `bg` light and `fg` dark, and check that `accent` reads
on both: it is also used as a background under text.

## 4. Set the wallpaper

The wallpaper is in `src/usr/share/backgrounds/argvus/abstract/<category>/`,
named `<id>-abstract-<category>.<ext>`, and the manifest points at its
installed path:

```toml
wallpaper = "/usr/share/backgrounds/argvus/abstract/dark/ocean-night-abstract-dark.jxl"
```

To replace it, put your image there (keep the name, or change the
`wallpaper` line to match) and delete the placeholder. Use an image at least
as large as your screen; JPEG XL (`.jxl`) gives the smallest package:

```sh
cjxl -q 90 ~/Pictures/ocean.png \
  src/usr/share/backgrounds/argvus/abstract/dark/ocean-night-abstract-dark.jxl
```

The image must be yours or licensed for redistribution.

## 5. Check the theme

```sh
make check
```

It renders every component of the theme with the templates installed on your
system, in both layouts, and reports each error with the template and the
line, for example an unknown token or a colour that is not valid. Then run the
repository checks:

```sh
make validate
```

## 6. Try it on your desktop

```sh
make try
argvus theme apply ocean-night
```

`make try` installs the theme as one of your own themes, in
`~/.local/share/argvus/themes/<id>/`, with its wallpaper. It also appears in
the theme menu (`SUPER + Shift + T`). While you work on the colours:

1. edit `theme.toml`;
2. run `make try` again;
3. run `argvus theme apply <id>` again: the desktop changes at once.

Check both layouts with `SUPER + Shift + M` (Sticky/Float), a highlight colour
of your own in **Control Center → Appearance → Highlight color**, and open the
components: the Control Panel, the launcher (`SUPER + D`), a notification
(`notify-send Test "Hello"`), the terminal, btop and the lock screen.

When you are done, return to another theme and remove the copy:

```sh
argvus theme apply argvus-dark
make untry
```

You can keep a theme just for yourself this way, with no package: a theme in
`~/.local/share/argvus/themes/<id>/` stays available. An installed package
with the same ID wins over it.

## 7. Build and install the package

```sh
make validate
make build      # build/dist/argvus-theme-<id>-<version>-1-any.pkg.tar.zst
make install    # sudo pacman -U the package
```

The package depends on `argvus` and `argvus-appearance`, and installs only
the manifest, its overrides and the wallpaper. Select the theme in the
Control Center (**Appearance → Themes**) or with `argvus theme apply <id>`.
Remove it with `sudo pacman -R argvus-theme-<id>`, after applying another
theme.

## 8. Publish it

1. Create the repository `argvus-theme-<id>` and push your branch.
2. Set the maintainer in `packaging/arch/local/PKGBUILD` and
   `packaging/arch/remote/PKGBUILD`, and your name in `AUTHORS.md`.
3. `make new` points the release (`url` in `packaging/arch/remote/PKGBUILD`)
   and the issue templates (`.github/ISSUE_TEMPLATE/config.yml`) at
   `github.com/argvus/argvus-theme-<id>`. Change them if your repository lives
   elsewhere: the release downloads the tag archive from `url`. Set the
   reviewers in `.github/CODEOWNERS`.
4. Tag a version; `.github/workflows/release.yml` builds, signs and publishes
   the package:

   ```sh
   git tag v0.1.0
   git push origin v0.1.0
   ```

The signing key, the secrets and the release steps are in
[DEVELOPMENT.md](DEVELOPMENT.md).

## Going further

**Names in other languages.** `[name_i18n]` gives the name per language:

```toml
[name_i18n]
en-US = "Ocean Night"
pt-BR = "Noite Oceânica"
```

**GTK colour scheme.** It follows the category; set `[gtk] scheme` to
`"prefer-dark"`, `"prefer-light"` or `"default"` to change it.

**Overrides.** When the palette is not enough for one component, give the
theme its own template for it: copy the component's template from
`/usr/share/argvus/<component>/theme-template/` into `overrides/`, edit it, and
name it in `[overrides]` by the consumer ID:

```toml
[overrides]
terminal = "overrides/terminal.conf"
launcher = "overrides/launcher.rasi"
```

A template is the component's file with `{{ expressions }}`: `{{ @accent | hex }}`
writes the accent, `{{ ansi.color1 | hex }}` a terminal colour, and
`{{ layout.<name> }}` a value of the Sticky or Float layout. Formats:
`hex`, `hexa`, `rgb`, `rgba`, `argb`, `bare`, `hypr`. Keep overrides rare: a
component that changes its template does not change yours.

| Consumer ID | File |
| --- | --- |
| `taskbar`, `taskbar-menu` | taskbar stylesheet and launcher icon |
| `widget-telemetry` | telemetry widget |
| `control-panel` | Control Panel (`Theme.qml`) |
| `hyprland` | window borders, groups and shadows |
| `hyprtoolkit`, `application-style` | Hyprland toolkit applications |
| `launcher` | Rofi |
| `notifications` | Dunst |
| `lock` | Hyprlock |
| `terminal` | kitty |
| `system-monitor` | btop |
| `qt6ct` | Qt applications |
| `tui` | Control Center and terminal tools |
| `taskbar-calendar` | calendar |
| `removable-devices` | removable-devices panel |
| `superfile` | superfile |
| `yazi-flavor`, `yazi-tmtheme` | yazi and its preview highlighting |

## Reference

| Command | What it does |
| --- | --- |
| `make new ID=… NAME="…" CATEGORY=… [WALLPAPER=…]` | turns the skeleton into your theme (once) |
| `make check` | renders every component in both layouts |
| `make try` / `make untry` | installs / removes the theme as your own theme |
| `make validate` | repository, manifest and packaging checks |
| `make build` | builds the package into `build/dist/` |
| `make install` | installs the package |
| `make clean` | removes `build/` |
| `argvus theme list` | the installed themes |
| `argvus theme apply <id>` | applies a theme |

| Path | Content |
| --- | --- |
| `src/usr/share/argvus/themes/<id>/theme.toml` | the theme |
| `src/usr/share/argvus/themes/<id>/overrides/` | templates of the theme |
| `src/usr/share/backgrounds/argvus/` | wallpapers |
| `packaging/arch/` | PKGBUILDs (local build and release) |
| `tools/sh/` | build, validation and try scripts |

## Troubleshooting

- **`make check` says a token is not defined**: a name in an expression or an
  override is misspelled; the message names the template and the line.
- **The theme does not appear in the menu**: run `argvus theme list`. A theme
  whose directory name differs from its `id`, or with an invalid manifest, is
  listed as a warning with the reason.
- **`argvus theme apply` refuses the theme**: it is not installed (run
  `make try`), or it does not render (run `make check`). The previous theme
  stays.
- **My changes do not show**: run `make try` and `argvus theme apply <id>`
  again; a package with the same ID wins over your copy.
- **`make validate` fails on the wallpaper**: the `wallpaper` line must name a
  file under `src/usr/share/backgrounds/argvus/`.

## License

GPL-3.0-only. See [LICENSE](LICENSE).

## Install a community theme from Git

Publish the skeleton-format repository, including its wallpaper, then install it. The installer reads the theme from `src/` only; `packaging/` is optional and is used to build Arch Linux packages. No PKGBUILD is needed for Git installation:

```sh
argvus theme install https://github.com/USER/argvus-theme-NAME.git
argvus theme install https://gitlab.com/USER/argvus-theme-NAME.git --ref v1.0
argvus theme install git@host:USER/argvus-theme-NAME.git --replace
argvus theme apply NAME
argvus theme uninstall NAME
```

HTTPS and SSH use your existing Git authentication. Install `git`, and `openssh`
for SSH. Installation uses the default branch unless `--ref` selects a branch or
tag. The repository must contain exactly one schema-2 theme under
`src/usr/share/argvus/themes/<id>/`. The manifest ID must match its directory.
Wallpaper and preview assets must be committed regular files, either relative to
the theme or shipped under `src/usr/share/`. Submodules and Git LFS are unsupported.
Repository scripts and package build instructions are never executed.

Installation is per user in `$XDG_DATA_HOME/argvus/themes/<id>` and does not apply
the theme. Select it in Control Center → Appearance → Themes → Custom themes;
press `r` to refresh an already open page. Existing custom IDs require `--replace`;
official installed IDs cannot be replaced. Reapply an active theme after replacing
it to see changes. Apply another theme before uninstalling the active one, including
when deleting through the Control Center. Official packages remain managed by pacman.
