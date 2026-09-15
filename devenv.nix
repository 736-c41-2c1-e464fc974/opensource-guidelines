{
  pkgs,
  lib,
  config,
  ...
}:

let
  # open-govpress (https://github.com/swiss-armed-forces/cyber-command/cea/open-govpress)
  # is the CLI used to render these .adoc documents to PDF. It ships as a
  # generic dynamically-linked Linux binary (electron-builder's tar.gz
  # target), which cannot execute directly on NixOS -- there is no
  # /lib64/ld-linux-x86-64.so.2 and no FHS layout for it to find its shared
  # libraries in. Wrapping it in an FHS environment (the same trick nixpkgs
  # itself uses for Chrome/Electron/AppImage binaries) lets the unmodified
  # upstream tarball run as-is, with no patchelf/rebuild step.
  #
  # The build is fetched from a GitHub Release rather than committed to the
  # repo: at ~112MiB it clears GitHub's 100MB hard limit on regular git
  # objects, and this repo is a fork, which GitHub's LFS policy blocks from
  # uploading *new* LFS objects at all -- release assets hit neither limit.
  govpressVersion = "0.0.7";
  govpressUrl = "https://github.com/736-c41-2c1-e464fc974/opensource-guidelines/releases/download/open-govpress-v${govpressVersion}/open-govpress-${govpressVersion}-linux-x64.tar.gz";
  govpressSha256 = "3766f1da1137208a438abe06b4ad8427734e1de782aac33ff1d47df3e975ecdf";

  govpressFHS = pkgs.buildFHSEnv {
    name = "open-govpress-fhs";
    targetPkgs =
      pkgs: with pkgs; [
        glib
        nss
        nspr
        atk
        at-spi2-atk
        at-spi2-core
        cups
        dbus
        libdrm
        gtk3
        pango
        cairo
        xorg.libX11
        xorg.libXcomposite
        xorg.libXdamage
        xorg.libXext
        xorg.libXfixes
        xorg.libXrandr
        xorg.libxcb
        xorg.libxshmfence
        libxkbcommon
        mesa
        libGL
        alsa-lib
        expat
        libgbm
        systemd
      ];
  };
in
{
  env = {
    DO_NOT_TRACK = 1;
  };

  dotenv = {
    enable = true;
    disableHint = true;
  };

  # https://devenv.sh/packages/
  packages = with pkgs; [
    git
    gh
    curl

    # document creation / verification
    #
    # Used ad hoc throughout this repo's Markdown -> AsciiDoc migration to
    # render and sanity-check every converted .adoc file; kept here so that
    # workflow doesn't depend on remembering `nix-shell -p asciidoctor`.
    asciidoctor-with-extensions # asciidoctor-pdf, asciidoctor-reducer, asciidoctor-diagram
    pandoc

    # headless rendering
    xvfb-run
  ];

  enterShell = ''
    (
      set -euo pipefail
      cd '${config.devenv.root}'

      if tty -s; then
        devenv-help
      fi
    )
  '';

  scripts.devenv-help = {
    description = "Print this help";
    exec = ''
      set -euo pipefail
      cd '${config.devenv.root}'

      echo
      echo "Helper scripts provided by the devenv:"
      echo
      sed -e 's| |XXXXXX|g' -e 's|=| |' <<EOF | column -t | sed -e 's|^|- |' -e 's|XXXXXX| |g'
      ${lib.generators.toKeyValue { } (lib.mapAttrs (name: value: value.description) config.scripts)}
      EOF
      echo
    '';
  };

  # The only way in: `open-govpress render <file.adoc>... -o out.pdf`.
  #
  # Always run under xvfb-run: Electron has no headless mode and the packaged
  # binary refuses to render without a display (exit code 5). xvfb-run makes
  # this work the same way whether or not the calling shell has a real
  # display, which keeps local dev and CI identical.
  #
  # Downloads and extracts the release tarball on first use rather than at
  # `enterShell` time, so entering the shell stays fast when nobody needs to
  # render anything, and caches both under open-govpress/ (gitignored) so
  # repeat invocations don't re-fetch or re-extract.
  scripts.open-govpress = {
    description = "Render .adoc documents (open-govpress render <file>... -o out.pdf)";
    exec = ''
      set -euo pipefail
      cd '${config.devenv.root}'

      govpress_cache_dir="$(pwd)/open-govpress/.cache"
      govpress_archive="''${govpress_cache_dir}/open-govpress-${govpressVersion}-linux-x64.tar.gz"
      govpress_extract_dir="$(pwd)/open-govpress/.extracted"
      govpress_bin="''${govpress_extract_dir}/open-govpress-${govpressVersion}/open-govpress"

      if [ ! -x "''${govpress_bin}" ]; then
        mkdir -p "''${govpress_cache_dir}" "''${govpress_extract_dir}"

        if [ ! -f "''${govpress_archive}" ]; then
          ${lib.getExe pkgs.curl} -fL --retry 3 -o "''${govpress_archive}.part" '${govpressUrl}'
          mv "''${govpress_archive}.part" "''${govpress_archive}"
        fi

        echo '${govpressSha256}  '"''${govpress_archive}" | ${pkgs.coreutils}/bin/sha256sum -c -
        tar xzf "''${govpress_archive}" -C "''${govpress_extract_dir}"
      fi

      exec ${lib.getExe govpressFHS} ${lib.getExe pkgs.xvfb-run} -a "''${govpress_bin}" --no-sandbox "''${@}"
    '';
  };

  # Builds the whole published site locally: every tracked .adoc rendered
  # once per language into build/<lang>/, with the same per-language index
  # pages and language chooser that CI publishes to GitHub Pages.
  #
  # It shares tools/site-index.sh and tools/site-root.sh with the workflow on
  # purpose -- the point of building locally is to see what will be published,
  # which a second implementation of the index would quietly stop doing.
  scripts.render-docs = {
    description = "Render every .adoc document in every language into build/ (render-docs [lang...])";
    exec = ''
      set -euo pipefail
      cd '${config.devenv.root}'

      if [ "$#" -gt 0 ]; then
        langs=("''${@}")
      else
        langs=(en de fr it rm)
      fi

      for lang in "''${langs[@]}"; do
        case "$lang" in
          en | de | fr | it | rm) ;;
          *)
            echo "render-docs: unknown language '$lang' (expected en, de, fr, it or rm)" >&2
            exit 1
            ;;
        esac
      done

      for lang in "''${langs[@]}"; do
        # A document may opt out of a language with `:l10n-languages:` in its
        # header; absent means all five. Skipping it here keeps an untranslated
        # document out of that language entirely, rather than rendering a PDF
        # whose body every ifeval:: guard rejected.
        docs=()
        while IFS= read -r doc; do
          doc_langs=$(sed -n 's/^:l10n-languages:[[:space:]]*//p' "$doc" | head -1)
          if [ -z "$doc_langs" ] || grep -qw "$lang" <<<"$doc_langs"; then
            docs+=("$doc")
          fi
        done < <(git ls-files '*.adoc')

        echo "Rendering ''${#docs[@]} documents in $lang..."
        mkdir -p "build/$lang"
        open-govpress render --lang "$lang" -o "build/$lang" "''${docs[@]}"
        ./tools/site-index.sh "$lang" "build/$lang"
      done

      ./tools/site-root.sh build
      echo "Site built in build/ -- open build/index.html"
    '';
  };
}
