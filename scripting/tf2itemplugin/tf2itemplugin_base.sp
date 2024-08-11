#include <sourcemod>
#include <lang>
#include <tf2>
#include <tf2_stocks>
#include <sdkhooks>
#include <sdktools>

#include <SteamWorks>
#include <smjansson>

#include <morecolors>

#include <tf2items>
#include <tf2attributes>
#include <tf_econ_data>

#pragma dynamic 131072

#define PLUGIN_CHATTAG "{mythical}[TF2Items]{white}"

#define MAX_WEAPONS	   3
#define MAX_COSMETICS  3
#define MAX_CLASSES	   9

/**
 * Obtains the class name of a class ID for visual representation.
 *
 * @param class The `TFClassType` class ID to obtain the name for.
 * @param buffer The buffer to store the class name.
 * @param size The size of the buffer.
 *
 * @return void
 */
stock void TF2ItemPlugin_GetTFClassName(TFClassType class, char[] buffer, int size)
{
	switch (class)
	{
		case TFClass_Scout: strcopy(buffer, size, "Scout");
		case TFClass_Soldier: strcopy(buffer, size, "Soldier");
		case TFClass_Pyro: strcopy(buffer, size, "Pyro");
		case TFClass_DemoMan: strcopy(buffer, size, "Demoman");
		case TFClass_Heavy: strcopy(buffer, size, "Heavy");
		case TFClass_Engineer: strcopy(buffer, size, "Engineer");
		case TFClass_Medic: strcopy(buffer, size, "Medic");
		case TFClass_Sniper: strcopy(buffer, size, "Sniper");
		case TFClass_Spy: strcopy(buffer, size, "Spy");
		default: strcopy(buffer, size, "Unknown");
	}
}

/**
 * Obtains the player class of a client and returns it as an integer.
 *
 * @param client Client index to obtain the class for.
 *
 * @return The player class of the client.
 */
stock int TF2_GetPlayerClassInt(int client)
{
	return view_as<int>(TF2_GetPlayerClass(client));
}
