# sakurai-dots

Personal dotfiles and system configuration for my Linux machines, managed with Nix Flakes and Home Manager.

## Purpose

This repository is the single source of truth for my desktop environment and daily tooling setup.  
It keeps my machines consistent by versioning:

- application configs (`~/.config/*`)
- window manager and shell UI setup
- theming and wallpaper-driven color generation
- editor configuration (Neovim / LazyVim)
- host-specific NixOS and Home Manager modules

The goal is reproducibility, easy syncing between machines, and quick recovery after reinstalling or changing hardware.

## What is managed here

### Nix + Home Manager

- `flake.nix` defines two targets:
  - `homeConfigurations."sakurai@cachyos-x8664"` for a non-NixOS desktop via Home Manager
  - `nixosConfigurations."elitebook"` for a NixOS laptop with integrated Home Manager
- `home/common.nix` links repo configs into `~/.config` with out-of-store symlinks, so local edits apply immediately.
- `home/desktop.nix` and `home/laptop.nix` split machine-specific behavior.

### System and host files

- `hosts/laptop/` contains NixOS host configuration (boot, services, hardware, user setup).

### Dotfile directories

- `config/hypr` – Hyprland, Hyprlock, Hypridle, scripts
- `config/quickshell` – panel/dashboard UI components
- `config/matugen` – dynamic color generation templates
- `config/alacritty` – terminal configuration and theme
- `config/nvim` – Neovim setup (LazyVim-based)
- `config/qt6ct` – Qt theming settings

## How I use this repo

I keep this repo at:

`~/dotfiles`

### Apply on desktop (non-NixOS)

```bash
home-manager switch --flake .
```

### Apply on laptop (NixOS)

```bash
sudo nixos-rebuild switch --flake .
```

### Sync and apply updates

`home/common.nix` includes a helper command:

```bash
dots-sync
```

It pulls latest changes in `~/dotfiles` and runs either `nixos-rebuild` (on NixOS) or `home-manager switch` (elsewhere).

## Design notes

- Configs are linked directly from this repo, not copied into the Nix store, so tools like Quickshell can hot-reload while editing.
- Laptop and desktop share a common base, but differ where hardware or OS integration requires it.
- The setup prioritizes practical day-to-day ergonomics (Wayland workflow, keyboard-driven setup, consistent app defaults).

## Maintenance workflow

1. Edit configuration files in this repo.
2. Rebuild with the appropriate command for the machine.
3. Test behavior in-session.
4. Commit and push when stable.

This keeps the environment declarative, tracked, and portable.
