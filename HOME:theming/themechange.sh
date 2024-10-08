#!/bin/sh

if [ $# -eq 0 ]; then
  if grep -q dark "$HOME/theme"; then
    theme=light
  else
    theme=dark
  fi
else
  theme="$1"
fi

if [ "$theme" = "light" ]; then
  # wallpaper
  python3 $HOME/desktop_img.py light &

  # os
  osascript -e 'tell application "System Events" to tell appearance preferences to set dark mode to false'

  # vscode
  # gsed -i -e 's/"workbench.colorTheme": ".*"/"workbench.colorTheme": "Rosé Pine Dawn"/g' "$HOME/Library/Application Support/Code/User/settings.json"

  # kitty
  kitty @ set-colors -a -c "$HOME/.config/kitty/dawn.conf"

  # sioyek
#  if ps aux | rg '[s]ioyek' >/dev/null; then
#    sioyek --execute-command setconfig_custom_text_color --execute-command-data "0.337 0.32 0.462745" >/dev/null 2>&1
#    sioyek --execute-command setconfig_custom_background_color --execute-command-data "0.97647 0.9569 0.933" >/dev/null 2>&1
#  fi

  # neovim
  echo 'light' > "$HOME/theme"
else
  python3 $HOME/desktop_img.py dark &
  osascript -e 'tell application "System Events" to tell appearance preferences to set dark mode to true'
  # gsed -i -e 's/"workbench.colorTheme": ".*"/"workbench.colorTheme": "Rosé Pine Moon"/g' "$HOME/Library/Application Support/Code/User/settings.json"
  kitty @ set-colors -a -c "$HOME/.config/kitty/everforest.conf"
#  if ps aux | rg '[s]ioyek' >/dev/null; then
#    sioyek --execute-command setconfig_custom_text_color --execute-command-data "0.879 0.87 0.95" >/dev/null 2>&1
#    sioyek --execute-command setconfig_custom_background_color --execute-command-data "0.137 0.13 0.2" >/dev/null 2>&1
#  fi
  echo 'dark' > "$HOME/theme"
fi
