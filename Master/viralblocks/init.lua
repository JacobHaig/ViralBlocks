-- possible mod names: CGM, conway, virus, gol, cowayblocks, automata, cgol, liveBlocks, viralblocks
-- possible block names: virus, populated_cell, pop_cell, lifecell, lifeblock

liveblock  = "viralblocks:liveblock"
liveBlocks = {}
adjBlocks = {}
allBlocks = {}
local timer = 0
gen = 0;

-- Creating the liveblock
minetest.register_node(liveblock, {
  description = "Populated (Alive) Cell of Conway's Game of Life",
  tiles = {"WiswardsMod_virus.png"},
  groups = {cracky= 3, oddly_breakable_by_hand= 2, flammable= 3},
  --sounds = default.node_sounds_defaults(),
})


-- Gets called every five seconds
minetest.register_globalstep(function(dtime)
	timer = timer + dtime;
	if timer >= 2 then -- Every Two seconds do stuff
    addAdjBlocks()
    removeAdjBlocks()
    glassify()

		timer = 0
	end
end)


-- Adds adjacentBlocks to the liveBlocks
function addAdjBlocks()
  for k, pos in pairs(liveBlocks) do
    for z_offset= -1, 1 do --Loop through Z
      for x_offset= -1, 1 do --Loop through X

        local newpos = {x= pos.x + x_offset, y= pos.y, z= pos.z + z_offset}
        local node = minetest.get_node(newpos)

        --Rule Out any lifeblocks INCLUDING itself
        if node.name ~= liveblock then --Found one
          -- If the block is already added to the
          -- adjacentBlocks then don't add another
          local alreadyAdded = false
          for _, v in pairs(adjBlocks) do
            if v.x == newpos.x and v.y == newpos.y and v.z == newpos.z  then
              alreadyAdded = true
            end
          end

          if not alreadyAdded then
            table.insert(adjBlocks, newpos)
          end
        end

      end
    end
  end
end


-- If any of the adjBlocks have 0 neighbors remove them
function removeAdjBlocks()
  for k, adjPos in pairs(adjBlocks) do
    -- If there is already a liveblock here
    local node = minetest.get_node(adjPos)
    if node.name == liveblock then
      table.remove(adjBlocks, k)
    elseif node.name == "default:glass" then
      minetest.set_node(adjPos, {name= "air"})
    end
    -- If the block has 0 neighbors
    if checkadjacent(adjPos) == 0 then
      table.remove(adjBlocks, k)
    end

  end
end


-- Check if chat message equals something
minetest.register_on_chat_message(function(name, message)
	if message == "fill" then
    for k, v in pairs(adjBlocks) do
      fillGlass(v)
    end
  elseif message == "showInfo" then
    showInfo()
	end
end)


-- Easier function to print stuff
function say(message) minetest.chat_send_all(message) end


-- Returns the number of elemnts in the table
function tablelength(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end


-- Display to mods current information
function showInfo()
  say("liveBlocks: " .. tostring(tablelength(liveBlocks)))
  say("adjBlocks: " .. tostring(tablelength(adjBlocks)))
end


-- Event that adds lifeblocks to table on placements of lifeblocks
minetest.register_on_placenode(function(pos, newnode, placer, oldnode, itemstack, pointed_thing)
  if newnode.name == liveblock then
    table.insert(liveBlocks, pos)
    removeAdjBlocks()
  end
end)


-- Remove liveBlocks from lifeblocks table
function removeLifeBlock(pos)
  for k, v in pairs(liveBlocks) do
    if v.x == pos.x and v.y == pos.y and v.z == pos.z  then
      table.remove(liveBlocks, k)
      removeAdjBlocks()
    end
  end
end


-- to show which blocks are selected
function fillGlass(pos)
  minetest.set_node(pos, {name= "glass"})
end

-- Turns all adjectent blocks to glass
function glassify()
  for k, adjPos in pairs(adjBlocks) do
    local node = minetest.get_node(adjPos)

    if node.name ~= liveblock then
      minetest.set_node(adjPos, {name= "default:glass"})
    end
  end
end


-- Onload, Find all liveBlocks and add them
minetest.register_lbm({
	name = "viralblocks:countblocks",
	nodenames = {liveblock},
  run_at_every_load = true,
	action = function(pos, node)
		table.insert(liveBlocks, pos)
    --minetest.chat_send_all("Found one at " .. minetest.pos_to_string(pos))
	end,
})


-- If destroyed remove pos from liveBlocks
minetest.register_on_dignode(function(pos, oldnode, digger)
  if oldnode.name == liveblock then
    removeLifeBlock(pos)
  end
end)


-- update liveblock
minetest.register_abm({
  nodenames = {liveblock},
  interval = 3,
  chance = 1,
  action = function(pos)
    if pos == nil then return
    end

    local meta = minetest.get_meta(pos)
    local gen = meta:get_int("gen")

    surround_count = checkadjacent(pos)
    -- minetest.chat_send_all("found " .. surround_count)
    if surround_count < 2 or surround_count > 3 then
       minetest.set_node(pos, {name= "air"})
       removeLifeBlock(pos)
       return
    end

    -- increment generation
    gen = gen + 1
    meta:set_int("gen", gen)
    meta:set_string("infotext", "Gen " .. gen)
	end,
})

-- Returns the number of adjectent liveBlocks
function checkadjacent(pos)
  local surround_count = 0
  for z_offset= -1, 1 do --Loop through Z
     for x_offset= -1, 1 do --Loop through X

        local newpos = {x= pos.x + x_offset, y= pos.y, z= pos.z + z_offset}
        local node = minetest.get_node(newpos)

        if not (x_offset == 0 and z_offset == 0) and node.name == liveblock then --Rule out the center block itself
          surround_count = surround_count + 1
        --elseif node.name == "air" then --Nope, it's empty
             --checkadjacent(newpos)
          --end
        end
        --if surround_count >= 4 then -- no need to count past four
        --  return 4
        --end
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
