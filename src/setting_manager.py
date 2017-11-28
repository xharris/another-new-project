import ConfigParser
from os.path import isfile

class SettingManager(object):
	def __init__(self, settings=[]):
		self.settings = {}
		self.onSet = None
		self.disable_onSet = False

		for setting in settings:
			self.addSetting(**setting)

	def addSetting(self, name='', default='', **kwargs):
		self.settings[name] = {'default':default, 'value':default}
		for arg in kwargs:
			self.settings[name][arg] = kwargs[arg]

		self._checkValueType(name)

	def _checkValueType(self, key):
		setting_type = self.settings[key]['type']

		if setting_type == 'number':
			self.settings[key]['default'] = int(self.settings[key]['default'])
			self.settings[key]['value'] = int(self.settings[key]['value'])
		if setting_type == 'checkbox':
			self.settings[key]['default'] = (self.settings[key]['default'] == 'True' or self.settings[key]['default'] == True)
			self.settings[key]['value'] = (self.settings[key]['value'] == 'True' or self.settings[key]['value'] == True)

	def __getitem__(self, key):
		if self.settings[key]:
			out_val = self.settings[key]['default']
			if 'value' in self.settings[key]:
				out_val = self.settings[key]['value']

			self._checkValueType(key)
			return out_val

	def __setitem__(self, key, value):
		self.settings[key]['value'] = value
		self._checkValueType(key)

		if self.onSet and not self.disable_onSet:
			self.onSet(self.settings)

	# gets the values of all settings in a name:value dict list
	def getDefaults(self):
		ret_dict = {}
		for s in self.settings:
			ret_dict[s] = self.settings[s]['default']

		return ret_dict

	def getValues(self):
		ret_dict = {}
		for s in self.settings:
			ret_dict[s] = self.settings[s]['value']

		return ret_dict

	# gets all setting data organized for bForm
	def getInputs(self):
		ret_array = []
		for s in self.settings:
			if not 'hidden' in self.settings[s]:
				self._checkValueType(s)

				setting = self.settings[s].copy()
				setting['name'] = s
				setting['value'] = self[s]
				ret_array.append(setting)
		
		return ret_array

	# reset values to defaults
	def reset(self):
		self.disable_onSet = True
		for s in self.settings:
			self[s] = self.settings[s]['default']
		self.disable_onSet = False

	# write settings to a file
	def write(self, in_filepath):
		sect_name = 'root'
		config = ConfigParser.RawConfigParser()
		if not config.has_section(sect_name):
			config.add_section(sect_name)

		values = self.getValues()
		for val in values:
			config.set(sect_name, val, values[val])

		with open(in_filepath, 'wb') as configfile:
			config.write(configfile)


	# get setting values from a file
	# if the file does not exist it will be written instead
	# NOTE: does not reset currently stored values
	def read(self, in_filepath):
		if not isfile(in_filepath):
			self.write(in_filepath)
			return

		sect_name = 'root'
		config = ConfigParser.ConfigParser()
		config.read(in_filepath)
		
		for s in self.settings:
			if config.has_option(sect_name, s):
				self[s] = config.get(sect_name, s)
			else:
				self[s] = self.settings[s]['default']