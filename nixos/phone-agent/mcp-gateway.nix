{ config, lib, ... }:
let cfg = config.phone-agent;
in {
  config = lib.mkIf cfg.enable {
    # gateway.yaml is hand-managed; surface the required values for the operator.
    environment.etc."phone-agent/gateway-peer.example.yaml".text = ''
      backends:
        phone-agent:
          transport: http
          url: http://${cfg.phoneTailscaleIP}:${toString cfg.port}/mcp
          # Authorization header value = "Bearer $(cat ${toString cfg.tokenFile})"
          namespace: phone
    '';
    warnings = lib.optional true
      "phone-agent: add the phone-agent backend to ~/.config/mcp-gateway/gateway.yaml (see /etc/phone-agent/gateway-peer.example.yaml).";
  };
}
