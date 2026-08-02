{ config, ... }:
{
  home.file.".config/micro/syntax/nix.yaml".text = ''
    filetype: nix

    detect:
        filename: "\\.nix$"

    rules:
        # Brackets and Operators
        - special: "(\\{|\\}|\\(|\\)|\\;|\\(|\\]|\\[|`|\\\\|\\$|<|>|!|=|&|\\|)"

        # Reserved words / Keywords
        - statement: "\\b(assert|else|if|in|inherit|let|rec|then|with|isNull)\\b"

        # Built-in functions/constants
        - identifier: "\\b(true|false|null|import|abort|throw|baseNameOf|dirOf|fetchTarball|map|removeAttrs|scopedImport|toString|derivation)\\b"

        # Comments
        - comment:
            start: "#"
            end: "$"
        - comment:
            start: "/\\*"
            end: "\\*/"

        # Strings
        - constant.string:
            start: "\""
            end: "\""
            skip: "\\\\."
            rules:
                - constant.specialChar: "\\\\."
                - constant.specialChar: "\\$\\{[^}]+\\}"

        # Indented Strings (Double Single Quotes)7
        - constant.string:
            start: "'''"
            end: "'''"
            rules:
                - constant.specialChar: "\\$\\$\\{[^}]+\\}"
                - constant.specialChar: "''''"

        # Numbers
        - constant.number: "\\b[0-9]+\\b"
  '';

  programs = {
    git = {
      enable = true;
      lfs.enable = true;
      # Globally ignore memd's per-project data so it can never be tracked into
      # a code repo (memory notes + agent contracts are personal, not for push).
      ignores = [
        ".memory/"
        ".model/"
      ];
      settings = {
        user = {
          name = "lowcache";
          email = "drawpdeadredd@gmail.com";
        };
        init.defaultBranch = "main";
        # gh supplies the credential for github.com pushes. The generated
        # ~/.config/git/config is a read-only Nix-store symlink, so
        # `gh auth setup-git` can't write it at runtime — declare the helper
        # here instead. Scoped to github.com so it never intercepts other hosts.
        credential."https://github.com".helper = "!gh auth git-credential";
      };
      signing = {
        signByDefault = false;
        format = "ssh";
        key = "${config.home.homeDirectory}/.ssh/id_ed25519.pub";
      };
    };

    starship.enable = true;

    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    micro = {
      enable = true;
      settings = {
        tabsize = 2;
        tabstospaces = true;
        autosu = true;
        colorscheme = "dracula-tc";
        fastdirty = true;
        filemanager = false;
        linter = false;
        multitab = "vsplit";
        parsecursor = true;
        saveundo = true;
        scrollbar = true;
        scrollbarchar = "[]";
        formatonsave = true;
        mkparents = true;
        "nix.formatter" = "nixfmt";
        cursorline = true;
        incsearch = true;
        ignorecase = true;
        smartcase = true;
        "lsp.server" = "nix=nil";
        # Third-party plugin channel for `preview` (pandoc-backed markdown
        # preview split). Plugins themselves install imperatively into
        # ~/.config/micro/plug, which persist.nix already keeps.
        pluginrepos = [
          "https://raw.githubusercontent.com/weebi/micro-preview/master/repo.json"
        ];
      };
    };
  };
}
