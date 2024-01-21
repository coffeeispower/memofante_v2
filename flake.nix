{
  description = "An example project using flutter";

  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.flake-compat = {
    url = "github:edolstra/flake-compat";
    flake = false;
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
          config.android_sdk.accept_license = true;
        };
        objectbox-c = with pkgs;
          stdenv.mkDerivation rec {
            pname = "objectbox-c";
            version = "0.20.0";
            src = fetchurl {
              url = "https://github.com/objectbox/${pname}/releases/download/v${version}/objectbox-linux-x64.tar.gz";
              sha256 = "sha256-GP1U3djSWZVrFTIq2aFoWGpmKW1ldk+fwb3RfrGsruo=";
            };
            nativeBuildInputs = [
              autoPatchelfHook
            ];

            buildInputs = [
              stdenv.cc.cc.lib
            ];

            sourceRoot = ".";

            installPhase = ''
              runHook preInstall
              mkdir $out
              mv $PWD/* $out
              mkdir $out/lib/pkgconfig
              cat >$out/lib/pkgconfig/objectbox.pc <<EOF
                prefix=$out
                includedir=$out/include
                libdir=''${prefix}/lib
                Name: libobjectbox
                Description: Database Library
                Version: ${version}
                Libs: -L\''${libdir} -lobjectbox
                Cflags: -I\''${includedir}
              EOF
              runHook postInstall
            '';
          };
      in {
        
        devShells.default =
          let android = pkgs.callPackage ./nix/android.nix { };
          in pkgs.mkShell {
            buildInputs = with pkgs; [
              # from pkgs
              flutter
              jdk17
              dart
              android.platform-tools
              cmake
              ninja
              objectbox-c
            ];

            ANDROID_HOME = "${android.androidsdk}/libexec/android-sdk";
            JAVA_HOME = pkgs.jdk17;
            ANDROID_AVD_HOME = (toString ./.) + "/.android/avd";
            GRADLE_USER_HOME = "/tmp/.gradle";
            GRADLE_HOME = "/tmp/.gradle";
            GRADLE_OPTS = "-Dorg.gradle.project.android.aapt2FromMavenOverride=${android.androidsdk}/libexec/android-sdk/build-tools/34.0.0/aapt2";
          };
      });
}
