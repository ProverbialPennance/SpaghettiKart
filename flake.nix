{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    self = {
      submodules = true;
      lfs = true;
    };
    lus = {
      url = "./libultraship";
      flake = false;
    };
  };

  outputs =
    {
      self,
      lus,
      nixpkgs,
    }:
    let
      # TODO: darwin/MacOS support?
      systems = [
        "x86_64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      formatter = forAllSystems (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
        in
        pkgs.nixfmt-tree
      );
      packages = forAllSystems (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
        in
        {
          default = pkgs.callPackage ./nix/package.nix {
            flake_input = self;
            lus = lus;
          };
        }
      );
    };
}
