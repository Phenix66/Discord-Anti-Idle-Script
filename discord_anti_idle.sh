#!/bin/bash
set -euo pipefail

# Configure appropriately depending on the AFK timer of your Discord server.
# The amount of time after which the command is triggered
IDLE_TIME_MINUTES=15
# Time between idle checks
SLEEP_TIME_MINUTES=5

# The default (Ctrl+/) opens and closes the keyboard shortcuts window.
# Should be fairly non-intrusive but other shortcuts could be used here, such
# as keying up and releasing PTT, if the behavior is undesirable.
ANTI_IDLE_KEYS="ctrl+slash"

# Location of the empty file that will be created whenever the user is idle
# on a system using Wayland.
WAYLAND_IDLE_FILE="${HOME}/isidle"

# Script dependencies, do not modify.
REQUIRED_TOOLS=(
    "xdotool"
    "wmctrl"
)

check_for_dependencies() {
    local valid="true"
    local missing=()

    if is_wayland; then
        REQUIRED_TOOLS+=("swayidle")
    else
        REQUIRED_TOOLS+=("xprintidle")
    fi

    for utility in "${REQUIRED_TOOLS[@]}"; do
        if ! command -v $utility &>/dev/null; then
            missing+=("$utility")
            valid="false"
        fi
    done

    if [[ $valid == "false" ]]; then
        echo "ERROR: Missing required command line tools!"
        echo "Missing tools: ${missing[@]}"
        exit 1
    fi
}

is_screen_locked() {
  if dbus-send --session --dest=org.freedesktop.ScreenSaver \
        --type=method_call --print-reply /org/freedesktop/ScreenSaver \
        org.freedesktop.ScreenSaver.GetActive | grep -q 'boolean true' &> /dev/null;
  then
    return 0
  else
    return 1
  fi
}

is_wayland() {
    if [[ -v "WAYLAND_DISPLAY" && -n $WAYLAND_DISPLAY ]] ||
       [[ $XDG_SESSION_TYPE == "wayland" ]] ||
       [[ $DESKTOP_SESSION =~ .*wayland ]]
    then
        return 0
    fi
    return 1
}

launch_discord() {
    if command -v flatpak && flatpak list | grep -q com.discordapp.Discord &>/dev/null; then
        /usr/bin/flatpak run --branch=stable --arch=x86_64 --command=com.discordapp.Discord com.discordapp.Discord &
    elif command -v discord &>/dev/null; then
        discord &
    else
        echo "Could not determine method with which to launch Discord!"
        echo "Please ensure Discord is installed via either Flatpak or your distribution's"
        echo "package manager and try again."
        exit 1
    fi
}

trigger_anti_idle_cmd() {
    # Get the currently active window
    local current_window="$(xdotool getwindowfocus getwindowname)"

    # Activate the Discord window
    wmctrl -a Discord

    # Send the anti-idle command. The default behavior sends it twice so actions
    # such as opening the keyboard shortcuts window also automatically close it.
    xdotool key --clearmodifiers "$ANTI_IDLE_KEYS"
    xdotool key --clearmodifiers "$ANTI_IDLE_KEYS"

    # Reactivate the previously active window
    wmctrl -a "$current_window"

    # When launched from the desktop shortcut, this will log to the journal.
    # View with `journalctl -b` to validate it is working properly.
    echo "Triggered Discord anti-idle command successfully."
}

monitor_session_for_idle() {
    if is_wayland; then
        swayidle -w timeout $IDLE_TIME_SEC "touch ${WAYLAND_IDLE_FILE}" resume "rm ${WAYLAND_IDLE_FILE}" &
    fi

    while sleep $SLEEP_TIME_SEC; do
        if ! wmctrl -l | grep -q Discord &>/dev/null; then
            if is_wayland; then
                pkill swayidle
            fi
            # Discord exited, exit script
            exit 0
        fi
        if ! is_screen_locked; then
            if is_wayland; then
                [[ -f $WAYLAND_IDLE_FILE ]] && trigger_anti_idle_cmd
            else
                idle=$(xprintidle)
                if [[ $idle -ge $IDLE_TIME_MS ]]; then
                    trigger_anti_idle_cmd
                fi
            fi
        fi
    done
}

IDLE_TIME_SEC=$((IDLE_TIME_MINUTES*60))
IDLE_TIME_MS=$((IDLE_TIME_SEC*1000))
SLEEP_TIME_SEC=$((SLEEP_TIME_MINUTES*60))

check_for_dependencies
launch_discord
monitor_session_for_idle
