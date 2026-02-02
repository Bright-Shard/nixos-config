{
  NPINS,
  crux,
  pkgs,
  lib,
  config,
  ...
}:

with crux;
let
  inherit (lib)
    mkOption
    types
    mkMerge
    ;
in

let
  # https://mozilla.github.io/policy-templates
  policies = {
    ExtensionSettings =
      let
        extensions = {
          "{d634138d-c276-4fc8-924b-40a0ea21d284}" = "1password-x-password-manager";
          "" = "adnauseam";
        };
      in
      mapAttrs (_: id: {
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/${id}/latest.xpi";
        installation_mode = "force_installed";
        private_browsing = true;
      }) extensions;

    DisablePocket = true;
    DNSOverHTTPS.Enabled = false;
    EnableTrackingProtection = {
      Value = false;
      Cryptomining = false;
      Fingerprinting = false;
    };
    HttpsOnlyMode = "enabled";
    NoDefaultBookmarks = true;
    OfferToSaveLogins = false;
    SearchEngines = {
      Add = [
        {
          Name = "Kagi";
          URLTemplate = "https://kagi.com/search?token=${PRIV.KAGI-TOKEN}&q={searchTerms}";
          Method = "GET";
          IconURL = "https://kagi.com/favicon.ico";
        }
      ];
      Default = "Kagi";
      Remove = [
        "Google"
        "eBay"
        "Amazon.com"
        "Bing"
        "Perplexity"
      ];
    };
    # https://searchfox.org/firefox-main/source/modules/libpref/init/StaticPrefList.yaml
    Preferences = {
      # Don't show a warning when visiting about:config
      "browser.aboutConfig.showWarning" = false;
      # Always show bookmarks bar
      "browser.toolbars.bookmarks.visibility" = "always";
      # Force Firefox to not show a titlebar
      # Without this it tries to render the titlebar inline with tabs, even
      # if client-side decorations are disabled...
      "browser.tabs.inTitlebar" = 0;
      # Use the same search engine for private windows
      "browser.search.separatePrivateDefault" = false;
      # "browser.uiCustomization.state" = null;

      # For firefox second sidebar
      "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
      "dom.allow_scripts_to_close_windows" = true;
    };
  };
in

{
  options = {
    programs.zen-browser = {
      profiles = mkOption {
        type = types.attrsOf (
          types.submodule {
            # Install custom fx-autoconfig scripts
            options.fx-autoconfig-scripts = mkOption {
              type = types.listOf types.path;
              description = "Paths to JavaScript scripts to be loaded by fx-autoconfig for this profile. Note that these paths are passed to symlinkJoin, so you should pass the folder that contains all the files to be loaded by fx-autoconfig, and not the files themselves.";
              default = [ ];
            };
          }
        );
      };
      installFxAutoconfig = mkOption {
        type = types.bool;
        description = "Install fx-autoconfig for Firefox modding.";
        default = false;
      };
      additionalPolicies = mkOption {
        type = types.attrsOf types.anything;
        description = "Additional browser policies to set. See https://mozilla.github.io/policy-templates.";
        default = { };
      };
    };
  };

  config = {
    programs.zen-browser =
      let
        cfg = config.programs.zen-browser;
      in
      {
        # The normal Zen browser flake's package, with two patches:
        # 1. We override the `policies` argument of the browser to our custom
        #    Firefox policies (see above)
        # 2. We add a post install hook that installs fx-autoconfig
        package =
          let
            zen-with-policies = (import NPINS.zen-browser { inherit pkgs; }).beta-unwrapped.override {
              # Apply custom Firefox policies
              policies = lib.attrsets.recursiveUpdate policies cfg.additionalPolicies;
            };
            zen-unwrapped =
              if cfg.installFxAutoconfig then
                zen-with-policies.overrideAttrs {
                  postInstall = ''
                    lib=$out/lib/zen-bin-${zen-with-policies.version}
                    prefs=$lib/defaults/pref

                    # Prefs has read-only permissions by default, it seems?
                    chmod -R 755 $prefs

                    cat > $prefs/config-prefs.js << EOF
                    ${readFile "${NPINS.fx-autoconfig}/program/defaults/pref/config-prefs.js"}
                    EOF

                    cat > $lib/config.js << EOF
                    ${readFile "${NPINS.fx-autoconfig}/program/config.js"}
                    EOF
                  '';
                }
              else
                zen-with-policies;
          in
          pkgs.wrapFirefox zen-unwrapped { };
        profiles."default" = {
          containersForce = true;
          spacesForce = true;
          settings = {
            "zen.glance.activation-method" = "shift";
            "zen.pinned-tab-manager.restore-pinned-tabs-to-pinned-url" = true;
            "zen.view.use-single-toolbar" = false;
            "zen.workspaces.separate-essentials" = false;
          };
        };
      };

    home.file = listToAttrs (
      concatLists (
        map (
          profileName:
          let
            profile = config.programs.zen-browser.profiles.${profileName};
          in
          [
            {
              name = ".zen/${profileName}/chrome/utils";
              value = {
                recursive = true;
                source = "${NPINS.fx-autoconfig}/profile/chrome/utils";
              };
            }
            {
              name = ".zen/${profileName}/chrome/JS";
              value = {
                recursive = true;
                source = pkgs.symlinkJoin {
                  name = "fx-autoconfig-scripts-${profileName}";
                  paths = profile.fx-autoconfig-scripts;
                };
              };
            }
          ]
        ) (attrNames config.programs.zen-browser.profiles)
      )
    );
  };
}
