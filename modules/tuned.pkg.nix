{
  python3Packages,
  fetchFromGitHub,
  python3,
  desktop-file-utils,
  pkg-config,
  systemd,
  gobject-introspection,
  wrapGAppsHook3,
  virt-what,
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
  ];

  dontWrapGApps = true;

  makeFlags = [
    "PYTHON=${python3}/bin/python3"
    "PREFIX="
    "DESTDIR=${placeholder "out"}"
    "PYTHON_SITELIB=/${python3.sitePackages}"
  ];
  preFixup = ''
    makeWrapperArgs+=("''${gappsWrapperArgs[@]}")
  '';

  doCheck = true;
  checkTarget = "test";
}
