{ inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./xserver.nix
    ./home
  ] ++ (with inputs.self.nixosModules; [
    android
    audio
    laptop
    opengl
    security
    xserver
  ]);

  system.stateVersion = "23.11";
}
