{
  den.aspects.forgejo = {
    nixos =
      { lib, ... }:
      {
        services.forgejo = {
          enable = true;
          settings = {
            server = {
              ROOT_URL = "http://127.0.0.1:3000/";
              HTTP_PORT = 3000;
              DOMAIN = "127.0.0.1";
            };
            database = {
              DB_TYPE = lib.mkForce "postgres";
              NAME = "forgejo";
              USER = "forgejo";
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
