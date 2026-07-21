#!/bin/bash
set -euo pipefail

# Configure appropriately depending on the AFK timer of your Discord server.
# The amount of time after which the command is triggered
IDLE_TIME_MINUTES=5
# Time between idle checks
SLEEP_TIME_MINUTES=1

# Derived from above, do not modify
IDLE_TIME_SEC=$((IDLE_TIME_MINUTES*60))
IDLE_TIME_MS=$((IDLE_TIME_SEC*1000))
SLEEP_TIME_SEC=$((SLEEP_TIME_MINUTES*60))

# The default (Ctrl+/) opens and closes the keyboard shortcuts window.
# Should be fairly non-intrusive but other shortcuts could be used here, such
# as keying up and releasing PTT, if the behavior is undesirable.
ANTI_IDLE_KEYS="ctrl+slash"

# The key codes for above. See /usr/include/linux/input-event-codes.h
ANTI_IDLE_KEY_CODES=(
    "29:1" # LCtrl down
    "53:1" # Forward slash down
    "53:0" # Forward slash up
    "29:0" # LCtrl up
)

# Location of the empty file that will be created whenever the user is idle
# on a system using Wayland.
WAYLAND_IDLE_FILE="${HOME}/isidle"

# Script dependencies, do not modify.
REQUIRED_WAYLAND_TOOLS=(
    "kdotool"
    "swayidle"
    "wmctrl"
    "ydotool"
)
REQUIRED_X11_TOOLS=(
    "xdotool"
    "xprintidle"
    "wmctrl"
)

check_for_dependencies() {
    local valid="true"
    local missing=()

    if is_wayland; then
        required=("${REQUIRED_WAYLAND_TOOLS[@]}")
    else
        required=("${REQUIRED_X11_TOOLS[@]}")
    fi

    for utility in "${required[@]}"; do
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
    local current_window=""
    if is_wayland; then
        current_window="$(kdotool getactivewindow)"
    else
        current_window="$(xdotool getwindowfocus getwindowname)"
    fi

    # Activate the Discord window
    wmctrl -a Discord

    # Send the anti-idle command. The default behavior sends it twice so actions
    # such as opening the keyboard shortcuts window also automatically close it.
    if is_wayland; then
        ydotool key "${ANTI_IDLE_KEY_CODES[@]}"
        ydotool key "${ANTI_IDLE_KEY_CODES[@]}"
    else
        xdotool key --clearmodifiers "$ANTI_IDLE_KEYS"
        xdotool key --clearmodifiers "$ANTI_IDLE_KEYS"
    fi

    # Reactivate the previously active window
    if is_wayland; then
        kdotool windowactivate "$current_window"
    else
        wmctrl -a "$current_window"
    fi

    # When launched from the desktop shortcut, this will log to the journal.
    # View with `journalctl -b` to validate it is working properly.
    echo "Triggered Discord anti-idle command successfully."
}

monitor_session_for_idle() {
    if is_wayland; then
        swayidle -w timeout $IDLE_TIME_SEC "touch ${WAYLAND_IDLE_FILE}" resume "rm ${WAYLAND_IDLE_FILE}" &
        # Just in case there is an uncleaned up process
        pkill ydotoold || true
        ydotoold &
    fi

    while sleep $SLEEP_TIME_SEC; do
        if ! wmctrl -l | grep -q Discord &>/dev/null; then
            # Discord exited, clean up and exit script
            if is_wayland; then
                pkill swayidle
                pkill ydotoold
            fi

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

check_for_dependencies
launch_discord
monitor_session_for_idle
