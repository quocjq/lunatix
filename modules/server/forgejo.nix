{
  server.forgejo = {
    nixos =
      { ... }:
      {
        services.forgejo = {
          enable = true;
          database = {
            type = "postgres";
            name = "forgejo";
            user = "forgejo";
            createDatabase = true;
          };
          settings = {
            server = {
              ROOT_URL = "https://git.lunixose.duckdns.org/";
              HTTP_PORT = 3000;
              DOMAIN = "git.lunixose.duckdns.org";
              HTTP_ADDR = "127.0.0.1";
            };
            database = {
              DB_TYPE = "postgres";
              NAME = "forgejo";
              USER = "forgejo";
              HOST = "/run/postgresql";
              SSL_MODE = "disable";
            };
            service = {
              DISABLE_REGISTRATION = true;
            };
            actions = {
              ENABLED = true;
              DEFAULT_ACTIONS_URL = "github";
            };
          };
        };
        services.postgresql = {
          enable = true;
          ensureDatabases = [ "forgejo" ];
          ensureUsers = [
            {
              name = "forgejo";
              ensureDBOwnership = true;
            }
          ];
        };
      };
  };
}
