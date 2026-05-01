{ pkgs, ... }:

{
  # This service ensures that the correct environment variables are available
  # to all graphical applications launched within the user session.
  systemd.user.services.export-environment = {
    Unit = {
      Description = "Export environment variables for the graphical session";
    };
    Service = {
      Type = "oneshot";
      # This command takes the essential variables and makes them available to the session.
      ExecStart = "${pkgs.dbus}/bin/dbus-update-activation-environment --systemd --all";
      RemainAfterExit = true;
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
