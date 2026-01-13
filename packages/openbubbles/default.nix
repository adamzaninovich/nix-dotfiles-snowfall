{ lib
, stdenv
, fetchurl
, autoPatchelfHook
, makeWrapper
, webkitgtk_4_1
, libnotify
, libayatana-appindicator
, jdk
, mpv
, glib
, gtk3
, libsecret
, libgpg-error
, alsa-lib
}:

stdenv.mkDerivation rec {
  pname = "openbubbles";
  version = "1.15.0+190";

  src = fetchurl {
    url = "https://github.com/OpenBubbles/openbubbles-app/releases/download/v${version}/bluebubbles-linux-x86_64.tar";
    hash = "sha256-3ZwuThLAQpKorHSWZYeURl5Yd4/MCgPX+zkEaIPPc4Y=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
  ];

  buildInputs = [
    webkitgtk_4_1
    libnotify
    libayatana-appindicator
    jdk
    mpv
    glib
    gtk3
    libsecret
    libgpg-error
    alsa-lib
    stdenv.cc.cc.lib
  ];

  unpackPhase = ''
    runHook preUnpack

    mkdir -p source
    tar -xf $src -C source
    cd source

    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    # Create directory structure
    mkdir -p $out/opt/openbubbles
    mkdir -p $out/bin
    mkdir -p $out/share/applications
    mkdir -p $out/share/pixmaps

    # Install the application files
    cp -r bluebubbles $out/opt/openbubbles/
    cp -r lib $out/opt/openbubbles/
    cp -r data $out/opt/openbubbles/

    # Use an icon from the assets
    cp data/flutter_assets/assets/icon/icon.png $out/share/pixmaps/openbubbles.png

    # Create desktop entry
    cat > $out/share/applications/openbubbles.desktop << EOF
[Desktop Entry]
Type=Application
Name=OpenBubbles
Comment=Cross-platform ecosystem for Apple platform services
Exec=openbubbles %u
Icon=openbubbles
Categories=Network;InstantMessaging;
Terminal=false
StartupWMClass=openbubbles
MimeType=x-scheme-handler/openbubbles;
EOF

    # Create wrapper script
    makeWrapper $out/opt/openbubbles/bluebubbles $out/bin/openbubbles \
      --prefix LD_LIBRARY_PATH : "$out/opt/openbubbles/lib" \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath buildInputs}" \
      --set GDK_BACKEND "x11"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Open-source cross-platform ecosystem for Apple platform services";
    homepage = "https://openbubbles.app";
    license = licenses.asl20;
    mainProgram = "openbubbles";
    platforms = platforms.linux;
    maintainers = [ ];
  };
}
