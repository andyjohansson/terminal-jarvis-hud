#!/usr/bin/env zsh
# ======================================================================
#  JARVIS HUD  ·  boot sequence demo (for screenshots and showing off)
#
#  zsh tools/demo.zsh          animated boot, ~5 seconds
#  zsh tools/demo.zsh --fast   jump straight to the final frame
# ======================================================================

zmodload zsh/zselect zsh/mathfunc 2>/dev/null
setopt localoptions no_nomatch

FAST=0; [[ "$1" == "--fast" || -n "$JARVIS_FAST" ]] && FAST=1

# ---------- palette ----------
C=$'\e[38;2;0;216;255m'    # cyan
I=$'\e[38;2;125;238;255m'  # ice
W=$'\e[38;2;233;251;255m'  # white-ish
T=$'\e[38;2;212;243;255m'  # text
M=$'\e[38;2;111;147;165m'  # muted
D=$'\e[38;2;47;85;102m'    # dim
DD=$'\e[38;2;22;44;56m'    # deep
G=$'\e[38;2;255;179;71m'   # gold
R=$'\e[38;2;255;77;94m'    # red
N=$'\e[38;2;61;255;184m'   # green
B=$'\e[1m'; X=$'\e[0m'

# ---------- helpers ----------
nap()   { (( FAST )) || zselect -t ${1:-3}; }          # centiseconds
type_out() {                                            # type text char by char
  local s="$1" i
  if (( FAST )); then print -n -- "$s"; return; fi
  for (( i = 1; i <= ${#s}; i++ )); do print -n -- "${s[i]}"; zselect -t 1; done
}
cleanup() { print -n $'\e[?25h'; }
trap cleanup EXIT INT TERM
print -n $'\e[?25l'                                     # hide cursor

bar() {                                     # bar <pct> <width> [invert]
  local pct=$1 w=${2:-24} fill col i out="" lvl
  (( pct < 0 )) && pct=0; (( pct > 100 )) && pct=100
  fill=$(( (pct * w + 50) / 100 ))
  lvl=$pct; [[ -n $3 ]] && lvl=$(( 100 - pct ))   # invert: low is bad
  if   (( lvl >= 90 )); then col=$R
  elif (( lvl >= 75 )); then col=$G
  else                       col=$C; fi
  for (( i = 1; i <= w; i++ )); do
    (( i <= fill )) && out+="${col}▰" || out+="${DD}▱"
  done
  print -n -- "${out}${X}"
}

# ---------- live readouts (all local, all fast) ----------
NCPU=$(sysctl -n hw.ncpu 2>/dev/null || echo 1)
CPU=$(ps -A -o %cpu 2>/dev/null | awk -v n="$NCPU" 'NR>1{s+=$1} END{v=int(s/n); print (v>100?100:v)}')
MEMFREE=$(memory_pressure 2>/dev/null | awk -F': ' '/free percentage/{gsub("%","",$2); print $2}')
MEM=$(( 100 - ${MEMFREE:-50} ))
DISK=$(df -k /System/Volumes/Data 2>/dev/null | awk 'NR==2{gsub("%","",$5); print $5}')
[[ -z "$DISK" ]] && DISK=$(df -k / | awk 'NR==2{gsub("%","",$5); print $5}')
BATT=$(pmset -g batt 2>/dev/null | grep -Eo '[0-9]+%' | head -1 | tr -d '%')
CHARGING=$(pmset -g batt 2>/dev/null | grep -q 'AC Power' && echo "charging" || echo "on battery")
OSV="macOS $(sw_vers -productVersion 2>/dev/null)"
CHIP=$(sysctl -n machdep.cpu.brand_string 2>/dev/null)
HOSTN="${HOST%%.*}"
NAME="${JARVIS_NAME:-${${(s: :)$(id -F 2>/dev/null)}[1]:-$USER}}"
HOUR=${(%):-%D{%H}}
if   (( HOUR < 5 ));  then GREET="Working late, $NAME."
elif (( HOUR < 12 )); then GREET="Good morning, $NAME."
elif (( HOUR < 18 )); then GREET="Good afternoon, $NAME."
else                       GREET="Good evening, $NAME."; fi
if [[ "$JARVIS_LANG" == "sv" ]]; then
  if   (( HOUR < 5 ));  then GREET="Sent uppe, $NAME."
  elif (( HOUR < 10 )); then GREET="God morgon, $NAME."
  elif (( HOUR < 18 )); then GREET="Välkommen tillbaka, $NAME."
  else                       GREET="God kväll, $NAME."; fi
fi

# ---------- arc reactor ----------
# Drawn with half-block "pixels" (two per character cell) so the rings
# come out round. Layers light up one by one as <stage> goes 0 -> 4.
RC=13; RR=12.5                                  # center column / pixel row
pix() {                                         # pix <x> <y> <stage> -> REPLY="r;g;b" or ""
  local dx=$(( $1 - RC )) dy=$(( $2 - RR )) d ang off="15;36;48"
  d=$(( sqrt(dx * dx + dy * dy) ))
  REPLY=""
  if   (( d < 3.0 ));  then (( $3 >= 1 )) && REPLY="233;251;255" || REPLY=$off
  elif (( d < 4.2 ));  then (( $3 >= 1 )) && REPLY="125;238;255" || REPLY=$off
  elif (( d >= 5.4 && d < 7.4 )); then (( $3 >= 2 )) && REPLY="92;230;255" || REPLY=$off
  elif (( d >= 8.6 && d < 11.0 )); then
    ang=$(( atan(dy, dx) * 180 / 3.14159265 + 180 ))
    if (( ang - int(ang / 36) * 36 < 29 )); then
      (( $3 >= 3 )) && REPLY="0;216;255" || REPLY=$off
    fi
  elif (( d >= 11.8 && d < 12.6 )); then (( $3 >= 4 )) && REPLY="47;85;102" || REPLY=$off
  fi
}
reactor_line() {                                # reactor_line <row 0-12> <stage>
  local row=$1 stage=$2 x top bot out=""
  for (( x = 0; x <= 26; x++ )); do
    pix $x $(( row * 2 ))     $stage; top=$REPLY
    pix $x $(( row * 2 + 1 )) $stage; bot=$REPLY
    if   [[ -z $top && -z $bot ]]; then out+=$'\e[0m '
    elif [[ -n $top && -z $bot ]]; then out+=$'\e[0m\e[38;2;'"${top}m▀"
    elif [[ -z $top && -n $bot ]]; then out+=$'\e[0m\e[38;2;'"${bot}m▄"
    elif [[ $top == $bot ]];       then out+=$'\e[0m\e[38;2;'"${top}m█"
    else out+=$'\e[38;2;'"${top}m"$'\e[48;2;'"${bot}m▀"
    fi
  done
  print -n -- "${out}${X}"
}

# right-hand panel, one line per reactor row (rows -6..6)
panel=(
  ""
  "${C}${B}J . A . R . V . I . S .${X}"
  "${M}just a rather very intelligent system${X}"
  ""
  "${T}${GREET}${X}"
  ""
  "${M}HOST    ${T}${HOSTN}${X}"
  "${M}SYSTEM  ${T}${OSV}${X}"
  "${M}CORE    ${T}${CHIP:-Apple silicon} ${D}· ${T}${NCPU} cores${X}"
  "${M}TIME    ${T}$(date '+%Y-%m-%d  %H:%M')${X}"
  ""
  "${D}────────────────────────────────────${X}"
  ""
)

draw_header() {                          # draw_header <stage>
  local y i=1
  for (( y = 0; y <= 12; y++ )); do
    print -n -- "  "; reactor_line $y $1
    print -- "    ${panel[i]}"
    (( i++ ))
  done
}

# ======================================================================
clear
print ""

# 1. Reactor ignition: rings light up from the core outwards
if (( FAST )); then
  draw_header 4
else
  for stage in 0 1 2 3 4; do
    print -n $'\e[H\n'
    draw_header $stage
    nap 12
  done
fi

# 2. Boot sequence
print ""
steps=(
  "Initializing neural interface"
  "Calibrating holographic display"
  "Syncing knowledge vault"
  "Establishing secure uplink"
  "Loading personality matrix"
)
spin=(⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏)
for s in $steps; do
  dots=${(l:$(( 38 - ${#s} ))::.:)}
  if (( FAST )); then
    print -- "  ${N}[ OK ]${X} ${T}${s}${X} ${DD}${dots}${X} ${M}done${X}"
    continue
  fi
  print -n -- "  ${C}[    ]${X} "; type_out "${T}${s}${X} "
  for k in {1..8}; do
    print -n -- "${C}${spin[$(( (k - 1) % 10 + 1 ))]}${X}"; zselect -t 3; print -n $'\b'
  done
  print -- $'\r'"  ${N}[ OK ]${X} ${T}${s}${X} ${DD}${dots}${X} ${M}done${X}"
done

# 3. Diagnostics
print ""
print -- "  ${D}── ${M}DIAGNOSTICS${D} ────────────────────────────────────────────────${X}"
diag() {                                 # diag <label> <pct> <suffix> [invert]
  local label=$1 target=$2 suffix=$3 inv=$4 p
  if (( FAST )); then
    print -- "  ${M}${(r:7:)label}${X}$(bar $target 24 $inv) ${T}${(l:3:)target}%${X}  ${D}${suffix}${X}"
    return
  fi
  for (( p = 0; p <= target; p += 4 )); do
    print -n -- $'\r'"  ${M}${(r:7:)label}${X}$(bar $p 24 $inv) ${T}${(l:3:)p}%${X}"; zselect -t 1
  done
  print -- $'\r'"  ${M}${(r:7:)label}${X}$(bar $target 24 $inv) ${T}${(l:3:)target}%${X}  ${D}${suffix}${X}"
}
diag "CPU"   ${CPU:-12}  "${NCPU} cores"
diag "MEMORY" ${MEM:-48} "pressure nominal"
diag "DISK"  ${DISK:-40} "data volume"
[[ -n "$BATT" ]] && diag "POWER" $BATT "$CHARGING" invert

# 4. Spectrum (the 16 terminal colors as one strip)
print ""
print -- "  ${D}── ${M}SPECTRUM${D} ───────────────────────────────────────────────────${X}"
strip1="" strip2=""
for n in {0..7};  do strip1+=$'\e['"$((40 + n))m      "; done
for n in {0..7};  do strip2+=$'\e['"$((100 + n))m      "; done
print -- "  ${strip1}${X}"
print -- "  ${strip2}${X}"

# 5. Sign-off
print ""
print -n -- "  ${C}◆${X} "
type_out "${I}All systems online.${X} ${T}Ready when you are.${X}"
print ""
print ""
