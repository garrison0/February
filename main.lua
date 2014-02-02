require "utility"
--[[
note -- (0,0) is top left

TO DO:
1. scrolling background

2. physics collision

3. main "game" class to script levels/check gamestate

4. bullet upgrade patterns

5. bleeps and bloops

--]]

CollisionSphere = {}

function CollisionSphere:new(h, k, r)
	local object = {
		h = h or 0, k = k or 0, r = r or 0
	}
	setmetatable(object,self)
	self.__index = self
	return object
end

function CollisionSphere.__add(a, b)
	local object = {
		h = a.h + b.h, k = a.k + b.k, r = 0
	}
end

-- ship image
ship = love.graphics.newImage("/graphics/ship.png")

-- enemy ship image
enemy_ship = love.graphics.newImage("/graphics/enemy.png")


-- Game metatable
Game = {}
Game.index = Game

function Game.new(w, h)
	love.window.setMode(w, h)
	return setmetatable({gamestate = "", w = w, h = h}, Game)
end

function Game.resizeWindow(w, h)
	love.window.setMode(w, h)
end

function Game.setState(state)
	self.gamestate = state
end


-- Player metatable
Player = {}
Player.__index = Player

function Player.new(loc, dx, dy)
	return setmetatable({loc = loc or {0, 0}, dx = dx or 0, dy = dy or 0, 
				shooting = false, fire_delay = 0, 
				width = 64, height = 64, bulletLevel = 1,
				a = 0, s = 0, d = 0, w = 0}, Player)
end

function Player.shoot()
	-- level 1
	if (player.bulletLevel == 1) then
		bullet = {loc={player.loc[1] + player.width/2, player.loc[2]}, dy=1000, life=.35}
		player.fire_delay = .5
		table.insert(bullets,bullet)
	end

	-- level 2
	if (player.bulletLevel == 2) then
		bullet = {loc={player.loc[1] + player.width/4, player.loc[2]}, dy=1000, life=.4}
		bullet2 = {loc={player.loc[1] + 3*player.width/4, player.loc[2]}, dy=1000, life=.4}
		player.fire_delay = .4
		table.insert(bullets, bullet)
		table.insert(bullets, bullet2)
	end

	-- level 3
	if (player.bulletLevel == 3) then
		bullet = {loc={player.loc[1] + player.width/4, player.loc[2]}, dy=1000, life=.5}
		bullet2 = {loc={player.loc[1] + 3*player.width/4, player.loc[2]}, dy=1000, life=.5}
		bullet3 = {loc={player.loc[1] + player.width, player.loc[2]}, dx = 200, dy=800, life=.5}
		bullet4 = {loc={player.loc[1], player.loc[2]}, dx = -200, dy=800, life=.5}
		player.fire_delay = .2
		table.insert(bullets, bullet)
		table.insert(bullets, bullet2)
		table.insert(bullets, bullet3)
		table.insert(bullets, bullet4)
	end
end


-- Enemy metatable
Enemy = {}
Enemy.__index = Enemy

function Enemy.new(loc, dx, dy)
	return setmetatable({loc = loc or {0,0}, dx = dx or 0, dy = dy or 0, amplitude = 200}, Enemy)
end


-- Bullet metatable
Bullet = {}
Bullet.__index = Bullet

--[[
function Bullet.new(loc, dx, dy, life, damage)
	return setmetatable({})
end
]]


function love.load()
	Test_Vector()

	-- player table
	--[[
	player = {a=0, s=0, d=0, w=0, space=0, height=64, width =64}
	player.shooting = false

	player = {a=0, s=0, d=0, w=0, e=0}
	player.loc = {350,350}
	player.dx = 300
	player.dy = 250
	player.fire_delay = 0;
	--]]
	player = Player.new({350, 350}, 300, 250)
	-- game
	game = Game.new(800, 700)

	-- player
	player = Player.new({350, 350}, 300, 250)
	player.bulletLevel = 3
	bullets = {}

	-- enemies
	enemies = {}
	for i = 1,7 do
		x_iter = 95 * i
		enemy = Enemy.new({x_iter, 0}, 0, 100)
		table.insert(enemies, enemy)
	end
end

function love.update(dt)
	-- update the player
	player.loc[1] = player.loc[1] - player.dx * dt * player.a
								  + player.dx * dt * player.d
	player.loc[2] = player.loc[2] + player.dy * dt * player.s
								  - player.dy * dt * player.w

	-- shoot bullets
	if (player.shooting == true) and player.fire_delay <= 0 then
		player.shoot()
	end

	-- update bullets
	for i, v in ipairs(bullets) do
		v.life = v.life - dt;
		print(v.life)
		v.loc[2] = v.loc[2] - v.dy * dt
		v.loc[1] = v.loc[1] + (v.dx or 0) * dt
		if v.life <= 0 then
			table.remove(bullets,i)
		end
	end

	player.fire_delay = player.fire_delay - dt

	-- update the enemies
	for i, v in ipairs(enemies) do
		v.loc[1] = v.loc[1] + math.sin(v.loc[2] / 10) * v.amplitude * dt
		v.loc[2] = v.loc[2] + v.dy * dt
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
    love.graphics.draw(ship, player.loc[1], player.loc[2])

    --draw bullets
    for i, v in ipairs(bullets) do
    	love.graphics.circle("line",v.loc[1],v.loc[2],10,10)
    end

    --draw enemies
    for i, v in ipairs(enemies) do
    	love.graphics.draw(enemy_ship, v.loc[1], v.loc[2])
    end
end
