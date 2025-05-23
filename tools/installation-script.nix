{
  bazelrcContent,
  namespace,
  pkgs,
}: let
  bazelrc = pkgs.writeText "${namespace}.bazelrc" ''
    # These flags are dynamically generated by the ${namespace} flake module.
    #
    # Add `try-import %%workspace%%/${namespace}.bazelrc` to your .bazelrc
    # to include these flags to your Bazel environment.

    ${bazelrcContent}
  '';
in ''
  if ! type -t git >/dev/null; then
    # In pure shells
    echo 1>&2 "WARNING: ${namespace}: git command not found; skipping installation."
  elif ! ${pkgs.git}/bin/git rev-parse --git-dir &> /dev/null; then
    echo 1>&2 "WARNING: ${namespace}: .git not found; skipping installation."
  else
    GIT_WC=`${pkgs.git}/bin/git rev-parse --show-toplevel`

    # These update procedures compare before they write, to avoid
    # filesystem churn. This improves performance with watch tools like
    # lorri and prevents installation loops by lorri.

    if ! readlink "''${GIT_WC}/${namespace}.bazelrc" >/dev/null \
      || [[ $(readlink "''${GIT_WC}/${namespace}.bazelrc") != ${bazelrc} ]]; then
      echo 1>&2 "${namespace}: updating $PWD repository"
      [ -L ${namespace}.bazelrc ] && unlink ${namespace}.bazelrc

      if [ -e "''${GIT_WC}/${namespace}.bazelrc" ]; then
        echo 1>&2 "${namespace}: WARNING: Refusing to install because of pre-existing ${namespace}.bazelrc"
        echo 1>&2 "  Remove the ${namespace}.bazelrc file and add ${namespace}.bazelrc to .gitignore."
      else
        ln -fs ${bazelrc} "''${GIT_WC}/${namespace}.bazelrc"
      fi
    fi
  fi
''
