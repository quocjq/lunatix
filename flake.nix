# flake.nix — thin shim that delegates to default.nix.
# Pin declarations live in modules under flake-file.inputs.*; refresh with
# `nix run .#write-npins` (or `nix run .#write-lock` which auto-dispatches).
{
  outputs = _: import ./.;
}
