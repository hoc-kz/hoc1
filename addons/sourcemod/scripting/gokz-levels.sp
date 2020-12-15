#include <sourcemod>

#include <autoexecconfig>

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

ConVar gCV_gokz_level_xp_multiplier;

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
	CreateConVars();
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
	AddExperience(client, 1000000);
}



// =====[ GENERAL ]=====

void CreateConVars()
{
	AutoExecConfig_SetFile("gokz-levels", "sourcemod/gokz");
	AutoExecConfig_SetCreateFile(true);
	
	gCV_gokz_level_xp_multiplier = AutoExecConfig_CreateConVar("gokz_level_xp_multiplier", "1.0", "Multiplier for gained XP", _, true, 0.2, true, 3.0);

	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();
}



// =====[ PRIVATE ]=====

static void AddExperience(int client, int experience)
{
	float fExperience = float(experience) * gCV_gokz_level_xp_multiplier.FloatValue;
	experience = RoundFloat(fExperience); 

	if (experience <= 0 || experience > 0xFF0000 || gI_Experience[client] >= 0x7F000000)
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

