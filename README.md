UI classes or whatever

.ui-input-group {
	label
	input
}

.ui-btn-group {
	creates transparent rounded box for buttons
}

INDIVIDUAL INPUTS STYLED
.ui-input (input: text, number, etc)
.ui-button (button)
.ui-select (select)
.ui-checkbox {
	input[type=checkbox]
	mdi-icon
}

CUSTOM MODULE things

Less file 
	- @import "imports";

FREQUENT FUNCTIONS
	b_project.autoSaveProject();

LIBRARY OBJECT PROPERTIES
entity
	- name 
	- code_path
image
	- name
	- path
scene
	- name
	- map
tile
	- name
	- img_source
	- parameters
		- tileHeight
		- tileWidth
		- tileMarginX
		- tileMarginY
spritesheet
	- name
	- img_source
	- parameters
		- frameWidth
		- frameHeight
		- frameMax
		- margin
		- spacing
		- speed
