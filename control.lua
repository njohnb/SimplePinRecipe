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
    frame.style.size = {250, 200}
    frame.style.padding = 12

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
        type = "empty-widget",  -- Filler to push the button to the right
        style = "draggable_space_header",
        style_mods = { horizontally_stretchable = true }
    }

    drag_handle.add{
        type = "sprite-button",
        name = "recipe_pin_close_button",
        sprite = "utility/close_black",
        style = "frame_action_button",
        hovered_sprite = "utility/close_black",
        clicked_sprite = "utility/close_black",
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
        content.add{type = "label", caption = string.format("- %s x%d", ing.name, ing.amount)}
    end

    content.add{type = "label", caption = "Outputs:"}
    for _, out in ipairs(recipe.products) do
        content.add{type = "label", caption = string.format("- %s x%.2f", out.name, out.amount)}
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
    frame.style.size = {300, 250}
    frame.style.padding = 12

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
        content.add{type = "label", caption = string.format("- %s x%d", ing.name, ing.amount)}
    end

    content.add{type = "label", caption = "Outputs:"}
    for _, out in ipairs(recipe.products) do
        content.add{type = "label", caption = string.format("- %s x%.2f", out.name, out.amount)}
    end

    content.add{type = "label", caption = "Craft time: " .. recipe.energy .. "s"}

    frame.add{
        type = "button",
        name = "recipe_preview_pin_button",
        caption = "📌 Pin this recipe",
        tags = { recipe = recipe.name }
    }
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
    frame.style.size = {300, 400}

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

    local scroll = frame.add{
        type = "scroll-pane",
        direction = "vertical"
    }
    scroll.style.vertically_stretchable = true
    scroll.style.maximal_height = 350

    for name, recipe in pairs(player.force.recipes) do
        scroll.add{
            type = "button",
            caption = recipe.localised_name or name,
            tags = { recipe = name },
            style = "button"
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
