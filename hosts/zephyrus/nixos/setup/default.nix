{
  config,
  lib,
  inputs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    (import ./disko.nix {device = "/dev/nvme0n1";})
    inputs.nixos-hardware.nixosModules.asus-zephyrus-ga401
  ];

  system.stateVersion = "24.05";

  boot.initrd.postDeviceCommands = lib.mkAfter ''
    mkdir /btrfs_tmp
    mount /dev/disk/by-partlabel/disk-main-ROOT /btrfs_tmp
    if [[ -e /btrfs_tmp/root ]]; then
      mkdir -p /btrfs_tmp/old_roots
      timestamp=$(date --date="@$(stat -c %Y /btrfs_tmp/root)" "+%Y-%m-%-d_%H:%M:%S")
      mv /btrfs_tmp/root "/btrfs_tmp/old_roots/$timestamp"
    fi

    delete_subvolume_recursively() {
      IFS=$'\n'
      for i in $(btrfs subvolume list -o "$1" | cut -f 9- -d ' '); do
        delete_subvolume_recursively "/btrfs_tmp/$i"
      done
      btrfs subvolume delete "$1"
    }

    for i in $(find /btrfs_tmp/old_roots/ -maxdepth 1 -mtime +30); do
      delete_subvolume_recursively "$i"
    done

    btrfs subvolume create /btrfs_tmp/root
    umount /btrfs_tmp
  '';

  boot.loader.grub.enable = true;
  boot.loader.grub.efiSupport = true;
  boot.loader.grub.efiInstallAsRemovable = true;

  fileSystems."/persist".neededForBoot = true;
  fileSystems."/home".neededForBoot = true;
  environment.nix-persist = {
    enable = true;
    path = "/persist";
  };

  #bluetooth support
  hardware.bluetooth.enable = true;

  hardware.nvidia.powerManagement = {
    enable = true;
    finegrained = true;
  };

  environment.etc = {
    "amdcard" = {source = "/dev/dri/by-path/pci-0000:04:00.0-card";};
    "nvicard" = {source = "/dev/dri/by-path/pci-0000:01:00.0-card";};
  };
  environment.sessionVariables.WLR_DRM_DEVICES = ''
    /etc/${config.environment.etc."amdcard".target}:/etc/${
      config.environment.etc."nvicard".target
    }
  '';
}
