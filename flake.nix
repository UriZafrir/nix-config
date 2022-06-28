{
  description = "My nix flake configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = { url = "github:nix-community/home-manager"; inputs.nixpkgs.follows = "nixpkgs"; };
    nur.url = "github:nix-community/NUR";
    neovim-nightly.url = "github:nix-community/neovim-nightly-overlay";
    nix-colors.url = "github:misterio77/nix-colors";
    discocss = { url = "github:mlvzk/discocss/flake"; inputs.nixpkgs.follows = "nixpkgs"; };
    pre-commit-hooks = { url = "github:cachix/pre-commit-hooks.nix"; inputs.nixpkgs.follows = "nixpkgs"; };
    agenix = { url = "github:ryantm/agenix"; inputs.nixpkgs.follows = "nixpkgs"; };
  };

  outputs = { self, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs = inputs.nixpkgs.legacyPackages.${system};
    in
    {
      nixosConfigurations = import ./hosts inputs;
      lib = import ./lib inputs;
      packages.${system} = import ./packages inputs;

      devShells.${system}.default = pkgs.mkShell {
        packages = [ pkgs.nixpkgs-fmt inputs.agenix.defaultPackage.${system} pkgs.age-plugin-yubikey ];
        inherit (self.checks.${system}.pre-commit-check) shellHook;
      };

      checks.${system}.pre-commit-check = inputs.pre-commit-hooks.lib.${system}.run {
        src = self;
        hooks.nixpkgs-fmt.enable = true;
        hooks.shellcheck.enable = true;
        hooks.statix.enable = true;
      };
    };
}
