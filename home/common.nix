{ config, ... }:
let
  # Live links into the repo (not copies in the Nix store), so edits take
  # effect immediately and Quickshell's hot reload keeps working
  dots = "${config.home.homeDirectory}/dotfiles/config";
  link = path: config.lib.file.mkOutOfStoreSymlink "${dots}/${path}";
in
{
  home.username = "sakurai";
  home.homeDirectory = "/home/sakurai";

  # The Home Manager release this config was first written for.
  # Don't change it later; it's not the version you're running.
  home.stateVersion = "26.05";

  programs.home-manager.enable = true;

  # ~/.config/<name>  ->  ~/dotfiles/config/<name>
  xdg.configFile = {
    "alacritty".source = link "alacritty";
    "hypr".source = link "hypr";
    "matugen".source = link "matugen";
    "qt6ct".source = link "qt6ct";
    "quickshell".source = link "quickshell";
  };

  # setwall lives in the repo; this puts it on your PATH
  home.file.".local/bin/setwall".source = link "hypr/scripts/setwall";
}
