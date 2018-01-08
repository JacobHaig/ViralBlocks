-- possible mod names: CGM, conway, virus, gol, cowayblocks, automata, cgol, lifeBlocks, viralblocks
-- possible block names: virus, populated_cell, pop_cell, lifecell, lifeBlock


-- -- local tools = require(minetest.get_modpath("viralblocks") .. "\tools.lua")
-- local tools = dofile(minetest.get_modpath("viralblocks") .. "\\tools.lua")
--
--
-- say = tools.say
-- tablelength = tools.tablelength
-- showInfo = tools.showInfo
-- glassify = tools.glassify

lifeBlock  = "viralblocks:lifeBlock"
paused = false
lifeBlocks = {}
adjBlocks = {}
blocksToAdd = {}
blocksToRemove = {}

local timer = 0
--gen = 0;


local say = minetest.chat_send_all

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- Easier function to print stuff
local say = minetest.chat_send_all

-- Returns the number of elements in the table
function tablelength(Table)
  local count = 0
  for _ in pairs(Table) do count = count + 1 end
  return count
end

-- Display to mods current information
function showInfo()
  say("lifeBlocks: " .. tostring(tablelength(lifeBlocks)))
  say("adjBlocks: " .. tostring(tablelength(adjBlocks)))
end

-- Turns all adjectent blocks to glass
function glassify()
  for k, adjPos in pairs(adjBlocks) do
    local node = minetest.get_node(adjPos)
    if node.name ~= lifeBlock then
      minetest.set_node(adjPos, {name= "default:glass"})
    end
  end
end



-- THE MAIN LOOP
minetest.register_globalstep(function(dtime)
  if not paused then
	   timer = timer + dtime;
	    if timer >= 3 then -- Every Three seconds do stuff

        setAdjacentBlocks()
        removeAdjacentBlocks()

        setTheBlocksToPlace()
        setTheBlocksToRemove()

        placeTheBlocks()
        removeTheBlocks()

		    timer = 0
	    end
  end
end)

-- Set the LifeBlocks
function setTheBlocksToPlace()
  for k, pos in pairs(adjBlocks) do
    if checkAdjacent(pos) == 3 then
      -- We only need to set what needs to be live next update
      -- If we update while we check adjecnt blocks, that can change the answer
      table.insert(blocksToAdd, pos)
    end
  end
  say("blocksToAdd (0 is best): " .. tostring(tablelength(blocksToAdd)))
end

-- Place the LifeBlocks
function placeTheBlocks()
  for k, pos in pairs(blocksToAdd) do
    -- Here, We need to place all of the blocks that we have queued
    -- We also need to empty the blocksToAdd when done
    minetest.set_node(pos, {name= lifeBlock})
    table.remove(blocksToAdd, k)
    table.insert(lifeBlocks, pos)
  end
  say("blocksToAdd (0 is best): " .. tostring(tablelength(blocksToAdd)))
end


-- Set LifeBlocks for Removal
function setTheBlocksToRemove()
  for k, pos in pairs(lifeBlocks) do
    -- Then, if a neighbors doesn't have 3 we need to mark them for removal
    count = checkAdjacent(pos)
    if count < 2 or count > 3 then
      table.insert(blocksToRemove, pos)
    end
  end
end


-- Remove the LifeBlocks
function removeTheBlocks()
  for k, pos in pairs(blocksToRemove) do
    -- Finally, We can remove the marked positions
    -- And remove them from the list
    minetest.set_node(pos, {name= "air"})
    table.remove(blocksToRemove, k)
  end
  for k, pos in pairs(lifeBlocks) do
    table.remove(lifeBlocks, k)
  end

  say("blocksToRemove (0 is best): " .. tostring(tablelength(blocksToRemove)))
end


-- Adds adjacentBlocks to the lifeBlocks
function setAdjacentBlocks()
  for k, pos in pairs(lifeBlocks) do
    for z_offset= -1, 1 do --Loop through Z
      for x_offset= -1, 1 do --Loop through X
        local posOffset = {x= pos.x + x_offset, y= pos.y, z= pos.z + z_offset}
        local node = minetest.get_node(posOffset)

        --Rule Out any lifeBlocks INCLUDING itself
        if node.name ~= lifeBlock then
          local alreadyAdded = false
          for k, pos in pairs(adjBlocks) do
            if pos.x == posOffset.x and pos.y == posOffset.y and pos.z == posOffset.z then
              alreadyAdded = true
            end
          end
          if not alreadyAdded then
            table.insert(adjBlocks, posOffset)
          end
        end

      end
    end
  end
end


-- If any of the adjBlocks have 0 neighbors remove them
function removeAdjacentBlocks()
  for k, pos in pairs(adjBlocks) do
    -- If there is already a lifeBlock here
    local node = minetest.get_node(pos)
    -- If the block has 0 neighbors
    if checkAdjacent(pos) == 0 then
      table.remove(adjBlocks, k)
    end
  end
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Remove lifeBlocks from lifeBlocks table
-- -- Place the living blocks
-- function livePlacement()
--   for k, pos in pairs(adjBlocks) do
--     if checkAdjacent(pos) == 3 then
--       table.insert(lifeBlocks, pos)
--       minetest.set_node(pos, {name= lifeBlock})
--     end
--   end
-- end

-- -- Adds blocks top be removed to array then deletes them
-- function checklifeBlock()
--   -- Add blocks that want to be added to the list
--   for k,pos in pairs(lifeBlocks) do
--     surround_count = checkAdjacent(pos)
--     if surround_count < 2 or surround_count > 3 then
--        table.insert(blocksToAdd, pos)
--     end
--   end
--   -- Remove all blocks
--   for k,pos in pairs(blocksToAdd) do
--     minetest.set_node(pos, {name= "air"})
--     removeLifeBlock(pos)
--   end
-- end


-- Returns the number of adjectent lifeBlocks
function checkAdjacent(pos)
  local surround_count = 0
  for z_offset= -1, 1 do --Loop through Z
     for x_offset= -1, 1 do --Loop through X
        local newpos = {x= pos.x + x_offset, y= pos.y, z= pos.z + z_offset}
        local node = minetest.get_node(newpos)
        if not (x_offset == 0 and z_offset == 0) and node.name == lifeBlock then --Rule out the center block itself
          surround_count = surround_count + 1
        end
     end
  end
  return surround_count
end



-- Creating the lifeBlock
minetest.register_node(lifeBlock, {
  description = "Populated (Alive) Cell of Conway's Game of Life",
  tiles = {"WiswardsMod_virus.png"},
  groups = {cracky= 3, oddly_breakable_by_hand= 2, flammable= 3},
  --sounds = default.node_sounds_defaults(),
})


-- Event that adds lifeBlocks to table on placements of lifeBlocks
minetest.register_on_placenode(function(pos, newnode, placer, oldnode, itemstack, pointed_thing)
  if newnode.name == lifeBlock then
    table.insert(lifeBlocks, pos)
    setAdjacentBlocks()

  end
end)


-- Onload, Find all lifeBlocks and add them
minetest.register_lbm({
	name = "viralblocks:countblocks",
	nodenames = {lifeBlock},
  run_at_every_load = true,
	action = function(pos, node)
		table.insert(lifeBlocks, pos)
	end,
})


-- If destroyed remove pos from lifeBlocks
minetest.register_on_dignode(function(pos, oldnode, digger)
  if oldnode.name == lifeBlock then
    for k, v in pairs(lifeBlocks) do
      if v.x == pos.x and v.y == pos.y and v.z == pos.z  then
        table.remove(lifeBlocks, k)
        setAdjacentBlocks()
      end
    end
  end
end)


-- Check if chat message equals something
minetest.register_on_chat_message(function(name, message)
  if message == "pauselife" then
    paused = true
    say("CGOL board paused globally!")

  elseif message == "resumelife"  then
    paused = false
    say("CGOL board resumed globally!")

  elseif message == "fill" then
    glassify()
    showInfo()
    say("Visualizing cell surroundings...")
  end
end)
