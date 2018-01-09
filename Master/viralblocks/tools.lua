

-- Easier function to print stuff
say = minetest.chat_send_all

-- Returns the number of elements in the table
function tableLength(Table)
  local count = 0
  for _ in pairs(Table) do count = count + 1 end
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
      minetest.set_node(adjPos, {name= "default:glass"})
    end
  end
end
