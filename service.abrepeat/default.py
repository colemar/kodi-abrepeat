# A-B Repeat - command entry point.
# Invoked from a keymap: RunScript(service.abrepeat[,arg]) or RunAddon(service.abrepeat).
#   cycle (default): set A -> set B and start loop -> clear
#   a / b / clear  : set A / set B / clear, for separate keys
# State lives in Home window (10000) properties and is read by service.py.
import sys
import xbmc
import xbmcaddon
import xbmcgui

ADDON = xbmcaddon.Addon()
L = ADDON.getLocalizedString
WIN = xbmcgui.Window(10000)
P_A, P_B = 'abrepeat.a', 'abrepeat.b'


def fmt(t):
    m, s = divmod(t, 60)
    h, m = divmod(int(m), 60)
    return f'{h}:{m:02d}:{s:06.3f}' if h else f'{m}:{s:06.3f}'


def notify(msg, ms=2000):
    xbmcgui.Dialog().notification(L(30000), msg, ADDON.getAddonInfo('icon'), ms, False)


def clear():
    WIN.clearProperty(P_A)
    WIN.clearProperty(P_B)


def set_a(t):
    WIN.clearProperty(P_B)
    WIN.setProperty(P_A, repr(t))
    notify(L(30001).format(a=fmt(t)))


def set_b(player, t):
    a = WIN.getProperty(P_A)
    if not a:
        notify(L(30003))
        return
    a = float(a)
    if t <= a + 0.2:
        notify(L(30004))
        return
    WIN.setProperty(P_B, repr(t))
    notify(L(30002).format(a=fmt(a), b=fmt(t)), 3000)
    player.seekTime(a)


def main():
    arg = sys.argv[1].lower() if len(sys.argv) > 1 else 'cycle'
    player = xbmc.Player()
    if arg == 'clear':
        clear()
        notify(L(30005))
        return
    if not player.isPlaying():
        notify(L(30006))
        return
    try:
        t = player.getTime()
    except RuntimeError:
        return
    if arg == 'a':
        set_a(t)
    elif arg == 'b':
        set_b(player, t)
    elif WIN.getProperty(P_B):
        clear()
        notify(L(30005))
    elif WIN.getProperty(P_A):
        set_b(player, t)
    else:
        set_a(t)


main()
