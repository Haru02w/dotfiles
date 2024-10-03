{
  lib,
  config,
  ...
}:
with lib; let
  cfg = config.modules.presets.desktop-v1.foot;
in {
  options.modules.presets.desktop-v1.foot.enable =
    mkEnableOption "desktop-v1 foot";

  config = mkIf cfg.enable {
    programs.foot = {
      enable = true;
      server.enable = true;
      settings.main.dpi-aware = mkForce "no";
    };
  };
}