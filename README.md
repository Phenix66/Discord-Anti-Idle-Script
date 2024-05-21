# Discord-Anti-Idle-Script

## Why this exists

I created this for one specific purpose, to keep myself from being kicked to the
AFK channel while playing video games in my Windows VM. The Linux host where I run
Discord has no way of picking up my keystrokes and other activity because I perform
PCI passthrough of an entire USB root device to the Windows VM (in addition to the
dedicated GPU).

## How to use

You may want to execute it manually from a terminal the first time to ensure you
have all the correct tools installed on your system (it will do a self-check on
startup). After that, just update your Discord desktop shortcut to point to this
script. An example `.desktop` file is included in this repo.

The script automatically launches Discord then goes into a monitor mode. It also
automatically exits once it detects that Discord is no longer running.
