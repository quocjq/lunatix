# Disko layouts library. Each file defines `den.aspects."disko-<layout>"`.
# Hosts reference the layout they want directly:
#   modules/hosts/<host>.nix:
#     includes = [ <settings> <disko-desktop> <lig/agenix> ... ];
#     disk = { name = "main"; device = "/dev/disk/by-id/..."; layout = "desktop"; };
#
# The `disk.layout` value is documentation/metadata (the aspect is picked by
# the include, not by the value) — but the script and layout files keep it in
# sync. layout values: desktop | server | simple-efi | swap | luks-interactive
# | tmpfs-root. Each is modeled on nix-community/disko examples.
{
  den.quirks.disk = {
    description = "Per-host disk declaration: name + device + layout";
  };
}
