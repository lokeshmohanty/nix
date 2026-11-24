{
  programs.sioyek = {
    enable = true;
    config = {
      # ── SyncTeX ────────────────────────────────────────────────────────────
      inverse_search_command = "nvim --headless -c \"VimtexInverseSearch %2 '%1'\"";
      should_open_new_pdf_in_existing_window = "1";
      should_load_tutorial_when_no_other_file = "0";

      # ── Rendering ──────────────────────────────────────────────────────────
      # Higher = sharper text at normal zoom levels
      linear_filter_ppm = "3000";

      # ── Scroll & zoom ──────────────────────────────────────────────────────
      smooth_scroll_speed = "3";
      vertical_move_amount = "0.15";   # fraction of screen per j/k
      horizontal_move_amount = "0.08";
      zoom_inc_factor = "1.15";        # per +/- press

      # ── Page layout ────────────────────────────────────────────────────────
      page_separator_width = "2";
      fit_to_page_width_on_load = "1";

      # ── Ruler / highlights ─────────────────────────────────────────────────
      should_use_ruler_to_highlight = "1";
      ruler_padding = "0.1";
      ruler_x_padding = "0.1";

      # ── Dark mode ──────────────────────────────────────────────────────────
      dark_mode_contrast = "0.8";
      default_dark_mode = "0";

      # ── External search engines (used by 'e' / shift_click) ────────────────
      search_url_0 = "https://scholar.google.com/scholar?q=%s";
      search_url_1 = "https://www.semanticscholar.org/search?q=%s";
      middle_click_search_engine = "0";
      shift_click_search_engine  = "1";
    };
  };
}
