#include <sourcemod>

#include <autoexecconfig>
#include <movementapi>

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

int gI_JumpsSinceInput[MAXPLAYERS + 1];
float gF_LastCountedJumpTime[MAXPLAYERS + 1];

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

public void OnClientPutInServer(int client)
{
	gI_JumpsSinceInput[client] = 0;
	gF_LastCountedJumpTime[client] = 0.0;
}

public void OnClientDisconnect(int client)
{
	UpdateInDatabase(client);
}

public void GOKZ_DB_OnClientSetup(int client, int steamID, bool cheater, int experience, int prestige, int rank, int maxrank)
{
	LogMessage("%N (%d) logged in with %d experience, %d prestige", client, steamID, experience, prestige);

	gI_Experience[client] = experience;
	gI_Prestige[client] = prestige;

	int level = GOKZ_LV_LevelForExperience(experience);
	Call_OnLevelChanged(client, level, prestige);
}

public void OnPlayerRunCmdPost(int client, int buttons, int impulse, const float vel[3], const float angles[3], int weapon, int subtype, int cmdnum, int tickcount, int seed, const int mouse[2])
{
	if (!(buttons & IN_JUMP))
	{
		gI_JumpsSinceInput[client] = 0;
	}
}

public void Movement_OnPlayerJump(int client, bool jumpbug)
{
	gI_JumpsSinceInput[client]++;
	
	// Cancel low speed jumps, to stop exploiting jumping in place
	if (Movement_GetSpeed(client) < GOKZ_LV_MIN_JUMP_SPEED)
	{
		return;
	}

	float time = GetEngineTime();

	// Cancel jumps that occur too fast, to stop exploiting low ceilings
	if (gF_LastCountedJumpTime[client] + GOKZ_LV_TIME_BETWEEN_JUMPS > time)
	{
		return;
	}	
	
	// Limit jumps that happen without releasing jump, to stop exploiting auto-bhop 
	if (gI_JumpsSinceInput[client] > GOKZ_LV_MAX_JUMPS_ON_ONE_INPUT)
	{
		return;
	}

	gF_LastCountedJumpTime[client] = time;

	AddExperience(client, GOKZ_LV_JUMP_XP);
}

public void GOKZ_LR_OnTimeProcessed(int client, int steamID, int mapID, int course, int mode, int style, 
	float runTime, int teleportsUsed, bool firstTime, float pbDiff, int rank, int maxRank, 
	bool firstTimePro, float pbDiffPro, int rankPro, int maxRankPro)
{
	if (!firstTime && !firstTimePro)
	{
		return;
	}

	int nubXP = GOKZ_LV_FIRST_NUB_XP;
	int proXP = GOKZ_LV_FIRST_PRO_XP;

	// Decrease XP given for anything that's not the main course, or the normal style.
	// This comes down to:
	//   - 166 XP for Main AutoBhop / Bonus Normal
	//   - 55 XP for Bonus AutoBhop
	if (style != Style_Normal)
	{
		nubXP /= 3;
		proXP /= 3;
	}
	if (course != 0)
	{
		nubXP /= 3;
		proXP /= 3;
	}

	if (firstTime)
	{
		AddExperience(client, nubXP);
	}
	if (firstTimePro)
	{
		AddExperience(client, proXP);
	}
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

void UpdateInDatabase(int client)
{
	if (GOKZ_DB_IsClientSetUp(client))
	{
		GOKZ_DB_SetLevel(client, gI_Experience[client], gI_Prestige[client]);
	}
}



// =====[ PRIVATE ]=====

static void AddExperience(int client, int experience)
{
	int maxXP = GOKZ_LV_ExperienceForLevel(GOKZ_LV_MAX_LEVEL);
	if (gI_Experience[client] >= maxXP)
	{
		return;
	}

	float fExperience = float(experience) * gCV_gokz_level_xp_multiplier.FloatValue;
	experience = RoundFloat(fExperience);

	int levelBefore = GOKZ_LV_LevelForExperience(gI_Experience[client]);
	gI_Experience[client] = IntMin(gI_Experience[client] + experience, maxXP);
	int levelAfter = GOKZ_LV_LevelForExperience(gI_Experience[client]);

	if (levelAfter != levelBefore)
	{
		GOKZ_PrintToChat(client, true, "%t", "Level Up", levelAfter);
		UpdateInDatabase(client);
		
		Call_OnLevelChanged(client, levelAfter, gI_Prestige[client]);
	}
}
