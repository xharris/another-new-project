import ConfigParser
from os.path import isfile

class SettingManager(object):
	def __init__(self, settings=[]):
		self.settings = {}

		for setting in settings:
			self.addSetting(**setting)

	def addSetting(self, name='', default='', **kwargs):
		self.settings[name] = {'default':default, 'value':default}
		for arg in kwargs:
			self.settings[name][arg] = kwargs[arg]

	def __getitem__(self, key):
		if self.settings[key]:
			return self.settings[key]['value']
		elif key == 'default' and 'value' in self.settings:
			return self.settings['value']

	def __setitem__(self, key, value):
		self.settings[key]['value'] = value

	# gets the values of all settings in a name:value dict list
	def getDefaults(self):
		ret_dict = {}
		for s in self.settings:
			ret_dict[s] = self.settings[s]['value']
		return ret_dict

	# gets all setting data organized for bForm
	def getInputs(self):
		ret_array = []
		for s in self.settings:
			setting = self.settings[s].copy()
			setting['name'] = s
			setting['default'] = setting['value']
			ret_array.append(setting)
		return ret_array

	# reset values to defaults
	def reset(self):
		for s in self.settings:
			self[s] = self.settings[s]['default']

	# write settings to a file
	def write(self, in_filepath):
		sect_name = 'root'
		config = ConfigParser.RawConfigParser()
		if not config.has_section(sect_name):
			config.add_section(sect_name)

		values = self.getDefaults()
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
			self[s] = config.get(sect_name, s)