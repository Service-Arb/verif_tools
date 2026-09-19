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
        github = v_flakes.github {
          inherit pkgs pname;
          enable = true;
          gitignore.extra = "*.pdf";
        };
        readme = v_flakes.readme-fw {
          inherit pkgs pname;
          defaults = true;
          lastSupportedVersion = "";
          rootDir = ./.;
          badges = [ "loc" ];
        };
        hooks = builtins.concatStringsSep "" (
          map v_flakes.utils.unwrapShellHook [ readme.shellHook typ.shellHook github.shellHook ]
        );

        # A sheet is cut, glued or hung by its front, and the plate only joins at
        # full size. The PDF says so, but only Acrobat reads it — the print dialog
        # is where the user has to set it.
        one-sided = pkgs.writers.writePython3Bin "one-sided" { libraries = [ pkgs.python3Packages.pypdf ]; } ''
          import sys

          from pypdf import PdfWriter

          w = PdfWriter(clone_from=sys.argv[1])
          p = w.create_viewer_preferences()
          p.duplex = "/Simplex"
          p.print_scaling = "/None"
          w.write(sys.argv[1])
        '';

        # A .typ nothing else imports is a document, and compiles to the same path
        # under $out; the rest are libraries, and typst would render them as a
        # blank page rather than say so. The letters under signs/ are cut to a
        # measured size, so the fonts are pinned rather than the builder's —
        # --ignore-system-fonts makes a missing one an error.
        #
        # A document reaching `typ/__main__.typ` through its imports is the half of
        # the sources a place decides; handed no place, a build draws the other half.
        sheets = { name, place ? null }: pkgs.stdenvNoCC.mkDerivation {
          inherit name;
          src = ./.;

          nativeBuildInputs = [ pkgs.typst one-sided ];

          buildPhase = ''
            : > edges
            for f in $(find typ -name '*.typ'); do
              for imp in $(grep -oE '"[^"]*\.typ"' "$f" | tr -d '"' || true); do
                case "$imp" in
                  /*) echo "$(realpath -m "$f") $(realpath -m ".$imp")" >> edges ;;
                  *) echo "$(realpath -m "$f") $(realpath -m "$(dirname "$f")/$imp")" >> edges ;;
                esac
              done
            done
            cut -d' ' -f2 edges | sort -u > imported

            # whatever imports something placed is itself placed, until it settles
            realpath -m typ/__main__.typ > placed
            while :; do
              was=$(wc -l < placed)
              awk 'NR==FNR { m[$0]; next } $2 in m { print $1 }' placed edges | cat - placed | sort -u > wider
              mv wider placed
              test "$(wc -l < placed)" = "$was" && break
            done

            # the documents date themselves off the clock, and the sandbox pins
            # SOURCE_DATE_EPOCH to 1970 — utils.typ refuses to render that year
            # ponytail: nix caches on inputs, so the date is the one the store path
            # was first built on; `__impure = true` if it has to follow the day
            unset SOURCE_DATE_EPOCH

            for f in $(find typ -name '*.typ'); do
              if grep -qxF "$(realpath -m "$f")" imported; then continue; fi
              ${pkgs.lib.optionalString (place == null) ''if grep -qxF "$(realpath -m "$f")" placed; then continue; fi''}
              mkdir -p "$out/$(dirname "$f")"
              typst compile --root . --ignore-system-fonts ${pkgs.lib.optionalString (place != null) "--input place=${place}"} \
                --font-path ${pkgs.liberation_ttf}/share/fonts/truetype \
                "$f" "$out/''${f%.typ}.pdf"
              one-sided "$out/''${f%.typ}.pdf"
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
            collect = dir: prefix:
              pkgs.lib.concatLists (pkgs.lib.mapAttrsToList
                (f: t:
                  let
                    relative = if prefix == "" then f else "${prefix}/${f}";
                    path = "${dir}/${f}";
                  in
                  if t == "regular" && pkgs.lib.hasSuffix ".typ" f then
                    [ relative ]
                  else if t == "directory" then
                    collect path relative
                  else
                    [ ])
                (if builtins.pathExists dir then builtins.readDir dir else { }));
            files = collect (./. + "/${name}") "";
          in
          builtins.listToAttrs (map
            (relative:
            let stem = pkgs.lib.removeSuffix ".typ" (builtins.baseNameOf relative);
            in pkgs.lib.nameValuePair stem (sheets {
              name = "${pname}-${stem}";
              place = "/${name}/${relative}";
            }))
            files);
        places = placesIn "examples" // placesIn "tmp";

        # Nested tmp directories keep several businesses at one physical location together.
        # Their basenames remain the flake attributes, so service-specific packs stay distinct.

        # The stock a door draws from before it is a particular door.
        typ-unplaced = sheets { name = "${pname}-typ"; };

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
          case "$place" in
            tmp/*.typ | ./tmp/*.typ | examples/*.typ | ./examples/*.typ | tmp/*/*.typ | ./tmp/*/*.typ | examples/*/*.typ | ./examples/*/*.typ) ;;
            *) echo "a place is a package, and nix reads them out of tmp/ and examples/: $place is in neither" >&2; exit 1 ;;
          esac

          place_dir=$(dirname "$place")
          place_file=$(basename "$place")
          case "$place_dir" in
            tmp | ./tmp) attr_name="$place_file" ;;
            *) attr_name="$place_file" ;;
          esac

          if [ -z "$out" ]; then
            out=$(${pkgs.xdg-user-dirs}/bin/xdg-user-dir DOWNLOAD)
            # what it answers when no user-dirs.dirs names one
            if [ "$out" = "$HOME" ]; then out="$HOME/Downloads"; fi
          fi

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

          # a flake ref is a URL, and a French street is full of accents
          attr=$(${pkgs.python3}/bin/python3 -c 'import sys,urllib.parse;print(urllib.parse.quote(sys.argv[1],safe=""))' "$(basename "$place" .typ)")
          built=$(nix build --no-link --print-out-paths "path:.#$attr")
          install -m 644 "$built/typ/to_print.pdf" "$out/to_print.pdf"
          echo "$out/to_print.pdf"
        '';
      in
      {
        apps.help = {
          type = "app";
          program = "${pkgs.writeShellScriptBin "help" ''
            cat <<EOF
            nix build .#typ               The signs no door decides, in every language
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
          typ = typ-unplaced;
          default = typ-unplaced;
        };

        devShells.default = pkgs.mkShell {
          shellHook =
            pre-commit-check.shellHook
            + hooks
            + ''
              cp -f ${(v_flakes.files.treefmt) { inherit pkgs; }} ./.treefmt.toml
            '';

          packages = [ pkgs.python3 ]
            ++ pre-commit-check.enabledPackages
            ++ typ.enabledPackages
            ++ readme.enabledPackages
            ++ github.enabledPackages;
        };
      }
    );
}
