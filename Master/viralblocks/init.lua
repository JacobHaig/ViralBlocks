-- possible mod names: CGM, conway, virus, gol, cowayblocks, automata, cgol, lifeBlocks, viralblocks
-- possible block names: virus, populated_cell, pop_cell, lifecell, lifeBlock

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--     __     __ _              _  ____   _               _                   --
--     \ \   / /(_) _ __  __ _ | || __ ) | |  ___    ___ | | __ ___           --
--      \ \ / / | || '__|/ _` || ||  _ \ | | / _ \  / __|| |/ // __|          --
--       \ V /  | || |  | (_| || || |_) || || (_) || (__ |   < \__ \          --
--        \_/   |_||_|   \__,_||_||____/ |_| \___/  \___||_|\_\|___/          --
--                     License: AGPLv3+                                       --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local tools = dofile(minetest.get_modpath("viralblocks") .. "/tools.lua")

-- say = say
-- tablelength = tools.tablelength
-- showInfo = tools.showInfo
-- glassify = tools.glassify

lifeBlock = "viralblocks:lifeblock"
DELAY_SECONDS = 3
paused = false

--------------------------------------------------------------------------------
-- Debug -----------------------------------------------------------------------
visDebug = false
showingLife = false
nextGeneration = true
STEP = true -- false for debuging

--------------------------------------------------------------------------------
-- Lists -----------------------------------------------------------------------

lifeBlocks = {}
airNeighborsList = {}
blocksToBeBorn = {}
blocksToDie = {}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- THE MAIN LOOP
local timer = 0
local gen = 0
minetest.register_globalstep(
  function(dtime)
    if not paused then
      timer = timer + dtime

      if timer >= DELAY_SECONDS and STEP then -- Every n seconds do stuff
        
        if nextGeneration then
          placeBlocksToBeBorn()
          removeBlocksToDie()
        end
        
        findAirNeighbors()
        findBlocksToBeBorn()
        findBlocksToDie()


        -- if not (tableLength(blocksToBeBorn) == 0 or tableLength(blocksToDie) == 0) then
        -- say("Pass " .. gen)
        --nextGeneration()
        -- gen = gen + 1
        -- end
        
        STEP = true -- false for debuging
        timer = 0
      end
    end
  end
)

function placeBlocksToBeBorn()
  for k, pos in pairs(blocksToBeBorn) do
    -- Here, We need to place all of the blocks that we have queued
    minetest.set_node(pos, {name = lifeBlock})
    -- And add those blocks positions to lifeBlocks
    table.insert(lifeBlocks, pos)
  end
  -- We also need to empty the blocksToBeBorn when done
  blocksToBeBorn = {}
end

-- Place the LifeBlocks
function removeBlocksToDie()
  -- Remove the LifeBlocks
  for k, pos in pairs(blocksToDie) do
    -- remove lifeBlocks from list
    table.remove(lifeBlocks, k)
    -- Finally, We can remove the marked positions from the world
    minetest.set_node(pos, {name = "air"})
  end
  -- And remove them from the list
  blocksToDie = {}
end

-- Set the LifeBlocks
function findBlocksToBeBorn()
  for k, pos in pairs(airNeighborsList) do
    if countLifeNeighbors(pos) == 3 then
      -- Add blocks with exactly three live neighbors to blocksToBeBorn
      table.insert(blocksToBeBorn, pos)
    end
  end
end

-- Set LifeBlocks for Removal
function findBlocksToDie()
  for k, pos in pairs(lifeBlocks) do
    -- Checks for two or three live neighbors - if not, mark for removal
    count = countLifeNeighbors(pos)
    if count < 2 or count > 3 then
      table.insert(blocksToDie, pos)
    end
  end
end

-- Adds findAirNeighbors to the lifeBlocks
function findAirNeighbors()
  airNeighborsList = {}
  for k, pos in pairs(lifeBlocks) do
    for z_offset = -1, 1 do --Loop through Z
      for x_offset = -1, 1 do --Loop through X
        local posOffset = {x = pos.x + x_offset, y = pos.y, z = pos.z + z_offset}
        local node = minetest.get_node(posOffset)
        -- in this loop is all neighbors
        if not (node.name == lifeBlock) then -- air only (for now)
          local alreadyAdded = false
          for k, pos in pairs(airNeighborsList) do --loop through table of air_neighbors
            if vector.equals(pos, posOffset) then -- make sure it's not already in there
              alreadyAdded = true
            end
          end
          if not alreadyAdded then
            table.insert(airNeighborsList, posOffset)
          -- say(dump(airNeighborsList))
          end
        end
      end
    end
  end
end


-- Creating the lifeBlock
minetest.register_node(
  lifeBlock,
  {
    description = "Populated (Alive) Cell of Conway's Game of Life",
    tiles = {"ViralBlocks_LifeBlock.png"},
    groups = {cracky = 3, oddly_breakable_by_hand = 2, flammable = 3}
    --sounds = default.node_sounds_defaults(),
  }
)

-- Event that adds lifeBlocks to table on placements of lifeBlocks
minetest.register_on_placenode(
  function(pos, newnode, placer, oldnode, itemstack, pointed_thing)
    if newnode.name == lifeBlock then
      table.insert(lifeBlocks, pos)
      findAirNeighbors()
    -- placer:get_player_name()
    end
  end
)

-- Onload, Find all lifeBlocks and add them
minetest.register_lbm(
  {
    name = "viralblocks:countblocks", -- countblocks is a dummy
    nodenames = {lifeBlock},
    run_at_every_load = true,
    action = function(pos, node)
      table.insert(lifeBlocks, pos)
    end
  }
)

-- If destroyed remove pos from lifeBlocks
minetest.register_on_dignode(
  function(pos, oldnode, digger)
    if oldnode.name == lifeBlock then
      for k, v in pairs(lifeBlocks) do
        if v.x == pos.x and v.y == pos.y and v.z == pos.z then
          table.remove(lifeBlocks, k)
          findAirNeighbors()
        end
      end
    end
  end
)

-- Check if chat message equals something
minetest.register_on_chat_message(
  function(name, message)
    if message == "debug" then
      findAirNeighbors()
      findBlocksToBeBorn()
      findBlocksToDie()
      debugView(true, showingLife) -- you should "pauselife" to see this
      say("Visual Debug: " .. "Done")
    elseif message == "showlife" then
      showingLife = (not showingLife)
      say("Showing Life: " .. isitTrue(showingLife))
    elseif message == "step" then
      STEP = true
      debugView(true, showingLife)
      say("STEPING : " .. "DONE")
    elseif message == "pauselife" then
      paused = true
      say("CGOL board paused globally!")
    elseif message == "resumelife" then
      paused = false
      say("CGOL board resumed globally!")
    elseif message == "info" then
      showInfo()
    ---say("Visualizing cell surroundings...")
    end
  end
)
