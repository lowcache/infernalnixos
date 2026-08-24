# Human accounts. The anon-mode isolation user lives in anonymous-mode.nix.
{
  config,
  username,
  ...
}:
{
  users = {
    users = {
      root = {
        hashedPasswordFile = config.sops.secrets.root_password.path;
      };
      ${username} = {
        isNormalUser = true;
        hashedPasswordFile = config.sops.secrets.user_password.path;
        extraGroups = [
          "adbusers"
          "networkmanager"
          "wheel"
          "video"
          "docker"
          "uinput"
        ];
      };
    };
  };
}
