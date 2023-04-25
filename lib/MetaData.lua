-- Generated 2023-03-18T17:26:59.9634180+01:00 by FactorioApi 22.1.0.0 
-- see https://github.com/hahoyer/factorio/tree/master/src/FApi
return 
{
    LuaBurnerPrototype = 
        {
            burnt_inventory_size = true,
            effectivity = true,
            fuel_categories = true,
            fuel_inventory_size = true,
            object_name = true
        },
        LuaElectricEnergySourcePrototype = 
        {
            buffer_capacity = true,
            drain = true,
            usage_priority = true,
            object_name = true
        },
        LuaEntityPrototype = 
        {
            type = true,
            name = true,
            is_building = true,
            items_to_place_this = true,
            autoplace_specification = true,
            fast_replaceable_group = true,
            mineable_properties = true,
            allowed_effects = true,
            ammo_category = true,
            attack_parameters = true,
            base_productivity = true,
            burner_prototype = true,
            burns_fluid = true,
            consumption = true,
            crafting_categories = true,
            crafting_speed = true,
            effectivity = true,
            electric_energy_source_prototype = true,
            energy_usage = true,
            active_energy_usage = true,
            idle_energy_usage = true,
            lamp_energy_usage = true,
            fixed_recipe = true,
            flags = true,
            fluid = true,
            fluid_capacity = true,
            fluid_energy_source_prototype = true,
            fluid_usage_per_tick = true,
            fluidbox_prototypes = true,
            heat_buffer_prototype = true,
            heat_energy_source_prototype = true,
            infinite_resource = true,
            ingredient_count = true,
            item_slot_count = true,
            lab_inputs = true,
            launch_wait_time = true,
            max_energy = true,
            max_energy_production = true,
            max_energy_usage = true,
            maximum_temperature = true,
            mining_speed = true,
            module_inventory_size = true,
            neighbour_bonus = true,
            next_upgrade = true,
            normal_resource_amount = true,
            pumping_speed = true,
            related_underground_belt = true,
            researching_speed = true,
            resource_categories = true,
            resource_category = true,
            result_units = true,
            rocket_entity_prototype = true,
            rocket_parts_required = true,
            rocket_rising_delay = true,
            scale_fluid_usage = true,
            selectable_in_game = true,
            speed = true,
            speed_multiplier_when_out_of_energy = true,
            stack = true,
            target_temperature = true,
            void_energy_source_prototype = true,
            localised_name = true,
            localised_description = true,
            group = true,
            subgroup = true,
            order = true,
            object_name = true
        },
        LuaFluidBoxPrototype = 
        {
            entity = true,
            filter = true,
            index = true,
            maximum_temperature = true,
            minimum_temperature = true,
            pipe_connections = true,
            production_type = true,
            volume = true,
            object_name = true
        },
        LuaFluidEnergySourcePrototype = 
        {
            burns_fluid = true,
            effectivity = true,
            fluid_box = true,
            fluid_usage_per_tick = true,
            maximum_temperature = true,
            scale_fluid_usage = true,
            object_name = true
        },
        LuaFluidPrototype = 
        {
            name = true,
            default_temperature = true,
            fuel_value = true,
            gas_temperature = true,
            heat_capacity = true,
            hidden = true,
            max_temperature = true,
            localised_name = true,
            localised_description = true,
            group = true,
            subgroup = true,
            order = true,
            object_name = true
        },
        LuaFuelCategoryPrototype = 
        {
            name = true,
            localised_name = true,
            localised_description = true,
            order = true,
            object_name = true
        },
        LuaHeatEnergySourcePrototype = 
        {
            default_temperature = true,
            heat_buffer_prototype = true,
            max_temperature = true,
            min_working_temperature = true,
            specific_heat = true,
            object_name = true
        },
        LuaItemPrototype = 
        {
            type = true,
            name = true,
            place_result = true,
            attack_parameters = true,
            burnt_result = true,
            category = true,
            default_request_amount = true,
            flags = true,
            fuel_category = true,
            fuel_value = true,
            infinite = true,
            inventory_size = true,
            inventory_size_bonus = true,
            module_effects = true,
            repair_result = true,
            rocket_launch_products = true,
            speed = true,
            stack_size = true,
            stackable = true,
            tier = true,
            localised_name = true,
            localised_description = true,
            group = true,
            subgroup = true,
            order = true,
            object_name = true
        },
        LuaModuleCategoryPrototype = 
        {
            name = true,
            localised_name = true,
            localised_description = true,
            order = true,
            object_name = true
        },
        LuaRecipeCategoryPrototype = 
        {
            name = true,
            localised_name = true,
            localised_description = true,
            order = true,
            object_name = true
        },
        LuaRecipePrototype = 
        {
            name = true,
            category = true,
            enabled = true,
            energy = true,
            hidden = true,
            hidden_from_player_crafting = true,
            ingredients = true,
            main_product = true,
            products = true,
            unlock_results = true,
            localised_name = true,
            localised_description = true,
            group = true,
            subgroup = true,
            order = true,
            object_name = true
        },
        LuaResourceCategoryPrototype = 
        {
            name = true,
            localised_name = true,
            localised_description = true,
            order = true,
            object_name = true
        },
        LuaTechnologyPrototype = 
        {
            name = true,
            effects = true,
            enabled = true,
            hidden = true,
            level = true,
            max_level = true,
            prerequisites = true,
            research_unit_count = true,
            research_unit_count_formula = true,
            research_unit_energy = true,
            research_unit_ingredients = true,
            upgrade = true,
            localised_name = true,
            localised_description = true,
            order = true,
            object_name = true
        }
}