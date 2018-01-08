


-- Easier function to print stuff
function say(message)
  minetest.chat_send_all(message) end

-- Returns the number of elements in the table
function tablelength(Table)
  local count = 0
  for _ in pairs(Table) do count = count + 1 end
  return count
end

-- Display to mods current information
function showInfo()
  say("liveBlocks: " .. tostring(tablelength(liveBlocks)))
  say("adjBlocks: " .. tostring(tablelength(adjBlocks)))
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
