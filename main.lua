--[[
note -- (0,0) is top left


--]]




-- ship image
ship = love.graphics.newImage("/graphics/ship.png")



function love.load()
	-- player table
	player = {a=0, s=0, d=0, w=0}
	player.x = 350
	player.y = 350
	player.dx = 100
	player.dy = 100
end

function love.update(dt)
	-- update the player
	player.x = player.x - player.dx * dt * player.a
						+ player.dx * dt * player.d
	player.y = player.y + player.dy * dt * player.s
						- player.dy * dt * player.w

	if love.keyboard.isDown("left") then
		player.x = player.x - player.dx * dt
	elseif love.keyboard.isDown("right") then
		player.x = player.x + player.dx * dt
	end

	if love.keyboard.isDown("up") then
		player.y = player.y - player.dy * dt
	elseif love.keyboard.isDown("down") then
		player.y = player.y + player.dy * dt
	end
end

function love.keypressed(key)
	player[key] = 1 -- Set key flag pressed
end

function love.keyreleased(key)
	player[key] = 0 -- Set key flag released
end

function love.draw()
    love.graphics.draw(ship, player.x, player.y)
end
