{ config, lib, pkgs, inputs, modulesPath, ... }:
{
  imports =
    [
      (modulesPath + "/installer/scan/not-detected.nix")
      inputs.nixos-hardware.nixosModules.lenovo-thinkpad-t480s
    ];

  services.fwupd.enable = true;
  services.fprintd.enable = true;

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.initrd.systemd.enable = true;
  boot.initrd.availableKernelModules = [ "xhci_pci" "thunderbolt" "nvme" "usb_storage" "uas" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];
  boot.supportedFilesystems = [ "zfs" ];

  fileSystems."/" = {
    device = "nixos/root";
    fsType = "zfs";
  };
  fileSystems."/nix" = {
    device = "nixos/nix";
    fsType = "zfs";
  };
  fileSystems."/var" = {
    device = "nixos/var";
    fsType = "zfs";
  };
  fileSystems."/home" = {
    device = "nixos/home";
    fsType = "zfs";
  };
  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/9D7C-5CDB";
    fsType = "vfat";
    options = [ "fmask=0077" "dmask=0077" ];
  };

  # fileSystems."/mnt/Backups" = {
  #   device = "10.1.1.2:/volume1/Backups";
  #   fsType = "nfs";
  #   options = [
  #     "auto"
  #     "nofail"
  #     "noatime"
  #     "nolock"
  #     "tcp"
  #     "actimeo=1800"
  #     "rsize=8192"
  #     "wsize=8192"
  #     "timeo=14"
  #     "nfsvers=4.1"
  #     "noexec"
  #     "rw"
  #   ];
  # };

  swapDevices = [
    {
      device = "/dev/disk/by-partuuid/32c50030-6e67-4e97-8a78-d954347f7e77";
      randomEncryption.enable = true;
    }
  ];

  zramSwap = {
    enable = true;
    algorithm = "zstd";
  };

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp0s31f6.useDHCP = lib.mkDefault true;
  # networking.interfaces.wlp61s0.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
