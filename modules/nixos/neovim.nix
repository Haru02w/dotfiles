{ lib, config, pkgs, ... }:
with lib;
let cfg = config.modules.neovim;
in {
  options.modules.neovim = {
    enable = mkEnableOption "neovim";
    package = lib.mkPackageOption pkgs "neovim";
  };
  config = mkIf cfg.enable {
    programs.neovim = {
      enable = true;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;
      configure.customRC = ''
        set number relativenumber
      '';
    };
  };
}