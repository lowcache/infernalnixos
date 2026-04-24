{ lib, stdenv, fetchurl, dpkg, makeWrapper
, gtk3, nss, cups, alsa-lib, mesa
}:

stdenv.mkDerivation rec {
  pname = "aionui-bin";
  version = "1.9.18";

  src = fetchurl {
    url = "https://github.com/iOfficeAI/AionUi/releases/download/v${version}/AionUi-${version}-linux-amd64.deb";
    sha256 = "939f48133b3c436425b8f08be403a7a911e7b2030baf5e7b3735e754fd0af6e7";
  };

  nativeBuildInputs = [ dpkg makeWrapper ];

  # Runtime dependencies from the PKGBUILD
  buildInputs = [ gtk3 nss cups alsa-lib mesa ];

  dontUnpack = true;

  installPhase = ''
    # Extract the .deb archive
    dpkg -x $src .

    # Copy the extracted contents to the Nix store output path and make it executable
	mkdir -p $out
    cp -r opt usr $out/ 2>/dev/null || cp -r "*" $out/
    BINARY_PATH=$(find $out/opt -type f -iname "aionui" | head -n 1) 
    chmod +x "$BINARY_PATH"
    # Wrap binary
  	wrapProgram "$BINARY_PATH" \
  	 --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath buildInputs}"

  	# Locate and patch desktop file
  	DESKTOP_FILE=$(find $out -type f -iname "*.desktop" | head -n 1)
  	if [ -n "$DESKTOP_FILE" ]; then
  		substituteInPlace "$DESKTOP_FILE" \
  		 --replace "icon=aionui" "icon=$out/share/icons/hicolor/1024x1024/apps/AionUi.png" || true
  	fi 
  '';

  meta = with lib; {
    description = "AionUi - Packaged for NixOS";
    homepage = "https://github.com/iOfficeAI/AionUi";
    license = licenses.unfree; # The license is marked 'unknown' in the PKGBUILD
    platforms = platforms.linux;
    maintainers = [ maintainers.nondeus ]; # You are the maintainer now
  };
}
