+++
title = 'Arch Linux ARM on the ASUS Chromebook Flip C101PA'
date = 2026-08-09T00:01:00+02:00
categories = ['linux', 'guides']
tags = ['arch-linux', 'chromebook', 'arm', 'linux', 'rockchip']
+++

The ASUS Chromebook Flip C101PA is a cheap, quiet, fanless ARM laptop that has been end-of-life on ChromeOS for years. It is still a perfectly good machine for browsing, writing, and light development — and it makes an excellent secondary Linux laptop if you are willing to install Arch Linux ARM on a microSD card.

The [official Arch Linux ARM guide](https://archlinuxarm.org/platforms/armv8/rockchip/asus-chromebook-flip-c101pa) is the starting point, but as of now it **no longer works as written**. The published rootfs ships the ancient 4.4 ChromeOS kernel, and current Arch userland (systemd) refuses to run on it — first boot fails with `Failed to mount early API filesystems` / `Freezing execution`. This guide bakes in the fix: replace the kernel and firmware with mainline **before** the first boot.

**Requirements:** a C101PA on the latest ChromeOS, a microSD card (8 GB+, fast one recommended), Wi-Fi, ~1 hour.

**⚠️ Enabling Developer Mode wipes all local ChromeOS data. Back up first.**

## 1. Enable Developer Mode

1. Power off. Hold **Esc + Refresh**, tap **Power**. The recovery screen appears.
2. Press **Ctrl-D** (no prompt is shown), confirm with Enter. The device wipes and reboots — this takes 10–15 minutes.
3. From now on, every boot shows the "OS verification is OFF" splash. Press **Ctrl-D** to boot ChromeOS, **Ctrl-U** to boot Linux from the SD card.

> ⚠️ **Never press Space** on that splash — it re-enables verification and wipes developer mode. Getting back to your Linux install is possible but tedious.

## 2. Allow booting from external media

Boot ChromeOS (guest session is fine), open crosh with **Ctrl+Alt+T**, then:

```
shell
sudo su
crossystem dev_boot_usb=1 dev_boot_signed_only=0
reboot
```

Both flags matter — without `dev_boot_signed_only=0`, pressing Ctrl-U just beeps.

## 3. Partition the SD card

Back in a ChromeOS root shell. Insert the SD card — it appears as `/dev/mmcblk1`.

> ⚠️ The internal eMMC is `/dev/mmcblk0`. Confirm with `ls /dev/mmcblk*` before writing anything. Writing to the wrong device destroys ChromeOS.

```
umount /dev/mmcblk1* 2>/dev/null
fdisk /dev/mmcblk1
```

In fdisk: `g` (new GPT), `w` (write). Then create the ChromeOS-style layout with `cgpt`:

```
cgpt create /dev/mmcblk1
cgpt add -i 1 -t kernel -b 8192 -s 65536 -l Kernel -S 1 -T 5 -P 10 /dev/mmcblk1
cgpt show /dev/mmcblk1        # note the START of "Sec GPT table" — call it XXXXX
cgpt add -i 2 -t data -b 73728 -s `expr XXXXX - 73728` -l Root /dev/mmcblk1
```

`partprobe` does not exist on ChromeOS, so use:

```
blockdev --rereadpt /dev/mmcblk1
mkfs.ext4 /dev/mmcblk1p2
```

If `mmcblk1p2` doesn't appear, eject and reinsert the card (and unmount whatever ChromeOS auto-mounts).

## 4. Install the rootfs

```
cd /tmp
curl -LO http://os.archlinuxarm.org/os/ArchLinuxARM-gru-latest.tar.gz
mkdir root
mount /dev/mmcblk1p2 root
tar -xf ArchLinuxARM-gru-latest.tar.gz -C root
```

## 5. Replace the 4.4 kernel with mainline — the critical step

**Do not boot yet.** The tarball's kernel will not boot current Arch. Browse `http://mirror.archlinuxarm.org/aarch64/core/` and note the exact filenames (**versions must match each other**):

- `linux-aarch64-<ver>-aarch64.pkg.tar.xz`
- `linux-aarch64-chromebook-<ver>-aarch64.pkg.tar.xz`
- `linux-firmware-<ver>-any.pkg.tar.xz` (or, if split upstream, `linux-firmware-marvell` + `linux-firmware-whence`)

Without the firmware package, Wi-Fi has no firmware blob (`mrvl/pcieusb8997_combo_v4.bin`) and will not associate.

Download and extract all of them over the rootfs:

```
curl -LO http://mirror.archlinuxarm.org/aarch64/core/<each-filename>
for f in linux-*.pkg.tar.xz; do
  tar -xf "$f" -C root/ --warning=no-unknown-keyword \
    --exclude=.PKGINFO --exclude=.BUILDINFO --exclude=.MTREE --exclude=.INSTALL
done
```

Now do the two steps pacman would normally do for you.

**Generate the module index.** Skip this and the display driver (a kernel module) won't load — you'll boot to a black screen. Use the exact directory name, hyphens and all:

```
ls root/usr/lib/modules/          # e.g. 7.1.2-2-aarch64-ARCH
depmod -b /tmp/root <that-exact-version-string>
```

**Flash the mainline kernel** to the kernel partition:

```
dd if=root/boot/vmlinux.kpart of=/dev/mmcblk1p1
umount root
sync
reboot
```

## 6. First boot

At the white splash, press **Ctrl-U**. Expect a black screen for up to ~30 seconds — there is no early console on mainline — before the login prompt. Log in as `root` / `root`.

Connect to Wi-Fi and make it persistent:

```
wifi-menu                  # pick network, enter passphrase
netctl list
netctl enable <profile>    # auto-reconnect on every boot
```

Hand everything over to pacman (this is what makes future updates automatic):

```
pacman-key --init
pacman-key --populate archlinuxarm
pacman -Sy
pacman -S --overwrite '*' linux-aarch64 linux-aarch64-chromebook linux-firmware
```

Answer **y** to "Remove linux-gru?" (the dead 4.4 kernel) and **y** to "flash the kernel to the kernel partition" — that prompt replaces the manual `dd` from now on. Then:

```
pacman -Syu
passwd                     # change root's password
```

Create your user:

```
useradd -m -G wheel,video,audio -s /bin/bash yourname
passwd yourname
pacman -S sudo
EDITOR=nano visudo         # uncomment: %wheel ALL=(ALL:ALL) ALL
```

## 7. Graphical environment (Sway + optional XFCE)

```
pacman -S mesa sway foot wmenu swaybg \
  xorg-server xf86-input-libinput xfce4 xfce4-goodies \
  ly brightnessctl pamixer waybar mako grim slurp wl-clipboard \
  ttf-font-awesome ttf-nerd-fonts-symbols noto-fonts noto-fonts-emoji firefox
systemctl enable ly@tty2.service     # ly@.service is a template unit
```

Reboot. The `ly` greeter appears on tty2 — **F1** switches between Sway and XFCE sessions. Log in as your user, not root — Sway refuses root/`su` sessions with "Failed to start a DRM session".

Minimal Sway additions in `~/.config/sway/config` (the `set $mod` line must come before anything using it; Mod4 = the Search key / Windows key):

```
set $mod Mod4
bindsym XF86MonBrightnessUp exec brightnessctl set +5%
bindsym XF86MonBrightnessDown exec brightnessctl set 5%-
bindsym XF86AudioRaiseVolume exec pamixer -i 5
bindsym XF86AudioLowerVolume exec pamixer -d 5
bindsym XF86AudioMute exec pamixer -t
bindsym $mod+Shift+s exec grim -g "$(slurp)" ~/screenshot-$(date +%s).png
bar { swaybar_command waybar }
```

## 8. Hardware quirks worth knowing

**Audio** — one-time card setup. Output is labeled "Headphones" even for the internal speakers; useful Master volume range is 0–9:

```
ALSA_CONFIG_UCM=/opt/alsa/ucm alsaucm -c rk3399-gru-sound set _verb HiFi
```

**Backlight** — create `/etc/udev/rules.d/backlight.rules` (your user must be in the `video` group):

```
SUBSYSTEM=="backlight",RUN+="/usr/bin/chgrp video /sys/class/backlight/%k/brightness /sys/class/backlight/%k/bl_power",RUN+="/usr/bin/chmod 664 /sys/class/backlight/%k/brightness /sys/class/backlight/%k/bl_power"
```

**Video playback** — browser decoding is CPU-only on this platform; ~720p is the realistic ceiling. The h264ify extension helps YouTube; `mpv` is much lighter than in-browser playback.

**Harmless boot noise** — `nxp/rgpower_WW.bin failed with error -2` (optional regulatory tables) and `chromeos_arm: invalid ... descriptor` lines are safe to ignore.

## Rescue: black screen after an upgrade

This is the single most common failure and it has a verified fix. `pacman -Syu` installed a new kernel's modules but the kernel image itself never got flashed to the kernel partition, so the old kernel keeps booting and can't find matching modules for its display driver.

Boot ChromeOS with **Ctrl-D**, open a root shell:

```
cd /tmp && mkdir -p root
mount /dev/mmcblk1p2 root
dd if=root/boot/vmlinux.kpart of=/dev/mmcblk1p1   # pacman already built the new kpart
umount root && sync && reboot
```

Ctrl-U, wait ~30 s, done.

**Prevention:** whenever an upgrade touches `linux-aarch64`, answer **y** to the "flash the kernel to the kernel partition" prompt. If you missed it, run `dd if=/boot/vmlinux.kpart of=/dev/mmcblk1p1` from within Arch before rebooting.

For anything else: everything is fixable from ChromeOS. Mount `/dev/mmcblk1p2`, check that `usr/lib/modules/` contains a directory matching the kernel version, run `depmod -b /tmp/root <version>` if `modules.dep` is missing, and re-`dd` the kpart as above. ChromeOS stays untouched on the eMMC as a permanent recovery environment — which is the quiet superpower of this dual-boot layout.
