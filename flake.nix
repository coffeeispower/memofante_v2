{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
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
          in pkgs.mkShell rec {
            buildInputs = with pkgs; [
              flutter
              android.androidsdk
              jdk17
              gtk3
              gtk3.dev
              graphite2
              graphite2.dev
              pkg-config
              gst_all_1.gstreamer
              gst_all_1.gstreamermm
              libsysprof-capture
              pcre2
              curlFull
              curlFull.dev
              cmake
              mount
              libunwind
              gst_all_1.gst-plugins-base
              gst_all_1.gst-plugins-good
              gst_all_1.gst-libav
              rustup
              bun
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
