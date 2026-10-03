{
    description = "ttop — thermal top: live CPU thermal monitor and bench (coretemp · RAPL · throttle)";

    inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    outputs = { self, nixpkgs }:
    let
        systems = [ "x86_64-linux" ];
        forAll  = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
        packages = forAll (pkgs: {
            # Not writeShellApplication: it forces errexit, and the script deliberately lives
            # without -e — ((x)) && … and grep without matches are normal branches there, not errors.
            default = pkgs.stdenvNoCC.mkDerivation {
                pname   = "ttop";
                version = "0.1.0";
                src     = ./.;
                nativeBuildInputs = [ pkgs.makeWrapper ];
                dontBuild = true;
                installPhase = ''
                    # bash
                    install -Dm755 ttop $out/bin/ttop
                    wrapProgram $out/bin/ttop \
                        --prefix PATH : ${pkgs.lib.makeBinPath (with pkgs; [ coreutils gawk stress-ng ])}
                '';
                meta = {
                    description = "Live CPU thermal monitor and bench in pure bash";
                    license     = pkgs.lib.licenses.mit;
                    platforms   = systems;
                    mainProgram = "ttop";
                };
            };
        });

        apps = forAll (pkgs: {
            default = { type = "app"; program = "${self.packages.${pkgs.stdenv.hostPlatform.system}.default}/bin/ttop"; };
        });
    };
}
