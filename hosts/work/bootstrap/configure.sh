#!/usr/bin/env bash
# configure.sh — Configure macOS work machine

if [[ "$SHELL" != "/bin/zsh" ]]; then
  chsh -s /bin/zsh
fi
