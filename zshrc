autoload -U colors && colors
PS1="%B%{$fg[red]%}[%{$fg[yellow]%}%n%{$fg[green]%}@%{$fg[blue]%}%M%{$fg[red]%}] %{$fg[magenta]%}%~%{$reset_color%}$%b "

# History in cache directory:
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history

setopt SHARE_HISTORY

plugins=(
  git
  history
  zsh-completions
  zsh-autosuggestions
  zsh-syntax-highlighting
  zsh-history-substring-search
)

source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh


alias update="sudo pacman -Syyu --noconfirm"
alias install="sudo pacman -S ---noconfirm"
alias remove="sudo pacman -Rcns --noconfirm"
alias enable="sudo systemctl enable"
alias disable="sudo systemctl disable"
alias status="sudo systemctl status"
alias c="clear"
alias v='vim'
alias search='pacman -Qs'
alias ls='ls --color=auto'
alias ll="ls -la"
alias nano="sudo nano"
alias xed="sudo xed"





