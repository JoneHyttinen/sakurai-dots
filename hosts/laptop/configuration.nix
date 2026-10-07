# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  boot.initrd.luks.devices."luks-59394f29-6636-4dcf-8ee8-69b42ed9cb99".device = "/dev/disk/by-uuid/59394f29-6636-4dcf-8ee8-69b42ed9cb99";
  networking.hostName = "elitebook"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Helsinki";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "fi_FI.UTF-8";
    LC_IDENTIFICATION = "fi_FI.UTF-8";
    LC_MEASUREMENT = "fi_FI.UTF-8";
    LC_MONETARY = "fi_FI.UTF-8";
    LC_NAME = "fi_FI.UTF-8";
    LC_NUMERIC = "fi_FI.UTF-8";
    LC_PAPER = "fi_FI.UTF-8";
    LC_TELEPHONE = "fi_FI.UTF-8";
    LC_TIME = "fi_FI.UTF-8";
  };

  # X11, used for the XFCE fallback session
  services.xserver = {
    enable = true;
    xkb = {
      layout = "fi";
      variant = "";
    };
    desktopManager.xfce.enable = true;
  };

  # Configure console keymap
  console.keyMap = "fi";

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users."sakurai" = {
    isNormalUser = true;
    description = "Jone";
    extraGroups = [ "networkmanager" "wheel" "video" ];
    packages = with pkgs; [];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Enable the newer nix CLI and flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Brightness: let your user change the backlight without sudo
  services.udev.packages = [ pkgs.brightnessctl ];

  # Power profiles (Saver / Balanced / Performance)
  services.power-profiles-daemon.enable = true;

  # Qt theming
  qt = {
      enable = true;
      platformTheme = "qt5ct";
  };

  # Hyprland with UWSM
  programs.hyprland = {
     enable = true;
     withUWSM = true;
  };

  programs.hyprlock.enable = true;

  programs.nix-ld.enable = true;

  programs.dconf.enable = true;

  programs.solaar.enable = true;

  # Bluetooth GUI
  services.blueman.enable = true;

  # Battery info for Quickshell's UPower service
  services.upower = {
      enable = true;
      percentageLow = 15;
      percentageCritical = 5;
      percentageAction = 3;
      criticalPowerAction = "PowerOff";
  };

  services.thermald.enable = true;

  hardware.graphics.extraPackages = [ pkgs.intel-media-driver ];

  nix.settings.auto-optimise-store = true;

  # List packages installed in system profile.
  # You can use https://search.nixos.org/ to find more packages (and options).
  environment.systemPackages = with pkgs; [
     git
     neovim
     kitty
     wget
     firefox
     adwaita-icon-theme
  ];

  environment.sessionVariables.SECLISTS = "${pkgs.seclists}/share/wordlists/seclists";

   # Login screen: SDDM, with a session menu for Hyprland and XFCE
  services.displayManager = {
    sddm = {
      enable = true;
      wayland.enable = false;
      settings.Theme = {
          CursorTheme = "Adwaita";
          CursorSize = 24;
      };
    };
    defaultSession = "hyprland-uwsm";
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "26.05"; # Did you read the comment?

}
