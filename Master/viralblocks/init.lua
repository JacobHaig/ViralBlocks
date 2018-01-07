-- possible mod names: conway, virus, gol, cowayblocks, automata, cgol, lifeblocks, viralblocks
-- possible block names: virus, populated_cell, pop_cell, lifecell, lifeblock

liveblock  = "viralblocks:lifeblock"

minetest.register_node(liveblock, {
   description = "Populated (Alive) Cell of Conway's Game of Life",
   tiles = {"WiswardsMod_virus.png"},
   groups = {cracky=3, oddly_breakable_by_hand=2, flammable=3},
   --sounds = default.node_sounds_defaults(),
})

gen = 0;

minetest.register_abm({
	nodenames = {liveblock},
	interval = 3,
	chance = 1,
	action = function(pos)
    -- minetest.set_node(pos, {name=minetest.get_node(vector.new(pos.x, pos.y, pos.z)).name})
			if pos == nil then return
      end

      local meta = minetest.get_meta(pos)
      local gen = meta:get_int("gen")


      surround_count = checkadjacent(pos)
      -- minetest.chat_send_all("found " .. surround_count)
      if surround_count < 2 or surround_count > 3 then
         minetest.set_node(pos, {name="air"})
         return
      end

      -- increment generation
      gen = gen + 1
      meta:set_int("gen", gen)
      meta:set_string("infotext", "Gen " .. gen)

	end,
})


function checkadjacent(pos)
  local surround_count = 0

  --loop through Z
  for z_offset=-1,1 do

    --loop through X
     for x_offset=-1,1 do

        local newpos = {x=pos.x+x_offset, y=pos.y, z=pos.z+z_offset}
        local node = minetest.get_node(newpos)

        --rule out the center block itself
        if not (x_offset == 0 and z_offset == 0) then

          --found one
          if node.name == liveblock then
             surround_count = surround_count+1

          --nope, it's empty
          elseif node.name == "air" then
             --checkadjacent(newpos)
          end
        end

        -- no need to count past four
        if surround_count == 4 then
          return 4
        end

     end
  end

  return surround_count
end


-- minetest.register_abm({
-- 	nodenames = {"mymod:virus"},
-- 	interval = 2,
-- 	chance = 3,
-- 	action = function(pos)
-- 		minetest.add_node({x = pos.x, y = pos.y , z = pos.z }, {name="air"})
-- 	end,
-- })
