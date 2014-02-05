require "utility"
require "objects"

--[[
	general -- detect whether or not two tables, a and b, collide
--]]
function detect(a, b)
	local a_bodies = a:collision()
	local b_bodies = b:collision()
	
	-- iterate through the two aggregates
	for i,v in ipairs(a_bodies) do

		-- check for Bounding-type
		if(v.class == "BoundingSphere") then

			for j,k in ipairs(b_bodies) do

				-- check for collisions
				if(k.class == "BoundingSphere") then
					return CirclevsCircle(v, k)
				end

				if(k.class == "BoundingTriangle") then
					return CirclevsTriangle(v, k)
				end
			end

		-- check for Bounding-type
		elseif(v.class == "BoundingTriangle") then

			for j,k in ipairs(b_bodies.aggregate) do

					-- check for collisions
					if(k.class == "BoundingSphere") then
						return CirclevsTriangle(k, v)
					end

					if(k.class == "BoundingTriangle") then
						return TrianglevsTriangle(v, k)
					end
			end
		
		else
			error("detect: Objects do not support collision behavior")
		end
	end
end

--[[
	-- Helper Functions
--]]

-- line : {Vector, Vector}
function LinevsLine(line_a, line_b)
	--[[
		Line segments intersect when equal:
			P(a) = P(b)
			P1 + Ua(P2 - P1) = P3 + Ub(P4 - P3)
				-- 0 <= Ua <= 1; 0 = startpoint; 1 = endpoint;

			Rewritten:
			x1 + Ua(x2 - x1) = x3 + Ub(x4 - x3)
			y1 + Ua(y2 - y1) = y3 + Ub(y4 - y3)
				-- where (x1, y1), (x2, y2) define line_a
						 (x3, y3), (x4, y4) define line_b

			Solve for U(a):
			U(a) = ((x4-x3)(y1-y3) - (y4-y3)(x1-x3)) / ((y4-y3)(x2-x1) - (x4-x3)(y2-y1))
			U(b) = ((x2-x1)(y1-y3) - (y2-y1)(x1-x3)) / ((y4-y3)(x2-x1) - (x4-x3)(y2-y1))

			Verify that Ua and Ub are between 0 and 1.
			IF you want the exact points, solve using Ua.
	]]
	x1 = line_a[1].x; x2 = line_a[2].x; x3 = line_b[1].x; x4 = line_b[2].x
	y1 = line_a[1].y; y2 = line_a[2].y; y3 = line_b[1].y; y4 = line_b[2].y

	denom = ((y4-y3) * (x2-x1) - (x4-x3) * (y2-y1))

	U_a = ((x4-x3) * (y1-y3) - (y4-y3) * (x1-x3)) / denom
	
	U_b = ((x2-x1) * (y1-y3) - (y2-y1) * (x1-x3)) / denom

	return (0 <= U_a and U_a <= 1) and (0 <= U_b and U_b <= 1)
end

-- sphere, line : BoundingSphere, {Vector, Vector} 
function CirclevsLine(sphere, line)

	-- AC = beginning of line segment to sphere center
	-- AB = the line segment
	local AC = sphere.center - line[1] 
	local AB = line[2] - line[1]

	-- project AC onto AB
	AB_hat = AB * (1 / (AB:norm()))
	AD = (AC * AB_hat) * AB_hat

	dist = (AC - AD):norm()
	return (dist <= sphere.radius)

end

-- T, point_a : BoundingTriangle, Vector
function PointinTriangle(T, point_a)
	--[[
	By the Barycentric Technique:
		x = a * x1 + b * x2 + c * x3
		y = a * y1 + b * y2 + c * y3
		a + b + c = 1

			-- where point_a = {x, y}, T = {{x1, y1}, {x2, y2}, {x3, y3}}
		Solve for a, b and c... 
			-- point p lies in triangle T iff. 0 <= a <= 1, 0 <= b <= 1, 0 <= c <= 1
	]]
	local x = point_a.x;		x1 = T.p1.x;		x2 = T.p2.x;		x3 = T.p3.x; 
	local y = point_a.y;		y1 = T.p1.y;		y2 = T.p2.y;		y3 = T.p3.y;

	denom = ((y2 - y3) * (x1 - x3)) + ((x3 - x2) * (y1 - y3))
	a = ((y2 - y3) * (x - x3) + (x3 - x2) * (y - y3)) / denom
	b = ((y3 - y1) * (x - x3) + (x1 - x3) * (y - y3)) / denom
	c = 1 - a - b

	return (0.0 <= a and a <= 1.0) and (0.0 <= b and b <= 1.0) 
								   and (0.0 <= c and c <= 1.0)
end

-- a_sphere, point_a : BoundingSphere, Vector
function PointinCircle(a_sphere, point_a)

	local dist = (a_sphere.center - point_a):norm()
	return (dist - a_sphere.radius) <= 0

end

--[[
	-- Collision Tests
--]]

function CirclevsCircle(a_sphere, b_sphere)

	local dist = (a_sphere.center - b_sphere.center):norm()
	return dist - a_sphere.radius - b_sphere.radius <= 0

end

-- a_sphere, T : BoundingSphere, BoundingTriangle
function CirclevsTriangle(a_sphere, T)

	--[[
	Three cases:
		1. any vertex in circle
		2. circle within triangle
		3. circle intersects any of the edges
	]]
	-- Case 1
	if(PointinCircle(a_sphere, T.p1) or PointinCircle(a_sphere, T.p2)
									 or PointinCircle(a_sphere, T.p3))
									 then return true end

	-- Case 2
	if(PointinTriangle(T, a_sphere.center)) then return true end

	-- Case 3
	if(CirclevsLine(a_sphere, {T.p1, T.p2}) or CirclevsLine(a_sphere, {T.p1, T.p3})
											or CirclevsLine(a_sphere, {T.p2, T.p3}))
											then return true end 

end

-- T1, T2 : BoundingTriangle, BoundingTriangle
function TrianglevsTriangle(T1, T2)
	--[[
	First, check if two sides of triangle A intersect with any side of triangle B.
	Then, check if any point of triangle A is within triangle B, and vice versa.
	]]
	T1_line_a = {T1.p2, T1.p1}
	T1_line_b = {T1.p3, T1.p1}
	T2_line_a = {T2.p2, T2.p1}
	T2_line_b = {T2.p3, T2.p1}
	T2_line_c = {T2.p3, T2.p2}

	-- Line-Line intersection check
	if (LinevsLine(T1_line_a, T2_line_a) or LinevsLine(T1_line_a, T2_line_b) or
		LinevsLine(T1_line_a, T2_line_c) or LinevsLine(T1_line_b, T2_line_a) or
		LinevsLine(T1_line_b, T2_line_b) or LinevsLine(T1_line_b, T2_line_c))
		then return true 
	end

	-- Points in Triangle check
	if (PointinTriangle(T1, T2.p1) or PointinTriangle(T1, T2.p2) or
		PointinTriangle(T1, T2.p3) or PointinTriangle(T2, T1.p1) or
	    PointinTriangle(T2, T1.p2) or PointinTriangle(T2, T1.p3)) 
		then return true
	end

	return false
end

function Physics_Tests()
	-- Line vs Line
	-- simple test
	line1 = {Vector:new(0,0), Vector:new(1,1)}
	line2 = {Vector:new(0, 1), Vector:new(1, 0)}
	assert(LinevsLine(line1, line2))

	-- vertical line
	line1 = {Vector:new(-35, 0), Vector:new(-35, -100)}
	line2 = {Vector:new(-55, -25), Vector:new(-10, -10)}
	assert(LinevsLine(line1, line2))

	-- horizontal line
	line1 = {Vector:new(0,0), Vector:new(25, 0)}
	line2 = {Vector:new(0, -10), Vector:new(25, 25)}
	assert(LinevsLine(line1, line2))

	-- false-positive test
	line1 = {Vector:new(0,0), Vector:new(10,10)}
	line2 = {Vector:new(0, -5), Vector:new(10, 5)}
	assert(not LinevsLine(line1, line2))

	-- Point in Triangle
	-- right triangle test
	p1 = Vector:new(0, 0)
	p2 = Vector:new(10, 0)
	p3 = Vector:new(0, 10)
	T = BoundingTriangle:new(p1, p2, p3)
	point = Vector:new(1,1)
	assert(PointinTriangle(T, point))

	-- more complicated
	p1 = Vector:new(-50, 0)
	p2 = Vector:new(-60, -40)
	p3 = Vector:new(-40, -50)
	T = BoundingTriangle:new(p1, p2, p3)
	point = Vector:new(-48, -30)
	assert(PointinTriangle(T, point))

	-- shared node
	p1 = Vector:new(-50, 0)
	p2 = Vector:new(-60, -40)
	p3 = Vector:new(-40, -50)
	T = BoundingTriangle:new(p1, p2, p3)
	point = Vector:new(-50, 0)
	assert(PointinTriangle(T, point))

	-- shared edge
	p1 = Vector:new(0, 0)
	p2 = Vector:new(10, 0)
	p3 = Vector:new(0, 10)
	T = BoundingTriangle:new(p1, p2, p3)
	point = Vector:new(5,5)
	assert(PointinTriangle(T, point))

	-- false positive
	p1 = Vector:new(0, 0)
	p2 = Vector:new(10, 0)
	p3 = Vector:new(0, 10)
	T = BoundingTriangle:new(p1, p2, p3)
	point = Vector:new(-5, -5)
	assert(not PointinTriangle(T, point))

	-- Triangle Vs. Triangle
	-- simple test
	p1 = Vector:new(0,0)
	p2 = Vector:new(10,0)
	p3 = Vector:new(0, 10)
	p4 = Vector:new(10,10)
	T1 = BoundingTriangle:new(p1,p2,p3)
	T2 = BoundingTriangle:new(p1,p2,p4)
	assert(TrianglevsTriangle(T1, T2))

	-- false positive
	p1 = Vector:new(0,0)
	p2 = Vector:new(10,0)
	p3 = Vector:new(0, 10)
	p4 = Vector:new(10,10)
	p5 = Vector:new(0, 5)
	p6 = Vector:new(5, 0)
	T1 = BoundingTriangle:new(p1, p5, p6)
	T2 = BoundingTriangle:new(p2, p4, p3)
	assert(not TrianglevsTriangle(T1, T2))

	-- no shared nodes
	p1 = Vector:new(0,0)
	p2 = Vector:new(10,0)
	p3 = Vector:new(0, 10)
	p4 = Vector:new(10,10)
	p5 = Vector:new(5, -3)
	p6 = Vector:new(5, 13)
	T1 = BoundingTriangle:new(p1, p6, p2)
	T2 = BoundingTriangle:new(p3, p4, p5)
	assert(TrianglevsTriangle(T1, T2))

	-- Triangle VS. Circle
	-- simple test
	p1 = Vector:new(0,0)
	p2 = Vector:new(5,0)
	p3 = Vector:new(0,5)
	circle = BoundingSphere:new(p1, .5)
	T =  BoundingTriangle:new(p1, p2, p3)
	assert(CirclevsTriangle(circle, T))

	-- center fully within
	p1 = Vector:new(0,-5)
	p2 = Vector:new(5,0)
	p3 = Vector:new(0,5)
	p4 = Vector:new(2,0)
	circle = BoundingSphere:new(p4, .5)
	T =  BoundingTriangle:new(p1, p2, p3)
	assert(CirclevsTriangle(circle, T))

	-- edge intersection
	p1 = Vector:new(0,-5)
	p2 = Vector:new(5,0)
	p3 = Vector:new(0,5)
	p4 = Vector:new(-1,0)
	circle = BoundingSphere:new(p4, 2)
	T =  BoundingTriangle:new(p1, p2, p3)
	assert(CirclevsTriangle(circle, T))

	-- false positive
	p1 = Vector:new(0,0)
	p2 = Vector:new(5,0)
	p3 = Vector:new(0,5)
	p4 = Vector:new(-5,-5)
	circle = BoundingSphere:new(p4, 2)
	T =  BoundingTriangle:new(p1, p2, p3)
	assert(not CirclevsTriangle(circle, T))
end