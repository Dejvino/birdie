# Birdie

Alarm app capable of waking up the system from suspended state. Designed for Linux phones.

![Screenshot](screenshot.png)

## Features
- system wakes up from power saving mode (suspend) to play the alarm
- single alarm
- alarm is repeated for selected days of the week
- snooze button
- pleasant wake up sound (included)
- gradual volume increase

## Install from source:

```
# on Mobian/Debian:
sudo apt install gcc make checkinstall
make install-deb

# or generic:
make install
```

## Uninstall:

```
# on Mobian/Debian:
sudo dpkg -r wake-mobile

# or generic:
make uninstall
```

# Notes
Forked from [Wake Mobile](https://gitlab.gnome.org/kailueke/wake-mobile), a proof-of-concept alarm app that uses systemd timers to wake up the system.


