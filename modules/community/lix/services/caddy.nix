{
  den.aspects.caddy = {
    nixos =
      { pkgs, ... }:
      let
        www = pkgs.runCommand "lunatix-www" { } ''
          mkdir -p $out
          cp ${./dashboard/index.html} $out/index.html
        '';
      in
      {
        services.caddy = {
          enable = true;
          virtualHosts = {
            "lunixose.duckdns.org" = {
              extraConfig = ''
                # Dashboard — server overview, notes, finance.
                handle {
                  root * ${www}
                  try_files {path} /index.html
                  file_server
                }
                # Forgejo
                handle_path /forgejo/* {
                  reverse_proxy 127.0.0.1:3000
                }
              '';
            };
            "dns.lunixose.duckdns.org" = {
              extraConfig = ''
                reverse_proxy 127.0.0.1:8080
              '';
            };
          };
        };
      };
  };
}
