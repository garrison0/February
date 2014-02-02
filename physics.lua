require "utility"

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

-- helper functions
-- note: line = {{point 1}, {point 2}}
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
	]]
	x1 = line_a[1][1]
	x2 = line_a[2][1]
	x3 = line_b[1][1]
	x4 = line_b[2][1]
	y1 = line_a[1][2]
	y2 = line_a[2][1]
	y3 = line_b[1][2]
	y4 = line_b[2][2]
	
	U_a = ((x4-x3) * (y1-y3) - (y4-y3) * (x1-x3)) / ((y4-y3) * (x2-x1) - (x4-x3) * (y2-y1))
	
	U_b = ((x2-x1) * (y1-y3) - (y2-y1) * (x1-x3)) / ((y4-y3) * (x2-x1) - (x4-x3) * (y2-y1))

	return (0 <= U_a and U_a <= 1) and (0 <= U_b and U_b <= 1)
end

function PointinTriangle(triangle, point_a)

end

-- specific collision tests
function CirclevsCircle(a_sphere, b_sphere)
	local dist = (a_sphere.center - b_sphere.center):norm()

	if dist - a_sphere.radius - b_sphere.radius <= 0 then
		return true
	else
		return false
	end
end

function CirclevsTriangle()

end

function TrianglevsTriangle()
	--[[
	First, check if two sides of triangle A intersect with triangle B.
	Then, check if any point of triangle A is within triangle B, and vice versa.
	]]
	-- Line-Line intersection

	-- Points in Triangle check

end

function Physics_Tests()
	-- Line vs Line
	-- simple test
	line1 = {{0, 0}, {1, 1}}
	line2 = {{0, 1}, {1, 0}}
	assert(LinevsLine(line1, line2))

	-- vertical line
	line1 = {{-35, 0}, {-35, -100}}
	line2 = {{-55, -25}, {-10, -10}}
	assert(LinevsLine(line1, line2))

	-- horizontal line
	line1 = {{0, 0}, {25, 0}}
	line2 = {{0, -10}, {25, 25}}
	assert(LinevsLine(line1, line2))

	-- false-positive test
	line1 = {{0,0}, {10, 10}}
	line2 = {{0, -5}, {10, 5}}
	assert(not LinevsLine(line1, line2))

end