-- Easier function to print stuff
say = minetest.chat_send_all

function log(tag, msg)
  if DEBUG_TAGS[tag] then
    say(msg)
  end
end

-- Returns the number of elements in the table
function tableLength(Table)
  local count = 0
  for _ in pairs(Table) do
    count = count + 1
  end
  return count
end

-- Display to mods current information
function showInfo()
  say("lifeBlocks: " .. tostring(tableLength(lifeBlocks)))
  say("airNeighborsList: " .. tostring(tableLength(airNeighborsList)))
end


-- Turns all adjectent blocks to glass
function glassify()
  for k, adjPos in pairs(airNeighborsList) do
    local node = minetest.get_node(adjPos)
    if node.name ~= lifeBlock then
      minetest.set_node(adjPos, {name = "default:glass"})
    end
  end
end

-- If true return "true" else "false"
function isitTrue(isTrue)
  if isTrue then
    return "true"
  end
  return "false"
end

-- Shows glass for all the selected Blocks
function debugView(visDebug, showingLife)
  -- for either to work we must list these lists
  if visDebug or showingLife then
    findAirNeighbors()
    findBlocksToBeBorn()
    findBlocksToDie()
  end

  if visDebug then
    -- Show obsidian_glass above lifeBlocks
    for k, adjPos in pairs(lifeBlocks) do
      local node = minetest.get_node(adjPos)
      local posOffset = {x = adjPos.x, y = adjPos.y + 1, z = adjPos.z}
      minetest.set_node(posOffset, {name = "default:obsidian_glass"})
    end
    -- Show glass above airNeighborsList
    for k, adjPos in pairs(airNeighborsList) do
      local node = minetest.get_node(adjPos)
      local posOffset = {x = adjPos.x, y = adjPos.y + 1, z = adjPos.z}
      minetest.set_node(posOffset, {name = "default:glass"})
    end
  end

  -- if we want to see all the next step
  if showingLife then
    -- Show aspen_leaves above blocksToBeBorn
    for k, adjPos in pairs(blocksToBeBorn) do
      local node = minetest.get_node(adjPos)
      local posOffset = {x = adjPos.x, y = adjPos.y + 2, z = adjPos.z}
      minetest.set_node(posOffset, {name = "default:aspen_leaves"})
    end
    -- Show grass above blocksToDie
    for k, adjPos in pairs(blocksToDie) do
      local node = minetest.get_node(adjPos)
      local posOffset = {x = adjPos.x, y = adjPos.y + 2, z = adjPos.z}
      minetest.set_node(posOffset, {name = "default:jungleleaves"})
    end
  end

end
