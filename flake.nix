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
        #
        # `root` is how far down the sources the documents are looked for, and a
        # build handed no `place` can only reach the ones that ask for none.
        sheets = { name, root, place ? null }: pkgs.stdenvNoCC.mkDerivation {
          inherit name;
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

            for f in $(find ${root} -name '*.typ'); do
              if grep -qxF "$(realpath -m "$f")" imported; then continue; fi
              mkdir -p "$out/$(dirname "$f")"
              typst compile --root . --ignore-system-fonts ${pkgs.lib.optionalString (place != null) "--input place=${place}"} \
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
          pkgs.lib.mapAttrs'
            (
              f: _:
              pkgs.lib.nameValuePair (pkgs.lib.removeSuffix ".typ" f) (sheets {
                name = "${pname}-${pkgs.lib.removeSuffix ".typ" f}";
                root = "typ";
                place = "/${name}/${f}";
              })
            )
            (
              pkgs.lib.optionalAttrs (builtins.pathExists dir) (
                pkgs.lib.filterAttrs (f: t: t == "regular" && pkgs.lib.hasSuffix ".typ" f) (builtins.readDir dir)
              )
            );
        places = placesIn "examples" // placesIn "tmp";

        # The stock a door draws from before it is a particular door.
        typ-reusable = sheets {
          name = "${pname}-typ";
          root = "typ/reusable";
        };

        # `nix build` leaves a symlink in the working directory, and where the pack
        # wants to be is the folder the print dialog opens in. Same derivation,
        # copied out of the store — one file, so -o takes the directory to put it.
        pack = pkgs.writeShellScriptBin "pack" ''
          set -eu
          place=""
          out=""
          while [ $# -gt 0 ]; do
            case "$1" in
              -o) out="''${2:?-o wants a directory}"; shift 2 ;;
              -*) echo "unknown flag: $1" >&2; exit 2 ;;
              *) place="$1"; shift ;;
            esac
          done
          test -n "$place" || { echo "usage: nix run . -- <tmp/place.typ> [-o DIR]" >&2; exit 2; }
          test -f "$place" || { echo "no such place: $place" >&2; exit 1; }
          case "$(dirname "$place")" in
            tmp | ./tmp | examples | ./examples) ;;
            *) echo "a place is a package, and nix reads them out of tmp/ and examples/: $place is in neither" >&2; exit 1 ;;
          esac

          if [ -z "$out" ]; then
            out=$(${pkgs.xdg-user-dirs}/bin/xdg-user-dir DOWNLOAD)
            # what it answers when no user-dirs.dirs names one
            if [ "$out" = "$HOME" ]; then out="$HOME/Downloads"; fi
          fi
          if [ ! -d "$out" ]; then
            echo "nowhere to put the pack: $out is not a directory" >&2
            echo "nothing on this machine says where downloads go, so name one:" >&2
            echo "  nix run . -- $place -o <dir>" >&2
            exit 1
          fi

          built=$(nix build --no-link --print-out-paths "path:.#$(basename "$place" .typ)")
          install -m 644 "$built/typ/to_print.pdf" "$out/to_print.pdf"
          echo "$out/to_print.pdf"
        '';
      in
      {
        apps.help = {
          type = "app";
          program = "${pkgs.writeShellScriptBin "help" ''
            cat <<EOF
            nix build .#typ              The signs no door decides, in every language
            nix build "path:.#<place>"    Every sheet for that door: result/typ/to_print.pdf
            nix run . -- <place.typ>      The same to_print.pdf, in your downloads or -o DIR
            nix flake show path:.         Which doors there are to build
            nix develop                   Enter the Typst development shell
            EOF
          ''}/bin/help";
        };

        apps.default = {
          type = "app";
          program = "${pack}/bin/pack";
        };

        packages = places // {
          typ = typ-reusable;
          default = typ-reusable;
        };

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
