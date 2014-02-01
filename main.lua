--[[
note -- (0,0) is top left


--]]




-- ship image
ship = love.graphics.newImage("/graphics/ship.png")



function love.load()
	-- player table
	player = {a=0, s=0, d=0, w=0, space=0}
	player.loc = {350,350}
	player.dx = 100
	player.dy = 100
end

function love.update(dt)
	-- update the player
	player.loc[1] = player.loc[1] - player.dx * dt * player.a
								  + player.dx * dt * player.d
	player.loc[2] = player.loc[2] + player.dy * dt * player.s
								  - player.dy * dt * player.w
end

function love.keypressed(key)
	player[key] = 1 -- Set key flag pressed
end

function love.keyreleased(key)
	player[key] = 0 -- Set key flag released
end

function love.draw()
    love.graphics.draw(ship, player.loc[1], player.loc[2])
end
