{ lib, config, pkgs, ... }:
with lib;
let
  cfg = config.bravo.dk.aws-cia;
in
{
  options.bravo.dk.aws-cia = {
    enable = mkEnableOption "AWS CIA authentication tools";

    profile = mkOption {
      type = types.str;
      default = "REDACTED_PROFILE";
      description = "AWS profile name to use";
    };
  };

  config = mkIf cfg.enable {
    home.sessionVariables = {
      AWS_PROFILE = cfg.profile;
      DOTNET_CLI_TELEMETRY_OPTOUT = "1";
    };

    # Install AWS CIA login script
    home.file.".local/bin/aws-cia-login.exp" = {
      text = ''
        #!/usr/bin/expect -f

        # Set encoding to UTF-8
        fconfigure stdout -encoding utf-8
        fconfigure stderr -encoding utf-8

        # Get username and password from macOS keychain
        set username [exec sh -c "security find-generic-password -a aws-cia -s username -w 2>/dev/null || echo \"\""]
        set password [exec sh -c "security find-generic-password -a aws-cia -s password -w 2>/dev/null || echo \"\""]

        # Check if environment variables are set
        if {$username eq "" || $password eq ""} {
          puts "Error: AWS credentials not found in keychain"
          puts "Run 'aws setup' to store your credentials securely"
          exit 1
        }
        set timeout 30

        # Start the aws-cia login command
        spawn aws-cia login

        # Handle username prompt
        expect "Enter Username:" {
          send "$username\r"
        }

        # Handle password prompt
        expect "Enter your password:" {
          send "$password\r"
        }

        # Wait for login success
        expect "Login Successful."

        # Wait for the Duo code prompt and extract the 3-digit code
        expect -re "Enter 3 digit Duo code in app: (\[0-9\]{3})" {
          set duo_code $expect_out(1,string)
          puts ""
          # Copy duo code to clipboard
          exec echo -n $duo_code | pbcopy
          puts "Waiting for MFA completion..."
        }

        # Wait for MFA success
        expect "MFA Successful."

        # Handle role selection - look for REDACTED_ROLE and select it
        expect {
          -re "(\[0-9\]+)\. REDACTED_ROLE" {
            set role_number $expect_out(1,string)
            puts "Found REDACTED_ROLE as option $role_number"
          }
        }

        expect "Choose your role:" {
          send "$role_number\r"
        }

        # Wait for final success message
        expect "Credentials updated successfully. Enjoy your AWS sessions!"

        puts "\nAWS login completed successfully!"
      '';
      executable = true;
    };

    # AWS command with subcommands for zsh
    programs.zsh.initContent = lib.mkOrder 975 ''
      aws() {
        local subcommand="$1"

        case "$subcommand" in
          login)
            ~/.local/bin/aws-cia-login.exp
            ;;
          setup)
            local existing_username
            existing_username="$(security find-generic-password -a aws-cia -s username -w 2>/dev/null)"

            if [[ -z "$existing_username" ]]; then
              echo -n "Enter AWS CIA username: "
              read username

              security add-generic-password -a aws-cia -s username -w "$username" 2>/dev/null
              echo "Username stored in keychain."
            else
              echo "Using existing username: $existing_username"
            fi

            echo -n "Enter AWS CIA password: "
            read -s password
            echo

            security delete-generic-password -a aws-cia -s password &>/dev/null || true
            security add-generic-password -a aws-cia -s password -w "$password" &>/dev/null

            echo "Password updated in keychain."
            echo "You can now use 'aws login' command."
            ;;
          update)
            dotnet tool update -g REDACTED_TOOL --no-cache
            ;;
          *)
            echo "Usage: aws {setup|login|update}"
            echo "  setup  - Store AWS CIA credentials in keychain"
            echo "  login  - Authenticate with AWS using stored credentials"
            echo "  update - Update REDACTED_TOOL dotnet tool"
            return 1
            ;;
        esac
      }

      # Tab completion for aws function
      _aws_completion() {
        local -a subcommands
        subcommands=(
          'setup:Store AWS CIA credentials in keychain'
          'login:Authenticate with AWS using stored credentials'
          'update:Update REDACTED_TOOL dotnet tool'
        )
        _describe 'aws subcommand' subcommands
      }
      compdef _aws_completion aws
    '';
  };
}
