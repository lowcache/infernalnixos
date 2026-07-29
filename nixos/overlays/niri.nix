# niri 26.04 vendors the Rust crate libdisplay-info-sys 0.3.0, which caps the C
# library libdisplay-info at < 0.4.0. This nixpkgs commit bumped libdisplay-info
# to 0.4.0, so niri fails to build ("Requested 'libdisplay-info < 0.4.0' but
# version of libdisplay-info is 0.4.0"). Pin libdisplay-info to 0.3.0 for niri
# only. Remove once nixpkgs ships a niri whose libdisplay-info-sys accepts 0.4.0.
_final: prev: {
  niri = prev.niri.override {
    libdisplay-info = prev.libdisplay-info.overrideAttrs (_old: {
      version = "0.3.0";
      src = prev.fetchFromGitLab {
        domain = "gitlab.freedesktop.org";
        owner = "emersion";
        repo = "libdisplay-info";
        rev = "0.3.0";
        sha256 = "sha256-nXf2KGovNKvcchlHlzKBkAOeySMJXgxMpbi5z9gLrdc=";
      };
    });
  };
}
