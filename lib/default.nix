{inputs, ...}: let
  lib = inputs.nixpkgs.lib;
  myLib = rec {
    flakeRoot = inputs.self.outPath;
    # generate inputs:{ "x86_64-linux" = input; "x86_64-darwin" = input; (...)}
    forEachSystemPkgs = f: lib.genAttrs lib.systems.flakeExposed (system: f pkgsFor.${system});

    # generate nixpkgs.legacyPackages with overlays and unfree packages
    pkgsFor = lib.genAttrs lib.systems.flakeExposed (system:
      import inputs.nixpkgs {
        inherit system;
        overlays = builtins.attrValues inputs.self.outputs.overlays;
        config.allowUnfree = true;
        config.allowUnfreePredicate = _: true;
      });

    listFilesRecursive = dir:
      lib.flatten (lib.mapAttrsToList (name: type:
        if type == "directory" || type == "symlink" then
          listFilesRecursive (dir + "/${name}")
        else
          dir + "/${name}"
      ) (builtins.readDir dir));

    # Generate path:[${path}/**/*.nix, (...)]
    nixFilesInPathR = path: lib.filter (value: lib.strings.hasSuffix ".nix" value) (listFilesRecursive path);
    # Generate path:[${path}/*/]
    dirsInPath = path:
      builtins.attrNames (lib.filterAttrs (_: value: value == "directory")
        (builtins.readDir path));

    hosts = dirsInPath ../hosts;
    mkHomeUsers = host:
      dirsInPath ../hosts/${host}/home-manager;

    # Generate nixosConfiguration for all dirs (hosts) in the `./hosts` dir
    mkNixosConfig = systemPerHost:
      builtins.listToAttrs
      (map (host: lib.nameValuePair host (lib.nixosSystem (systemPerHost host))) hosts);

    mkHomeConfig = systemPerHostAndUser:
      builtins.listToAttrs (lib.flatten (map (host:
        map (user:
          lib.nameValuePair "${user}@${host}"
          (systemPerHostAndUser host user)) (mkHomeUsers host))
      hosts));

    mkTemplates = builtins.listToAttrs (map (dir: lib.nameValuePair dir {path = ../templates/${dir};}) (dirsInPath ../templates));

    # Generate NixVim Package with `pkgs` as input
    mkNixvimPkg = pkgs: let
      nixvimModule = pkgs: {
        inherit pkgs;
        module = import ../modules/nixvim; # import the module directly
        # You can use `extraSpecialArgs` to pass additional arguments to your module files
        extraSpecialArgs = {
          # inherit (inputs) foo;
        };
      };
    in
      with inputs.nixvim.legacyPackages.x86_64-linux;
        makeNixvimWithModule (nixvimModule pkgs);
  };
in
  lib.extend (_: _: inputs.home-manager.lib // myLib)
