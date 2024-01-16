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
