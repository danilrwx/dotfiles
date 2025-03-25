external_menu () {
  tr -d '\t' | remove_ansi_escapes | dmenu -b -fn 'IosevkaTerm Nerd Font-14' -sb '#000000' -sf '#ffffff' -nb '#ffffff' -nf '#000000' -l 30 -p "$1"
}
