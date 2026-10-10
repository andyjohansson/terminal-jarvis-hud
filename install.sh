#!/usr/bin/env zsh
# ======================================================================
#  JARVIS HUD  ·  installer for macOS Terminal + zsh
#  Safe to run more than once. Backs up anything it replaces.
# ======================================================================
set -e

REPO="${0:A:h}"
CONF="$HOME/.config"
JARVIS_DIR="$CONF/jarvis"
ZSHRC="$HOME/.zshrc"
STAMP="$(date +%Y%m%d-%H%M%S)"
MARK_START="# >>> jarvis-hud >>>"
MARK_END="# <<< jarvis-hud <<<"

cyan=$'\e[38;2;0;216;255m'; gold=$'\e[38;2;255;179;71m'; r=$'\e[0m'
say()  { print -r -- "${cyan}◆${r} $*"; }
warn() { print -r -- "${gold}!${r} $*"; }

# 1. Terminal profile
say "Importing Terminal profile \"Jarvis HUD\""
open "$REPO/Jarvis HUD.terminal"
sleep 1
defaults write com.apple.Terminal "Default Window Settings" -string "Jarvis HUD"
defaults write com.apple.Terminal "Startup Window Settings" -string "Jarvis HUD"

# 2. Starship config
mkdir -p "$CONF" "$JARVIS_DIR"
if [[ -f "$CONF/starship.toml" && ! -L "$CONF/starship.toml" ]]; then
  if ! cmp -s "$CONF/starship.toml" "$REPO/starship/starship.toml"; then
    cp "$CONF/starship.toml" "$CONF/starship.toml.bak-$STAMP"
    warn "Existing starship.toml backed up to starship.toml.bak-$STAMP"
  fi
fi
cp "$REPO/starship/starship.toml" "$CONF/starship.toml"
say "Installed ~/.config/starship.toml"

# 3. Banner
cp "$REPO/banner/jarvis-banner.zsh" "$JARVIS_DIR/jarvis-banner.zsh"
say "Installed ~/.config/jarvis/jarvis-banner.zsh"

# 4. ~/.zshrc block (replaced on every run, never duplicated)
touch "$ZSHRC"
if grep -qF "$MARK_START" "$ZSHRC"; then
  cp "$ZSHRC" "$ZSHRC.bak-$STAMP"
  sed -i '' "/$MARK_START/,/$MARK_END/d" "$ZSHRC"
fi
cat >> "$ZSHRC" <<EOF

$MARK_START
# JARVIS_NAME="Andy"   # name in the greeting
# JARVIS_LANG="sv"     # sv or en
# JARVIS_BANNER=0      # turn the banner off
[[ -f "\$HOME/.config/jarvis/jarvis-banner.zsh" ]] && source "\$HOME/.config/jarvis/jarvis-banner.zsh"
[[ -d "\$HOME/.local/bin" && ":\$PATH:" != *":\$HOME/.local/bin:"* ]] && export PATH="\$HOME/.local/bin:\$PATH"
command -v starship >/dev/null && eval "\$(starship init zsh)"
$MARK_END
EOF
say "Updated ~/.zshrc"

# 5. Starship itself
if ! command -v starship >/dev/null; then
  warn "Starship is not installed. Install it with one of:"
  print -r -- "    brew install starship"
  print -r -- "    curl -sS https://starship.rs/install.sh | sh -s -- -b ~/.local/bin"
fi

say "Done. Open a new Terminal window to see it."
