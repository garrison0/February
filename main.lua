require "object"
require "utility"
require "objects"
require "physics"

--[[
note -- (0,0) is top left

TO DO:
1. scrolling background

2. physics collision
	-- HEY YOU! READ THIS!
	For some reason Circle VS. Triangle WORKS... but... 
	it only returns true when the circle's center is within the triangle
	i.e. the "edge" detection is broken...
	if you want to fix, pls do, but as is it's still a better approximation than before.

3. main "game" class to script levels/check gamestate

4. bleeps and bloops

5. particle effects for enemy/player deaths
	
6. boss...

7. main menu
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

function love.load()
	Test_Vector()
	Physics_Tests()

	-- game
	game = Game:new(800, 700)

	-- player
	player = Player:new(Vector:new(350, 350), Vector:new(300, 250))
	player.bulletLevel = 3

	-- enemies
	enemies = {}
	for i = 1,7 do
		x_iter = 95 * i
		y_iter = -200 + 20 * i
		enemy = Enemy:new(Vector:new(x_iter, y_iter), Vector:new(0, 100))
		table.insert(enemies, enemy)
	end

	for i = 1,12 do
		x_iter = 400
		y_iter = -1000 + i
		enemy = Enemy:new(Vector:new(x_iter, y_iter), Vector:new(0, 50))
		table.insert(enemies, enemy)
	end

	-- boss
	boss = Boss:new(Vector:new(100, 50), Vector:new(0,0), 600, 200, 500)
	k = boss:collision()
	for i, v in pairs(k) do
		print (i, v.class)
		for k, j in pairs(v) do print(k, j) end 
	end
end

function love.update(dt)
	-- update the player
	player:update(dt)

	-- update laser
	if player.laserOn then
		mouse_pos = Vector:new(love.mouse.getX(), love.mouse.getY())
		player.laser:update(mouse_pos)

		-- check for oollision with enemies
		for i, v in ipairs(enemies) do
			if detect(v, player.laser) then
				table.remove(enemies, i)
			end
		end

		-- check for collision with boss
		if (boss ~= nil) then
			if detect(boss, player.laser) then
				print("collision detected")
				boss.health = boss.health - player.laser.damage
			end
		end
	end

	-- shoot bullets
	if (player.shooting) and player.fire_delay <= 0 then
		player.shoot()
	end

	-- update bullets
	for i, v in ipairs(player.bullets) do
		v:update(dt)

		if v.life <= 0 then
			table.remove(player.bullets,i)
		end
	end

	-- update boss
	if (boss ~= nil) then 
		boss:update(dt)

		if boss.health <= 0 then
			boss = nil
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
	
	for i, v in ipairs(player.bullets) do
		for j, k in ipairs(enemies) do
			-- check collision between bullets and enemies
			if detect(v,k) then
				table.remove(enemies, j)
				table.remove(player.bullets, i)
			end
		end
		if (boss ~= nil) then
			if detect(v, boss) then
				table.remove(player.bullets, i)
				boss.health = boss.health - 5
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

	if button == 'r' then
		mouse_pos = Vector:new(love.mouse.getX(), love.mouse.getY())
		player:shootLaser(mouse_pos)
	end
end

function love.mousereleased(x, y, button)
	if button == 'l' then
		player.shooting = false
	end

	if button == 'r' then
		player.laserOn = false
	end
end

function love.draw()
	-- draw player
    love.graphics.polygon("line", {player.pos.x, player.pos.y + 32, player.pos.x + 8, player.pos.y, player.pos.x + 12, player.pos.y + 10,
    							   player.pos.x + 14, player.pos.y + 11, player.pos.x + 16, player.pos.y + 6, player.pos.x + 18, player.pos.y + 11,
    							   player.pos.x + 20, player.pos.y + 10, player.pos.x + 24, player.pos.y + 0, player.pos.x + 32, player.pos.y + 32,
    							   player.pos.x + 20, player.pos.y + 18, player.pos.x + 18, player.pos.y + 18, player.pos.x + 16, player.pos.y + 24,
    							   player.pos.x + 14, player.pos.y + 18, player.pos.x + 12, player.pos.y + 18, player.pos.x, player.pos.y + 32, player.pos.x, player.pos.y + 8})

    -- drawing the hitbox
    local p1 = Vector:new(player.pos.x + 14, player.pos.y + 11)
	local p2 = Vector:new(player.pos.x + 18, player.pos.y + 11)
	local p3 = Vector:new(player.pos.x + 18, player.pos.y + 18)
	local p4 = Vector:new(player.pos.x + 14, player.pos.y + 18)
	love.graphics.polygon("fill", {p1.x, p1.y, p2.x, p2.y, p3.x, p3.y, p4.x, p4.y})

    -- draw bullets
    for i, v in ipairs(player.bullets) do
    	love.graphics.circle("line", v.pos.x, v.pos.y, 4, 10)
    end

    -- draw the laser 
    if(player.laserOn) then
    	player.laser:draw()
    end

    -- draw enemies
    for i, v in ipairs(enemies) do
    	love.graphics.polygon("line", {v.pos.x, v.pos.y, v.pos.x + 32, v.pos.y, v.pos.x + 16, v.pos.y + 32})
    end

    -- draw boss
    if(boss ~= nil) then
    	boss:draw()
    end
end