
local spherebox = {
	type ="fixed",
	fixed = { { -0.5, -0.5, -0.5, 0.5, -0.5, 0.5 } },
}

minetest.register_node("sphere:earth", {
	description = "Maybe, just maybe! You'll find intelligent life here!",
	drawtype = "mesh",
	paramtype = "light",
	light_source = 12,
	paramtype2 = "facedir",
	mesh = "Earth.obj",
	tiles = { "Earth.png" },
	groups = {choppy=2, oddly_breakable_by_hand=2, flammable=3},
	sounds = default.node_sound_wood_defaults(),
	selection_box = spherebox,
	collision_box = spherebox,
	
})


minetest.register_craft({
    output = "sphere:earth",
    recipe = {
        { "","","" },
        { "","default:sapling","" },
        { "","","" },
    },
})


