# load slimzsh
source "$HOME/.slimzsh/slim.zsh"

# load zgen
source "${HOME}/.zgen/zgen.zsh"

# if the init scipt doesn't exist
if ! zgen saved; then
    zgen load unixorn/autoupdate-zgen
    zgen load zsh-users/zsh-autosuggestions
    zgen load zsh-users/zsh-syntax-highlighting
    zgen load zsh-users/zsh-history-substring-search
    zgen load zsh-users/zsh-completions src
    zgen load paulirish/git-open

    zgen save
fi

# Environment Variables
export LC_ALL=en_US.UTF-8

# PATH exports
export PATH=$PATH:$HOME/bin
export PATH="$HOME/.jenv/bin:$PATH"
export PATH="/usr/local/opt/node@12/bin:$PATH"
export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"

test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

# import https://github.com/rupa/z
source /usr/local/etc/profile.d/z.sh

# zsh helpers
source "$HOME/.zshcfg/zsh_aliases"
source "$HOME/.zshcfg/zsh_functions"

# Start GPG Agent to enable SSH via Yubikey
export GPG_TTY="$(tty)"
export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
gpgconf --launch gpg-agent

# JENV Initialisation
eval "$(jenv init -)"

export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"