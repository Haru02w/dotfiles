{ config, lib, pkgs, ...}:

{
  security.rtkit.enable = true;
  security.polkit.enable = true;

  security.polkit.extraConfig = ''
  polkit.addRule(function(action, subject) {
    if (action.id.indexOf("org.freedesktop.NetworkManager.") == 0 && subject.isInGroup("network")) {
      return polkit.Result.YES;
    }
  });
   polkit.addRule(function(action, subject) {
     if (
       subject.isInGroup("users")
         && (
           action.id == "org.freedesktop.login1.reboot" ||
           action.id == "org.freedesktop.login1.reboot-multiple-sessions" ||
           action.id == "org.freedesktop.login1.power-off" ||
           action.id == "org.freedesktop.login1.power-off-multiple-sessions")
     )
     {
       return polkit.Result.YES;
     }
  });
  '';
}