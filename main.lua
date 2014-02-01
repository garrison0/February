--[[
note -- (0,0) is top left


--]]

-- ship image
ship = love.graphics.newImage("/graphics/ship.png")

function love.load()
	-- player table

	player = {a=0, s=0, d=0, w=0, space=0, height=64, width =64}
	player.loc = {350,350}
	player.dx = 100
	player.dy = 100
	player.shooting = false

	player = {a=0, s=0, d=0, w=0, e=0}
	player.loc = {350,350}
	player.dx = 300
	player.dy = 250
	player.width = 64
	player.height = 64
	player.fire_delay = 0;

	bullets = {}


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
    love.graphics.draw(ship, player.loc[1], player.loc[2])

    for i, v in ipairs(bullets) do
    	love.graphics.circle("fill",v.loc[1],v.loc[2],10,10)
    end

    for i, v in ipairs(bullets) do
    	love.graphics.circle("fill",v.loc[1],v.loc[2],10,10)
    end

end
