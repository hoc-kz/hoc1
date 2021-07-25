#include <sourcemod>

#include <cstrike>
#include <sdktools>

#include <gokz/core>
#include <gokz/vip>

#undef REQUIRE_EXTENSIONS
#undef REQUIRE_PLUGIN
#include <gokz/jumpstats>
#include <updater>

#pragma newdecls required
#pragma semicolon 1



public Plugin myinfo = 
{
	name = "GOKZ Hook", 
	author = "Szwagi", 
	description = "Allows players to use grappling hook", 
	version = GOKZ_VERSION, 
	url = "https://bitbucket.org/kztimerglobalteam/gokz"
};

#define UPDATER_URL GOKZ_UPDATER_BASE_URL..."gokz-hook.txt"

bool gB_GOKZJumpstats;
int gI_BeamSprite;
int gI_HaloSprite;
bool gB_Hooking[MAXPLAYERS + 1];
float gF_HookingTarget[MAXPLAYERS + 1][3];
int gI_HookColor[MAXPLAYERS + 1][4];



// =====[ PLUGIN EVENTS ]=====

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	RegPluginLibrary("gokz-hook");
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslations("gokz-core.phrases");

	RegisterCommands();
}

public void OnAllPluginsLoaded()
{
	if (LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATER_URL);
	}
	gB_GOKZJumpstats = LibraryExists("gokz-jumpstats");
}

public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "updater"))
	{
		Updater_AddPlugin(UPDATER_URL);
	}
	gB_GOKZJumpstats = gB_GOKZJumpstats || StrEqual(name, "gokz-jumpstats");
}

public void OnLibraryRemoved(const char[] name)
{
	gB_GOKZJumpstats = gB_GOKZJumpstats && !StrEqual(name, "gokz-jumpstats");
}

public void OnMapStart()
{
	gI_BeamSprite = PrecacheModel("materials/sprites/laserbeam.vmt");
	gI_HaloSprite = PrecacheModel("materials/sprites/glow01.vmt");
}



// =====[ CLIENT EVENTS ]=====

public void OnClientConnected(int client)
{
	gB_Hooking[client] = false;
	gI_HookColor[client] = gI_HookColorValues[gI_VIPOptionDefaults[VIPOption_HookColor]];
}

public void OnClientCookiesCached(int client)
{
	gI_HookColor[client] = gI_HookColorValues[GOKZ_VIP_GetOption(client, VIPOption_HookColor)];
}

public void GOKZ_OnOptionChanged(int client, const char[] option, any newValue)
{
	if (StrEqual(option, gC_VIPOptionNames[VIPOption_HookColor]))
	{
		gI_HookColor[client] = gI_HookColorValues[newValue];
	}
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if (!IsPlayerAlive(client) || !gB_Hooking[client])
	{
		return Plugin_Continue;
	}

	InvalidateJumpAndTimer(client);

	float eyePosition[3];
	GetClientEyePosition(client, eyePosition);

	float velocity[3];
	MakeVectorFromPoints(eyePosition, gF_HookingTarget[client], velocity);
	NormalizeVector(velocity, velocity);
	ScaleVector(velocity, 1000.0);

	Movement_SetVelocity(client, velocity);
	Movement_SetMovetype(client, MOVETYPE_LADDER); // Stops the player from sticking to the ground
	SetEntityFlags(client, GetEntityFlags(client) | FL_ATCONTROLS); // Stops the players keys from doing anything

	// Send beam
	if (tickcount % 4 == 0)
	{
		eyePosition[2] -= 22.0;

		TE_SetupBeamPoints(eyePosition, gF_HookingTarget[client], gI_BeamSprite, gI_HaloSprite, 0, 0, 0.06, 1.0, 1.0, 0, 0.0, gI_HookColor[client], 0);
		TE_SendToAll();
	}

	return Plugin_Continue;
}



// =====[ HOOK ]=====

void EnableHook(int client)
{
	if (!IsPlayerAlive(client) || gB_Hooking[client])
	{
		return;
	}

	InvalidateJumpAndTimer(client);

	float eyePosition[3];
	float eyeAngles[3];
	GetClientEyePosition(client, eyePosition);
	GetClientEyeAngles(client, eyeAngles);

	TR_TraceRayFilter(eyePosition, eyeAngles, MASK_SHOT, RayType_Infinite, TraceRayDontHitEntities);
	if (!TR_DidHit())
	{
		return;
	}

	TR_GetEndPosition(gF_HookingTarget[client]);
	gB_Hooking[client] = true;
}

void DisableHook(int client)
{
	if (!IsPlayerAlive(client) || !gB_Hooking[client])
	{
		return;
	}

	InvalidateJumpAndTimer(client);

	if (Movement_GetMovetype(client) == MOVETYPE_LADDER)
	{
		Movement_SetMovetype(client, MOVETYPE_WALK);
	}
	SetEntityFlags(client, GetEntityFlags(client) & ~FL_ATCONTROLS);

	gB_Hooking[client] = false;
}

public bool TraceRayDontHitEntities(int entity, int mask, any data)
{
	return false;
}

void InvalidateJumpAndTimer(int client)
{
	if (gB_GOKZJumpstats)
	{
		GOKZ_JS_InvalidateJump(client);
	}

	if (GOKZ_StopTimer(client))
	{
		GOKZ_PrintToChat(client, true, "%t", "Timer Stopped (Hooked)");
	}
}



// =====[ COMMANDS ]=====

void RegisterCommands()
{
	RegConsoleCmd("+hook", CommandEnableHook);
	RegConsoleCmd("-hook", CommandDisableHook);
}

public Action CommandEnableHook(int client, int argc)
{
	EnableHook(client);
	return Plugin_Handled;
}

public Action CommandDisableHook(int client, int argc)
{
	DisableHook(client);
	return Plugin_Handled;
}


