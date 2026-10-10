# ======================================================================
#  JARVIS HUD  ·  start banner for zsh
#  Sourced from ~/.zshrc. Prints a short status greeting in new windows.
#
#  Settings (set in ~/.zshrc BEFORE this file is sourced):
#    JARVIS_NAME="Andy"      name in the greeting (default: first name from macOS)
#    JARVIS_LANG="sv"        sv or en (default: en)
#    JARVIS_BANNER=0         turn the banner off
# ======================================================================

jarvis_banner() {
  [[ "${JARVIS_BANNER:-1}" == "0" ]] && return
  [[ -o interactive ]] || return

  local c=$'\e[38;2;0;216;255m'      # cyan
  local i=$'\e[38;2;125;238;255m'    # ice
  local t=$'\e[38;2;212;243;255m'    # text
  local d=$'\e[38;2;47;85;102m'      # dim
  local m=$'\e[38;2;111;147;165m'    # muted
  local g=$'\e[38;2;255;179;71m'     # gold
  local b=$'\e[1m' r=$'\e[0m'

  local name="${JARVIS_NAME:-${${(s: :)$(id -F 2>/dev/null)}[1]:-$USER}}"
  local hour=${(%):-%D{%H}}
  local lang="${JARVIS_LANG:-en}"
  local greet status_line

  if [[ "$lang" == "sv" ]]; then
    if   (( hour < 5 ));  then greet="Sent uppe, $name"
    elif (( hour < 10 )); then greet="God morgon, $name"
    elif (( hour < 18 )); then greet="Välkommen tillbaka, $name"
    else                       greet="God kväll, $name"; fi
    status_line="Alla system är online."
  else
    if   (( hour < 5 ));  then greet="Working late, $name"
    elif (( hour < 12 )); then greet="Good morning, $name"
    elif (( hour < 18 )); then greet="Good afternoon, $name"
    else                       greet="Good evening, $name"; fi
    status_line="All systems online."
  fi

  # Fast system readouts (no network, no slow commands)
  local os="macOS $(sw_vers -productVersion 2>/dev/null)"
  local host="${HOST%%.*}"
  local up="$(uptime 2>/dev/null | sed -E 's/.*up ([^,]*(, *[0-9]+:[0-9]+)?).*/\1/; s/  */ /g')"
  local batt="$(pmset -g batt 2>/dev/null | grep -Eo '[0-9]+%' | head -1)"
  local now=${(%):-%D{%Y-%m-%d  %H:%M}}

  print -r -- ""
  print -r -- "${d}┌──────────────────────────────────────────────${r}"
  print -r -- "${d}│${r} ${c}${b}◆ J.A.R.V.I.S.${r}  ${m}just a rather very intelligent system${r}"
  print -r -- "${d}│${r}"
  print -r -- "${d}│${r} ${t}${greet}.${r} ${i}${status_line}${r}"
  print -r -- "${d}│${r}"
  print -r -- "${d}│${r} ${m}TIME${r}    ${t}${now}${r}"
  print -r -- "${d}│${r} ${m}SYSTEM${r}  ${t}${os}${r} ${d}·${r} ${t}${host}${r}"
  [[ -n "$up" ]]   && print -r -- "${d}│${r} ${m}UPTIME${r}  ${t}${up}${r}"
  [[ -n "$batt" ]] && print -r -- "${d}│${r} ${m}POWER${r}   ${g}${batt}${r}"
  print -r -- "${d}└──────────────────────────────────────────────${r}"
}

jarvis_banner
