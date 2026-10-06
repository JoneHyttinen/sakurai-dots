{ pkgs, lib, ... }:
let
  quickshell = pkgs.symlinkJoin {
    name = "quickshell";
    paths = [ pkgs.quickshell ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      for bin in quickshell qs; do
        if [ -e $out/bin/$bin ]; then
          wrapProgram $out/bin/$bin \
            --prefix QML_IMPORT_PATH : "${pkgs.kdePackages.qt5compat}/lib/qt-6/qml"
        fi
      done
    '';
  };
in
{
  home.stateVersion = lib.mkForce "26.05";

  home.packages = with pkgs; [
      # Shell and theming
      quickshell
      matugen
      awww
      imagemagick
      kdePackages.qt5compat
      kdePackages.qt6ct
      kdePackages.breeze
      kdePackages.breeze-icons
      adw-gtk3

      # Hypr ecosystem
      hypridle
      hyprlock
      hyprsunset

      # Used by shell features
      wl-clipboard
      libnotify
      pavucontrol
      networkmanagerapplet
      playerctl
      xhost

      # My default apps (variables.lua)
      alacritty
      neovim
      kdePackages.dolphin
      firefox-devedition
      gnome-calculator
      btop
      fastfetch
      slurp
      satty
      grim

      # Fonts
      material-symbols
      inter
      nerd-fonts.jetbrains-mono

      # LazyVim Dependencies
      gcc
      tree-sitter
      gnumake
      unzip
      curl
      ripgrep
      fd
      lazygit
      nodejs
      cargo

      # Language toolchains
      cmake
      jdk

      # Laptop specific
      brightnessctl

      solaar
  ];

  fonts.fontconfig.enable = true;

  home.sessionVariables = {
     QML_IMPORT_PATH = "${pkgs.kdePackages.qt5compat}/lib/qt-6/qml";
  };

  home.sessionPath = [
    "~/.local/share/nvim/mason/staging/nil/bin"
  ];

  home.pointerCursor = {
    enable = true;
    name = "Bibata-Modern-Classic";
    size = 24; # Change size if needed (e.g., 16, 24, 32)
    package = pkgs.bibata-cursors;
    gtk.enable = true;
  };

  home.sessionVariables = {
    XCURSOR_THEME = "Bibata-Modern-Classic";
    XCURSOR_SIZE = "24";
    HYPRCURSOR_THEME = "Bibata-Modern-Classic";
    HYPRCURSOR_SIZE = "24";
  };

  programs.home-manager.enable = true;
}
