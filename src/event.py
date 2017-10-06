class Event(object):
	def __init__(self):
		self.events = {}

	def on(self, name, fn):
		if not name in self.events:
			self.events[name] = []
		self.events[name].append(fn)
	
	def trigger(self, name):
		if name in self.events:
			for ev in self.events[name]:
				ev()