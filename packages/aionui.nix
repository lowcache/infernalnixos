{ lib, stdenv, fetchurl, undeb, makeWrapper
, gtk3, nss, libcups, alsa-lib, mesa
}:

stdenv.mkDerivation rec {
  pname = "aionui-bin";
  version = "1.9.18";

  src = fetchurl {
    url = "https://github.com/iOfficeAI/AionUi/releases/download/v${version}/AionUi-${version}-linux-amd64.deb";
    sha256 = "939f48133b3c436425b8f08be403a7a911e7b2030baf5e7b3735e754fd0af6e7";
  };

  nativeBuildInputs = [ undeb makeWrapper ];

  # Runtime dependencies from the PKGBUILD
  buildInputs = [ gtk3 nss libcups alsa-lib mesa ];

  dontUnpack = true;

  installPhase = ''
    # Extract the .deb archive
    undeb ${src}

    # Copy the extracted contents to the Nix store output path
    cp -r usr $out/

    # The binary needs to find its shared library dependencies.
    # We create a wrapper script that sets the LD_LIBRARY_PATH.
    # The actual binary is at $out/opt/aionui/aionui based on typical .deb structure for electron apps.
    wrapProgram $out/opt/aionui/aionui 
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath buildInputs}"

    # Fix the absolute icon path in the .desktop file for the applications menu
    substituteInPlace $out/share/applications/AionUi.desktop 
      --replace "Icon=aionui" "Icon=$out/share/icons/hicolor/1024x1024/apps/AionUi.png"
  '';

  meta = with lib; {
    description = "AionUi for agent - Packaged for NixOS";
    homepage = "https://github.com/iOfficeAI/AionUi";
    license = licenses.unknown; # The license is marked 'unknown' in the PKGBUILD
    platforms = platforms.linux;
    maintainers = [ ]; # You are the maintainer now
  };
}
