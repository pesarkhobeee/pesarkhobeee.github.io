+++
title = 'Arch Linux ARM on the ASUS Chromebook Flip C101PA, Part 2: Making It a Daily Driver'
date = 2026-09-13T14:00:00+02:00
categories = ['linux', 'guides']
tags = ['arch-linux', 'chromebook', 'arm', 'linux', 'rockchip', 'sway', 'encryption']
+++

[Part 1]({{< ref "arch-linux-asus-c101pa" >}}) got Arch Linux ARM booting on the C101PA with a mainline kernel, Sway, and working audio and backlight. This post is everything that came after: turning a proof-of-concept install into a small laptop I actually reach for — a modern shell, real applications (including ones that officially don't exist for this platform), compressed swap, an encrypted home directory, and the hardware quirks that only show up once you use the machine every day.

Everything below runs on the stock Arch Linux ARM repos plus Flathub. Nothing needs AUR builds, which matters on a 4 GB fanless machine.

## A correction to Part 1 first

The device names **swap between ChromeOS and mainline Linux**. In ChromeOS (where Part 1's installation happens) the SD card is `/dev/mmcblk1` and the eMMC is `/dev/mmcblk0`. Booted into Arch, it is the other way around: the SD card is `/dev/mmcblk0` (root on `mmcblk0p2`) and the ChromeOS eMMC is `/dev/mmcblk1`.

So the prevention command in Part 1's rescue section — flashing the kernel *from within Arch* — must target `mmcblk0p1`, not `mmcblk1p1`:

```
dd if=/boot/vmlinux.kpart of=/dev/mmcblk0p1
```

Always confirm with `lsblk` before any `dd`: the eMMC is the 14.7 GB device with a dozen ChromeOS partitions.

While we are on kernel gotchas, a cosmetic one: the package version and the kernel's own version string differ. `linux-aarch64 7.2.2-1` boots as `7.2.0-1-aarch64-ARCH`. To check whether your running kernel matches the installed modules, compare `uname -r` against `ls /usr/lib/modules/` — not against the pacman version.

## zsh, oh-my-zsh, and a shell worth typing in

```
sudo pacman -S zsh zsh-autosuggestions zsh-syntax-highlighting
chsh -s /usr/bin/zsh
RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
```

The two plugin packages come from the repos rather than git clones, so pacman keeps them updated. Source them at the end of `~/.zshrc`:

```
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
```

Grey inline suggestions from history plus live syntax coloring — on a machine this slow to type on, autosuggestions genuinely save time.

## wezterm, and why not ghostty

Ghostty is not packaged for Arch Linux ARM (building it means a Zig toolchain on a 4 GB ARM board — no thanks). The repos do carry the other modern GPU-accelerated terminals: kitty, wezterm, alacritty, foot. I wanted tabs, so:

```
sudo pacman -S wezterm
```

and in `~/.config/sway/config`:

```
set $term wezterm
```

`Ctrl+Shift+T` for a new tab, `Ctrl+Tab` to cycle. The Mali GPU handles it fine under Wayland. `foot` stays installed as a fallback — at 900 KB it costs nothing.

## Software that "doesn't exist" for ARM Linux

The pleasant surprise of 2026: most of it actually ships aarch64 builds now, just not always through pacman.

**Google Cloud CLI** — not in the repos, but Google publishes an ARM tarball with its own bundled Python:

```
cd ~/apps
curl -LO https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-linux-arm.tar.gz
tar xzf google-cloud-cli-linux-arm.tar.gz
./google-cloud-sdk/install.sh
```

Since pacman knows nothing about it, updates go through its own mechanism: `gcloud components update`.

**Brave** — the official Flathub package builds for aarch64:

```
flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install --user flathub com.brave.Browser
```

Make it run natively on Wayland instead of through XWayland — Brave reads extra flags from a config file inside its flatpak sandbox:

```
flatpak override --user --socket=wayland com.brave.Browser
echo "--ozone-platform=wayland" > ~/.var/app/com.brave.Browser/config/brave-flags.conf
```

**Claude Code** — Anthropic's CLI ships a native Linux arm64 binary; the installer needs no root and lands in `~/.local/bin`:

```
curl -fsSL https://claude.ai/install.sh | bash
```

An AI pair programmer on a fanless €150 laptop is a strange sentence, but it works.

**Kubernetes tooling** — `kubectl`, `kubectx`, and `k9s` are all in the plain repos:

```
sudo pacman -S kubectl kubectx k9s
```

One Sway detail if you launch things with `wmenu` (`$mod+d`): it only lists executables on `PATH`, so flatpak apps are invisible to it. A two-line wrapper fixes that:

```
mkdir -p ~/.local/bin
printf '#!/bin/sh\nexec flatpak run com.brave.Browser "$@"\n' > ~/.local/bin/brave
chmod +x ~/.local/bin/brave
```

with `export PATH="$HOME/.local/bin:$PATH"` in `~/.zprofile` so the Sway session inherits it.

## Firefox renders blank images — the panfrost fix

At some point Firefox stopped showing images and icons: text rendered fine, pictures came out blank. Brave was unaffected. The difference is that Chromium blocklists this Mali GPU and silently falls back to software rendering, while Firefox optimistically runs GPU WebRender on the panfrost driver — which breaks exactly the image/texture path.

The fix is one switch in `about:config`:

```
gfx.webrender.software = true
```

Software WebRender is perfectly fluid at this screen size, and images are back.

## zram: swap for a 4 GB machine without killing the SD card

Four gigabytes of RAM, Chromium browsers, Electron apps — sooner or later the OOM killer starts eating your session. A swap file would grind the SD card down; compressed in-RAM swap costs nothing:

```
sudo pacman -S zram-generator
```

`/etc/systemd/zram-generator.conf`:

```
[zram0]
zram-size = ram
compression-algorithm = zstd
```

Then `systemctl daemon-reload && systemctl start systemd-zram-setup@zram0.service` (it starts itself on every subsequent boot). One caveat: this kernel's zram module lacks zstd, so the generator silently falls back to `lzo-rle`. That is fine — lzo-rle is the faster algorithm and still compresses around 2×. Check with `zramctl`.

## Encrypting the home directory with fscrypt

The machine boots from a microSD card. Anyone can pull that card out and read every file on it — SSH keys, cloud credentials, browser sessions. Full-disk LUKS is possible on this device but unpleasant (the kernel command line lives inside the signed kpart image, the passphrase prompt races the 30-second blank screen, and converting the root filesystem in place is a good way to lose it). ext4's native encryption via **fscrypt** gets you the protection that actually matters — data at rest — with none of that.

The mainline chromebook kernel ships `CONFIG_FS_ENCRYPTION=y`, so it is only:

```
sudo pacman -S fscrypt
sudo tune2fs -O encrypt /dev/mmcblk0p2
sudo fscrypt setup
```

Wire it into PAM so the home directory unlocks automatically at login — append to `/etc/pam.d/system-login`:

```
auth       optional   pam_fscrypt.so
session    optional   pam_fscrypt.so
```

and to `/etc/pam.d/passwd`:

```
password   optional   pam_fscrypt.so
```

Existing directories cannot be encrypted in place, so the migration is: create a new directory, encrypt it, copy everything, swap:

```
sudo mkdir /home/you.new && sudo chown you:you /home/you.new
sudo fscrypt encrypt /home/you.new --source=pam_passphrase --user=you
sudo rsync -aHAX /home/you/ /home/you.new/
sudo mv /home/you /home/you.old && sudo mv /home/you.new /home/you
```

Reboot, log in at the console — if your files are there, PAM unlock works. Only then `rm -rf /home/you.old` and run `fstrim /` so the old plaintext blocks are gone from the flash translation layer's point of view.

Two consequences worth knowing before you commit:

**SSH public-key logins land in a locked home after every reboot.** Key auth never presents a password, so PAM has nothing to derive the key from — you get a home full of base64 gibberish filenames and zsh greeting you like a new user (press `q`, do not let it create files). One password login — at the console, over SSH with password auth, or `fscrypt unlock /home/you` — unlocks it for every session until shutdown. And since `~/.ssh/authorized_keys` is itself inside the encrypted directory, sshd cannot read it while locked, which would lock your key out permanently. Move it outside — `/etc/ssh/sshd_config.d/20-fscrypt-keys.conf`:

```
AuthorizedKeysFile .ssh/authorized_keys /etc/ssh/authorized_keys.d/%u
```

with your public keys copied to `/etc/ssh/authorized_keys.d/you` *before* the first reboot.

**Encrypting is not retroactive.** Your keys already lived unencrypted on this card; forensically recoverable remnants may survive in unallocated flash. After the migration, rotate what matters: generate a fresh SSH keypair, and `gcloud auth revoke` / re-login. Ten minutes, and the remnants are worthless.

The protector is your login password, and someone holding the card can brute-force it offline — make it a real password.

## USB-C displays: the flip trick

External monitors over USB-C (DisplayPort alt mode) work — *sometimes*. The rk3399's `cdn-dp` controller plus the ChromeOS embedded controller negotiate alt mode reliably in only **one plug orientation** on mainline. If the monitor is not detected: unplug, **rotate the connector 180°**, plug again. That's it. That was weeks of "sometimes it works" resolved by a coin flip's worth of physics.

You can watch the negotiation in the journal — failure and success are unambiguous:

```
cdn-dp fec00000.dp: Not connected; disabling cdn     # failed attempt
cdn-dp fec00000.dp: Connected, not enabled; enabling cdn
```

The sequel gotcha: once DisplayPort alt mode is up, that port's USB-3 lanes belong to the display. A keyboard receiver or hub plugged into **the monitor's USB ports** (or the same USB-C port) fails to enumerate in an endless `attempt power cycle` loop. Peripherals go in the port on the *other side* of the laptop, always.

## Odds and ends

- **Screenshots**: `grim` (full screen) and `grim -g "$(slurp)"` (region) bound to `$mod+p` / `$mod+Shift+p`, with matching `screenshot` / `screenshot-area` wrappers in `~/.local/bin` so they are callable from wmenu too.
- **Phone hotspots**: the Marvell chip does 2.4 and 5 GHz only. A Galaxy hotspot defaulting to 6 GHz is simply invisible — set the phone's hotspot band to 2.4 GHz.
- **Keep a cheatsheet**: `~/CHEATSHEET.md` with the Sway bindings, aliases, and the traps above, plus `alias cheat='less ~/CHEATSHEET.md'`. On a machine you use intermittently, future-you will thank present-you.

## Where that leaves the machine

An end-of-life Chromebook now running: current Arch with a mainline kernel, Sway on Wayland, an encrypted home directory, compressed swap, Brave and Firefox rendering correctly, cloud and Kubernetes tooling, and an AI coding agent — all quiet, all fanless, all on a microSD card, with untouched ChromeOS one Ctrl-D away as a recovery environment. Not bad for hardware the manufacturer gave up on years ago.
