{
  den.aspects.forgejo = {
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
              ROOT_URL = "https://lunixose.duckdns.org/forgejo/";
              HTTP_PORT = 3000;
              DOMAIN = "lunixose.duckdns.org";
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
