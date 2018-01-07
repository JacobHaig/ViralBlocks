
minetest.register_node("mymod:virus", {
	tiles = {"WiswardsMod_virus.png"},
	groups = {snappy=1, choppy=2, oddly_breakable_by_hand=2, flammable=3},
})

minetest.register_abm({
	nodenames = {"mymod:virus"},
	interval = 1,
	chance = 2,
	action = function(pos)

		--minetest.chat_send_all(minetest.get_node({x = pos.x, y = pos.y , z = pos.z }).name)
		local direction = math.random(1, 6)

		local x, y, z = pos.x, pos.y, pos.z
		local adjacentBlocks = {
			{x+1, y, z}, {x-1, y, z},
			{x, y+1, z}, {x, y-1, z},
		  {x, y, z+1}, {x, y, z-1},
			{x+1, y+1, z}, {x-1, y-1, z},
			{x, y+1, z+1}, {x, y-1, z-1},
		  {x+1, y, z+1}, {x-1, y, z-1},
			{x+1, y+1, z+1}, {x-1, y-1, z-1}
		}

		-- not yet sure if for loops work this way
		for n, coords in adjacentBlocks do
			if minetest.get_node(coords).name ~= "air" and minetest.get_node(coords).name ~= "mymod:virus" then
			  minetest.add_node(coords, {name="mymod:virus"})
		  end
		end

		--explist

		[[
		for key,value in adjacentBlocks do --pseudocode
    	value = "foobar"
		end

		for key,value in pairs(myTable) do --actualcode
    	myTable[key] = "foobar"
		end
		]]

	end,
})

minetest.register_abm({
	nodenames = {"mymod:virus"},
	interval = 1,
	chance = 5,
	action = function(pos)
		minetest.add_node({x= pos.x, y= pos.y, z= pos.z }, {name= "air"})
	end,
})
