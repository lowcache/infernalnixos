# NetworkManager for the physical interfaces. The VM taps are handled in
# vms.nix (systemd-networkd + NM unmanaged list) and anonymous-mode egress
# marking in anonymous-mode.nix.
{
  networking.networkmanager = {
    enable = true;
    wifi = {
      scanRandMacAddress = true;
      macAddress = "stable-ssid";
    };
    settings = {
      "connection-tether-lowprio" = {
        match-device = "driver:rndis_host,driver:cdc_ether,driver:cdc_ncm";
        "ipv4.route-metric" = 700;
      };
    };
  };
}
