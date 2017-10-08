import time
import inspect
from threading import Timer

class cooldown(object):
    def __init__(self, duration):
        self._duration = duration
        self._timer = None

    def __call__(self, func):
        def startIt(*args, **kwargs):
            if self._timer:
                self._timer.cancel()
            self._timer = Timer(self._duration, func, args, kwargs)
            self._timer.start()
        return startIt
