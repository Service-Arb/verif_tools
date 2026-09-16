{
  nixConfig = {
    extra-substituters = [ "https://valeratrades.cachix.org" ];
    extra-trusted-public-keys = [ "valeratrades.cachix.org-1:gXVwhzO5YB+BaiEJYT48qZgzdaErGQew6xtZcz4Fo1Q=" ];
  };

  inputs = {
    v_flakes.url = "github:valeratrades/v_flakes?ref=v1.6";
  };

  outputs = { self, v_flakes }:
    let
      inherit (v_flakes) flake-utils pre-commit-hooks;
      pname = "verif_tools";
    in
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import v_flakes.default_nixpkgs { inherit system; };
        pre-commit-check = pre-commit-hooks.lib.${system}.run (v_flakes.files.preCommit { inherit pkgs; });

        typ = v_flakes.typ { inherit pkgs; lsp = true; };
        readme = v_flakes.readme-fw {
          inherit pkgs pname;
          defaults = true;
          lastSupportedVersion = "";
          rootDir = ./.;
          badges = [ "loc" ];
        };
        readmeHook = v_flakes.utils.unwrapShellHook readme.shellHook;
        typstyleFmt = pkgs.writeShellScriptBin "typstyle-fmt" ''
          exec ${pkgs.typstyle}/bin/typstyle --line-width 190 --indent-width 2 "$@"
        '';

        # The place is an argument rather than a path in the sources, so one
        # checkout draws any number of doors. Typst resolves it against --root.
        build = pkgs.writeShellScriptBin "build" ''
          set -eu
          place="''${1:?usage: build <examples/place.typ> [out.pdf]}"
          test -f "$place" || { echo "no such place: $place" >&2; exit 1; }
          # the devShell pins it, and utils.typ refuses to date a document 1980
          unset SOURCE_DATE_EPOCH
          exec ${pkgs.typst}/bin/typst compile --root . --input place="/''${place#/}" \
            typ/to_print.typ "''${2:-$(basename "''${place%.typ}").pdf}"
        '';
        exampleplace = "/examples/aquafix_-_Clermont-Ferrand_-_North.typ";
      in
      {
        apps.help = {
          type = "app";
          program = "${pkgs.writeShellScriptBin "help" ''
            cat <<EOF
            nix run . -- examples/<place>.typ   Every sheet for that door, in tray order
            nix build .#typ                     Each document on its own, off the example place
            nix develop                         Enter the Typst development shell
            EOF
          ''}/bin/help";
        };

        apps.default = {
          type = "app";
          program = "${build}/bin/build";
        };

        packages.build = build;

        # A .typ nothing else imports is a document, and compiles to the same path
        # under $out; the rest are libraries, and typst would render them as a
        # blank page rather than say so. The letters under signs/ are cut to a
        # measured size, so the fonts are pinned rather than the builder's —
        # --ignore-system-fonts makes a missing one an error.
        packages.typ = pkgs.stdenvNoCC.mkDerivation {
          name = "${pname}-typ";
          src = ./.;

          nativeBuildInputs = [ pkgs.typst ];

          buildPhase = ''
            : > imported
            for f in $(find typ -name '*.typ'); do
              for imp in $(grep -oE '"[^"]*\.typ"' "$f" | tr -d '"' || true); do
                case "$imp" in
                  /*) realpath -m ".$imp" >> imported ;;
                  *) realpath -m "$(dirname "$f")/$imp" >> imported ;;
                esac
              done
            done

            # the documents date themselves off the clock, and the sandbox pins
            # SOURCE_DATE_EPOCH to 1970 — utils.typ refuses to render that year
            # ponytail: nix caches on inputs, so the date is the one the store path
            # was first built on; `__impure = true` if it has to follow the day
            unset SOURCE_DATE_EPOCH

            for f in $(find typ -name '*.typ'); do
              if grep -qxF "$(realpath -m "$f")" imported; then continue; fi
              mkdir -p "$out/$(dirname "$f")"
              typst compile --root . --ignore-system-fonts --input place=${exampleplace} \
                --font-path ${pkgs.liberation_ttf}/share/fonts/truetype \
                "$f" "$out/''${f%.typ}.pdf"
            done
          '';

          dontInstall = true;
        };

        packages.default = self.packages.${system}.typ;

        devShells.default = pkgs.mkShell {
          shellHook =
            pre-commit-check.shellHook
            + readmeHook
            + ''
              cp -f ${(v_flakes.files.treefmt) { inherit pkgs; }} ./.treefmt.toml
              cp -f ${(v_flakes.files.gitignore { inherit pkgs; langs = [ ]; extra = "*.pdf"; })} ./.gitignore
            '';

          packages = [ pkgs.treefmt typstyleFmt pkgs.python3 build ]
            ++ pre-commit-check.enabledPackages
            ++ typ.enabledPackages
            ++ readme.enabledPackages;
        };
      }
    );
}
