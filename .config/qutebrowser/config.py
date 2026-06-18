## Reload:  :config-source
## Portal:  qute://settings

config.load_autoconfig()

# ── Catppuccin Mocha theme ──────────────────────────────────────────────
import catppuccin
catppuccin.setup(c, 'mocha', True)

# ── Catppuccin pink accents ─────────────────────────────────────────────
# Tab contrast (unselected tabs slightly lighter for visual separation)
c.colors.tabs.selected.odd.bg = "#1e1e2e"     # base (selected odd)
c.colors.tabs.selected.even.bg = "#1e1e2e"    # base (selected even)
c.colors.tabs.odd.bg = "#45475a"              # surface1 (unselected odd)
c.colors.tabs.even.bg = "#45475a"             # surface1 (unselected even)
# Statusbar in normal mode — pink text
c.colors.statusbar.normal.bg = "#1e1e2e"      # base
c.colors.statusbar.normal.fg = "#f5c2e7"      # pink
# Completion category headers — pink
c.colors.completion.category.bg = "#1e1e2e"
c.colors.completion.category.fg = "#f5c2e7"

# ── Startup ───────────────────────────────────────────────────────────
c.url.start_pages = ["https://duckduckgo.com"]
c.auto_save.session = True
c.tabs.position = "top"
c.tabs.show = "multiple"         # hide when only 1 tab
c.tabs.background = True
c.tabs.title.alignment = "center"
c.tabs.title.format = "{current_title}"
c.tabs.title.format_pinned = "{current_title}"
c.tabs.tooltips = False  # disable qutebrowser tab tooltip requests
c.window.hide_decoration = True  # hide OS title bar; komorebi also strips it

# ── Window decorations (frameless via Qt FramelessWindowHint / WS_POPUP) ─
# Keep this block unless qutebrowser/Qt changes its window API again.
#
# Why this exists:
# - qutebrowser 3.x on Windows runs on Qt 6 / PyQt6.
# - c.window.hide_decoration is not enough here: on this setup it can remove
#   the min/max/close buttons without reliably removing the actual title bar.
# - Komorebi's remove_titlebar_applications rule is still useful, but by itself
#   it did not remove qutebrowser's title bar in testing.
# - Setting Qt.WindowType.FramelessWindowHint on qutebrowser's main window is
#   the piece that actually made the title bar disappear again.
#
# Important implementation details:
# - Use qutebrowser's own Qt compatibility imports, not PyQt5/PyQt6 directly.
#   qutebrowser exposes Qt through qutebrowser.qt.*.
# - Use objreg to get the real qutebrowser main window. QApplication.activeWindow
#   was unreliable during config loading.
# - Config is read before the main window is always registered, so retry with
#   QTimer.singleShot until objreg can return the window.
# - FramelessWindowHint maps to a native frameless/WS_POPUP-style window on
#   Windows, so DWM does not draw the normal title bar.
from qutebrowser.qt.core import QTimer, Qt
from qutebrowser.utils import objreg


def _frameless():
    try:
        win = objreg.get("main-window", scope="window", window=0)
    except objreg.NoWindow:
        # The main window is not registered yet during early config load.
        # Retry shortly instead of failing config.py startup.
        QTimer.singleShot(50, _frameless)
        return

    flags = win.windowFlags()
    win.setWindowFlags(flags | Qt.WindowType.FramelessWindowHint)

    # Changing Qt window flags can hide/recreate the native window; show() makes
    # the updated native style visible immediately.
    win.show()


QTimer.singleShot(0, _frameless)

# ── Global Qt tooltip suppression ───────────────────────────────────
# qutebrowser's tabs.tooltips only covers tab hover text. QtWebEngine and
# other widgets can still request native QToolTip windows, which Komorebi sees
# as independent top-level windows. Block tooltip events at QApplication level
# and make direct QToolTip.showText calls no-op.
try:
    from qutebrowser.qt.core import QObject, QEvent
    try:
        from qutebrowser.qt.widgets import QApplication, QToolTip
    except Exception:
        from PyQt6.QtWidgets import QApplication, QToolTip

    class _NoToolTipFilter(QObject):
        def eventFilter(self, obj, event):
            tooltip_events = {
                getattr(QEvent.Type, "ToolTip", None),
                getattr(QEvent.Type, "ToolTipChange", None),
                getattr(QEvent.Type, "WhatsThis", None),
            }
            if event.type() in tooltip_events:
                try:
                    QToolTip.hideText()
                except Exception:
                    pass
                return True
            return False

    def _disable_qt_tooltips():
        app = QApplication.instance()
        if app is None:
            QTimer.singleShot(50, _disable_qt_tooltips)
            return

        def _noop_tooltip(*args, **kwargs):
            try:
                QToolTip.hideText()
            except Exception:
                pass
            return None

        for attr in ("showText", "show_text"):
            if hasattr(QToolTip, attr):
                try:
                    setattr(QToolTip, attr, staticmethod(_noop_tooltip))
                except Exception:
                    pass

        global _no_tooltip_filter
        try:
            app.removeEventFilter(_no_tooltip_filter)
        except Exception:
            pass
        _no_tooltip_filter = _NoToolTipFilter(app)
        app.installEventFilter(_no_tooltip_filter)

        for widget in app.allWidgets():
            for setter in ("setToolTip", "setStatusTip", "setWhatsThis"):
                if hasattr(widget, setter):
                    try:
                        getattr(widget, setter)("")
                    except Exception:
                        pass
        try:
            QToolTip.hideText()
        except Exception:
            pass

    QTimer.singleShot(0, _disable_qt_tooltips)
except Exception:
    pass

# ── Qt popups/tooltips (Komorebi rule dependency) ───────────────────
# The right-click context menu in Qt6 creates a separate OS window with
# classes like Qt\\d+QWindowPopup.*. Tab hover tooltips use
# Qt*QWindowTool* classes; disable tab tooltips with c.tabs.tooltips = False,
# then suppress all native Qt tooltip events with the global filter above.
#
# The fix lives in komorebi.org (Floating Applications section):
#   Exe: qutebrowser.exe + Class: Qt\\d+QWindowPopup.*
#
# If the popup class changes with a Qt version upgrade, re-identify it with:
#   komorebic visible-windows   (run while context menu is visible)

# ── Privacy ────────────────────────────────────────────────────────────
c.content.cookies.accept = "no-3rdparty"
c.content.headers.do_not_track = True
c.content.headers.user_agent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
c.content.javascript.enabled = True

# ── Downloads ──────────────────────────────────────────────────────────
c.downloads.location.directory = "~/Downloads"
c.downloads.location.prompt = False
c.downloads.remove_finished = 5000

# ── Editor (for Ctrl-E in text fields) ─────────────────────────────────
c.editor.command = [
    "C:/Program Files/Emacs/emacs-30.2/bin/emacsclientw.exe",
    "-c", "-F", "'(name . \"qute-edit\")'",
    "-n", "{file}",
]

# ── Fonts ──────────────────────────────────────────────────────────────
c.fonts.default_family = "CaskaydiaCove NFM"
c.fonts.default_size = "11pt"
c.fonts.tabs.selected = "12pt default_family"
c.fonts.tabs.unselected = "12pt default_family"
c.fonts.completion.entry = "10pt default_family"
c.fonts.completion.category = "bold 10pt default_family"
c.fonts.hints = "bold 10pt default_family"

# ── Hints ─────────────────────────────────────────────────────────────
c.hints.chars = "asdfghjkl"
c.hints.uppercase = True             # show uppercase; accepts lowercase
c.hints.border = "1px solid #f5c2e7"  # catppuccin pink
c.colors.hints.fg = "#cdd6f4"        # text
c.colors.hints.bg = "#313244"        # surface0 (matching mocha)
c.colors.hints.match.fg = "#cdd6f4"

c.url.searchengines = {
    "DEFAULT": "https://duckduckgo.com/?q={}",
    "g":       "https://google.com/search?q={}",
    "w":       "https://en.wikipedia.org/wiki/{}",
    "yt":      "https://www.youtube.com/results?search_query={}",
    "gh":      "https://github.com/search?q={}",
    "aw":      "https://wiki.archlinux.org/title/{}",
    "npm":     "https://www.npmjs.com/search?q={}",
    "aur":     "https://aur.archlinux.org/packages?O=0&K={}",
}

c.content.blocking.enabled = True
c.content.blocking.method = "auto"
c.content.blocking.adblock.lists = [
    "https://easylist.to/easylist/easylist.txt",
    "https://easylist.to/easylist/easyprivacy.txt",
]
c.content.blocking.hosts.lists = [
    "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts",
]

# Disable dark mode globally
c.colors.webpage.bg = "#1e1e2e"
c.colors.webpage.darkmode.enabled = False
c.colors.webpage.preferred_color_scheme = "dark"

# Toggle on/off per page (config-cycle flips booleans)
config.bind("gr", "config-cycle colors.webpage.darkmode.enabled")

# Reader mode (extract article content, open in new tab)
config.bind("gR", "spawn --userscript readability.bat")

# ── History navigation (J = back, K = forward) ─────────────────────────
config.bind("J", "back")
config.bind("K", "forward")

# ── Tab switching (H = prev, L = next) ─────────────────────────────────
config.bind("H", "tab-prev")
config.bind("L", "tab-next")

# ── Tab management ────────────────────────────────────────────────────
config.bind("x", "tab-close")
config.bind("X", "undo")
config.bind("t", "open -t")                    # blank new tab
config.bind("T", "tab-clone")                  # duplicate tab
config.bind("gx0", "tab-close -o")     # close other tabs
config.bind("gx$", "tab-close -r")     # close right tabs
config.bind("<", "tab-move -")        # move tab left
config.bind(">", "tab-move +")        # move tab right
config.bind("g0", "tab-focus 1")       # first tab
config.bind("g$", "tab-focus -1")      # last tab

# ── Scrolling (d = down 1/4 page, u = up 1/4 page) ────────────────────
config.bind("d", "scroll-page 0 0.25")
config.bind("u", "scroll-page 0 -0.25")
config.bind("h", "scroll-page -0.5 0")
config.bind("l", "scroll-page 0.5 0")
config.bind("$", "scroll-to-percent 100")
config.bind("^", "scroll-to-percent 0")

# ── Window navigation (C-h/j/k/l = consistent with Emacs) ────────────
config.bind("<Ctrl-h>", "home")
config.bind("<Ctrl-l>", "cmd-set-text -s :open")
config.bind("<Ctrl-j>", "scroll-page 0 1")
config.bind("<Ctrl-k>", "scroll-page 0 -1")

# ── Tab index shortcuts (Ctrl+1-9 → tab 1-9, Ctrl+0 → last) ────────
config.bind("<Ctrl-1>", "tab-focus 1")
config.bind("<Ctrl-2>", "tab-focus 2")
config.bind("<Ctrl-3>", "tab-focus 3")
config.bind("<Ctrl-4>", "tab-focus 4")
config.bind("<Ctrl-5>", "tab-focus 5")
config.bind("<Ctrl-6>", "tab-focus 6")
config.bind("<Ctrl-7>", "tab-focus 7")
config.bind("<Ctrl-8>", "tab-focus 8")
config.bind("<Ctrl-9>", "tab-focus 9")
config.bind("<Ctrl-0>", "tab-focus -1")

# ── URL / search ──────────────────────────────────────────────────────
config.bind("o", "cmd-set-text -s :open")
config.bind("O", "cmd-set-text -s :open -t")
config.bind("N", "cmd-set-text -s :open -t {url}")        # current URL new tab
config.bind("M", "bookmark-add")
config.bind("S", "cmd-set-text -s :quickmark-load")
config.bind("B", "quickmark-load -t")
config.bind("?", ":help")
config.bind("ZZ", "quit")

# ── Org capture (url+title → Emacs: journal/log/task/denote) ─────────
config.bind("yl", "spawn --detach wscript //B \"$HOME/.config/scripts/utility/org-capture.vbs\" l \"{url}\" \"{title}\"")
config.bind("yt", "spawn --detach wscript //B \"$HOME/.config/scripts/utility/org-capture.vbs\" t \"{url}\" \"{title}\"")
config.bind("ya", "spawn --detach wscript //B \"$HOME/.config/scripts/utility/org-capture.vbs\" a \"{url}\" \"{title}\"")
config.bind("yd", "spawn --detach wscript //B \"$HOME/.config/scripts/utility/org-capture.vbs\" d \"{url}\" \"{title}\"")
config.bind("yo", "spawn --detach wscript //B \"$HOME/.config/scripts/utility/org-capture.vbs\" o \"{url}\" \"{title}\"")

# ── Timed passthrough (z / C-z; auto‑leave after 2.5 s) ───────────────
config.bind("z", "mode-enter passthrough ;; cmd-later 2000 mode-leave")
config.bind("<Ctrl+z>", "mode-enter passthrough")
config.unbind("<Ctrl+v>")              # moved to C-z

# ── Misc ──────────────────────────────────────────────────────────────
config.bind("gf", "view-source")       # view source (like tridactyl gf)
