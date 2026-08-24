# The volnix instance: machine identity, feature switches, and host-specific
# option values. How each feature WORKS lives in ../modules/; this file says
# what THIS machine IS.
{
  config,
  ...
}:
{
  imports = [
    ../modules
    ../vms.nix
    ../windows-vm.nix
    ../phone-agent
  ];

  networking.hostName = "volnix";
  time.timeZone = "America/Chicago";
  system.stateVersion = "24.11"; # do not bump

  vol.anon-mode.enable = true;

  vol.ai-stack = {
    ollama.enable = true;
    ollama.exposeToTailscaleVm = true;
    open-webui.enable = true;
  };

  # Phone agent (S26 Ultra MCP integration, Phase 8). Bearer token is the
  # laptop's sops-materialized copy of the phone's token (matches the phone's
  # ~/.config/phone-agent/token). phoneTailscaleIP is stable per node key.
  phone-agent = {
    enable = true;
    phoneTailscaleIP = "100.101.229.9";
    tokenFile = config.sops.secrets.phone_agent_token.path;
  };
}
