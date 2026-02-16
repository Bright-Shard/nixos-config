# Similar to https://github.com/NixOS/flake-compat/blob/master/default.nix
#
# However this one respects `inputs.x.follows` settings and lets you specify
# follow deps from stable nix

pkgs:

{
  src,
  follows ? { },
}:

with builtins;

let
  flake = import "${src}/flake.nix";

  outputs =
    if pathExists "${src}/flake.lock" then
      let
        lock = fromJSON (readFile "${src}/flake.lock");
        fetchFromLock =
          if lock.version == 7 then
            import ./lock-v7.nix { inherit flake lock pkgs; }
          else
            throw "Unsupported lockfile version ${lock.version} from flake ${src}";

        parseFollows =
          inputName: settings:
          if settings ? follows then
            inputs.${inputName}
          else
            throw "Flake ${src} has an `inputs.something.inputs.otherthing` setting that isn't 'follows'";
        importInput =
          input: cfg:
          follows.${input} or (
            let
              src = fetchFromLock input;
            in
            if cfg.flake or true then
              import ./. pkgs {
                inherit src;
                follows = mapAttrs parseFollows (cfg.inputs or { });
              }
            else
              src
          );
        inputs = mapAttrs importInput (flake.inputs or { });
      in
      flake.outputs (inputs // { self = result; })
    else
      flake.outputs { self = result; };

  # Special flake attributes
  result = outputs // {
    outPath = src;
    _type = "flake";
  };
in
result
