require "object"
require "physics"

-- generic moving enemy
Enemy = Object:new({class = "Enemy"})

	function Enemy:new(pos, vel, pathingType, minDepth, maxDepth, turningDirection)
		local enemy = Object:new({
			pos = pos or Vector:new(0,0), vel = vel or Vector:new(0,0),
			pathingType = pathingType or "standard", amplitude = 200, 
			health = 5, life = 12, width = 32, height = 32
		})

		-- special parameters for this pathing type
		if pathingType == "z-shape" then

			enemy.minDepth = minDepth
			enemy.maxDepth = maxDepth
			enemy.turningDirection = turningDirection
			enemy.pathingPhase = 0

		end

		setmetatable(enemy,self)
		self.__index = self
		return enemy
	end

	function Enemy:collision()

		local p1 = self.pos
		local p2 = Vector:new(self.pos.x + 32, self.pos.y)
		local p3 = Vector:new(self.pos.x + 16, self.pos.y + 32)
		return BoundingAggregate:new({BoundingTriangle:new(p1, p2, p3)})

	end

	function Enemy:update(dt)

		-- update life
		self.life = self.life - dt

		if self.pathingType == "standard" then

			self.pos = self.pos + self.vel * dt

		end

		-- moves like a wave
		if self.pathingType == "wave" then

			self.pos.x = self.pos.x + math.sin(self.pos.y / 10) * self.amplitude * dt
			self.pos.y = self.pos.y + self.vel.y * dt

		end

		-- z-shape
		if self.pathingType == "z-shape" then

			if self.pathingPhase == 0 then

				self.pos.y = self.pos.y + self.vel.y * dt

				if self.pos.y >= self.maxDepth then

					self.pathingPhase = 1
					-- update velocity according to turn direction
					if self.turningDirection == "right" then

						self.vel = Vector:new(self.vel.x, -self.vel.y)

					elseif self.turningDirection == "left" then

						self.vel = -1 * self.vel

					end
				end
			end

			if self.pathingPhase == 1 then


				self.pos = self.pos + self.vel * dt

				if self.pos.y <= self.minDepth then

					self.pathingPhase = 2

				end
			end

			if self.pathingPhase == 2 then

				self.vel = Vector:new(0, -self.vel.y)
				self.pathingType = "standard"

			end
		end
	end

	function Enemy:draw()

		love.graphics.polygon("line", {self.pos.x, self.pos.y, self.pos.x + 32, self.pos.y, self.pos.x + 16, self.pos.y + 32})

	end

-- AI-based enemy
-- for info: http://www.red3d.com/cwr/steer/gdc99/
SteeringEnemy = Object:new({class = "SteeringEnemy"})

	function SteeringEnemy:new(mass, radius, pos, vel, max_force, max_speed, orientation, behaviorType, target)
			
		enemy = Object:new({mass = mass, pos = pos, vel = vel, max_force = max_force,
							radius = radius, max_speed = max_speed, orientation = orientation,
							behaviorType = behaviorType or "seek", target = target or Vector:new(400, 400)})
		self.__index = self
		setmetatable(enemy, self)
		if behaviorType == "wandering" then enemy.initializeSteering = true end
		return enemy

	end

	function SteeringEnemy:update(dt)

		-- keep it on screen
		self.pos.x = self.pos.x % shmupgame.width
		self.pos.y = self.pos.y % shmupgame.height

		-- determine steering force
		-- fixed target point
		if self.behaviorType == "seek" then

			desired_velocity = (self.target - self.pos):normalize() * self.max_speed
			self.steering = desired_velocity - self.vel

		end

		if self.behaviorType == "flee" then

			desired_velocity = (self.pos - self.target):normalize() * self.max_speed
			self.steering = desired_velocity - self.vel

		end

		-- NOTE: these two assume you pass in a target object, not a position.
		-- dynamic target; entity
		if self.behaviorType == "pursuit" then

			target_pos = self.target.pos
			desired_velocity = (target_pos - self.pos):normalize() * self.max_speed
			self.steering = desired_velocity - self.vel

		end

		if self.behaviorType == "evade" then

			target_pos = self.target.pos
			desired_velocity = (self.pos - target_pos):normalize() * self.max_speed
			self.steering = desired_velocity - self.vel

		end

		-- fixed target
		if self.behaviorType == "arrival" then

			offset = self.target - self.pos
			distance = offset:norm()
			slowing_distance = 110
			ramped_speed = self.max_speed * (distance / slowing_distance)
			clipped_speed = math.min(ramped_speed, self.max_speed)
			desired_velocity = (clipped_speed / distance) * offset
			self.steering = desired_velocity - self.vel

		end

		-- no target
		if self.behaviorType == "flock" then

			-- find members of a local neighborhood
			self.neighbors = {}
			neighborhood_distance = 100
			for i, v in ipairs(enemies) do

				distance_between = (v.pos - self.pos):norm()
				if distance_between <= neighborhood_distance then

					table.insert(self.neighbors, v)

				end
			end

			--[[ 
				seperation behavior: maintain a distance apart from others
						1. find the distance between each object in the neighborhood
						2. normalize and weigh it by 1 / r
						3. sum together all of the repulsive forces
						4. the steering force = the sum of all repulsive forces
			]]
			seperation_steering = 0
			for i, v in ipairs(self.neighbors) do

				repulsive_force = self.pos - v.pos
				distance = repulsive_force:norm()
				repulsive_force = repulsive_force:normalize()

				-- account for divide by zero error
				if distance == 0 then distance = .001 end

				repulsive_force = repulsive_force * (1 / distance)^2
				seperation_steering = seperation_steering + repulsive_force

			end

			--[[ 
				cohesion behavior: keep the flock together
						1. find average position in the neighborhood
						2. steer in the direction of that position
			]]
			total_position = Vector:new(0,0)
			count = 0
			for i, v in ipairs(self.neighbors) do

				count = count + 1
				total_position = total_position + v.pos

			end
			-- "gravity center" of the neighborhood
			average_position = total_position * (1 / count)
			cohesion_steering = self.pos - average_position

			--[[ 
				alignment behavior: steer the flock in the same direction
						1. find average (desired) velocity 
						2. steering in the diection of that velocity
			]]
			total_velocity = 0
			count = 0 
			for i, v in ipairs(self.neighbors) do

				count = count + 1
				total_velocity = total_velocity + v.vel

			end
			desired_velocity = total_velocity * (1 / count)
			alignment_steering = desired_velocity - self.vel

			-- normalize three behaviors, scale by weighting factors, then combine.
			alignment_steering = alignment_steering:normalize()
			seperation_steering = seperation_steering:normalize()
			cohesion_steering = cohesion_steering:normalize()

			self.steering = 40*(.5 * alignment_steering + .1 * seperation_steering + .4 * cohesion_steering)

		end

		-- random steering
		if self.behaviorType == "wandering" then

			-- steering movement is constrained to the perimeter of a circle 
			-- in front of the vehicle
			circleRadius = 75
			velNorm = self.vel:normalize()
			circleCenter = self.pos + velNorm * 25 + velNorm * circleRadius
			maximumOffset = math.pi / 1000
			if self.initializeSteering == true then
				self.posOnCircle = Vector:new(circleRadius, 0)
				self.initializeSteering = false
			else
				offset = math.random(-maximumOffset, maximumOffset)
				self.posOnCircle = self.posOnCircle:rotate(offset)
			end
			posInWorld = circleCenter + self.posOnCircle
			self.steering = posInWorld - self.pos

		end

		-- truncate the steering force by max force
		if self.steering:norm() > self.max_force then
			self.steering = self.steering:normalize() * self.max_force
		end

		-- determine acceleration
		self.acc = self.steering * (1 / self.mass)

		-- truncate velocity by max speed
		self.vel = self.vel + self.acc
		self.vel = self.vel * 1.001

		if self.vel:norm() > self.max_speed then
			self.vel = self.vel:normalize() * self.max_speed
		end

		-- update position
		self.pos = self.pos + self.vel * dt

		-- update orientation (which way is it facing?)
		self.orientation = self.vel:angle()

	end

	function SteeringEnemy:collision()

		--return BoundingAggregate:new({BoundingSphere:new(self.pos, self.radius)})
		return BoundingAggregate:new({})

	end

	function SteeringEnemy:draw()

		p1 = self.pos
		velNorm = self.vel:normalize() 
		velPerp = velNorm:rotate(math.pi / 2)
		backEnd = (p1 - velNorm * 32)
		p2 = backEnd + velPerp * 16
		p3 = backEnd - velPerp * 16
		love.graphics.polygon("line", self.pos.x, self.pos.y, p2.x, p2.y, p3.x, p3.y)

		-- if self.behaviorType == "wandering" then
		-- 	-- draw circle
		-- 	circleCenter = p1 + velNorm * 25 + velNorm * circleRadius
		-- 	love.graphics.circle("line", circleCenter.x, circleCenter.y, circleRadius)
		-- 	-- draw position on the circle
		-- 	love.graphics.circle("fill", posInWorld.x, posInWorld.y, 5)
		-- end
		-- draw the target
		--if self.target.class == "Vector" then
		--	love.graphics.circle("fill", self.target.x, self.target.y, 5, 100)
		--else
		--	love.graphics.circle("fill", self.target.pos.x, self.target.pos.y, 5, 100)
		--end
		
		--draw the velocity vec
		--love.graphics.line(self.pos.x, self.pos.y, self.pos.x + self.vel.x / 5, self.pos.y + self.vel.y / 5)
		-- -- draw steering force
		--love.graphics.line(self.pos.x, self.pos.y, self.pos.x + self.steering.x * 10, self.pos.y + self.steering.y * 10)

	end

-- Move and Shoot enemy
Turret = Object:new({class = "Turret"})

	function Turret:new(pos, targetPos, velScalar, fireDelay, bulletLevel, health, width, height)
		turret = Object:new({pos = pos, targetPos = targetPos or Vector:new(0,0),
				  velScalar = velScalar or 50,
				  fireDelay = fireDelay or 1, fireRate = fireDelay or 1, 
				  width = width or 32, height = height or 32,
				  bulletLevel = bulletLevel or 1, health = health or 100, life = life or 20})
		self.__index = self
		setmetatable(turret, self)
		return turret
	end

	function Turret:update(dt)

		-- update the position
		if self.targetPos - self.pos ~= Vector:new(0, 0) then

			-- find velocity direction, multiply by velocity scalar.
			direction = (self.targetPos - self.pos)
			direction = direction * (1 / direction:norm())
			velocity = direction * self.velScalar

			self.pos = self.pos + velocity * dt

		end

		self.fireDelay = self.fireDelay - dt

		if self.fireDelay <= 0 then

			-- fire at the player depending upon bulletLevel
			player_middle = Vector:new(player.pos.x + player.width / 2, player.pos.y + player.height / 2)
			turret_middle = Vector:new(self.pos.x + self.width / 2, self.pos.y + self.height / 2)
			turret_to_player = (player_middle - turret_middle)
			turret_to_player = (turret_to_player * (1/turret_to_player:norm()))

			velocity = turret_to_player * 200
			velocity.y = velocity.y * -1

			if self.bulletLevel == 1 then

				bullet = Bullet:new(turret_middle + turret_to_player * 50, velocity, 10, 10)
				table.insert(shmupgame.enemyBullets, bullet)

			end

			if self.bulletLevel == 9 then

				velocity = velocity:rotate(-math.pi / 2)
				variance = math.random(-1, 1)

				for i = 1, 11 do

					velocity = velocity:rotate(math.pi / (variance + 11))
					bullet = Bullet:new(turret_middle + turret_to_player * 50, velocity, 10, 10)
					table.insert(shmupgame.enemyBullets, bullet)

				end
			end

			self.fireDelay = self.fireRate
		end
	end

	function Turret:collision()

		p1 = self.pos
		p2 = Vector:new(self.pos.x + self.width, self.pos.y)
		p3 = Vector:new(self.pos.x, self.pos.y + self.height)
		p4 = Vector:new(self.pos.x + self.width, self.pos.y + self.height)
		return BoundingAggregate:new({BoundingTriangle:new(p1, p2, p3), BoundingTriangle:new(p2, p3, p4)})

	end

	function Turret:draw()

		-- draw the box
		p1 = self.pos
		p2 = Vector:new(self.pos.x + self.width, self.pos.y)
		p3 = Vector:new(self.pos.x, self.pos.y + self.height)
		p4 = Vector:new(self.pos.x + self.width, self.pos.y + self.height)
		love.graphics.polygon("line", p1.x, p1.y, p2.x, p2.y, p4.x, p4.y, p3.x, p3.y)

		-- draw the gun
		player_middle = Vector:new(player.pos.x + player.width / 2, player.pos.y + player.height / 2)
		turret_middle = Vector:new(self.pos.x + self.width / 2, self.pos.y + self.height / 2)
		turret_to_player = (player_middle - turret_middle)
		turret_to_player = (turret_to_player * (1/turret_to_player:norm()))

		endpos = turret_middle + (turret_to_player * 50)
		love.graphics.line(turret_middle.x, turret_middle.y, endpos.x, endpos.y)

	end

-- First Boss
Boss = Object:new({class = "Boss"})

	function Boss:new(pos, vel, width, height, health, fireDelay)

		local boss = Object:new({
			pos = pos or Vector:new(0,0), vel = vel or Vector:new(0,0),
			health = health or 0, width = width or 0, height = height or 0,
			fireRate = fireDelay or .5, fireDelay = fireDelay or .5,
			phase = 1
		})
		setmetatable(boss, self)
		self.__index = self
		return boss

	end

	function Boss:update(dt)

		self.pos = self.pos + self.vel * dt

		if self.pos.x + self.width > shmupgame.width - 10 or self.pos.x < 10 then
			self.vel.x = self.vel.x * -1
		end


		self.fireDelay = self.fireDelay - dt

		self.pos = self.pos + self.vel * dt

		-- gun points
		local p7 = Vector:new(self.pos.x + 3 * self.width / 4, self.pos.y + self.height + 25)
		local p8 = Vector:new(self.pos.x + self.width / 4, self.pos.y + self.height + 25)
		points = {p7, p8}

		if self.fireDelay <= 0 then

			for i = 1, 2 do

				player_middle = Vector:new(player.pos.x + player.width / 2, player.pos.y + player.height / 2)

				-- add player velocities to be cheeky 
				variance = (12 * math.random(0, 400) / math.sqrt(player.vel:norm()))

				player_middle.x = player_middle.x + variance *((player.vel.x * dt * -player.a)
												  + (player.vel.x * dt * player.d))

				player_middle.y = player_middle.y + variance *((player.vel.y * dt * -player.w)
												  + (player.vel.y * dt * player.s))

				gun_to_player = (player_middle - points[i])
				gun_to_player = (gun_to_player * (1 / gun_to_player:norm()))

				velocity = gun_to_player * 400
				velocity.y = -1 * velocity.y

				bullet = Bullet:new(points[i], velocity, 10, 10)
				table.insert(shmupgame.enemyBullets, bullet)

			end

			self.fireDelay = self.fireRate

		end
	end

	function Boss:collision()

		-- shape of a long hexagon
		local p1 = Vector:new(self.pos.x, self.pos.y + self.height / 2)
		local p2 = Vector:new(self.pos.x + self.width / 8, self.pos.y)
		local p3 = Vector:new(self.pos.x + self.width / 8, self.pos.y + self.height)
		
		local p4 = Vector:new(self.pos.x + 7 * self.width / 8, self.pos.y)
		local p5 = Vector:new(self.pos.x + self.width, self.pos.y + self.height / 2)
		local p6 = Vector:new(self.pos.x + 7 * self.width / 8, self.pos.y + self.height)

		-- additional gun points
		local p7 = Vector:new(self.pos.x + 3 * self.width / 4, self.pos.y + self.height)
		local p8 = Vector:new(self.pos.x + self.width / 4, self.pos.y + self.height)

		T1 = BoundingTriangle:new(p1, p2, p3)
		T2 = BoundingTriangle:new(p4, p5, p6)
		T3 = BoundingTriangle:new(p2, p4, p3)
		T4 = BoundingTriangle:new(p3, p6, p4)
		T5 = BoundingTriangle:new(Vector:new(p7.x + 10, p7.y), Vector:new(p7.x, p7.y + 25),
								  Vector:new(p7.x - 10, p7.y))
		T6 = BoundingTriangle:new(Vector:new(p8.x + 10, p8.y), Vector:new(p8.x, p8.y + 25),
								  Vector:new(p8.x - 10, p8.y))

		return BoundingAggregate:new({T1, T2, T3, T4, T5, T6})

	end

	function Boss:draw()

		-- main shape
		local p1 = Vector:new(self.pos.x, self.pos.y + self.height / 2)
		local p2 = Vector:new(self.pos.x + self.width / 8, self.pos.y)
		local p3 = Vector:new(self.pos.x + self.width / 8, self.pos.y + self.height)
		
		local p4 = Vector:new(self.pos.x + 7 * self.width / 8, self.pos.y)
		local p5 = Vector:new(self.pos.x + self.width, self.pos.y + self.height / 2)
		local p6 = Vector:new(self.pos.x + 7 * self.width / 8, self.pos.y + self.height)

		-- additional gun points
		local p7 = Vector:new(self.pos.x + 3 * self.width / 4, self.pos.y + self.height)
		local p8 = Vector:new(self.pos.x + self.width / 4, self.pos.y + self.height)

		love.graphics.polygon("line", p1.x, p1.y, p2.x, p2.y, p4.x, p4.y, p5.x, p5.y, p6.x, p6.y, 
									  p7.x + 10, p7.y, p7.x, p7.y + 25, p7.x - 10, p7.y, 
									  p8.x + 10, p8.y, p8.x, p8.y + 25, p8.x - 10, p8.y,
									  p3.x, p3.y)
	end

-- TO BE DETERMINED.. Springy/Rotationy Thing
BossTwo = Object:new({class = "BossTwo"})

	function BossTwo:new(rotCenter, radius, angle, vel, rotVel, rotAcc, health, fireDelay)
		
		local boss = Object:new({
			rotCenter = rotCenter or Vector:new(0,0), vel = vel or Vector:new(0,0),
			radius = radius or 0, rotVel = rotVel or 10, rotAcc = rotAcc or 1,
			fireRate = fireDelay or .5, fireDelay = fireDelay or .5,
			health = health or 5, angle = angle or 0,
		})

		ballEnd = (Vector:new(1, 0)):rotate(angle)
		ballEnd = ballEnd * radius
		ballEnd = ballEnd + rotCenter
		boss.springBall = SpringBall:new(ballEnd, ballEnd, .1)

		setmetatable(boss, self)
		self.__index = self
		return boss

	end

	function BossTwo:update(dt)

		-- keep it on screen
		if self.rotCenter.x + 25 >= shmupgame.width then
			self.vel.x = self.vel.x * -1
		end
		if self.rotCenter.x - 25 <= 0 then
			self.vel.x = self.vel.x * -1
		end
		if self.rotCenter.y + 25 >= shmupgame.height then
			self.vel.y = self.vel.y * -1
		end
		if self.rotCenter.y - 25 <= 0 then
			self.vel.y = self.vel.y * -1
		end

		-- spring-like wind-up for the arm (F = -k * x)
		self.rotAcc =  - .4 * self.angle

		self.rotCenter = self.rotCenter + self.vel * dt
		self.rotVel = self.rotVel + self.rotAcc * dt
		self.angle = self.angle + self.rotVel * dt
		
		-- update tether ball-like thing
		ballEnd = (Vector:new(1, 0)):rotate(self.angle)
		ballEnd = ballEnd * self.radius
		ballEnd = ballEnd + self.rotCenter
		self.springBall.equilibriumPos = ballEnd
		self.springBall:update(dt)

		-- truncate the velocity
		velocity = (self.springBall.vel):norm()
		maxVel = 3500
		if velocity > maxVel then
			direction = (self.springBall.vel):normalize()
			newVel = direction * maxVel
			self.springBall.vel = newVel
		end
	end

	function BossTwo:draw()

		-- draw rotational center
		love.graphics.circle("fill", self.rotCenter.x, self.rotCenter.y, 25)

		-- draw line to ball
		ballEnd = (Vector:new(1, 0)):rotate(self.angle)
		ballEnd = ballEnd * self.radius
		ballEnd = ballEnd + self.rotCenter
		love.graphics.line(self.rotCenter.x, self.rotCenter.y, ballEnd.x, ballEnd.y)

		-- draw the ball on the end
		love.graphics.circle("line", ballEnd.x, ballEnd.y, 5)

		-- draw the Springball
		self.springBall:draw()

	end

	function BossTwo:collision()

		return BoundingAggregate:new({})

	end