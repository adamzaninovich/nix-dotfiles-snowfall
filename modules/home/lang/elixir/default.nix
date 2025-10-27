{ lib, config, pkgs, ... }:
with lib;
let
  cfg = config.bravo.lang.elixir;
in
{
  options.bravo.lang.elixir = with types; {
    enable = mkEnableOption "Elixir language support";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      elixir_1_17
      erlang_27
      # lexical
    ] ++ lib.optional stdenv.isLinux inotify-tools
    ++ lib.optional stdenv.isDarwin terminal-notifier;

    home.sessionVariables = {
      ERL_AFLAGS = "-kernel shell_history enabled";
    };

    home.file.".iex.exs".text = /* elixir */ ''
      # IEx.configure colors: [enabled: true]
      Application.put_env(:elixir, :ansi_enabled, true)
      IEx.configure(
        colors: [
          eval_result: [:green, :bright],
          eval_error: [:red, :bright],
          eval_info: [:yellow, :bright],
        ]
        default_prompt:
          "#{IO.ANSI.magenta} #{IO.ANSI.reset}(%counter) |",
        continuation_prompt:
          "#{IO.ANSI.magenta} #{IO.ANSI.reset}(.) |"
      )

      defmodule Benchmark do
        def measure(function) do
          function
          |> :timer.tc
          |> elem(0)
          |> Kernel./(1_000_000)
        end
      end
    '';

    # lsp support
    # programs.git.ignores = [ ".lexical" ".elixir-ls" ];
    #
    # xdg.configFile."nvim/lsp/lexical.lua".text = /* lua */ ''
    #   return {
    #     cmd = { 'lexical' },
    #     filetypes = { 'elixir', 'eelixir', 'heex', 'surface' },
    #     root_markers = { '.mix.exs', '.git'}
    #   }
    # '';
    #
    # programs.neovim.extraLuaConfig = /* lua */ ''
    #   vim.lsp.enable('lexical')
    # '';
  };
}

