# tmux — Prime's tmux workflow (sessionizer + cleanup), Prime-style.
# `ctrl+a` prefix, fzf sessionizer over ~/Proj projects, project-jump from
# tmux (`prefix+f`) and from hyprland (`Mod+SHIFT+T`). Stale-session cleanup
# is a manual script + optional opt-in timer.
{ ... }:
{
  lix.tmux = {
    homeManager =
      { pkgs, ... }:
      let
        # --- config ---
        extraProjects = [ ]; # extra dirs besides ~/Proj/* (deduped first)
        enableAutoCleanup = false; # opt-in: auto-kill stale sessions on a timer
        idleMinutes = 120; # kill sessions idle longer than this

        sessionizer = pkgs.writeShellScript "tmux-sessionizer" ''
          set -euo pipefail

          PROJ_DIR="''${TMUX_PROJ_DIR:-$HOME/Proj}"

          # Explicit list ++ one-level scan of ~/Proj, deduped, sorted.
          dirs="$(
            {
              ${pkgs.findutils}/bin/find "$PROJ_DIR" -mindepth 1 -maxdepth 1 -type d \
                -not -name '.*' 2>/dev/null
              for d in ${builtins.concatStringsSep " " extraProjects}; do
                echo "$d"
              done
            } | sort -u
          )"

          selected="$(printf '%s\n' "$dirs" | ${pkgs.fzf}/bin/fzf --height 40% --layout reverse \
            --prompt 'tmux session > ' --preview 'ls -1 {} 2>/dev/null | head -20')" || exit 0
          [ -n "$selected" ] || exit 0

          name="$(basename "$selected")"
          if ${pkgs.tmux}/bin/tmux has-session -t "$name" 2>/dev/null; then
            ${pkgs.tmux}/bin/tmux switch-client -t "$name"
          else
            ${pkgs.tmux}/bin/tmux new-session -d -s "$name" -c "$selected"
            ${pkgs.tmux}/bin/tmux switch-client -t "$name"
          fi
        '';
        killSessions = pkgs.writeShellScript "tmux-kill-sessions" ''
          set -euo pipefail
          IDLE_MIN="${toString idleMinutes}"
          cur="$(${pkgs.tmux}/bin/tmux display-message -p '#S' 2>/dev/null || true)"
          now="$(date +%s)"
          ${pkgs.tmux}/bin/tmux list-sessions -F '#{session_name} #{session_attached} #{session_activity}' 2>/dev/null | while read -r name att last; do
            [ "$name" = "$cur" ] && continue
            [ "$att" = "1" ] && continue
            idle=$(( (now - last) / 60 ))
            if [ "$idle" -ge "$IDLE_MIN" ]; then
              echo "killing idle tmux session: $name (idle ''${idle}m)"
              ${pkgs.tmux}/bin/tmux kill-session -t "$name"
            fi
          done
        '';
      in
      {
        programs.tmux = {
          enable = true;
          prefix = "C-a";
          keyMode = "vi";
          mouse = true;
          baseIndex = 1;
          escapeTime = 0;
          sensibleOnTop = true;
          extraConfig = ''
            set -g default-terminal "tmux-256color"
            set -g status-style "bg=#1e1e2e,fg=#cdd6f4"
            set -g status-left "#[bg=#b4befe,fg=#1e1e2e] #S "
            set -g status-right "#[bg=#313244,fg=#a6adc8] %H:%M "
            set -g window-status-current-style "bg=#45475a,fg=#f5e0dc"
            set -g pane-border-style "fg=#313244"
            set -g pane-active-border-style "fg=#b4befe"

            # Prime's sessionizer: prefix+f -> fzf pick a project
            bind f run-shell '~/.local/bin/tmux-sessionizer'
          '';
        };

        home.file.".local/bin/tmux-sessionizer" = {
          source = sessionizer;
          executable = true;
        };
        home.file.".local/bin/tmux-kill-sessions" = {
          source = killSessions;
          executable = true;
        };

        # Optional auto-cleanup timer (opt-in).
        systemd.user.timers.tmux-clean = pkgs.lib.mkIf enableAutoCleanup {
          Unit.Description = "Kill stale tmux sessions";
          Timer.OnCalendar = "hourly";
          Timer.Persistent = true;
          Install.WantedBy = [ "timers.target" ];
        };
        systemd.user.services.tmux-clean = pkgs.lib.mkIf enableAutoCleanup {
          Unit.Description = "Kill stale tmux sessions";
          Service.Type = "oneshot";
          Service.ExecStart = killSessions;
          Install.WantedBy = [ "default.target" ];
        };
      };
  };
}
