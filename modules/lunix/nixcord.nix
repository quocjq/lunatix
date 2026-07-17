{ inputs, ... }: {
  flake-file.inputs = {
    nixcord = {
      url = "github:4evy/nixcord";
    };
  };
  lix.nixcord = {
    homeManager = { pkgs, ... }: {
      imports = [ inputs.nixcord.homeModules.nixcord ];
      programs.nixcord = {
        enable = true;
        discord = {
          equicord.enable = true; # Equicord (has more plugins)
          branch = "stable";
          krisp.enable = true;
          openASAR.enable = true;
        };
        quickCss = "/* css goes here */";
        config = {
          useQuickCss = true;
          enabledThemeLinks = [
            # "https://raw.githubusercontent.com/refact0r/system24/refs/heads/main/theme/system24.theme.css"
            "https://raw.githubusercontent.com/refact0r/midnight-discord/refs/heads/master/themes/midnight.theme.css"
          ];
          frameless = true;
          transparent = true;
          plugins = {
            betterActivities.enable = true;
            betterAudioPlayer.enable = true;
            betterBanReasons.enable = true;
            betterSettings.enable = true;
            betterUploadButton.enable = true;
            biggerStreamPreview.enable = true;
            blurNsfw.enable = true;
            cancelFriendRequest.enable = true;
            cleanerChannelGroups.enable = true;
            clearUrls.enable = true;
            clickableRoles.enable = true;
            clientSideBlock = {
              hideBlockedMessages = false;
            };
            clipsEnhancements.enable = true;
            clipUpload.enable = true;
            declutter.enable = true;
            decor.enable = true;
            dragify.enable = true;
            f8Break.enable = true;
            fakeNitro.enable = true;
            fakeProfileThemes.enable = true;
            findReply.enable = true;
            fixFileExtensions.enable = true;
            hideMedia.enable = true;
            ignoreActivities = {
              enable = true;
              ignorePlaying = true;
            };
            limitlessScreenshare.enable = true;
            noF1.enable = true;
            noMosaic.enable = true;
            noNitroUpsell.enable = true;
            noOnboardingDelay.enable = true;
            noPendingCount.enable = true;
            quickReply.enable = true;
            showSongName.enable = true;
            silentMessageToggle.enable = true;
            silentTyping.enable = true;
            themeLibrary.enable = true;
            translate = {
              autoTranslate = true;
            };
            translatePlus.enable = true;
            unlimitedAccounts.enable = true;
            whoReacted.enable = true;
            whosWatching.enable = true;
          };
        };
        extraConfig.plugins = {
          CollapsibleUI = {
            enable = true;
            detachUserArea = false;
          };
          fakeNitro = {
            useHyperLinks = true;
          };
          fontLoader = {
            applyOnClodeBlocks = false;
          };
          globalBadges = {
            showRa1ncord = true;
          };
          limitlessScreenshare = {
            resolutions = [
              {
                label = "480p";
                value = 480;
              }
              {
                label = "720p";
                value = 720;
              }
              {
                label = "1080p";
                value = 1080;
              }
              {
                label = "1440p";
                value = 1440;
              }
              {
                label = "Source";
                value = 0;
              }
            ];
            fpss = [
              {
                label = "15fps";
                value = 15;
              }
              {
                label = "30fps";
                value = 30;
              }
              {
                label = "60fps";
                value = 60;
              }
            ];
            roundResolution = false;
          };
          messageClickActions = {
            enableDeleteOnClick = true;
            enableDoubleClickToEdit = true;
            enableDoubleClickToReply = true;
            requireModifier = false;
          };
          noBlockedMessages = {
            applyToIgnoredUsers = true;
            ignoreBlockedMessages = false;
            ignoreMessages = false;
          };
          platformIndicators = {
            badges = true;
          };
          showHiddenChannels = {
            hideUnreads = true;
          };
          showMeYourName = {
            displayNames = false;
            friendNicknames = "dms";
            inReplies = false;
            mode = "user-nick";
          };
          silentTyping = {
            contextMenu = true;
            isEnabled = true;
            showIcon = false;
          };
          translate = {
            shavian = true;
            sitelen = true;
            target = "en";
            toki = true;
          };
        };
      };
    };
  };
}
