require "object"
require "utility"
require "objects"

--[[
note -- (0,0) is top left

TO DO:
1. scrolling background

2. physics collision

3. main "game" class to script levels/check gamestate

4. bullet upgrade patterns

5. bleeps and bloops

--]]

-- Axis-Aligned Bounding Box
AABB = {}
AABB.__index = AABB

--[[
	new():
		pos : {}
		width : int.
		height : int.
]]
function AABB:new(pos, width, height)
	local object = {
		pos = Vector:new(pos[1], pos[2]),
		half_width = width/2 or 0, half_height = height/2 or 0}
	return setmetatable(object, AABB)
end

--[[
	update():
		pos : Vector
]]
--[[
function AABB:update(pos)
	self.pos = pos
end

-- Collision Detection
function AABBvsAABB(a, b)
	-- Vector from A to B
	n = a.body.pos - b.body.pos

	-- calculate overlap on X axis
	x_overlap = a.body.half_width + b.body.half_width - math.abs(n.x)

	-- SAT/Seperating Axis Theorem
	if (x_overlap > 0) then
		-- repeat for y
		y_overlap = a.body.half_height + b.body.half_height - math.abs(n.y)

		-- SAT
		if (y_overlap > 0) then
			-- Collision detected.
			return true

			--[[
			-- Axis of least penetration:
			if(x_overlap > y_overlap) then
				if(n.x < 0) then
					normal = Vector(-1, 0)
				else
					normal = Vector(1, 0)
				end

				-- fix the x overlap and/or destroy object

			else
				if(n.x < 0) then
					normal = Vector(0, -1)
				else
					normal = Vector(0, 1)
				end

				-- fix the y overlap and/or destroy object

			end
		end
	end
end
--]]
-- ship image
ship = love.graphics.newImage("/graphics/ship.png")

-- enemy ship image
enemy_ship = love.graphics.newImage("/graphics/enemy.png")


-- Game metatable
Game = {}
Game.index = Game

function Game:new(w, h)
	love.window.setMode(w, h)
	return setmetatable({gamestate = "", w = w, h = h}, Game)
end

function Game:resizeWindow(w, h)
	self.w = w
	self.h = h
	love.window.setMode(w, h)
end

function Game:setState(state)
	self.gamestate = state
end

-- Player metatable

function Player.shoot()
	-- level 1
	if (player.bulletLevel == 1) then
		bullet = Bullet:new(Vector:new(player.pos.x + player.width/2, player.pos.y), 
									Vector:new(0,1000), .35)

		player.fire_delay = .5
		table.insert(bullets, bullet)
	end

	-- level 2
	if (player.bulletLevel == 2) then
		bullet = Bullet:new(Vector:new(player.pos.x + player.width/4, player.pos.y),
									Vector:new(0,1000), .4)
		bullet2 = Bullet:new(Vector:new(player.pos.x + 3*player.width/4, player.pos.y), 
									Vector:new(0,1000), .4)

		player.fire_delay = .4
		table.insert(bullets, bullet)
		table.insert(bullets, bullet2)
	end

	-- level 3
	if (player.bulletLevel == 3) then
		bullet = Bullet:new(Vector:new(player.pos.x + player.width/4, player.pos.y), 
									Vector:new(0,1000), .5)

		bullet2 = Bullet:new(Vector:new(player.pos.x + 3*player.width/4, player.pos.y), 
									Vector:new(0,1000), .5)

		bullet3 = Bullet:new(Vector:new(player.pos.x + player.width, player.pos.y), 
									Vector:new(200,800), .5)

		bullet4 = Bullet:new(Vector:new(player.pos.x, player.pos.y), 
									Vector:new(-200,800), .5)

		player.fire_delay = .01
		table.insert(bullets, bullet)
		table.insert(bullets, bullet2)
		table.insert(bullets, bullet3)
		table.insert(bullets, bullet4)
	end
end

function Player:update(dt)
	-- image
	self.pos.x = self.pos.x - self.vel.x * dt * self.a
								  + self.vel.x * dt * self.d
	self.pos.y = self.pos.y + self.vel.y * dt * self.s
								  - self.vel.y * dt * self.w

	-- delay
	self.fire_delay = self.fire_delay - dt

	-- physical body
	--self.body:update(self.pos)
end

function Enemy:update(dt)
	-- image
	self.pos.x = self.pos.x + math.sin(self.pos.y / 10) * self.amplitude * dt
	self.pos.y = self.pos.y + self.vel.y * dt
	-- physical component
	--self.body:update(self.pos)
end

function Bullet:update(dt)
	-- image
	self.life = self.life - dt;
	self.pos.y = self.pos.y - self.vel.y * dt
	self.pos.x = self.pos.x + (self.vel.x or 0) * dt

	-- physical body
	--self.body:update(self.pos)
end


--[[
	detect whether or not two tables, a and b, collide
--]]
function detect(a, b)
	local a_sphere = a:collision(); b_sphere = b:collision()
	if a_sphere and b_sphere then
		local dist = (a_sphere.center - b_sphere.center):norm()
		if dist - a_sphere.radius - b_sphere.radius <= 0 then
			return true
		else
			return false
		end
	else
		error("detect: Objects do not support collision behavior")
	end
end

function love.load()
	Test_Vector()

	-- game
	game = Game:new(800, 700)

	-- player
	player = Player:new(Vector:new(350, 350), Vector:new(300, 250))
	player.bulletLevel = 3
	bullets = {}

	-- enemies
	enemies = {}
	for i = 1,7 do
		x_iter = 95 * i
		enemy = Enemy:new(Vector:new(x_iter, 0), Vector:new(0, 100))
		table.insert(enemies, enemy)
	end
end

function love.update(dt)
	-- update the player
	player:update(dt)

	-- shoot bullets
	if (player.shooting == true) and player.fire_delay <= 0 then
		player.shoot()
	end

	-- update bullets
	for i, v in ipairs(bullets) do
		v:update(dt)

		if v.life <= 0 then
			table.remove(bullets,i)
		end
	end

	-- update the enemies
	for i, v in ipairs(enemies) do
		-- check for collisions with player
		v:update(dt)
		if detect(v, player) then
			table.remove(enemies, i)
		end
	end

	for i, v in ipairs(bullets) do
		for j, k in ipairs(enemies) do
			if detect(v,k) then
				table.remove(enemies,j)
				table.remove(bullets,i)
			end
		end
	end
end

-- input
function love.keypressed(key)
	player[key] = 1 -- Set key flag pressed
	print(key .. " " .. player[key])
end

function love.keyreleased(key)
	player[key] = 0 -- Set key flag released
	print(key .. " " .. player[key])

end

function love.mousepressed(x, y, button)
	if button == 'l' then
		player.shooting = true
	end
end

function love.mousereleased(x, y, button)
	if button == 'l' then
		player.shooting = false
	end

end

function love.draw()
	-- draw player
    love.graphics.draw(ship, player.pos.x, player.pos.y)

    -- draw bullets
    for i, v in ipairs(bullets) do
    	love.graphics.circle("line",v.pos.x, v.pos.y, 10, 10)
    end

    -- draw enemies
    for i, v in ipairs(enemies) do
    	love.graphics.draw(enemy_ship, v.pos.x, v.pos.y)
    end
end