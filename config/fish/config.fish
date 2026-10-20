# CachyOS's fish setup (greeting, aliases, functions):
# the system's copy on CachyOS, the copy in this repo elsewhere
if test -f /usr/share/cachyos-fish-config/cachyos-config.fish
    source /usr/share/cachyos-fish-config/cachyos-config.fish
else
    source (status dirname)/cachyos-config.fish
end

# overwrite greeting
# potentially disabling fastfetch
#function fish_greeting
#    # smth smth
#end

# opencode
fish_add_path /home/sakurai/.opencode/bin
# nil (Nix LSP)
fish_add_path /home/sakurai/.local/share/nvim/mason/staging/nil/bin

# ssh-agent from the systemd user service (CachyOS);
# on NixOS, programs.ssh.startAgent sets SSH_AUTH_SOCK itself
if test -S $XDG_RUNTIME_DIR/ssh-agent.socket
    set -gx SSH_AUTH_SOCK $XDG_RUNTIME_DIR/ssh-agent.socket
end
