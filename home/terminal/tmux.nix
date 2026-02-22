{pkgs, ...}: {
  programs.tmux = {
    enable = true;
    baseIndex = 1;
    mouse = true;
    keyMode = "vi";
    customPaneNavigationAndResize = true;
    shell = "${pkgs.fish}/bin/fish";
    terminal = "screen-256color";
    historyLimit = 5000;
    prefix = "M-f";
    extraConfig = ''
      # general
      set -g renumber-windows on
      set-option -g status-position top
      set-option -sg escape-time 0

      # keybindings
      bind "\`" switch-client -t "{marked}"
      bind-key M-h split-window -hc "#{pane_current_path}"
      bind-key M-v split-window -vc "#{pane_current_path}"
      bind c new-window -c "#{pane_current_path}"
      bind Space last-window
      bind-key M-Space switch-client -l
      bind-key M-j choose-window 'join-pane -h -s "%%"'
      bind-key M-J choose-window 'join-pane -s "%%"'

      # copy and paste
      bind -T copy-mode-vi v send -X begin-selection
      bind -T copy-mode-vi v send -X begin-selection
      bind -T copy-mode-vi y send-keys -X copy-selection-and-cancel
      bind P paste-buffer
      bind -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel

      # for image support in yazi
      set -g allow-passthrough all
      set -ga update-environment TERM
      set -ga update-environment TERM_PROGRAM
    '';
    plugins = with pkgs.tmuxPlugins; [gruvbox];
  };
}
