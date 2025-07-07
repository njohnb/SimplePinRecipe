local function add_ingredient_row(parent, sprite, name, amount)
    local flow = parent.add{type = "flow", direction = "horizontal"}
    flow.add{type = "sprite", sprite = sprite}
    flow.add{type = "label", caption = string.format("%s x%s", name, amount)}
end
local function create_recipe_ui(player)
    local gui = player.gui.screen
    if gui.recipe_pin then return end

    local frame = gui.add{
        type = "frame",
        name = "recipe_pin",
        caption = "📌 Pinned Recipe",
        direction = "vertical"
    }
    frame.auto_center = true
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


    -- content holder
    frame.add{type = "flow", name = "recipe_content", direction = "vertical"}
    player.opened = frame
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
end
local function get_product_sprite(recipe)
    local first_product = recipe.products and recipe.products[1]
    if first_product then
        local proto_type = first_product.type or "item"
        return proto_type .. "/" .. first_product.name
    end
    return "utility/questionmark"
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


    for name, recipe in pairs(player.force.recipes) do
        local sprite = get_product_sprite(recipe)

        grid.add{
            type = "sprite-button",
            sprite = sprite,
            tooltip = recipe.localised_name or name,
            style = "slot_button",
            tags = { recipe = name }
        }
    end

end

script.on_event("open-recipe-picker-hotkey", function(event)
    local player = game.get_player(event.player_index)
    if player then open_recipe_picker(player) end
end)
script.on_event(defines.events.on_gui_click, function(event)
    local element = event.element
    if not (element and element.valid) then return end

    local player = game.get_player(event.player_index)
    if not player then return end

    if element.name == "recipe_picker_close_button" then
        element.parent.parent.destroy()
        return
    end

    if element.name == "recipe_preview_pin_button" then
        local recipe = player.force.recipes[element.tags.recipe]
        if recipe then
            create_recipe_ui(player)
            clear_and_display_recipe(player.gui.screen.recipe_pin, recipe)
        end
        return
    end


    if element.name == "recipe_pin_close_button" then
        element.parent.parent.destroy()
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
