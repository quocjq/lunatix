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
              ROOT_URL = "http://127.0.0.1:3000/";
              HTTP_PORT = 3000;
              DOMAIN = "127.0.0.1";
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
