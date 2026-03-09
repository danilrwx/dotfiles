# Statusbar loop
while true; do
   xsetroot -name "$( date +"%F %R" )"
   sleep 1m    # Update time every minute
done &

# Autostart section
firefox & 
udiskie &
dunst &
feh --bg-scale ~/Backgrounds/1.jpg &

setxkbmap -model pc105 -layout us,ru -option grp:alt_shift_toggle

#exec ~/dotfiles/scripts/run-dwm
exec awesome

