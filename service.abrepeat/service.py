# A-B Repeat - background service.
# Every 50 ms: if both A and B are set and the playback position is >= B, seek to A.
# A/B are cleared whenever playback starts, stops or ends.
# No keymap is installed: map a key with Keymap Editor or manually (see README).
import time
import xbmc
import xbmcgui

WIN = xbmcgui.Window(10000)
P_A, P_B = 'abrepeat.a', 'abrepeat.b'
POLL = 0.05        # seconds
SEEK_GUARD = 0.75  # seconds: ignore position right after a seek (getTime may still be stale)


def clear():
    WIN.clearProperty(P_A)
    WIN.clearProperty(P_B)


class Player(xbmc.Player):
    def onAVStarted(self):
        clear()

    def onPlayBackStopped(self):
        clear()

    def onPlayBackEnded(self):
        clear()


def run():
    clear()
    monitor = xbmc.Monitor()
    player = Player()
    last_seek = 0.0
    while not monitor.waitForAbort(POLL):
        a, b = WIN.getProperty(P_A), WIN.getProperty(P_B)
        if not (a and b) or not player.isPlaying():
            continue
        now = time.monotonic()
        if now - last_seek < SEEK_GUARD:
            continue
        try:
            t = player.getTime()
        except RuntimeError:
            continue
        if t >= float(b):
            player.seekTime(float(a))
            last_seek = now


run()
