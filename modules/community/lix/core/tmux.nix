# tmux — Prime's tmux workflow (sessionizer + cleanup), Prime-style.
# `ctrl+a` prefix, fzf sessionizer over ~/Proj projects, project-jump from
# tmux (`prefix+f`) and from hyprland (`Mod+SHIFT+T`). Stale-session cleanup
# is a manual script; the opt-in timer was dropped with home-manager (nix-maid
# manages no services).
{ ... }:
{
  lix.tmux = {
    os = { pkgs, ... }: {
      environment.systemPackages = with pkgs; [
        tmux
        fzf
        findutils
      ];
    };
    maid = {
      file.xdg_config."tmux/tmux.conf".source = ./_config/.config/tmux/tmux.conf;
      file.home.".local/bin/tmux-sessionizer" = {
        source = ./_config/.local/bin/tmux-sessionizer;
        executable = true;
      };
      file.home.".local/bin/tmux-kill-sessions" = {
        source = ./_config/.local/bin/tmux-kill-sessions;
        executable = true;
      };
    };
  };
}
