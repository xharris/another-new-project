class SettingManager(object):
	def __init__(self, settings=[]):
		self.settings = {}

		for setting in settings:
			self.addSetting(**setting)

	def addSetting(self, name='', default='', **kwargs):
		self.settings[name] = {'value':default}
		for arg in kwargs:
			self.settings[name][arg] = kwargs[arg]

	def __getitem__(self, key):
		if self.settings[key]:
			return self.settings[key]['value']
		elif key == 'default' and 'value' in self.settings:
			return self.settings['value']

	def __setitem__(self, key, value):
		self.settings[key]['value'] = value

	def getDefaults(self):
		ret_dict = {}
		for s in self.settings:
			ret_dict[s] = self.settings[s]['value']
		return ret_dict

	def getInputs(self):
		ret_array = []
		for s in self.settings:
			setting = self.settings[s].copy()
			setting['name'] = s
			setting['default'] = setting['value']
			ret_array.append(setting)
		return ret_array