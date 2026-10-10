{
  description = "lost - nixos configuration flake for thinkpad t16 gen 1 (alder lake i7-1260p + mx550)";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, ... }@inputs: {
    nixosConfigurations = {
      lost = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./nixos/configuration.nix
        ];
      };
      default = self.nixosConfigurations.lost;
    };
  };
}
