require "object"
require "utility"

BoundingAggregate = Object:new({class = "BoundingAggregate"})

	function BoundingAggregate:new(aggregate)
		local boundingAggregate = Object:new(aggregate or {})
		setmetatable(aggregate, self)
		self.__index = self
		return boundingAggregate
	end

BoundingSphere = Object:new({class = "BoundingSphere"})

	function BoundingSphere:new(center, radius)
		local sphere = Object:new({center = center or Vector:new(0,0),
								   radius = radius or 0})
		setmetatable(sphere,self)
		self.__index = self
		return sphere
	end

	--[[ translation
		x must be either a BoundingSphere, Vector, or number
		y must be either a BoundingSphere, Vector, or number
		one and only one of x and y must be a BoundingSphere
	--]]
	function BoundingSphere.__add(x, y)
		local x_isSphere = x.class == "BoundingSphere"
		local y_isSphere = y.class == "BoundingSphere"
		if x_isSphere and y_isSphere then
		elseif x_isSphere then
			local v = Vector:new(0,0)
			v = v + y
			return BoundingSphere:new(x.center + v, x.radius)
		elseif y_isSphere then
			local v = Vector:new(0,0)
			v = v + x
			return BoundingSphere:new(y.center + v, y.radius)
		end
	end

	function BoundingSphere.__sub(x, y)
		local x_isSphere = x.class == "BoundingSphere"
		local y_isSphere = y.class == "BoundingSphere"
		if x_isSphere and y_isSphere then
		elseif x_isSphere then
			local v = Vector:new(0,0)
			v = v + y
			return BoundingSphere:new(x.center - v, x.radius)
		elseif y_isSphere then
			local v = Vector:new(0,0)
			v = v + x
			return BoundingSphere:new(y.center - v, y.radius)
		end
	end

BoundingTriangle = Object:new({class = "BoundingTriangle"})
	
	function BoundingTriangle:New(p1, p2, p3)
		local triangle = Object:new{p1 = p1 or Vector:new(0,0),
									p2 = p2 or Vector:new(0,0),
									p3 = p3 or Vector:new(0,0)}
		setmetatable(triangle, self)
		self.__index = self
		return triangle
	end

	-- TO DO: translation functions

Player = Object:new({class = "Player"})

	function Player:new(pos, vel)
		local player = Object:new({
			pos = pos or Vector:new(0,0), vel = vel or Vector:new(0,0),
			shooting = false, fire_delay = 0, width = 64, height = 64,
			bulletLevel = 1, bullets = {}, a = 0, s = 0, d = 0, w = 0
		})
		setmetatable(player,self)
		self.__index = self
		return player
	end

	function Player:collision()
		local v = Vector:new(self.pos.x + self.width/2, 
							 self.pos.y + self.height/2)
		return BoundingAggregate:new({BoundingSphere:new(v,30)})
	end

	-- TODO: Move Player-Member functions in here
	function Player:update(dt)
		-- image
		self.pos.x = self.pos.x - self.vel.x * dt * self.a
									  + self.vel.x * dt * self.d
		self.pos.y = self.pos.y + self.vel.y * dt * self.s
									  - self.vel.y * dt * self.w

		-- delay
		self.fire_delay = self.fire_delay - dt
	end

	function Player:shoot()
		-- level 1
		if (player.bulletLevel == 1) then
			bullet = Bullet:new(Vector:new(player.pos.x + player.width/2, player.pos.y), 
										Vector:new(0,1000), .35)

			player.fire_delay = .5
			table.insert(player.bullets, bullet)
		end

		-- level 2
		if (player.bulletLevel == 2) then
			bullet = Bullet:new(Vector:new(player.pos.x + player.width/4, player.pos.y),
										Vector:new(0,1000), .4)
			bullet2 = Bullet:new(Vector:new(player.pos.x + 3*player.width/4, player.pos.y), 
										Vector:new(0,1000), .4)

			player.fire_delay = .4
			table.insert(player.bullets, bullet)
			table.insert(player.bullets, bullet2)
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
			table.insert(player.bullets, bullet)
			table.insert(player.bullets, bullet2)
			table.insert(player.bullets, bullet3)
			table.insert(player.bullets, bullet4)
		end
	end

Enemy = Object:new({class = "Enemy"})

	function Enemy:new(pos, vel)
		local enemy = Object:new({
			pos = pos or Vector:new(0,0), vel = vel or Vector:new(0,0),
			amplitude = 200, width = 32, height = 32
		})
		setmetatable(enemy,self)
		self.__index = self
		return enemy
	end

	function Enemy:collision()
		local v = Vector:new(self.pos.x + self.width/2, 
							 self.pos.y + self.height/2)
		return BoundingAggregate:new({BoundingSphere:new(v,15)})
	end

	function Enemy:update(dt)
		self.pos.x = self.pos.x + math.sin(self.pos.y / 10) * self.amplitude * dt
		self.pos.y = self.pos.y + self.vel.y * dt

	end

Bullet = Object:new({class = "Bullet"})

	function Bullet:new(pos, vel, life, damage)
		local bullet = Object:new({
			pos = pos or Vector:new(0,0), vel = vel or Vector:new(0,0),
			life = life or 0, damage = damage or 0, width = 8, height = 8
		})
		setmetatable(bullet,self)
		self.__index = self
		return bullet
	end

	function Bullet:collision()
		local v = Vector:new(self.pos.x + self.width/2, 
							 self.pos.y + self.height/2)
		return BoundingAggregate:new({BoundingSphere:new(v,4)})
	end

	function Bullet:update(dt)
		self.life = self.life - dt;
		self.pos.y = self.pos.y - self.vel.y * dt
		self.pos.x = self.pos.x + (self.vel.x or 0) * dt

end