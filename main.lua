--[[
note -- (0,0) is top left

TO DO:
1. scrolling background

2. physics collision

3. main "game" class to script levels/check gamestate


--]]




-- ship image
ship = love.graphics.newImage("/graphics/ship.png")

-- enemy ship image
enemy_ship = love.graphics.newImage("/graphics/enemy.png")


-- Game metatable
Game = {}
Game.index = Game

function Game.new()
	return setmetatable({gamestate = ""}, Game)
end

-- Player metatable
Player = {}
Player.__index = Player

function Player.new(loc, dx, dy)
	return setmetatable({loc = loc or {0, 0}, dx = dx or 0, dy = dy or 0, 
				shooting = false, fire_delay = 0, 
				width = 64, height = 64,
				a = 0, s = 0, d = 0, w = 0}, Player)
end

-- Enemy metatable
Enemy = {}
Enemy.__index = Enemy

function Enemy.new(loc, dx, dy)
	return setmetatable({loc = loc or {0,0}, dx = dx or 0, dy = dy or 0, amplitude = 200}, Enemy)
end



function love.load()
	-- player
	player = Player.new({350, 350}, 300, 250)

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

	if (player.shooting == true) and player.fire_delay <= 0 then
		bullet = {loc={player.loc[1] + player.width/2, player.loc[2]}, dy=1000, life=.35}
		player.fire_delay = .5
		table.insert(bullets,bullet)
	end

	for i, v in ipairs(bullets) do
		v.life = v.life - dt;
		print(v.life)
		v.loc[2] = v.loc[2] - v.dy * dt
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
