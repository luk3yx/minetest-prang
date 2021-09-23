--
-- fs51 - Compatibility layer for Minetest formspecs
--
-- Copyright © 2021 by luk3yx.
--

local fixers = ...
local get_player_information, type = minetest.get_player_information, type
local function remove_hypertext(text)
    -- If the text doesn't contain backslashes use gsub for performance
    if not text:find('\\', 1, true) then
        return text:gsub('<[^>]+>', '')
    end

    -- Otherwise iterate over it
    local res = ''
    local escaping, ignoring
    for i = 1, #text do
        local char = text:sub(i, i)
        if ignoring then
            ignoring = char ~= '>'
        elseif escaping then
            res = res .. char
            escaping = false
        elseif char == '<' then
            ignoring = true
        elseif char == '\\' then
            escaping = true
        else
            res = res .. char
        end
    end
    return res
end

local function backport_for(name, formspec)
    local info = get_player_information(name)
    local formspec_version = info and info.formspec_version or 1
    if formspec_version >= 3 then return formspec end

    local tree, err = formspec_ast.parse(formspec)
    if not tree then
        minetest.log('warning', '[fs51] Error parsing formspec (in ' ..
            'monkey_patching.lua): ' .. tostring(err))
        return formspec
    end

    -- Add some placeholders
    local modified
    for node in formspec_ast.walk(tree) do
        local node_type = node.type
        if formspec_version == 1 and node_type == 'background9' then
            -- No need to set modified here
            node.type = 'background'
            node.middle_x, node.middle_y = nil, nil
            node.middle_x2, node.middle_y2 = nil, nil
        elseif node_type == 'animated_image' then
            modified = true
            node.type = 'image'
            local frame_start = node.frame_start or 1
            node.texture_name = ('(%s)^[verticalframe:%d:%d'):format(
                node.texture_name, node.frame_count, frame_start - 1)
        elseif node_type == 'model' and node.textures[1] then
            modified = true
            node.type = 'image'
            node.texture_name = node.textures[1]
        elseif node_type == 'hypertext' then
            -- Convert hypertext elements to regular textareas
            modified = true
            node.type = 'textarea'
            node.name = ''
            node.label = ''
            node.default = remove_hypertext(node.text)
            node.text = nil
        elseif node_type == 'scroll_container' then
            modified = true
            node.type = 'container'
            -- Scroll containers are always going to be broken on older clients
            for i = #node, 1, -1 do
                local inner_node = node[i]
                if inner_node.x and inner_node.y and
                        (inner_node.x >= node.w or inner_node.y >= node.h) then
                    table.remove(node, i)
                end
            end
        elseif formspec_version == 1 and node_type == 'tabheader' then
            node.w, node.h = nil, nil
        elseif formspec_version == 2 and node_type == 'bgcolor' then
            modified = true
            fixers.bgcolor(node)
        end
    end

    if formspec_version == 1 then
        modified = true
        tree = fs51.backport(tree)
    end

    if modified then
        return assert(formspec_ast.unparse(tree))
    end
    return formspec
end

-- Patch minetest.show_formspec()
local show_formspec = minetest.show_formspec
function minetest.show_formspec(pname, formname, formspec)
    return show_formspec(pname, formname, backport_for(pname, formspec))
end

-- Patch player:set_inventory_formspec()
local old_set_inventory_formspec
local function new_set_inventory_formspec(self, formspec, ...)
    return old_set_inventory_formspec(self,
        backport_for(self:get_player_name(), formspec), ...)
end

minetest.register_on_joinplayer(function(player)
    if old_set_inventory_formspec == nil then
        assert(type(player) == 'userdata', 'Fake player object?')
        local cls = getmetatable(player)
        old_set_inventory_formspec = cls.set_inventory_formspec
        cls.set_inventory_formspec = new_set_inventory_formspec

        -- In case the inventory formspec has been set in the meantime
        player:set_inventory_formspec(player:get_inventory_formspec())
    end
end)

if minetest.settings:get_bool('fs51.disable_meta_override') then
    return
end

-- Patch minetest.get_meta()
-- Inspired by https://gitlab.com/sztest/nodecore/-/blob/master/mods/nc_api
local old_nodemeta_set_string
local function new_nodemeta_set_string(self, k, v)
    if k == 'formspec' and type(v) == 'string' then
        v = fs51.backport_string(v) or v
    end
    return old_nodemeta_set_string(self, k, v)
end

local get_meta = minetest.get_meta
function minetest.get_meta(...)
    local meta = get_meta(...)
    if old_nodemeta_set_string == nil and type(meta) == 'userdata' then
        minetest.get_meta = get_meta
        local cls = getmetatable(meta)
        old_nodemeta_set_string = cls.set_string
        cls.set_string = new_nodemeta_set_string
    end
    return meta
end
