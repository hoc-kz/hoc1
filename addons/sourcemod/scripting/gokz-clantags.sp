#include <sourcemod>

#include <cstrike>

#include <gokz/core>

#undef REQUIRE_EXTENSIONS
#undef REQUIRE_PLUGIN
#include <updater>

#include <gokz/levels>
#include <gokz/localdb>

#pragma newdecls required
#pragma semicolon 1



public Plugin myinfo = 
{
	name = "GOKZ Clan Tags", 
	author = "DanZay", 
	description = "Sets the clan tags of players", 
	version = GOKZ_VERSION, 
	url = "https://bitbucket.org/kztimerglobalteam/gokz"
};

#define UPDATER_URL GOKZ_UPDATER_BASE_URL..."gokz-clantags.txt"

bool gB_GOKZLevels;



// =====[ PLUGIN EVENTS ]=====

public void OnAllPluginsLoaded()
{
	if (LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATER_URL);
	}
	gB_GOKZLevels = LibraryExists("gokz-levels");
}

public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "updater"))
	{
		Updater_AddPlugin(UPDATER_URL);
	}
	gB_GOKZLevels = gB_GOKZLevels || StrEqual(name, "gokz-levels");
}

public void OnLibraryRemoved(const char[] name)
{
	gB_GOKZLevels = gB_GOKZLevels && !StrEqual(name, "gokz-levels");
}



// =====[ CLIENT EVENTS ]=====

public void OnClientPutInServer(int client)
{
	UpdateClanTag(client);
}

public void GOKZ_OnOptionChanged(int client, const char[] option, any newValue)
{
	Option coreOption;
	if (!GOKZ_IsCoreOption(option, coreOption))
	{
		return;
	}
	
	if (coreOption == Option_Mode)
	{
		UpdateClanTag(client);
	}
}

public void GOKZ_LV_OnLevelChanged(int client, int level, int prestige)
{
	UpdateClanTag(client);
}



void UpdateClanTag(int client)
{
	if (IsFakeClient(client) || !IsClientInGame(client))
	{
		return;
	}

	if (gB_GOKZLevels && GOKZ_DB_IsClientSetUp(client))
	{
		int level = GOKZ_LV_GetLevel(client);

		char clantag[32];
		FormatEx(clantag, sizeof(clantag), "[Lv%d] %s", level, gC_ModeNamesShort[GOKZ_GetCoreOption(client, Option_Mode)]);

		CS_SetClientClanTag(client, clantag);
	}
	else
	{
		CS_SetClientClanTag(client, gC_ModeNamesShort[GOKZ_GetCoreOption(client, Option_Mode)]);
	}
}
