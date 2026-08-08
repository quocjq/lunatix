{ inputs, ... }:
{
  # `flake-file` reads `flake-file.inputs.X` from across the repo and merges
  # them into the top-level `inputs` attr of flake.nix on regeneration.
  flake-file.inputs.lotus = {
    url = "github:lotusinputmethod/fcitx5-lotus";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  lix.lotus = {
    os = { pkgs, ... }: {
      imports = [ inputs.lotus.nixosModules.fcitx5-lotus ];
      services.fcitx5-lotus = {
        enable = true;
        package = inputs.lotus.packages.${pkgs.stdenv.hostPlatform.system}.fcitx5-lotus;
        users = [ "lunixose" ];
      };

      i18n.inputMethod = {
        enable = true;
        type = "fcitx5";
      };
    };

    homeManager = { pkgs, ... }: {
      i18n.inputMethod = {
        enable = true;
        type = "fcitx5";
        fcitx5 = {
          waylandFrontend = true;
          addons = [
            inputs.lotus.packages.${pkgs.stdenv.hostPlatform.system}.fcitx5-lotus
          ];
          settings = {
            globalOptions = {
              "Hotkey" = {
                "EnumerateWithTriggerKeys" = "True";
                "ActivateKeys" = "";
                "DeactivateKeys" = "";
                "AltTriggerKeys" = "";
                "EnumerateForwardKeys" = "";
                "EnumerateBackwardKeys" = "";
                "EnumerateSkipFirst" = "False";
                "PrevPage" = "";
                "NextPage" = "";
                "PrevCandidate" = "";
                "NextCandidate" = "";
                "TogglePreedit" = "";
                "ModifierOnlyKeyTimeout" = "250";
              };
              "Hotkey/TriggerKeys"."0" = "Control+backslash";
              "Hotkey/EnumerateGroupForwardKeys"."0" = "Control+backslash";
              "Hotkey/EnumerateGroupBackwardKeys"."0" = "Shift+Super+blackslash";
              "Behavior" = {
                "ActiveByDefault" = "False";
                "resetStateWhenFocusIn" = "No";
                "ShareInputState" = "All";
                "PreeditEnabledByDefault" = "True";
                "ShowInputMethodInformation" = "True";
                "showInputMethodInformationWhenFocusIn" = "False";
                "CompactInputMethodInformation" = "True";
                "ShowFirstInputMethodInformation" = "True";
                "DefaultPageSize" = "5";
                "OverrideXkbOption" = "False";
                "CustomXkbOption" = " ";
                "EnabledAddons" = " ";
                "DisabledAddons" = " ";
                "PreloadInputMethod" = "True";
                "AllowInputMethodForPassword" = "False";
                "ShowPreeditForPassword" = "False";
                "AutoSavePeriod" = "30";
              };
            };
            inputMethod = {
              GroupOrder."0" = "Default";
              "Groups/0" = {
                Name = "Default";
                "Default Layout" = "us";
                DefaultIM = "keyboard-us";
              };
              "Groups/0/Items/0".Name = "keyboard-us";
              "Groups/0/Items/1".Name = "lotus";
            };
          };
        };
      };
    };
  };
}
