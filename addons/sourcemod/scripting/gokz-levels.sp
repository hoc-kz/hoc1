#include <sourcemod>

#include <gokz/core>
#include <gokz/localdb>
#include <gokz/levels>

#undef REQUIRE_EXTENSIONS
#undef REQUIRE_PLUGIN
#include <updater>

#pragma newdecls required
#pragma semicolon 1



public Plugin myinfo = 
{
	name = "GOKZ Levels", 
	author = "Szwagi", 
	description = "Tracks player levels and experience", 
	version = GOKZ_VERSION, 
	url = "https://bitbucket.org/kztimerglobalteam/gokz"
}

#define UPDATER_URL GOKZ_UPDATER_BASE_URL..."gokz-levels.txt"

int gI_Prestige[MAXPLAYERS + 1];
int gI_Experience[MAXPLAYERS + 1];

#include "gokz-levels/api.sp"
#include "gokz-levels/commands.sp"



// =====[ PLUGIN EVENTS ]=====

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNatives();
	RegPluginLibrary("gokz-levels");
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslations("gokz-levels.phrases");

	CreateGlobalForwards();
	RegisterCommands();
}

public void OnAllPluginsLoaded()
{
	if (LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATER_URL);
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

public void OnClientDisconnect(int client)
{
	if (GOKZ_DB_IsClientSetUp(client))
	{
		GOKZ_DB_SetLevel(client, gI_Experience[client], gI_Prestige[client]);
	}
}

public void GOKZ_DB_OnClientSetup(int client, int steamID, bool cheater, int experience, int prestige)
{
	gI_Experience[client] = experience;
	gI_Prestige[client] = prestige;

	int level = GOKZ_LV_LevelForExperience(experience);
	Call_OnLevelChanged(client, level, prestige);
}

public void Movement_OnPlayerJump(int client, bool jumpbug)
{
	AddExperience(client, 10000);
}



// =====[ PRIVATE ]=====

static void AddExperience(int client, int experience)
{
	if (experience <= 0)
	{
		return;
	}

	int levelBefore = GOKZ_LV_LevelForExperience(gI_Experience[client]);
	gI_Experience[client] += experience;
	int levelAfter = GOKZ_LV_LevelForExperience(gI_Experience[client]);

	if (levelAfter != levelBefore)
	{
		GOKZ_PrintToChat(client, true, "%t", "Level Up", levelAfter);
		
		Call_OnLevelChanged(client, levelAfter, gI_Prestige[client]);
	}
}

