export EDITOR=nvim
export PATH="$PATH:/opt/nvim-linux64/bin"

set -U fish_greeting

set BLK 03 
set CHR 03
set DIR 04
set EXE 02
set REG 07
set HARDLINK 05
set SYMLINK 05
set MISSING 08
set ORPHAN 01
set FIFO 06
set SOCK 03
set UNKNOWN 01

export NNN_COLORS="#04020301;4231"
export NNN_FCOLORS="$BLK$CHR$DIR$EXE$REG$HARDLINK$SYMLINK$MISSING$ORPHAN$FIFO$SOCK$UNKNOWN"
export BAT_THEME="Catppuccin-mocha"
fish_config theme choose "catppuccin-mocha"

alias sysupdate="sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y"
alias mkdir="mkdir -p"
alias ls="lsd"
alias cls="clear && lsd"
alias la="lsd -A "
alias cla="clear && lsd -A "
alias tree="lsd --tree"
alias bat="batcat"
alias cat="batcat"

# enable/disable Pop Shop
alias pop-shop-enable='sed -i "s/X-GNOME-Autostart-enabled=false/X-GNOME-Autostart-enabled=true/" /home/$USER/.config/autostart/io.elementary.appcenter-daemon.desktop; echo "Pop! Store enabled"; nohup io.elementary.appcenter -s >/dev/null 2>&1 &'

alias pop-shop-disable='sed -i "s/X-GNOME-Autostart-enabled=true/X-GNOME-Autostart-enabled=false/" /home/$USER/.config/autostart/io.elementary.appcenter-daemon.desktop; echo "Pop! Store disabled"; killall io.elementary.appcenter'

if status is-interactive
end

starship init fish | source
zoxide init fish | source
test -r ~/.dir_colors && eval $(dircolors ~/.dir_colors)
test -s ~/.config/envman/load.fish; and source ~/.config/envman/load.fish

colorscript -e crunchbang-mini

set -x N_PREFIX "$HOME/.local/node"; contains "$N_PREFIX/bin" $PATH; or set -a PATH "$N_PREFIX/bin"  # Added by n-install (see http://git.io/n-install-repo).
