{
  lix.bash = {
    homeManager = {
      programs.bash = {
        enable = true;
        initExtra = ''
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
        '';
      };
    };
  };
}
