--[[
note -- (0,0) is top left


--]]




-- ship image
ship = love.graphics.newImage("/graphics/ship.png")



function love.load()
	-- player table
	player = {}
	player.x = 350
	player.y = 350
	player.dx = 100
	player.dy = 100
end

function love.update(dt)
	-- update the player
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


function love.draw()
    love.graphics.draw(ship, player.x, player.y)
end
