script.on_init(function()
    global = global or {}  -- usually unnecessary, but ultra safe for updated versions
    global.pinned_recipes = global.pinned_recipes or {}
end)
local function ensure_global()
    global = global or {}
    global.pinned_recipes = global.pinned_recipes or {}
end

local function add_ingredient_row(parent, sprite, name, amount)
    local flow = parent.add{type = "flow", direction = "horizontal"}
    flow.add{type = "sprite", sprite = sprite}
    flow.add{type = "label", caption = string.format("%s x%s", name, amount)}
end
local function get_product_sprite(recipe)
    local first_product = recipe.products and recipe.products[1]
    if first_product then
        local proto_type = first_product.type or "item"
        return proto_type .. "/" .. first_product.name
    end
    return "utility/questionmark"
end

local function ensure_escape_guard(player)
    local gui = player.gui.screen
    if gui.recipe_escape_guard then return end

    local guard = gui.add{
        type = "frame",
        name = "recipe_escape_guard",
        visible = false  -- hidden!
    }
    player.opened = guard
end
local function remove_escape_guard(player)
    local gui = player.gui.screen
    if gui.recipe_escape_guard then
        gui.recipe_escape_guard.destroy()
        player.opened = nil
    end
end



local function clear_and_display_recipe(frame, recipe)

    local content = frame.recipe_content
    content.clear()
    if not recipe then
        content.add{type = "label", caption = "No recipe found."}
        return
    end

    content.add{type = "label", caption = "Inputs:"}
    for _, ing in ipairs(recipe.ingredients) do
        local sprite = ing.type == "fluid" and ("fluid/" .. ing.name) or ("item/" .. ing.name)
        add_ingredient_row(content, sprite, ing.name, ing.amount)
    end

    content.add{type = "label", caption = "Outputs:"}
    for _, out in ipairs(recipe.products) do
        local sprite = out.type == "fluid" and ("fluid/" .. out.name) or ("item/" .. out.name)
        add_ingredient_row(content, sprite, out.name, out.amount)
    end

    content.add{type = "label", caption = "Craft time: " .. recipe.energy .. "s"}
end
local function create_recipe_ui(player, recipe, reuse_frame_name)
    local gui = player.gui.screen
    local unique_name = "recipe_pin_" .. recipe.name .. "_" .. game.tick


    if not reuse_frame_name then
        ensure_global()
        global.pinned_recipes = global.pinned_recipes or {}
        for _, entry in ipairs(global.pinned_recipes) do
            if entry.player_index == player.index and entry.frame_name == unique_name then
                return
            end
        end

        table.insert(global.pinned_recipes, {
            player_index = player.index,
            recipe_name = recipe.name,
            frame_name = unique_name,
            location = nil,  -- let it be set via on_gui_location_changed
            collapsed = false
        })
    end
    local frame = gui.add{
        type = "frame",
        name = unique_name,
        caption = "📌 Pinned Recipe",
        direction = "vertical"
    }
    frame.style.padding = 8

    -- drag handle
    local drag_handle = frame.add{
        type = "flow",
        direction = "horizontal"
    }
    drag_handle.drag_target = frame



    drag_handle.add{
        type = "empty-widget",
        style = "draggable_space_header",
        style_mods = {horizontally_stretchable = true, height = 24}
    }
    drag_handle.add{
        type = "sprite-button",
        name = "recipe_pin_close_button",
        sprite = "utility/close_black",
        style = "frame_action_button",
        tooltip = {"gui.close-instruction"},
    }

    drag_handle.add{
        type = "button",
        name = "recipe_pin_toggle_button",
        caption = "▼",  -- or use "\"►\"" when collapsed
        style = "frame_action_button",
        tooltip = "Collapse/Expand"
    }

    -- 🟦 Add recipe icon (initially hidden since it's expanded at creation)
    drag_handle.add{
        type = "sprite",
        name = "recipe_pin_icon_sprite",
        sprite = get_product_sprite(recipe),
        tooltip = recipe.localised_name or recipe.name,
        visible = false
    }

    -- content holder
    frame.add{type = "flow", name = "recipe_content", direction = "vertical"}



    clear_and_display_recipe(frame, recipe)
end

local function populate_recipe_grid(player, grid, filter)
    grid.clear()
    for name, recipe in pairs(player.force.recipes) do
        local localized_name = recipe.localised_name or name
        if not filter or string.find(name:lower(), filter:lower(), 1, true) or
                (type(localized_name) == "string" and string.find(localized_name:lower(), filter:lower(), 1, true)) then
            local sprite = get_product_sprite(recipe)
            grid.add{
                type = "sprite-button",
                sprite = sprite,
                tooltip = localized_name,
                style = "slot_button",
                tags = { recipe = name }
            }
        end
    end
end


local function show_recipe_preview(player, recipe)
    local gui = player.gui.screen
    if gui.recipe_preview then gui.recipe_preview.destroy() end

    local frame = gui.add{
        type = "frame",
        name = "recipe_preview",
        caption = "Recipe: " .. recipe.name,
        direction = "vertical"
    }
    frame.auto_center = true
    frame.style.padding = 8

    -- Header bar
    local drag_handle = frame.add{
        type = "flow",
        direction = "horizontal"
    }
    drag_handle.drag_target = frame

    drag_handle.add{
        type = "empty-widget",
        style = "draggable_space_header",
        style_mods = { horizontally_stretchable = true, height = 24 }
    }

    drag_handle.add{
        type = "sprite-button",
        name = "recipe_preview_close_button",
        sprite = "utility/close_black",
        style = "frame_action_button"
    }

    local content = frame.add{type = "flow", direction = "vertical"}

    content.add{type = "label", caption = "Inputs:"}
    for _, ing in ipairs(recipe.ingredients) do
        local sprite = ing.type == "fluid" and ("fluid/" .. ing.name) or ("item/" .. ing.name)
        add_ingredient_row(content, sprite, ing.name, ing.amount)
    end

    content.add{type = "label", caption = "Outputs:"}
    for _, out in ipairs(recipe.products) do
        local sprite = out.type == "fluid" and ("fluid/" .. out.name) or ("item/" .. out.name)
        add_ingredient_row(content, sprite, out.name, out.amount)
    end

    content.add{type = "label", caption = "Craft time: " .. recipe.energy .. "s"}

    frame.add{
        type = "button",
        name = "recipe_preview_pin_button",
        caption = "📌 Pin this recipe",
        tags = { recipe = recipe.name }
    }
    ensure_escape_guard(player)
end


local function open_recipe_picker(player)
    local gui = player.gui.screen
    if gui.recipe_picker then return end

    local frame = gui.add{
        type = "frame",
        name = "recipe_picker",
        caption = "Select a Recipe",
        direction = "vertical"
    }
    frame.auto_center = true
    frame.style.padding = 8
    frame.style.maximal_height = 450

    -- search bar
    local search_flow = frame.add{
        type = "flow",
        direction = "horizontal"
    }
    search_flow.add{
        type = "label",
        caption = "Search:"
    }
    search_flow.add{
        type = "textfield",
        name = "recipe_picker_search_field"
    }

    local drag_handle = frame.add{
        type = "flow",
        direction = "horizontal"
    }
    drag_handle.drag_target = frame

    drag_handle.add{
        type = "empty-widget",
        style = "draggable_space_header",
        style_mods = {horizontally_stretchable = true, height = 24}
    }

    drag_handle.add{
        type = "sprite-button",
        name = "recipe_picker_close_button",
        sprite = "utility/close_black",
        style = "frame_action_button"
    }

    -- 🟩 Scrollable content holder
    local scroll = frame.add{
        type = "scroll-pane",
        name = "recipe_scroll",
        direction = "vertical"
    }
    scroll.style.vertically_stretchable = false
    scroll.style.maximal_height = 350 -- 👈 auto-scroll activates when exceeded
    scroll.style.minimal_height = 100
    scroll.style.padding = 4

    -- 🟥 Grid inside scroll-pane
    local grid = scroll.add{
        type = "table",
        column_count = 10,
        name = "recipe_grid"
    }
    populate_recipe_grid(player, grid, nil)

    ensure_escape_guard(player)
end

script.on_event("open-recipe-picker-hotkey", function(event)
    local player = game.get_player(event.player_index)
    if player then open_recipe_picker(player) end
end)
script.on_event(defines.events.on_gui_click, function(event)
    ensure_global()
    local element = event.element
    if not (element and element.valid) then return end

    local player = game.get_player(event.player_index)
    if not player then return end

    global.pinned_recipes = global.pinned_recipes or {}

    if element.name == "recipe_picker_close_button" then

        element.parent.parent.destroy()
        return
    end

    if element.name == "recipe_preview_pin_button" then
        local recipe = player.force.recipes[element.tags.recipe]
        if recipe then
            create_recipe_ui(player, recipe)
        end
        return
    end


    if element.name == "recipe_pin_close_button" then
        local frame = element.parent.parent
        local name = frame.name
        frame.destroy()

        -- 🗑 Remove from global.pinned_recipes
        if global.pinned_recipes then
            for i, entry in ipairs(global.pinned_recipes) do
                if entry.player_index == player.index and name:find(entry.recipe_name) then
                    table.remove(global.pinned_recipes, i)
                    break
                end
            end
        end
        return
    end
    if element.name == "recipe_pin_toggle_button" then
        local frame = element.parent.parent
        local content = frame.recipe_content
        if content then
            content.visible = not content.visible

            element.caption = content.visible and "▼" or "►"

            -- Toggle the icon visibility
            local drag_handle = element.parent  -- since the toggle button is inside the drag handle
            local icon_sprite = drag_handle.recipe_pin_icon_sprite
            if icon_sprite then
                icon_sprite.visible = not content.visible
            end

            -- update collapsed state in globale.pinned_recipes
            if global.pinned_recipes then
                for _, entry in ipairs(global.pinned_recipes) do
                    if entry.player_index == player.index and frame.name:find(entry.recipe_name) then
                        entry.collapsed = not content.visible
                        break
                    end
                end
            end
        end
        return
    end

    if element.name == "recipe_preview_close_button" then
        element.parent.parent.destroy()
        return
    end

    if element.tags and element.tags.recipe then
        local recipe = player.force.recipes[element.tags.recipe]
        if recipe then
            show_recipe_preview(player, recipe)
        end
        return
    end
end)
script.on_event(defines.events.on_gui_text_changed, function(event)
    local element = event.element
    if not (element and element.valid and element.name == "recipe_picker_search_field") then return end

    local player = game.get_player(event.player_index)
    if not player then return end

    local frame = element.parent.parent
    local grid = frame.recipe_scroll.recipe_grid
    if not grid then return end

    local search_text = element.text
    populate_recipe_grid(player, grid, search_text)
end)
function get_pinned_entry(player_index, frame_name)
    ensure_global()
    if not global or not global.pinned_recipes then return nil end
    if not global.pinned_recipes then return nil end
    for _, entry in ipairs(global.pinned_recipes) do
        if entry.player_index == player_index and entry.frame_name == frame_name then
            return entry
        end
    end
end
script.on_event(defines.events.on_gui_location_changed, function(event)
    ensure_global()
    local element = event.element
    if not (element and element.valid and element.name:find("recipe_pin_")) then return end

    local player_index = event.player_index
    local entry = get_pinned_entry(player_index, element.name)
    if entry then
        entry.location = element.location
    end
end)
script.on_event(defines.events.on_player_joined_game, function(event)

    ensure_global()
    local player = game.get_player(event.player_index)
    if not player then return end

    if global.pinned_recipes then
        for _, entry in ipairs(global.pinned_recipes) do
            if entry.player_index == player.index then
                local recipe = player.force.recipes[entry.recipe_name]
                if recipe then
                    create_recipe_ui(player, recipe, entry.frame_name)
                    local frame = player.gui.screen[entry.frame_name]
                    if frame and entry.location then
                        frame.location = entry.location
                    end
                    if frame and entry.collapsed then
                        frame.recipe_content.visible = false
                        frame.recipe_pin_toggle_button.caption = "►"
                        frame.recipe_pin_icon_sprite.visible = true
                    end
                end
            end
        end
    end
end)

script.on_event("close-recipe-windows", function(event)
    local player = game.get_player(event.player_index)
    if not player then return end

    local gui = player.gui.screen

    local closed_any = false

    if gui.recipe_preview then
        gui.recipe_preview.destroy()
        closed_any = true
    end
    if gui.recipe_picker then
        gui.recipe_picker.destroy()
        closed_any = true
    end

    -- Remove the guard only if both are now closed
    if not gui.recipe_preview and not gui.recipe_picker then
        remove_escape_guard(player)
    end
end)
script.on_configuration_changed(function()
    global.pinned_recipes = global.pinned_recipes or {}
end)
script.on_load(function()
    ensure_global()
end)
