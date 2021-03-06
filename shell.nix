{ pkgs ? import ./nix {}, useNix1 ? false }:

let
  # A random Nixpkgs revision *before* the default glibc
  # was switched to version 2.27.x.
  oldpkgsSrc = pkgs.fetchFromGitHub {
    owner = "nixos";
    repo = "nixpkgs";
    rev = "0252e6ca31c98182e841df494e6c9c4fb022c676";
    sha256 = "1sr5a11sb26rgs1hmlwv5bxynw2pl5w4h5ic0qv3p2ppcpmxwykz";
  };

  oldpkgs = import oldpkgsSrc {};

  inherit (pkgs) stdenv;

  phpEnv = stdenv.mkDerivation rec {
    name = "gh-event-forwarder";
    src = null;
    buildInputs = with pkgs; [
      nix-prefetch-git
      php
      phpPackages.composer
      git
      php
      curl
      bash
    ]
      ++ stdenv.lib.optional useNix1 nix1;

    # HISTFILE = "${src}/.bash_hist";
  };

  rustEnv = stdenv.mkDerivation rec {
    name = "gh-event-forwarder";
    buildInputs = with pkgs; [
      bash
      nix-prefetch-git
      rust.rustc
      rust.cargo
      rustfmt
      carnix
      openssl.dev
      pkgconfig
      git
    ]
      ++ stdenv.lib.optional useNix1 nix1
      ++ stdenv.lib.optional stdenv.isDarwin pkgs.darwin.Security;

    postHook = ''
      checkPhase() {
          ( cd "${builtins.toString ./.}/ofborg" && cargo test --lib )
      }
    '';

    HISTFILE = "${toString ./.}/.bash_hist";
    RUSTFLAGS = "-D warnings";
    LOCALE_ARCHIVE_2_21 = "${oldpkgs.glibcLocales}/lib/locale/locale-archive";
    LOCALE_ARCHIVE_2_27 = "${pkgs.glibcLocales}/lib/locale/locale-archive";
    RUST_BACKTRACE = "1";
    RUST_LOG = "ofborg=debug";
    passthru.phpEnv = phpEnv;
  };


in rustEnv
