# Replacement for nix-on-droid's upstream android-integration module.
#
# Upstream calls pkgs.callPackage directly on the termux-am/termux-tools
# derivation files, which bypasses the pkgs overlay and therefore never sees
# the prootUnpack fix in droid/backports.nix. This copy is identical in
# options and implementation but uses pkgs.termux-am / pkgs.termux-tools so
# the overlay overrides take effect.
#
# Upstream is disabled via disabledModules in droid/default.nix.
{ config, lib, pkgs, ... }:

let
  cfg = config.android-integration;
  ifD = cond: pkg: if cond then [ pkg ] else [ ];
in
{
  options.android-integration = {
    am.enable = lib.mkEnableOption "am (activity manager) command via termux-am";
    termux-open.enable = lib.mkEnableOption "termux-open (open files/URLs in external apps)";
    termux-open-url.enable = lib.mkEnableOption "termux-open-url (android.intent.action.VIEW)";
    termux-setup-storage.enable = lib.mkEnableOption "termux-setup-storage";
    termux-reload-settings.enable = lib.mkEnableOption "termux-reload-settings";
    termux-wake-lock.enable = lib.mkEnableOption "termux-wake-lock";
    termux-wake-unlock.enable = lib.mkEnableOption "termux-wake-unlock";
    xdg-open.enable = lib.mkEnableOption "xdg-open (symlink to termux-open)";
    unsupported.enable = lib.mkEnableOption "unsupported/untested termux commands";
  };

  config.environment.packages =
    (ifD cfg.am.enable pkgs.termux-am)
    ++ (ifD cfg.termux-setup-storage.enable pkgs.termux-tools.setup_storage)
    ++ (ifD cfg.termux-open.enable pkgs.termux-tools.open)
    ++ (ifD cfg.termux-open-url.enable pkgs.termux-tools.open_url)
    ++ (ifD cfg.termux-reload-settings.enable pkgs.termux-tools.reload_settings)
    ++ (ifD cfg.termux-wake-lock.enable pkgs.termux-tools.wake_lock)
    ++ (ifD cfg.termux-wake-unlock.enable pkgs.termux-tools.wake_unlock)
    ++ (ifD cfg.xdg-open.enable pkgs.termux-tools.xdg_open)
    ++ (ifD cfg.unsupported.enable pkgs.termux-tools.out);
}
