{
  description = "sakurai's desktop and laptop";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";  # use the same nixpkgs as everything else
    };
  };

  outputs = { nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      # Desktop (CachyOS): standalone Home Manager
      homeConfigurations."sakurai@cachyos-x8664" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [
          ./home/common.nix
          ./home/desktop.nix
        ];
      };

      # Laptop (NixOS) gets added here in step 4, as nixosConfigurations.<name>
    };
}
