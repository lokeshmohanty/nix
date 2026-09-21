{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:
let
  agents = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};
  localPkgs = import ../pkgs { inherit pkgs inputs; };
in
{
  options.modules.ai.enable = lib.mkEnableOption "AI CLI tooling";

  config = lib.mkIf config.modules.ai.enable {
    home.packages = with agents; [
      # harness
      chatgpt 
      claude-code 
      antigravity-cli 
      pi
      agent-browser
      opencode
      pkgs.libsixel # required by pi for image rendering

      # AXI agent-facing CLIs (gh-axi, chrome-devtools-axi, lavish-axi).
      # Required on PATH by the Claude SessionStart hooks in
      # config/agentic-harness/claude/settings.json.
      localPkgs.axi-tools
    ];
  };
}
