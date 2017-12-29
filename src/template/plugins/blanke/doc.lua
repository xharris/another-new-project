--[[ 
TODO
* manually adding assets

WIP
* View.squeezeH()
* Image.chop()
* Input region

variable - value (arg)
variable = value (keyword arg)
aMethod(arg, [optional_arg])
]]

--- INITIALIZE BLANKE ENGINE

-- in main.lua:
require('blanke.Blanke')

function love.load()
	BlankE.init()
end

-- possible init options
Blanke.init(first_state) -- first_state: can be string or object

--[[
 ###  #######     #     ####### ###### 
#        #       # #       #    #      
 ###     #      #   #      #    #####  
    #    #     #######     #    #      
 ###     #    #       #    #    ###### 

State
	based on HUMP plugin
]]

-- init code generated by IDE
myState = Class{classname='myState'}

-- methods
-- Ex: function myState:enter(arg) end
load()				-- run only first time state is loaded
enter(previous)		-- run every time state is loaded. previous = prev state
leave()				-- run every time state is left for another.
update(dt)
draw()

-- loading a state
State.switch(myState)

--[[
###### #   #  ####### ##### ####### #     # 
#      ##  #     #      #      #     #   #  
#####  # # #     #      #      #      # #   
#      #  ##     #      #      #       #    
###### #   #     #    #####    #       #    

Entity
	game object that can have hitboxes/collisions and sprite animations
	collisions use HardonCollider
]]

-- init code generated by IDE
myEntity = Class{__includes=Entity, classname='myEntity'}

-- instance properties
str sprite_index
num	sprite_width, sprite_height
num sprite_angle					-- in degrees
num sprite_xscale, sprite_yscale	-- 1 = normal scaling, -1 = flip
num sprite_xoffset, sprite_yoffset
num sprite_xshear, sprite_yshear
num sprite_color{r, g, b}			-- blend color for sprite. default = 255(white)
num sprite_alpha					-- default = 255
num sprite_speed					-- default = 1
num sprite_frame

num direction						-- in degrees
num friction
num gravity
num gravity_direction				-- in degrees. 0 = right, 270 = down
num hspeed, vspeed
num speed 							-- best used with 'direction'
num xprevious, yprevious			-- location during last update loop
num xstart, ystart					-- location when object is first created. not always 0,0

-- overridable methods
preUpdate(dt)
update(dt)							-- caution: controls all physics/motion/position variables
postUpdate(dt)
preDraw()
draw()								-- caution: controls sprite, animation
postDraw()

-- regular methods
debugSprite()						-- call during drawing (ex. state:draw)
debugCollision()					-- shows hitboxes
setSpriteIndex(str index)			
addAnimation{...}					--[[
	name = str
	image = str 					-- name of asset (ex. bob_stand, bob_walk)
	frames = {...}
	frame_size = {width, height}
	speed = float					
]]
addShape(...)						--[[
	name - str
	shape - str rectangle, circle, polygon, point
	dimensions - {...}
		- rectangle {left, top, width, height}
		- circle {center_x, center_y, radius}
	}
]]
setMainShape(name)
removeShape(name)					-- disables a shape. it is still in the shapes table however and will be replaced using addShape(same_name)
distance_point(x ,y)				-- entity origin distance from point
move_towards_point(x, y, speed)		-- sets direction and speed vars
contains_point(x, y)				-- checks if a point is inside the sprite (not hitboxes)

-- special collision methods
func onCollision{name}
func collisionStopX()
func collisionStopY()

-- platformer collisions example
self:addShape("main", "rectangle", {0, 0, 32, 32})		-- rectangle of whole players body
self:addShape("jump_box", "rectangle", {4, 30, 24, 2})	-- rectangle at players feet

function entity0:preUpdate(dt)
	self.onCollision["main"] = function(other, sep_vector)	-- other: other hitbox in collision
		if other.tag == "ground" then
			-- ceiling collision
            if sep_vector.y > 0 and self.vspeed < 0 then
                self:collisionStopY()
            end
            -- horizontal collision
            if math.abs(sep_vector.x) > 0 then
                self:collisionStopX() 
            end
		end
	end

	self.onCollision["jump_box"] = function(other, sep_vector)
        if other.tag == "ground" and sep_vector.y < 0 then
                -- floor collision
            if not self.can_jump and self.nickname == 'player' then
                Signal.emit('jump')
            end
            self.can_jump = true 
        self:collisionStopY()
        end 
    end
end

--[[
#     # ##### ###### #      # 
#     #   #   #      #      # 
 #   #    #   #####  #      # 
  # #     #   #      #  ##  # 
   #    ##### ###### ##    ## 

View
	extension of HUMP camera
]]

-- instance properties
bool disabled
Entity follow_entity		-- entity for view to follow

num follow_x, follow_y 		-- better to use moveToPosition()
num offset_x, offset_y		
str motion_type 			-- none, linear, smooth
num speed 					-- = 1
num max_distance			-- = 0

num angle 					-- default: 0 degrees
num rot_speed				-- angle rotation speed
str rot_type				-- none, damped
num scale_x, scale_y		-- = 1, stretch/squeeze view
num zoom_speed				-- = .5
str zoom_type				-- none, damped

num port_x, port_y			-- uses love2d Scissor to crop view
num port_width, port_height -- uses love2d Scissor to crop view
bool noclip					-- HUMP attach option. no idea what it does

num shake_x, shake_y		-- = 0
num shake_intensity			-- = 7
num shake_falloff 			-- = 2.5
str shake_type 				-- smooth, rigid

bool draggable				-- drag the camera around using mouse_position
Input drag_input			-- input that toggles whether camera is being dragged

-- methods
position()					-- returns camera position
follow(Entity)				-- follows an Entity
moveTo(Entity) 				-- camera smoothly/linearly moves to entity position
snapTo(Entity)				-- camera immediately moves to entity
moveToPosition(x,y)			
snapToPosition(x,y)
rotateTo(angle)
zoom(scale_x, [scale_y])	-- if only scale_x is supplied, scale_y is set to scale_x
mousePosition()				-- get mouse position relative to world
shake(x, [y])				-- sets shake_x
squeezeH(amt)				-- similar to scale_x except view is centered
attach()					-- set the camera for drawing
detach()					-- unset camera for drawing
draw(draw_function)			-- wraps draw_function in attach/detach methods

--[[
##### #     #      #      #####  ###### 
  #   ##   ##     # #    #       #      
  #   ### ###    #   #   # ####  #####  
  #   #  #  #   #######  #     # #      
##### #     #  #       #  #####  ###### 

Image
]]

-- instance properties
num x, y 					-- position for draw()
num angle 					-- degrees
num xscale, yscale 			-- = 1
							-- xscale = -1 to flip horizontally
							-- yscale = -1 to flip vertically
num xoffset, yoffset 		
num color{r,g,b}			-- = 255, blend color
num alpha 					-- = 255, opacity
num orig_width 				-- original width of image (before scaling)
num orig_height
num width, height 			-- width/height including scaling

-- methods
draw()
chop(width, height)			-- chops image into smaller images of width/height
crop(x, y, w, h)			-- obvious

--[[
##### #   #  ####  #     # ####### 
  #   ##  #  #   # #     #    #    
  #   # # #  ####  #     #    #    
  #   #  ##  #     #     #    #    
##### #   #  #      #####     #    

Input
]]

Input(...)					--[[ constructor containing tracked inputs
Keyboard
	a, b, c, 1, 2, 3...
	!, ", #, &...
	space, backspace, return 		return is also enter
	up, down, left, right
	home, end, pageup, pagedown
	insert, tab, clear
	f1, f2, f3...
	numlock, capslock, scrolllock
	lshift, rshift
	rctrl, lctrl, ralt, lalt
	rgui, lgui						Command/Windows key
	menu						
	application						windows menu key
	mode 							?

Numpad
	kp0, kp1...				number
	kp. kp, kp+
	kpenter

	https://love2d.org/wiki/KeyConstant

Mouse
	mouse.1		left mouse button
	mouse.2		middle mouse button
	mouse.3 	right mouse button

Mouse Wheel
	wheel.up
	wheel.down
	wheel.right	very rare
	wheel.left	also very rare lol

Region			mouse click in a region
	WIP
]]

-- usage
k_left = Input('left', 'a')
if k_left() then
	hspeed = -125
end

--[[
 ###    ##### ###### #   #  ###### 
#      #      #      ##  #  #      
 ###   #      #####  # # #  #####  
    #  #      #      #  ##  #      
 ###    ##### ###### #   #  ###### 

Scene
	To create a Scene in the IDE just type 
		my_scene = Scene("mylevel")
	as if it already existed. A blank scene will be created.
]]

Scene(scene_name)							-- initialize a scene as scene_name.json

-- instance methods
addEntity(Entity)
addTile(image_name, x, y, crop_options)		--[[
	crop_options - {x, y, width, height}
]]
getTile(x, y, layer, img_name)				-- returns list of tile_data?
getTileImage(x, y, layer, img_name)			-- same as geTTile but returns list of Image()
removeTile(x, y, layer, img_name)
removeHitboxAtPoint(x, y, layer)
getList(object_type)
draw()

-- json format
{
	"layers": {
		"layer0": {
			"tile": [
				{x, y, img_name, crop:{x, y, img_name, width, height}},
				...
			],
			"hitbox": [
				{name, points:[10,20,30,50,...]},
				...
			],
			"entity": [
				?
			]
		}
	},
	"objects": {
		"layers": ["layer0",...],
		"hitbox": [
			{name, uuid, color},
			...
		]
	}
}

--[[
#####   #####      #     #      #
#    #  #   #     # #    #      #
#    #  ####     #   #   #      #
#    #  #   #   #######  #  ##  #
#####   #    # #       # ##    ##

Draw
]]

-- class properties
num[4] color 						-- {r, g, b, a} used for ALL Draw operations
num[4] reset_color					-- {255, 255, 255, 255} (white) : used in resetColor()
num[4] 	red 
		pink
		purple
		indigo
		blue
		green
		yellow
		orange
		brown
		grey 
		black 
		white 
		black2 						-- lighter black
		white2 						-- eggshell white :)

-- class methods
setBackgroundColor(r, g, b, a)
setColor(r, g, b, a)				
resetColor()						-- color = reset_color
-- shapes
point(x, y, ...)					-- also takes in a table							
points								-- the same as point()
line(x1, y1, x2, y2)				
rect(mode, x, y, width, height)		-- mode = "line"/"fill"
circle(mode, x, y, radius)
polygon(mode, x1, y2, x2, y2, ...)
text(text, x, y, rotation, scale_x, scale_y, offset_x, offset_y)
									-- rotation in radians

--[[
####### ##### #     #  ###### #####
   #      #   ##   ##  #      #   #
   #      #   ### ###  #####  ####
   #      #   #  #  #  #      #   #
   #    ##### #     #  ###### #    #

Timer
]]

-- all time units are in seconds for Timer

-- constructor
Timer([duration])						-- in seconds

-- instance properties
int duration							-- 0s
bool disable_on_all_called				-- true. The timer will stop running once every supplied function is called
int time 								-- elapsed time in seconds

-- instance methods
before(function, [delay])				-- starts immediately unless delay is supplied
every(function, [interval])				-- interval=1 , function happens on every interal
after(function, [delay])				-- happens after `duration` supplied to constructor with optional delay
start()									-- MUST BE CALLED TO START THE TIMER. DO NOT FORGET THIS OR YOU WILL GO NUTS

-- example: have an 'enemy' entity shoot a laser every 2 seconds
function enemy:shootLaser()
	...
end

function enemy:spawn()
	self.shoot_timer = Timer()
	self.shoot_timer:every(self.shootLaser, 2):start()
end