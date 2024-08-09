/**
 * Initializes the user inventory data for a player when joining.
 *
 * @param client Client index to initialize the inventory for.
 *
 * @return void
 */
stock void TF2ItemPlugin_InitializeInventory(int client)
{
	// Go through each class and slot to initialize their inventory to default values.
	for (int i = 0; i < MAXPLAYERS + 1; i++)
	{
		for (int j = 0; j < MAX_CLASSES; j++)
		{
			for (int x = 0; x < MAX_WEAPONS; x++)
			{
				// Set the client, class, and slot ID for this inventory slot beforehand.
				g_inventories[i][j][x].client = client;
				g_inventories[i][j][x].class  = j;
				g_inventories[i][j][x].slotId = x;

				// Reset the inventory slot fully.
				g_inventories[i][j][x].Reset(true);
			}
		}
	}
}

/**
 * Builds and displays the menu used to select a weapon slot to modify.
 *
 * @param client Client index to build the menu for.
 */
void TF2ItemPlugin_Menus_MainMenu(int client)
{
	// Construct a new menu instance.
	Menu main = new Menu(MainMenuHandler);

	// Set the menu title.
	char className[64];
	TF2ItemPlugin_GetTFClassName(TF2_GetPlayerClass(client), className, sizeof(className));

	main.SetTitle("Weapons Manager - %s", className);

	// Loop through each weapon slot.
	for (int i = 0; i <= MAX_WEAPONS; i++)
	{
		// Obtain the weapon at said slot.
		int weapon = GetPlayerWeaponSlot(client, i);

		// If the weapon is not valid, skip this slot but do add an empty item (to maintain the slot order).
		if (weapon == -1)
		{
			main.AddItem("", "", ITEMDRAW_IGNORE);
			continue;
		}

		// Obtain the weapon's definition index.
		int	 itemDefinitionIndex = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");

		// Obtain the name for this weapon through TFEconData.
		char name[64], weaponEntityStr[12];
		TF2Econ_GetItemName(itemDefinitionIndex, name, sizeof(name));
		Format(weaponEntityStr, sizeof(weaponEntityStr), "%d", weapon);

		// Add the weapon to the menu.
		char itemDefinitionIndexString[12];
		Format(itemDefinitionIndexString, sizeof(itemDefinitionIndexString), "%d", itemDefinitionIndex);

		main.AddItem(weaponEntityStr, name);
	}

	// Add information options first.
	main.AddItem(".", "Remember that your overrides affect your currently equipped weapon.", ITEMDRAW_DISABLED);
	main.AddItem(".", "Select a weapon of your choice to begin.", ITEMDRAW_DISABLED);

	// Add options to reset all configurations.
	main.AddItem("load", "Load my preferences");
	main.AddItem("save", "Save my preferences");
	main.AddItem("reset", "Reset all my preferences");
	main.AddItem("delete", "Delete my saved preferences");

	// Configure the menu's options.
	main.ExitButton = true;

	// Display the menu.
	main.Display(client, MENU_TIME_FOREVER);
}

/**
 * Callback handler for the main menu selections.
 */
public int MainMenuHandler(Menu menu, MenuAction action, int client, int param)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			// Obtain the weapon entity ID and its name.
			char weaponEntityStr[12], weaponName[64];
			menu.GetItem(param, weaponEntityStr, sizeof(weaponEntityStr), _, weaponName, sizeof(weaponName));

			// If this is a special option, handle that first.
			if (StrEqual(weaponEntityStr, "reset"))
			{
				// Reset all inventory configurations for the player.
				TF2ItemPlugin_InitializeInventory(client);

				// Print a message to their chat to inform them of the reset.
				CPrintToChat(client, "%s Your weapon preferences have been reset to default values.", PLUGIN_CHATTAG);

				return 0;
			}

			// Convert the string to an integer.
			int weaponEntity = StringToInt(weaponEntityStr);

			// Build and open the weapon menu.
			TF2ItemPlugin_Menus_WeaponMenu(client, param, weaponName, weaponEntity);
		}
	}

	return 0;
}

/**
 * Builds and displays a menu where a weapon can be configured.
 *
 * @param client Client index to build the menu for.
 * @param slot Slot ID to configure.
 * @param name The name of the selected weapon.
 * @param weapon Weapon entity index referenced for configuration.
 *
 * @return void
 */
void TF2ItemPlugin_Menus_WeaponMenu(int client, int slot, char[] name, int weapon)
{
	// Construct a new menu instance.
	Menu weaponMenu = new Menu(WeaponMenuHandler);

	// Obtain the player's class configuration from their inventory.
	int class		= TF2_GetPlayerClassInt(client);

	// Access the inventory configuration.
	TFInventory_Weapons_Slot inventory;
	inventory = g_inventories[client][class][slot];

	// Set the menu title.
	char className[64];
	TF2ItemPlugin_GetTFClassName(view_as<TFClassType>(class), className, sizeof(className));

	weaponMenu.SetTitle("Modifying %s for %s", name, className);

	// Hidden properties that transfer data to the menu handler.
	char weaponStr[12], slotStr[2];
	Format(weaponStr, sizeof(weaponStr), "%d", weapon);
	Format(slotStr, sizeof(slotStr), "%d", slot);

	weaponMenu.AddItem(name, "weaponName", ITEMDRAW_IGNORE);
	weaponMenu.AddItem(weaponStr, "weaponEntityId", ITEMDRAW_IGNORE);
	weaponMenu.AddItem(slotStr, "weaponSlotId", ITEMDRAW_IGNORE);

	// Add the toggleable override option.
	weaponMenu.AddItem("override", inventory.isActiveOverride ? "[X] Active changes" : "[ ] Active changes");

	// Add an information item.
	weaponMenu.AddItem("", "Remember to activate the override to apply changes.", ITEMDRAW_DISABLED);
	weaponMenu.AddItem("", "Below is the current set configuration for your slot:", ITEMDRAW_DISABLED);

	char infoWeapon[64], infoSlot[32];
	if (inventory.weaponDefIndex != -1) TF2Econ_GetItemName(inventory.weaponDefIndex, infoWeapon, sizeof(infoWeapon));
	else strcopy(infoWeapon, sizeof(infoWeapon), "No weapon set");

	TF2ItemPlugin_GetWeaponSlotName(slot, infoSlot, sizeof(infoSlot));

	Format(infoWeapon, sizeof(infoWeapon), "Actively set for weapon: %s", infoWeapon);
	Format(infoSlot, sizeof(infoSlot), "Affects slot: %s", infoSlot);

	weaponMenu.AddItem("", infoWeapon, ITEMDRAW_DISABLED);
	weaponMenu.AddItem("", infoSlot, ITEMDRAW_DISABLED);

	// Add the Australium option.
	int canAustralium = TF2ItemPlugin_CanItemAustralium(inventory.weaponDefIndex);
	weaponMenu.AddItem("australium", (canAustralium != TF2Weapon_NoAustralium ? (inventory.isAustralium ? "[X] Australium" : "[ ] Australium") : "Weapon cannot be australium"), canAustralium != TF2Weapon_NoAustralium ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

	// Add the Festive option.
	bool canFestivizer = TF2ItemPlugin_CanItemFestivize(inventory.weaponDefIndex);
	weaponMenu.AddItem("festive", (canFestivizer ? (inventory.isFestive ? "[X] Festive" : "[ ] Festive") : "Weapon cannot be festivized"), canFestivizer ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

	// Add the War Paint ID option.
	char warPaint[64];
	Format(warPaint, sizeof(warPaint), "War Paint ID: %d", inventory.warPaintId);

	weaponMenu.AddItem("warPaintId", warPaint, ITEMDRAW_DISABLED);

	// Add the War Paint Wear option.
	char warPaintWear[32];
	TF2ItemPlugin_GetWarPaintWearString(inventory.warPaintWear, warPaintWear, sizeof(warPaintWear));
	Format(warPaintWear, sizeof(warPaintWear), "War Paint Wear: %s", warPaintWear);

	weaponMenu.AddItem("warPaintWear", warPaintWear, ITEMDRAW_DISABLED);

	// Add the Unusual Effect ID option.
	char unusualEffect[64];
	Format(unusualEffect, sizeof(unusualEffect), "Unusual Effect ID: %d", inventory.unusualEffectId);

	weaponMenu.AddItem("unusualEffectId", unusualEffect, ITEMDRAW_DISABLED);

	// Add the Killstreak option.
	weaponMenu.AddItem("killstreak", "Killstreak Configuration", ITEMDRAW_DISABLED);

	// Add the spells option.
	weaponMenu.AddItem("spells", "Halloween Spell Configuration", ITEMDRAW_DISABLED);

	// Configure the menu's options.
	weaponMenu.ExitButton = true;

	// Display the menu.
	weaponMenu.Display(client, MENU_TIME_FOREVER);
}

/**
 * Callback handler for the weapon menu selections.
 */
public int WeaponMenuHandler(Menu menu, MenuAction action, int client, int param)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			// Obtain the selected option and hidden information.
			char option[64], weaponName[64], weaponStr[12], slotStr[2];
			menu.GetItem(param, option, sizeof(option));
			menu.GetItem(0, weaponName, sizeof(weaponName));
			menu.GetItem(1, weaponStr, sizeof(weaponStr));
			menu.GetItem(2, slotStr, sizeof(slotStr));

			// Convert the weapon string to an integer.
			int weapon = StringToInt(weaponStr), slot = StringToInt(slotStr);

			// If client had changed classes or the weapon entity is no longer valid, return and do nothing.
			if (!IsValidEdict(weapon) || !IsValidEdict(client)) return 0;

			// If the weapon edict is not a weapon, return and do nothing.
			char edictClassName[64];
			GetEdictClassname(weapon, edictClassName, sizeof(edictClassName));

			if (StrContains(edictClassName, "tf_weapon_", false) == -1 && !StrEqual(edictClassName, "saxxy")) return 0;

			// Handle the selected option.
			if (StrEqual(option, "override"))
			{
				// Activate the override for the slot and class.
				int class = TF2_GetPlayerClassInt(client), itemDefinitionIndex = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"),
					quality = GetEntProp(weapon, Prop_Send, "m_iEntityQuality"), level = GetEntProp(weapon, Prop_Send, "m_iEntityLevel");

				// Convert the weapon definition index to a variant if it is a stock weapon.
				int strangeVariantIndex = TF2ItemPlugin_GetStrangeVariant(itemDefinitionIndex);

				// If a stock weapon was converted, set it on the loadout information.
				if (strangeVariantIndex != itemDefinitionIndex && strangeVariantIndex != -1) g_inventories[client][class][slot].stockWeaponDefIndex = itemDefinitionIndex;

				// Toggle the slot override status.
				TF2ItemPlugin_ToggleSlotOverride(client, class, slot, strangeVariantIndex == -1 ? itemDefinitionIndex : strangeVariantIndex, quality, level);
			}

			if (StrEqual(option, "australium"))
				// Toggle the Australium status.
				TF2ItemPlugin_ToggleAustralium(client, slot);

			if (StrEqual(option, "festive"))
				// Toggle the Festive status.
				TF2ItemPlugin_ToggleFestive(client, slot);

			// Rebuild the weapons menu after some miliseconds to allow for the changes to take effect (probably a strange variant being given).
			DataPack data = new DataPack();
			data.WriteCell(client);
			data.WriteCell(slot);
			data.WriteString(weaponName);

			CreateTimer(0.25, TF2ItemPlugin_HandleWeaponMenuRebuild, data, TIMER_FLAG_NO_MAPCHANGE);
		}
	}

	return 0;
}

public Action TF2ItemPlugin_HandleWeaponMenuRebuild(Handle timer, DataPack data)
{
	// Reset the DataPack to its initial index.
	data.Reset();

	// Obtain the client and slot from the data pack.
	int	 client = data.ReadCell(), slot = data.ReadCell();

	char weaponName[64];
	data.ReadString(weaponName, sizeof(weaponName));

	// If the client is dead, return and do nothing.
	if (!IsPlayerAlive(client)) return Plugin_Stop;

	// Obtain the client's weapon at that slot.
	int weapon = GetPlayerWeaponSlot(client, slot);

	// If the entity is not valid, return and do nothing.
	if (!IsValidEdict(weapon)) return Plugin_Stop;

	// Rebuild the weapon menu.
	TF2ItemPlugin_Menus_WeaponMenu(client, slot, weaponName, weapon);

	// Free up the data pack.
	delete data;

	return Plugin_Stop;
}