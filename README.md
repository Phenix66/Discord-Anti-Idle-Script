# Discord-Anti-Idle-Script

Tested on Wayland with KDE and X11. YMMV on other combinations. I welcome PRs.

## Why this exists

I created this for one specific purpose, to keep myself from being kicked to the
AFK channel while playing video games in my Windows VM. The Linux host where I run
Discord has no way of picking up my keystrokes and other activity because I perform
PCI passthrough of an entire USB root device to the Windows VM (in addition to the
dedicated GPU).

## How to use

You may want to execute it manually from a terminal the first time to ensure you
have all the correct tools installed on your system (it will do a self-check on
startup). After that, copy the `.desktop` file to `/home/user/.local/share/applications/`.

The script automatically launches Discord then goes into a monitor mode. It also
automatically exits once it detects that Discord is no longer running.

### Wayland

Wayland requires a few more setup steps than X11. Perform the following:

1. Add your user to the `input` group:

   ```sh
   sudo usermod -aG input "$USER"
   ```

2. Create `/etc/udev/rules.d/60-uinput.rules`:

   ```
   KERNEL=="uinput", GROUP="input", MODE="0660", OPTIONS+="static_node=uinput"
   ```

3. Reload udev rules and ensure the `uinput` module is loaded (the
   `static_node` option only applies on next module load):

   ```sh
   sudo udevadm control --reload-rules
   sudo modprobe -r uinput && sudo modprobe uinput
   ```

   Log out and back in (or `newgrp input`) so the group change takes
   effect for your session.
