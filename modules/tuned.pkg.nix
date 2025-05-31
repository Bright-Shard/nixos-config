{
  python3Packages,
  fetchFromGitHub,
  python3,
  desktop-file-utils,
  pkg-config,
  systemd,
  gobject-introspection,
  wrapGAppsHook3,
  virt-what
}:

python3Packages.buildPythonApplication rec {
  pname = "tuned";
  version = "2.25.1";
  pyproject = false;

  src = fetchFromGitHub {
    owner = "redhat-performance";
    repo = "tuned";
    rev = "refs/tags/v${version}";
    hash = "sha256-MMyYMgdvoAIeLCqUZMoQYsYYbgkXku47nZWq2aowPFg=";
  };

  postPatch = ''
    # The makefile has 2 arguments (DESTDIR and PREFIX) that are used
    # in different places to prefix different things... here we unify
    # a few places
    substituteInPlace Makefile \
      --replace-fail "mkdir -p \$(DESTDIR)/" "mkdir -p \$(PREFIX)/"

    # These tests try to access TTY, which isn't available in the Nix
    # sandbox. So we prefix them with _ to disable them.
    substituteInPlace tests/unit/hardware/test_device_matcher_udev.py \
      --replace-fail "def test_regex_search" "def _test_regex_search" \
      --replace-fail "def test_simple_search" "def _test_simple_search"
    substituteInPlace tests/unit/hardware/test_inventory.py \
      --replace-fail "def test_get_device" "def _test_get_device"

    # TuneD tries to load its glade file from a fixed system path
    substituteInPlace "tuned-gui.py" \
      --replace-fail "/usr/share/tuned/ui/tuned-gui.glade" "${placeholder "out"}/share/tuned/ui/tuned-gui.glade"
  '';

  nativeBuildInputs = [
    desktop-file-utils
    pkg-config
    gobject-introspection
    wrapGAppsHook3
  ];
  buildInputs = [ systemd ];
  propagatedBuildInputs = [ virt-what ];
  dependencies = with python3.pkgs; [
    dbus-python
    python-linux-procfs
    pygobject3
    pyudev
    pyperf
  ];

  dontWrapGApps = true;

  makeFlags = [
    "PYTHON=${python3}/bin/python3"
    "PYTHON_SITELIB=$(PREFIX)/${python3.sitePackages}"
    "PREFIX=${placeholder "out"}"
    "SYSCONFDIR=$(PREFIX)/etc"
    "TMPFILESDIR=$(PREFIX)$(TMPFILESDIR_FALLBACK)"
    "UNITDIR=$(PREFIX)$(UNITDIR_FALLBACK)"
  ];
  preFixup = ''
    makeWrapperArgs+=("''${gappsWrapperArgs[@]}")
  '';

  pythonImportsCheck = "tuned";
  installCheckTarget = "test";
}
