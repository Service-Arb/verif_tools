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

        # A .typ nothing else imports is a document, and compiles to the same path
        # under $out; the rest are libraries, and typst would render them as a
        # blank page rather than say so. The letters under signs/ are cut to a
        # measured size, so the fonts are pinned rather than the builder's —
        # --ignore-system-fonts makes a missing one an error.
        sheets = place: pkgs.stdenvNoCC.mkDerivation {
          name = "${pname}-${pkgs.lib.removeSuffix ".typ" (baseNameOf place)}";
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
              typst compile --root . --ignore-system-fonts --input place=${place} \
                --font-path ${pkgs.liberation_ttf}/share/fonts/truetype \
                "$f" "$out/''${f%.typ}.pdf"
            done
          '';

          dontInstall = true;
        };

        # `nix build` takes no argument, so each place file is a package of its own,
        # named after the file. A door sits in tmp/, which git does not track and so
        # `.#` cannot see — `path:.#<place>` copies the working tree instead, and
        # reads the same for a tracked place.
        placesIn =
          name:
          let
            dir = ./. + "/${name}";
          in
          pkgs.lib.mapAttrs' (f: _: pkgs.lib.nameValuePair (pkgs.lib.removeSuffix ".typ" f) (sheets "/${name}/${f}")) (
            pkgs.lib.optionalAttrs (builtins.pathExists dir) (
              pkgs.lib.filterAttrs (f: t: t == "regular" && pkgs.lib.hasSuffix ".typ" f) (builtins.readDir dir)
            )
          );
        places = placesIn "examples" // placesIn "tmp";
      in
      {
        apps.help = {
          type = "app";
          program = "${pkgs.writeShellScriptBin "help" ''
            cat <<EOF
            nix build "path:.#<place>"    Every sheet for that door: result/typ/to_print.pdf
            nix flake show path:.         Which doors there are to build
            nix develop                   Enter the Typst development shell
            EOF
          ''}/bin/help";
        };

        packages = places;

        devShells.default = pkgs.mkShell {
          shellHook =
            pre-commit-check.shellHook
            + readmeHook
            + ''
              cp -f ${(v_flakes.files.treefmt) { inherit pkgs; }} ./.treefmt.toml
              cp -f ${(v_flakes.files.gitignore { inherit pkgs; langs = [ ]; extra = "*.pdf"; })} ./.gitignore
            '';

          packages = [ pkgs.treefmt typstyleFmt pkgs.python3 ]
            ++ pre-commit-check.enabledPackages
            ++ typ.enabledPackages
            ++ readme.enabledPackages;
        };
      }
    );
}
