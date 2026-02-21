;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!


;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets. It is optional.
(setq user-full-name "Lokesh Mohanty"
      user-mail-address "")

;; Doom exposes five (optional) variables for controlling fonts in Doom:
;;
;; - `doom-font' -- the primary font to use
;; - `doom-variable-pitch-font' -- a non-monospace font (where applicable)
;; - `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;; - `doom-symbol-font' -- for symbols
;; - `doom-serif-font' -- for the `fixed-pitch-serif' face
;;
;; See 'C-h v doom-font' for documentation and more examples of what they
;; accept. For example:
;;
;; (setq doom-font (font-spec :family "Fira Code" :size 18 :weight 'semi-light)
;;      doom-variable-pitch-font (font-spec :family "Fira Sans" :size 19))
(setq doom-font (font-spec :family "JetBrainsMono" :size 18)
      doom-variable-pitch-font (font-spec :family "DejaVu Sans" :size 19))
;;
;; If you or Emacs can't find your font, use 'M-x describe-font' to look them
;; up, `M-x eval-region' to execute elisp code, and 'M-x doom/reload-font' to
;; refresh your font settings. If Emacs still can't find your font, it likely
;; wasn't installed correctly. Font issues are rarely Doom issues!

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
;; (setq doom-theme 'doom-one)

;; `gruvbox-material' contrast and palette options
(setq doom-everforest-background  "medium")  ; or hard (defaults to soft)

;; ;; `gruvbox-material-light' contrast and palette options
;; (setq doom-everforest-light-background  "medium") ; or hard (defaults to soft)

;; set `doom-theme'
(setq doom-theme 'doom-everforest) ; dark variant
;; (setq doom-theme 'doom-everforest-light) ; light variant

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type 'relative)


;; Whenever you reconfigure a package, make sure to wrap your config in an
;; `after!' block, otherwise Doom's defaults may override your settings. E.g.
;;
;;   (after! PACKAGE
;;     (setq x y))
;;
;; The exceptions to this rule:
;;
;;   - Setting file/directory variables (like `org-directory')
;;   - Setting variables which explicitly tell you to set them before their
;;     package is loaded (see 'C-h v VARIABLE' to look up their documentation).
;;   - Setting doom variables (which start with 'doom-' or '+').
;;
;; Here are some additional functions/macros that will help you configure Doom.
;;
;; - `load!' for loading external *.el files relative to this one
;; - `use-package!' for configuring packages
;; - `after!' for running code after a package has loaded
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c c k').
;; This will open documentation for it, including demos of how they are used.
;; Alternatively, use `C-h o' to look up a symbol (functions, variables, faces,
;; etc).
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.

;; When I bring up Doom's scratch buffer with SPC x, it's often to play with
;; elisp or note something down (that isn't worth an entry in my notes). I can
;; do both in `lisp-interaction-mode'.
(setq doom-scratch-initial-major-mode 'lisp-interaction-mode)

;; Prevents some cases of Emacs flickering.
(add-to-list 'default-frame-alist '(inhibit-double-buffering . t))


;; ;;
;; ;;; Modules

;; ;;; :completion corfu
;; ;; IMO, modern editors have trained a bad habit into us all: a burning need for
;; ;; completion all the time -- as we type, as we breathe, as we pray to the
;; ;; ancient ones -- but how often do you *really* need that? I say rarely, so opt
;; ;; for manual completion:
;; ;; (after! corfu
;; ;;   (setq corfu-auto nil))


;; ;;; :ui modeline
;; ;; An evil mode indicator is redundant with cursor shape
;; (setq doom-modeline-modal nil
;;       doom-modeline-check-simple-format t)


;; ;;; :editor evil
;; ;; Focus new window after splitting
;; (setq evil-split-window-below t
;;       evil-vsplit-window-right t)

;; ;; Implicit /g flag, because I rarely use it without
;; (setq evil-ex-substitute-global t)


;;; :lang org
(setq org-directory "~/Documents/Org/"
      org-roam-directory "~/Documents/Org/Roam")

(setq org-appear-delay "0.3"
      org-appear-autolinks t)

;;; :ui doom-dashboard
(setq fancy-splash-image (file-name-concat doom-user-dir "splash.png"))
;; Hide the menu for as minimalistic a startup screen as possible.
(setq +doom-dashboard-functions '(doom-dashboard-widget-banner))

(map! :leader
      "-" #'dirvish)
