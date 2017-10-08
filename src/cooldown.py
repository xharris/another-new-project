# https://stackoverflow.com/questions/33948731/modifying-a-cooldown-decorator-to-work-for-methods-instead-of-functions

import time
import inspect

class cooldown(object):
    def __init__(self, duration):
        self._duration = duration
        self._storage = self
        self._start_time = 0

    def __getRemaining(self):
        if not hasattr(self._storage, "_start_time"):
            self._storage._start_time = 0
        return self._duration - (time.time() -
                                 self._storage._start_time)

    def __setRemaining(self, value):
        self._storage._start_time = time.time() - (self._duration -
                                                   value)

    remaining = property(__getRemaining, __setRemaining)

    def __call__(self, func):
        is_method = inspect.getargspec(func).args[0] == 'self'
        def call_if(*args, **kwargs):
            if is_method :
                self._storage = args[0]
            else:
                self._storage = self
            if self.remaining <= 0:
                self.remaining = self._duration
                return func(*args, **kwargs)

        call_if.setRemaining = self.__setRemaining
        call_if.getRemaining = self.__getRemaining
        return call_if