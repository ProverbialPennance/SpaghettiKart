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
        "aarch64-linux"
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
          alternate-method = pkgs.callPackage ./nix/package.nix {
            flake_input = self;
            lus = lus;
          };

          default =
            let
              dr-libs = pkgs.fetchFromGitHub {
                owner = "mackron";
                repo = "dr_libs";
                rev = "da35f9d6c7374a95353fd1df1d394d44ab66cf01";
                hash = "sha256-ydFhQ8LTYDBnRTuETtfWwIHZpRciWfqGsZC6SuViEn0=";
              };

              gamecontrollerdb = pkgs.fetchFromGitHub {
                owner = "mdqinc";
                repo = "SDL_GameControllerDB";
                rev = "e84a52679007c6a6346794cda1fdbcb941ac6494";
                hash = "sha256-npgsTvRQRQkgT8C1nwisJqq2m+DT9q/r/Zev2NipGcU=";
              };

              imgui' = pkgs.applyPatches {
                src = pkgs.fetchFromGitHub {
                  owner = "ocornut";
                  repo = "imgui";
                  tag = "v1.91.9b-docking";
                  hash = "sha256-mQOJ6jCN+7VopgZ61yzaCnt4R1QLrW7+47xxMhFRHLQ=";
                };
                patches = [
                  "${lus}/cmake/dependencies/patches/imgui-fixes-and-config.patch"
                ];
              };

              libgfxd = pkgs.fetchFromGitHub {
                owner = "glankk";
                repo = "libgfxd";
                rev = "008f73dca8ebc9151b205959b17773a19c5bd0da";
                hash = "sha256-AmHAa3/cQdh7KAMFOtz5TQpcM6FqO9SppmDpKPTjTt8=";
              };

              prism = pkgs.fetchFromGitHub {
                owner = "KiritoDv";
                repo = "prism-processor";
                rev = "7ae724a6fb7df8cbf547445214a1a848aefef747";
                hash = "sha256-G7koDUxD6PgZWmoJtKTNubDHg6Eoq8I+AxIJR0h3i+A=";
              };

              stb_impl = pkgs.writeTextFile {
                name = "stb_impl.c";
                text = ''
                  #define STB_IMAGE_IMPLEMENTATION
                  #include "stb_image.h"
                '';
              };

              stb' = pkgs.fetchurl {
                name = "stb_image.h";
                url = "https://raw.githubusercontent.com/nothings/stb/0bc88af4de5fb022db643c2d8e549a0927749354/stb_image.h";
                hash = "sha256-xUsVponmofMsdeLsI6+kQuPg436JS3PBl00IZ5sg3Vw=";
              };

              stormlib' = pkgs.applyPatches {
                src = pkgs.fetchFromGitHub {
                  owner = "ladislav-zezula";
                  repo = "StormLib";
                  tag = "v9.25";
                  hash = "sha256-HTi2FKzKCbRaP13XERUmHkJgw8IfKaRJvsK3+YxFFdc=";
                };
                patches = [
                  "${lus}/cmake/dependencies/patches/stormlib-optimizations.patch"
                ];
              };

              thread_pool = pkgs.fetchFromGitHub {
                owner = "bshoshany";
                repo = "thread-pool";
                tag = "v4.1.0";
                hash = "sha256-zhRFEmPYNFLqQCfvdAaG5VBNle9Qm8FepIIIrT9sh88=";
              };
            in
            pkgs.stdenv.mkDerivation (finalAttrs: {
              pname = "spaghetti-kart";
              version = "git" + (if self ? rev then "+${self.rev}" else "");

              src = "${self}";

              patches = [
                ./nix/no-git-execute.patch
                ./nix/dont-fetch-stb.patch

                (pkgs.replaceVars ./nix/git-deps.patch {
                  libgfxd_src = pkgs.fetchFromGitHub {
                    owner = "glankk";
                    repo = "libgfxd";
                    rev = "96fd3b849f38b3a7c7b7f3ff03c5921d328e6cdf";
                    hash = "sha256-dedZuV0BxU6goT+rPvrofYqTz9pTA/f6eQcsvpDWdvQ=";
                  };
                  spdlog_src = pkgs.fetchFromGitHub {
                    owner = "gabime";
                    repo = "spdlog";
                    rev = "7e635fca68d014934b4af8a1cf874f63989352b7";
                    hash = "sha256-cxTaOuLXHRU8xMz9gluYz0a93O0ez2xOxbloyc1m1ns=";
                  };
                  yaml-cpp_src = pkgs.fetchFromGitHub {
                    owner = "jbeder";
                    repo = "yaml-cpp";
                    rev = "28f93bdec6387d42332220afa9558060c8016795";
                    hash = "sha256-59/s4Rqiiw7LKQw0UwH3vOaT/YsNVcoq3vblK0FiO5c=";
                  };
                  tinyxml2_src = pkgs.srcOnly pkgs.tinyxml-2;
                })
              ];

              nativeBuildInputs = with pkgs; [
                cmake
                copyDesktopItems
                installShellFiles
                lsb-release
                gnumake
                git
                ninja
                python3Full
                makeWrapper
                pkg-config
              ];

              buildInputs = with pkgs; [
                dr-libs
                SDL2
                SDL2_net
                libpng
                nlohmann_json
                libzip
                tinyxml-2
                spdlog
                boost
                libogg
                libvorbis
                libGL
                yaml-cpp
                xorg.libX11
              ];

              cmakeFlags = with pkgs; [
                (lib.cmakeFeature "CMAKE_INSTALL_PREFIX" "${placeholder "out"}")
                (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_DR_LIBS" "${dr-libs}")
                (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_IMGUI" "${imgui'}")
                (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_THREADPOOL" "${thread_pool}")
                (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_PRISM" "${prism}")
                (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_TINYXML2" "${tinyxml-2}")
                (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_YAML-CPP" "${yaml-cpp.src}")
                (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_LIBGFXD" "${libgfxd}")
                (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_STORMLIB" "${stormlib'}")
              ];

              strictDeps = true;

              enableParallelBuilding = true;
              hardeningDisable = [ "format" ];

              preConfigure = ''
                mkdir stb
                cp ${stb'} ./stb/${stb'.name}
                cp ${stb_impl} ./stb/${stb_impl.name}
                substituteInPlace libultraship/cmake/dependencies/common.cmake \
                  --replace-fail "\''${STB_DIR}" "$(readlink -f ./stb)"
              '';

              postBuild = ''
                cp ${gamecontrollerdb}/gamecontrollerdb.txt gamecontrollerdb.txt
                ./TorchExternal/src/TorchExternal-build/torch pack ../assets spaghetti.o2r o2r
              '';

              postInstall = ''
                echo $(ls | xargs echo)
                echo $(ls ..)
                mv Spaghettify spaghetti-kart
                installBin {spaghetti-kart,TorchExternal/src/TorchExternal-build/torch}
                mkdir -p $out/share/spaghetti-kart/
                cp -r yamls $out/share/spaghetti-kart
                install -Dm644 -t $out/share/spaghetti-kart {spaghetti.o2r,config.yml,gamecontrollerdb.txt}
                install -Dm644 ../icon.png $out/share/pixmaps/spaghetti-kart.png
                # TODO: there isn't a license in the upstream yet
                # install -Dm644 -t $out/share/licenses/spaghetti-kart ../LICENSE.md
                install -Dm644 -t $out/share/licenses/spaghetti-kart/SDL_GameControllerDB ${gamecontrollerdb}/LICENSE
                install -Dm644 -t $out/share/licenses/spaghetti-kart/libgfxd ${libgfxd}/LICENSE
                install -Dm644 -t $out/share/licenses/spaghetti-kart/libultraship ../libultraship/LICENSE
              '';

              postFixup = ''
                wrapProgram $out/bin/spaghetti-kart \
                  --prefix PATH ":" $pkgs.{lib.makeBinPath [pkgs.zenity]} \
                  --run 'mkdir -p ~/.local/share/spaghetti-kart' \
                  --run "ln -sf $out/share/spaghetti-kart/spaghetti.o2r ~/.local/share/spaghetti-kart/spaghetti.o2r" \
                  --run "ln -sf $out/share/spaghetti-kart/config.yml ~/.local/share/spaghetti-kart/config.yml" \
                  --run "ln -sfT $out/share/spaghetti-kart/yamls ~/.local/share/spaghetti-kart/yamls" \
                  --run "ln -sf $out/share/spaghetti-kart/gamecontrollerdb.txt ~/.local/share/spaghetti-kart/gamecontrollerdb.txt" \
                  --run 'cd ~/.local/share/spaghetti-kart'
              '';

              desktopItems = pkgs.makeDesktopItem {
                name = "Spaghetti Kart";
                icon = "spaghetti-kart";
                exec = "spaghetti-kart";
                comment = finalAttrs.meta.description;
                genericName = "spaghetti-kart";
                desktopName = "spaghetti-kart";
                categories = [ "Game" ];
              };

              meta = with pkgs; {
                description = "Mario Kart 64 PC port";
                license = lib.licenses.unfree;
                mainProgram = "spaghetti-kart";
                homepage = "https://github.com/HarbourMasters/SpaghettiKart";
                changelog = "https://github.com/HarbourMasters/SpaghettiKart/releases/tag/Latest";
                sourceProvenance = with lib.sourceTypes; [
                  fromSource
                ];
                platforms = [ "x86_64-linux" ];
              };
            });
        }
      );
    };
}
