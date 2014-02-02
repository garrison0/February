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

end