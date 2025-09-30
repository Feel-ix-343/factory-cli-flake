{
  description = "Factory AI CLI (droid) - AI-powered development agent for your terminal";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        version = "0.15.0";

        # Map Nix system to Factory AI platform names
        platformMap = {
          x86_64-linux = { platform = "linux"; arch = "x64"; };
          aarch64-linux = { platform = "linux"; arch = "arm64"; };
          x86_64-darwin = { platform = "darwin"; arch = "x64"; };
          aarch64-darwin = { platform = "darwin"; arch = "arm64"; };
        };

        platformInfo = platformMap.${system} or (throw "Unsupported system: ${system}");
        platform = platformInfo.platform;
        arch = platformInfo.arch;

        # SHA256 hashes for each platform
        hashes = {
          "linux-x64" = "sha256-yFuxZik1kzspcn6Lg47S0kHU9KG5yj1UY+1wZfH28K4=";
          "linux-arm64" = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
          "darwin-x64" = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
          "darwin-arm64" = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
        };

        rgHashes = {
          "linux-x64" = "sha256-viR2yXY0K5IWYRtKhMG8LsZIjsXHkeoBmhMnJ2RO8Zw=";
          "linux-arm64" = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
          "darwin-x64" = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
          "darwin-arm64" = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
        };

        platformKey = "${platform}-${arch}";

      in
      {
        packages.default = pkgs.stdenv.mkDerivation {
          pname = "factory-cli";
          inherit version;

          src = pkgs.fetchurl {
            url = "https://downloads.factory.ai/factory-cli/releases/${version}/${platform}/${arch}/droid";
            hash = hashes.${platformKey};
          };

          dontUnpack = true;
          dontBuild = true;

          nativeBuildInputs = [ pkgs.makeWrapper ];

          rgSrc = pkgs.fetchurl {
            url = "https://downloads.factory.ai/ripgrep/${platform}/${arch}/rg";
            hash = rgHashes.${platformKey};
          };

          installPhase = ''
            runHook preInstall

            mkdir -p $out/bin
            mkdir -p $out/lib/factory

            # Install the main droid binary
            install -m755 $src $out/bin/droid

            # Install ripgrep
            install -m755 $rgSrc $out/lib/factory/rg

            # Wrap droid to ensure ripgrep is in PATH
            wrapProgram $out/bin/droid \
              --prefix PATH : $out/lib/factory

            runHook postInstall
          '';

          meta = with pkgs.lib; {
            description = "Factory AI CLI - AI-powered development agent for your terminal";
            homepage = "https://factory.ai";
            license = licenses.unfree;
            maintainers = [ ];
            platforms = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
            mainProgram = "droid";
          };
        };

        apps.default = {
          type = "app";
          program = "${self.packages.${system}.default}/bin/droid";
        };
      }
    );
}