#include "tf2itemplugin/tf2itemplugin_base.sp"
#include "tf2itemplugin/tf2itemplugin_weapon_base.sp"
#include "tf2itemplugin/tf2itemplugin_weapon_sqlite.sp"
#include "tf2itemplugin/tf2itemplugin_weapon_data.sp"
#include "tf2itemplugin/tf2itemplugin_weapon_menus.sp"

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "4.0.0"
#define DEBUG		   true

public Plugin myinfo =
{
	name		= "TF2 Item Plugins - Weapons Manager",
	author		= "Lucas 'punteroo' Maza",
	description = "Customize your weapons and manage your server inventory.",
	version		= PLUGIN_VERSION,
	url			= "https://github.com/punteroo/TF2-Item-Plugins"
};

/**
 * Load the "Regenerate" SDK call to refresh player inventories.
 *
 * @return Handle to the "Regenerate" SDK call.
 */
public Handle TF2ItemPlugin_LoadRegenerateSDK()
{
	// Load TF2 gamedata.
	Handle hGameConf = LoadGameConfigFile("sm-tf2.games");

	// Prepare the SDK call for the player entity.
	StartPrepSDKCall(SDKCall_Player);

	// Set the SDK call to find the "Regenerate" signature.
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "Regenerate");
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);

	// End the SDK call preparation.
	return EndPrepSDKCall();
}

/**
 * Uses hooks to attach into the maps' `func_respawnroom` entities to determine if a player is within a spawn room.
 *
 * @return void
 */
public void TF2ItemPlugin_AttachSpawnRoomHooks()
{
	// Declare a starting index for the spawn room entities.
	int trigger = -1;

	while ((trigger = FindEntityByClassname(trigger, "func_respawnroom")) != -1)
	{
		// Hook callbacks into the trigger.
		SDKHook(trigger, SDKHook_StartTouch, OnStartTouchSpawnRoom);
		SDKHook(trigger, SDKHook_EndTouch, OnEndTouchSpawnRoom);
	}
}

public Action OnStartTouchSpawnRoom(int entity, int other)
{
	// If player is alive and real, mark them as in spawn room.
	if (IsClientInGame(other) && IsPlayerAlive(other) && !IsClientSourceTV(other) && !IsClientObserver(other) && other <= MaxClients)
		g_bInSpawnRoom[GetClientOfUserId(other)] = true;

	return Plugin_Continue;
}

public Action OnEndTouchSpawnRoom(int entity, int other)
{
	// If player is alive and real, mark them as not in spawn room.
	if (IsClientInGame(other) && IsPlayerAlive(other) && !IsClientSourceTV(other) && !IsClientObserver(other))
		g_bInSpawnRoom[GetClientOfUserId(other)] = false;

	return Plugin_Continue;
}

public void OnPluginStart()
{
	g_cvar_weapons_onlySpawn			 = CreateConVar("tf2items_weapons_spawnonly", "0",
														"If enabled, weapon changes are only allowed when the player is within a spawn room.", 0, true, 0.0, true, 1.0);

	// Load the "Regenerate" SDK call.
	hRegen								 = TF2ItemPlugin_LoadRegenerateSDK();

	// Find the network offsets for the weapon clip and ammo.
	clipOff								 = FindSendPropInfo("CTFWeaponBase", "m_iClip1");
	ammoOff								 = FindSendPropInfo("CTFPlayer", "m_iAmmo");

	// Register the weapon commands.
	static const char commandNames[][24] = { "sm_weapons", "sm_weapon", "sm_wep", "sm_weps" };
	for (int i = 0; i < sizeof(commandNames); i++)
		RegAdminCmd(commandNames[i], CMD_TF2ItemPlugin_WeaponManager, ADMFLAG_GENERIC, "Manage weapons on the server.");

#if defined DEBUG
	// Register a debug command to print the player's inventory state.
	RegAdminCmd("sm_weapons_debug", CMD_TF2ItemPlugin_DebugInventory, ADMFLAG_GENERIC, "Print the player's inventory state.");
#endif
}

public void OnMapStart()
{
	// Attach hooks to the spawn room entities.
	TF2ItemPlugin_AttachSpawnRoomHooks();
}

public void OnClientAuthorized(int client)
{
	// Initialize the client's inventory.
	TF2ItemPlugin_InitializeInventory(client);
}

public Action CMD_TF2ItemPlugin_WeaponManager(int client, int args)
{
	// If the client is not in a spawn room and the cvar is enabled, notify them.
	if (!g_bInSpawnRoom[client] && g_cvar_weapons_onlySpawn.BoolValue)
	{
		CPrintToChat(client, "%s You must be in a spawn room to manage your weapons.", PLUGIN_CHATTAG);
		return Plugin_Handled;
	}

	// Build and open the main menu.
	TF2ItemPlugin_Menus_MainMenu(client);

	return Plugin_Handled;
}

#if defined DEBUG

void		Print_Slot(int client, int class, int slot)
{
	PrintToConsole(client, "Slot %d:\n" ...
							"Client ID: %d\n" ...
							"Class ID: %d\n" ...
							"Slot ID: %d\n" ...
							"Active Override: %d\n" ...
							"Weapon Def Index: %d\n" ...
							"Stock Def Index: %d\n" ...
							"Quality: %d\n" ...
							"Level: %d\n" ...
							"Australium: %d\n" ...
							"Festive: %d\n" ...
							"Unusual Effect: %d\n" ...
							"War Paint ID: %d\n" ...
							"War Paint Wear: %d\n" ...
							"- Killstreak:\n" ...
							"  - Active: %d\n" ...
							"  - Tier: %d\n" ...
							"  - Sheen: %d\n" ...
							"  - Killstreaker: %d\n" ...
							"Spells Bitfield: %d\n" ...
							"\n\n",
							slot, g_inventories[client][class][slot].client,
							g_inventories[client][class][slot].class, g_inventories[client][class][slot].slotId,
							g_inventories[client][class][slot].isActiveOverride, g_inventories[client][class][slot].weaponDefIndex, g_inventories[client][class][slot].stockWeaponDefIndex,
							g_inventories[client][class][slot].quality, g_inventories[client][class][slot].level,
							g_inventories[client][class][slot].isAustralium, g_inventories[client][class][slot].isFestive,
							g_inventories[client][class][slot].unusualEffectId, g_inventories[client][class][slot].warPaintId,
							g_inventories[client][class][slot].warPaintWear, g_inventories[client][class][slot].killstreak.isActive,
							g_inventories[client][class][slot].killstreak.tier, g_inventories[client][class][slot].killstreak.sheen,
							g_inventories[client][class][slot].killstreak.killstreaker, g_inventories[client][class][slot].halloweenSpell.spells
	);
}

public Action CMD_TF2ItemPlugin_DebugInventory(int client, int args)
{
	PrintToConsole(client, "Inventory Debug\n\n\n");

	// If arguments were passed, interpret them as either a class, or a class and a slot index.
	if (args >= 1)
	{
		char class[2];
		GetCmdArg(1, class, sizeof(class));

		int iclass = StringToInt(class);

		if (args >= 2)
		{
			char slot[2];
			GetCmdArg(2, slot, sizeof(slot));

			int islot = StringToInt(slot);

			PrintToConsole(client, "For class %d, slot %d\n", iclass, islot);

			Print_Slot(client, iclass, islot);

			return Plugin_Handled;
		}

		PrintToConsole(client, "For class %d\n", iclass);

		for (int j = 0; j < MAX_WEAPONS; j++)
			Print_Slot(client, iclass, j);

		return Plugin_Handled;
	}

	for (int i = 0; i < MAX_CLASSES; i++)
	{
		PrintToConsole(client, "For class %d\n", i);

		for (int j = 0; j < MAX_WEAPONS; j++)
		{
			Print_Slot(client, i, j);
		}
	}

	return Plugin_Handled;
}
#endif