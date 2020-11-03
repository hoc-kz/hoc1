#include <sourcemod>

#include <sdkhooks>
#include <sdktools>

#include <gokz/core>

#undef REQUIRE_EXTENSIONS
#undef REQUIRE_PLUGIN
#include <updater>

#pragma newdecls required
#pragma semicolon 1



public Plugin myinfo = 
{
	name = "GOKZ Styles", 
	author = "Szwagi", 
	description = "Styles for GOKZ", 
	version = GOKZ_VERSION, 
	url = "https://bitbucket.org/kztimerglobalteam/gokz"
};

#define UPDATER_URL GOKZ_UPDATER_BASE_URL..."gokz-styles.txt"

ConVar gCV_AutoBunnyHopping;



// =====[ PLUGIN EVENTS ]=====

public void OnPluginStart()
{
	CreateConVars();
}

public void OnAllPluginsLoaded()
{
	if (LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATER_URL);
	}

	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client))
		{
			OnClientPutInServer(client);
		}
	}
}

public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "updater"))
	{
		Updater_AddPlugin(UPDATER_URL);
	}
}


// =====[ CLIENT EVENTS ]=====

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_PreThinkPost, SDKHook_OnClientPreThink_Post);
	ReplicateConVars(client);
}

public void GOKZ_OnOptionChanged(int client, const char[] option, any newValue)
{
	if (StrEqual(option, gC_CoreOptionNames[Option_Style]))
	{
		ReplicateConVars(client);
	}
}

public void SDKHook_OnClientPreThink_Post(int client)
{
	if (!IsPlayerAlive(client))
	{
		return;
	}

	TweakConVars(client);
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if (!IsPlayerAlive(client))
	{
		return Plugin_Continue;
	}

	if (GetStyle(client) == Style_WOnly)
	{
		int flags = GetEntityFlags(client);

		int badButtons = (buttons & IN_BACK) | (buttons & IN_MOVELEFT) | (buttons & IN_MOVERIGHT);
		if (badButtons != 0)
		{
			flags |= FL_ATCONTROLS;
			buttons &= ~badButtons;
		}
		else
		{
			flags &= ~FL_ATCONTROLS;
		}

		SetEntityFlags(client, flags);
	}
	return Plugin_Continue;
}



// =====[ GENERAL ]=====

int GetStyle(int client)
{
	return GOKZ_GetCoreOption(client, Option_Style);
}



// =====[ CONVARS ]=====

void CreateConVars()
{
	gCV_AutoBunnyHopping = FindConVar("sv_autobunnyhopping");
}

void TweakConVars(int client)
{
	if (GetStyle(client) == Style_AutoBhop)
	{
		gCV_AutoBunnyHopping.BoolValue = true;
	}
	else
	{
		gCV_AutoBunnyHopping.BoolValue = false;
	}
}

void ReplicateConVars(int client)
{
	// Replicate convars only when player changes style in GOKZ
	// so that lagg isn't caused by other players using other
	// styles, and also as an optimisation.
	
	if (IsFakeClient(client))
	{
		return;
	}
	
	if (GetStyle(client) == Style_AutoBhop)
	{
		gCV_AutoBunnyHopping.ReplicateToClient(client, "1");
	}
	else
	{
		gCV_AutoBunnyHopping.ReplicateToClient(client, "0");
	}
}
