# Discord-Anti-Idle-Script

Only works on X11. Sadly Wayland does not support many of the APIs that are
required to make this work in a seamless manner. I'm sure there's a method of
achieving it but I'm not terribly interested in sinking the time into figuring
it out.

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
