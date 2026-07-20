{ den, ... }:
{
  den.batteries.os-user = {
    den.classes.user.description = "Lightweight user environment forwarding to OS users.users";

    # Built-in policy: route user class content to the host's OS at
    # users.users.<userName>. Injects osConfig so user-class modules
    # can reference the parent NixOS/Darwin config.
    # The route's ensureEntry mechanism creates users.users.<name> even
    # when no user-class content exists (home-manager references the entry).
    den.default.includes = [ den.policies.user-to-host ];

    den.policies.user-to-host =
      { user, host, ... }:
      [
        (den.lib.policy.route {
          fromClass = "user";
          intoClass = host.class;
          path = [
            "users"
            "users"
            user.userName
          ];
          adaptArgs = args: args // { osConfig = args.config; };
        })
      ];
  };
}
