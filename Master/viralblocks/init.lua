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

-- non-lua conventions used here: camelCase names

local tools = dofile(minetest.get_modpath("viralblocks") .. "/tools.lua")

-- say = say
-- tablelength = tools.tablelength
-- showInfo = tools.showInfo
-- glassify = tools.glassify



LIFEBLOCK = "viralblocks:lifeblock"
DELAY_SECONDS = 5


--------------------------------------------------------------------------------
-- Debug -----------------------------------------------------------------------
isPaused = false
visDebug = false
showingLife = false
makeChanges = true
STEP = true -- false for debugging
DEBUG_TAGS = {passes = true, no_action = true}

--------------------------------------------------------------------------------
-- Lists -----------------------------------------------------------------------

lifeBlocks = {}
airNeighborsList = {}
blocksToBeBorn = {}
blocksToDie = {}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- TODO make everything local, lol

-- THE MAIN LOOP, automatic
local timer = 0
local gen = 0
minetest.register_globalstep(
  function(dtime)
    if not isPaused then
      timer = timer + dtime
      if timer >= DELAY_SECONDS then -- Every n seconds do stuff

        if tableLength(lifeBlocks) ~= 0 then  -- TODO: make isTableEmpty() so we don't inefficiently count past one
          nextGeneration()
        end

        STEP = true -- false for debuging
        timer = 0
      end
    end
  end
)


function nextGeneration()
  -- efficiency note: nextGeneration() should only be called when there are lifeblocks (tableLength(lifeBlocks) ~= 0).

  --first do harmless counting, no changes to the world.
  --This comes first because we want the most up-to-date lists before making changes
  findAirNeighbors()
  numBlocksToBeBorn = findBlocksToBeBorn()
  numBlocksToDie = findBlocksToDie()
  log("passes", "Scanning gen ".. gen ..". Pop:" .. tableLength(lifeBlocks) .. ", Change: (+" .. numBlocksToBeBorn.. ", -" .. numBlocksToDie .. ")")

  -- then do changes to world, if enabled
  if numBlocksToBeBorn + numBlocksToDie > 0 and makeChanges then
      placeBlocksToBeBorn()
      -- removeBlocksToDie()
  else
    log("no-action", "Nothing to do!")
  end
  gen = gen + 1
end

-- manually increment the system, called by /life nextgen
function manualAdvance()
  if not isPaused then
    say("Warning: manually advancing while the board is not paused!")
  end
  say("Advancing one generation only:")
  nextGeneration()
end

function placeBlocksToBeBorn()
  for k, pos in pairs(blocksToBeBorn) do
    -- Here, We need to place all of the blocks that we have queued
    minetest.set_node(pos, {name = LIFEBLOCK})
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
  local found = 0
  for k, pos in pairs(airNeighborsList) do
    if countLifeNeighbors(pos) == 3 then
      -- Add blocks with exactly three live neighbors to blocksToBeBorn
      table.insert(blocksToBeBorn, pos)
      found = found + 1
    end
  end
  return found
end

-- TODO merge findBlocksToDie() with findAirNeighbors for efficiency, same loop: pairs(lifeBlocks)

-- Set LifeBlocks for Removal
function findBlocksToDie()
  local found = 0
  for k, pos in pairs(lifeBlocks) do
    -- Checks for two or three live neighbors - if not, mark for removal
    count = countLifeNeighbors(pos)
    if count < 2 or count > 3 then
      table.insert(blocksToDie, pos)
      found = found + 1
    end
  end
  return found
end

-- Adds any Neighboring air nodes to the lifeBlocks
function findAirNeighbors()
  airNeighborsList = {}
  for k, pos in pairs(lifeBlocks) do
    for z_offset = -1, 1 do --Loop through Z
      for x_offset = -1, 1 do --Loop through X
        local posOffset = {x = pos.x + x_offset, y = pos.y, z = pos.z + z_offset}
        local node = minetest.get_node(posOffset)
        -- in this loop is all neighbors
        if not (node.name == LIFEBLOCK) then -- air only (for now)
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
  LIFEBLOCK,
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
    if newnode.name == LIFEBLOCK then
      table.insert(lifeBlocks, pos)
      local meta = minetest.get_meta(pos)
      meta:set_string("infotext", "LifeBlock placed by player")
    -- placer:get_player_name()
    end
  end
)

-- Onload, Find all lifeBlocks and add them
minetest.register_lbm(
  {
    label = "Count existing lifeblocks",
--  ^ Descriptive label for profiling purposes (optional).
    name = "viralblocks:countblocks", -- countblocks is a dummy (a: huh? this is our LBM's name)
    nodenames = {LIFEBLOCK},
    run_at_every_load = true,
--  ^ Whether to run the LBM's action every time a block gets loaded,
--    and not just for blocks that were saved last time before LBMs were
--    introduced to the world. (>Adroit says: huh?)
    action = function(pos, node)  -- runs once per preexisting lifeblock
      table.insert(lifeBlocks, pos)
      say("Adding preexisting lifeblock")
    end
  }
)

-- If destroyed remove pos from lifeBlocks
-- >adroit says: What if it's destroyed by a non-player?
minetest.register_on_dignode(
  function(pos, oldnode, digger)
    if oldnode.name == LIFEBLOCK then
      for k, v in pairs(lifeBlocks) do
        if v.x == pos.x and v.y == pos.y and v.z == pos.z then
          table.remove(lifeBlocks, k)
          findAirNeighbors()
        end
      end
    end
  end
)


-- Main command
minetest.register_chatcommand("life",
{
    params = "<step|pause|resume|show|debug>", -- Short parameter description
    description = "Debugging commands for ViralBlocks", -- Full description
    privs = {privs=true}, -- Require the "privs" privilege to run
    func = function(name, param)  -- Called when command is run.
             commandResponse(name, param)
           end                    -- Returns boolean success and text output.
})


-- Respond to specific chats
function commandResponse(name, param)
    if param == "debug" then
      findAirNeighbors()
      findBlocksToBeBorn()
      findBlocksToDie()
      debugView(true, showingLife) -- you should "pauselife" to see this
      say("Visual Debug: " .. "Done")
    elseif param == "show" then
      showingLife = (not showingLife)
      say("Showing Life: " .. isitTrue(showingLife))
    elseif param == "step" then
      STEP = true
      debugView(true, showingLife)
      say("STEPPING : " .. "DONE")
    elseif param == "nextgen" then
      manualAdvance()
    elseif param == "pause" then
      isPaused = true
      say("CGOL board paused globally!")
    elseif param == "resume" then
      isPaused = false
      say("CGOL board resumed globally!")
    elseif param == "info" then
      showInfo()
    ---say("Visualizing cell surroundings...")
    end
    return true
end
