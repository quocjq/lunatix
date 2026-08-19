# bash — login shell (interactive shell of record is nushell). Hooks for the
# hjem-managed tools (fzf/zoxide/starship) + eza aliases + secret env loader.
# Rendered by hjem (lix.bash); binaries come from the host environment.

[[ $- == *i* ]] || return

HISTFILESIZE=100000
HISTSIZE=10000
shopt -s histappend extglob globstar checkjobs

# eza (lix.eza)
alias -- ls=eza
alias -- la='eza -lah '
alias -- ll='eza  -lh --no-user --long'
alias -- lla='eza -la'
alias -- lt='eza --tree --level=2'
alias -- tree='eza --tree '

# fzf (lix.fzf)
eval "$(fzf --bash)"

# zoxide (lix.zoxide)
eval "$(zoxide init bash)"

# starship (lix.starship)
if [[ $TERM != "dumb" ]]; then
  eval "$(starship init bash)"
fi

# yazi cd-on-exit (lix.yazi)
function y() {
  local tmp="$(mktemp -t "yazi-cwd.XXXXX")"
  command yazi "$@" --cwd-file="$tmp"
  if cwd="$(<"$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
    builtin cd -- "$cwd"
  fi
  rm -f -- "$tmp"
}

if [ -r "$HOME/.config/secrets/env" ]; then
  set -a
  . "$HOME/.config/secrets/env"
  set +a
fi

claudem3() {
  # Check if API key exists
  if [ -z "$MINIMAX_API_KEY" ]; then
    echo "Error: MINIMAX_API_KEY is not set. Please add it to secret env"
    return 1
  fi

  # Clear any existing Anthropic key
  unset ANTHROPIC_API_KEY

  # Configure for MiniMax
  export ANTHROPIC_BASE_URL="https://api.minimax.io/anthropic"
  export ANTHROPIC_AUTH_TOKEN="$MINIMAX_API_KEY"
  export API_TIMEOUT_MS="3000000"
  export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1

  export ANTHROPIC_MODEL="MiniMax-M3"
  export ANTHROPIC_SMALL_FAST_MODEL="MiniMax-M3"
  export ANTHROPIC_DEFAULT_SONNET_MODEL="MiniMax-M3"
  export ANTHROPIC_DEFAULT_OPUS_MODEL="MiniMax-M3"
  export ANTHROPIC_DEFAULT_HAIKU_MODEL="MiniMax-M3"

  # Run Claude Code
  claude "$@"
}
clauded() {
  # Check if API key exists
  if [ -z "$MY_ANTHROPIC_API_KEY" ]; then
      echo "Error: MY_ANTHROPIC_API_KEY is not set. Please add it to secret env"
      return 1
  fi

  # Clear any existing Anthropic key
  unset ANTHROPIC_API_KEY

  export ANTHROPIC_AUTH_TOKEN="$MY_ANTHROPIC_API_KEY"
  export ANTHROPIC_BASE_URL="https://agentrouter.org"
  export ANTHROPIC_MODEL="claude-opus-4-8"
  export ANTHROPIC_SMALL_FAST_MODEL="claude-opus-4-8"
  export ANTHROPIC_DEFAULT_SONNET_MODEL="claude-opus-4-8"
  export ANTHROPIC_DEFAULT_OPUS_MODEL="claude-opus-4-8"
  export ANTHROPIC_DEFAULT_HAIKU_MODEL="claude-opus-4-8"

  claude "$@"
}
