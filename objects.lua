require "object"
require "utility"
require "physics"

Game = Object:new({class = "Game"})

	function Game:new(initial_state, width, height, fullscreen)

		love.window.setMode(width, height, {fullscreen = fullscreen or false})
		local game = {width = width or 0, height = height or 0, 
					stateNotLoaded = true, fullscreen = fullscreen or false}
		game.state = initial_state or "level1"
		setmetatable(game, self)
		self.__index = self
		return game

	end

	function Game:resizeWindow(w, h)

		self.width = w
		self.height = h
		love.window.setMode(w, h)

	end

	function Game:setState(state)

		self.gamestate = state

	end

	function Game:update()


	end

MenuButton = Object:new({class = "MenuButton"})

	function MenuButton:new(text, pos, width, height)

		local button = Object:new({text = text or "", pos = pos or Vector:new(0,0),
								   width = width or 0, height = height or 0})
		setmetatable(button, self)
		self.__index = self
		return button

	end

	function MenuButton:draw()

		-- the box
		p1 = self.pos
		p2 = Vector:new(self.pos.x + self.width, self.pos.y)
		p3 = Vector:new(self.pos.x, self.pos.y + self.height) 
		p4 = Vector:new(self.pos.x + self.width, self.pos.y + self.height)
		love.graphics.polygon("line", p1.x, p1.y, p3.x, p3.y, p4.x, p4.y, p2.x, p2.y)

		-- the text
		love.graphics.print(self.text, self.pos.x + 50, self.pos.y + 50)

	end

	function MenuButton:collision()

		p1 = self.pos
		p2 = Vector:new(self.pos.x + self.width, self.pos.y)
		p3 = Vector:new(self.pos.x, self.pos.y + self.height)
		p4 = Vector:new(self.pos.x + self.width, self.pos.y + self.height)
		T1 = BoundingTriangle:new(p1, p2, p4)
		T2 = BoundingTriangle:new(p1, p3, p4)
		return BoundingAggregate:new({T1, T2})

	end

Bullet = Object:new({class = "Bullet"})

	function Bullet:new(pos, vel, life, damage)

		local bullet = Object:new({
			pos = pos or Vector:new(0,0), vel = vel or Vector:new(0,0),
			life = life or 0, damage = damage or 0, width = 4, height = 4
		})
		setmetatable(bullet,self)
		self.__index = self
		return bullet

	end

	function Bullet:collision()

		local v = Vector:new(self.pos.x + self.width/2, 
							 self.pos.y + self.height/2)
		return BoundingAggregate:new({BoundingSphere:new(v,2)})

	end

	function Bullet:update(dt)

		self.life = self.life - dt;
		self.pos.y = self.pos.y - self.vel.y * dt
		self.pos.x = self.pos.x + (self.vel.x or 0) * dt

	end

Laser = Object:new({class = "Laser"})

	function Laser:new(spawn_pos, end_pos, damage)

		local laser = Object:new({
			spawn_pos = spawn_pos or Vector:new(0, 0), 
			end_pos = end_pos or Vector:new(0, 0),
			damage = damage or 0,
			angle = 0, goal_angle = 0, rot_vel = math.pi / 2500
		})

		-- find angle
		ship_middle = Vector:new(player.pos.x + player.width / 2, player.pos.y + player.height / 2)

		vec_A = end_pos - ship_middle
		
		laser.angle = math.atan2(vec_A.y, vec_A.x)
		if laser.angle < 0 then laser.angle = laser.angle + math.pi * 2 end

		-- for later use
		clockwise_angle = 0
		counterclockwise_angle = 0

		setmetatable(laser, self)
		self.__index = self
		return laser

	end

	function Laser:collision()

		-- this is a hack.
		arbitrary_vec = Vector:new(1,1)
		local p1 = self.spawn_pos - arbitrary_vec
		local p2 = self.spawn_pos + arbitrary_vec
		local p3 = self.end_pos - arbitrary_vec
		local p4 = self.end_pos + arbitrary_vec
		T1 = BoundingTriangle:new(p1, p2, p3)
		T2 = BoundingTriangle:new(p4, p2, p1)
		return BoundingAggregate:new({T1, T2})

	end

	function Laser:update(dt, mouse_pos)

		-- update position if the ship is moving
		if player.isMovingX then

			self.spawn_pos.x = self.spawn_pos.x - player.vel.x * dt * player.a
									  + player.vel.x * dt * player.d
			

			self.end_pos.x = self.end_pos.x - player.vel.x * dt * player.a
									  + player.vel.x * dt * player.d
			
		end

		if player.isMovingY then
			
			self.spawn_pos.y = self.spawn_pos.y + player.vel.y * dt * player.s
									  - player.vel.y * dt * player.w

			self.end_pos.y = self.end_pos.y + player.vel.y * dt * player.s
									  - player.vel.y * dt * player.w

		end

		-- calculate new vector based on mouse position
		ship_middle = Vector:new(player.pos.x + player.width / 2, player.pos.y + player.height / 2)
		ship_to_mouse = (mouse_pos - ship_middle)

		vec_A = ship_to_mouse

		self.goal_angle = math.atan2(vec_A.y, vec_A.x)

		-- keep it in the range [0, 2pi); 
		-- note that since (0,0) is top left, positive rotation is clockwise.
		if self.goal_angle < 0 then self.goal_angle = self.goal_angle + math.pi * 2 end

		-- find the counterclockwise and clockwise angles if we need to rotate
		if self.angle < (self.goal_angle - self.rot_vel) or self.angle > (self.goal_angle + self.rot_vel) then

			if self.angle > self.goal_angle then

				counterclockwise_angle = self.angle - self.goal_angle
				clockwise_angle = 2*math.pi - self.angle + self.goal_angle

			elseif self.goal_angle > self.angle then

				clockwise_angle = self.goal_angle - self.angle
				counterclockwise_angle = 2*math.pi - self.goal_angle + self.angle
			
			end
		end

		--print("clck: " .. tostring(clockwise_angle) .. " cc: " .. tostring(counterclockwise_angle) .. " angle: " .. tostring(self.angle))
		
		-- determine if we need to rotate
		if self.angle < (self.goal_angle - self.rot_vel) or self.angle > (self.goal_angle + self.rot_vel) then

			-- determine which angle is smallest rotate in
			if clockwise_angle < (counterclockwise_angle) then

				-- rotate counterclockwise
				self.angle = self.angle + self.rot_vel

				-- keep it in the range (0, 2pi]
				self.angle = self.angle % (2*math.pi)

				spawn_pos = self.spawn_pos - ship_middle
				spawn_pos = spawn_pos:rotate(self.rot_vel)
				spawn_pos = spawn_pos * (1 / spawn_pos:norm())
				self.spawn_pos = ship_middle + (spawn_pos * 32)
				self.end_pos = ship_middle + (spawn_pos * 258)

			end

			if counterclockwise_angle < (clockwise_angle) then

				-- rotate clockwise
				self.angle = self.angle - self.rot_vel

				-- keep it in range (0, 2pi]
				if self.angle <= 0 then self.angle = 2*math.pi + self.angle end

				spawn_pos = self.spawn_pos - ship_middle
				spawn_pos = spawn_pos:rotate(- self.rot_vel)
				spawn_pos = spawn_pos * (1 / spawn_pos:norm())
				self.spawn_pos = ship_middle + (spawn_pos * 32)
				self.end_pos = ship_middle + (spawn_pos * 258)

			end
		end
	end

	function Laser:draw()

		local p1 = self.spawn_pos
		local p2 = self.end_pos
		love.graphics.line(p1.x, p1.y, p2.x, p2.y)

	end

PowerUp = Object:new({class = "PowerUp"})

	function PowerUp:new(pos, lifetime)

		powerup = Object:new({pos = pos or Vector:new(0,0),
							  vel = Vector:new(0, 75),
							  lifetime = lifetime or 0,
							  width = 25, height = 25})
		setmetatable(powerup, self)
		self.__index = self
		return powerup

	end

	function PowerUp:collision()

		local p1 = self.pos 
		local p2 = Vector:new(self.pos.x + self.width, self.pos.y)
		local p3 = Vector:new(self.pos.x, self.pos.y + self.height)
		
		local p4 = self.pos
		local p5 = Vector:new(self.pos.x, self.pos.y + self.height)
		local p6 = Vector:new(self.pos.x + self.width, self.pos.y + self.height)
		T1 = BoundingTriangle:new(p1, p2, p3)
		T2 = BoundingTriangle:new(p4, p5, p6)
		return BoundingAggregate:new({T1, T2})

	end

	function PowerUp:draw()

		local p1 = self.pos 
		local p2 = Vector:new(self.pos.x + self.width, self.pos.y)
		local p3 = Vector:new(self.pos.x, self.pos.y + self.height)
		local p4 = Vector:new(self.pos.x + self.width, self.pos.y + self.height)
		love.graphics.polygon("line", p1.x, p1.y, p2.x, p2.y, p4.x, p4.y, p3.x, p3.y)
		love.graphics.print("P", p1.x + self.width/3, p1.y + self.height/3)
	end

	function PowerUp:update(dt)

		self.pos = self.pos + self.vel * dt
		self.lifetime = self.lifetime - dt

	end

SpringBall = Object:new({class = "SpringBall"})

	function SpringBall:new(pos, equilibriumPos, k)

		spring = Object:new({pos = pos,
							 equilibriumPos = equilibriumPos or pos,
							 vel = Vector:new(0, 0), acc = Vector:new(0, 0),
							 k = k or .25})
		setmetatable(spring, self)
		self.__index = self
		return spring

	end

	function SpringBall:collision()

		return BoundingAggregate:new({})

	end

	function SpringBall:draw()

		-- draw the line from the equilibrium pos to the current position (tether)
		love.graphics.line(self.equilibriumPos.x, self.equilibriumPos.y, self.pos.x, self.pos.y)

		-- draw the ball
		love.graphics.circle("fill", self.pos.x, self.pos.y, 5)

	end

	function SpringBall:update(dt)

		-- find velocity based on Hooke's Law
		displacement = (self.pos - self.equilibriumPos)
		self.acc = (- self.k * displacement)

		self.vel = self.vel + self.acc
		self.pos = self.pos + self.vel * dt

	end

Bomb = Object:new({class = "Bomb"})

Shield = Object:new({class = "Shield"})
