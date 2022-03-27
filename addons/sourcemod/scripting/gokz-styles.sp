#include <sourcemod>

#include <sdkhooks>
#include <sdktools>

#include <gokz/core>

#undef REQUIRE_EXTENSIONS
#undef REQUIRE_PLUGIN
#include <updater>

#pragma newdecls required
#pragma semicolon 1

/*
	This file is very messy!!!

	This should really be split into multiple files, each for it's own style, like modes are.
	The reason it's not at the moment, is that I didn't know what an appropriate API would be at the time.
*/



public Plugin myinfo = 
{
	name = "GOKZ Styles", 
	author = "Szwagi", 
	description = "Styles for GOKZ", 
	version = GOKZ_VERSION, 
	url = "https://bitbucket.org/kztimerglobalteam/gokz"
};

#define UPDATER_URL GOKZ_UPDATER_BASE_URL..."gokz-styles.txt"
#define MAX_LADDERJUMP_TIME 2.0
#define MAX_BAD_BUTTON_TIME 0.1
#define MAX_LAH_GROUND_TICKS 5

ConVar gCV_AutoBunnyHopping;
ConVar gCV_Accelerate;
ConVar gCV_Friction;
ConVar gCV_JumpImpulse;

bool gB_LadderJump[MAXPLAYERS + 1];
float gF_LadderJumpTime[MAXPLAYERS + 1];

bool gB_SidewaysBlockGround[MAXPLAYERS + 1];
bool gB_SidewaysBlockAir[MAXPLAYERS + 1];
float gF_OnGroundChangedTime[MAXPLAYERS + 1];
int gI_LastJumpTick[MAXPLAYERS + 1];
int gI_LadderGrabTick[MAXPLAYERS + 1];
bool gB_TouchingWorld[MAXPLAYERS + 1];

#include "gokz-styles/natives.sp"



// =====[ PLUGIN EVENTS ]=====

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNatives();
	RegPluginLibrary("gokz-styles");
	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVars();
	HookEvents();
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
	gB_LadderJump[client] = false;
	gF_LadderJumpTime[client] = -999999.0;

	gB_SidewaysBlockGround[client] = false;
	gB_SidewaysBlockAir[client] = false;
	gF_OnGroundChangedTime[client] = -999999.0;
	gI_LastJumpTick[client] = -999999;
	gI_LadderGrabTick[client] = -999999;

	HookClientEvents(client);
}

public void OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!IsValidClient(client))
	{
		return;
	}

	// Give a weapon (negev/deagle styles)
	int style = GetStyle(client);
	if (style == Style_Negev)
	{
		GiveWeapon(client, "weapon_negev", CS_SLOT_PRIMARY);
	}
	else if (style == Style_Deagle)
	{
		GiveWeapon(client, "weapon_deagle", CS_SLOT_SECONDARY);
	}
}

public void GOKZ_OnOptionChanged(int client, const char[] option, any newValue)
{
	if (!StrEqual(option, gC_CoreOptionNames[Option_Style]))
	{
		return;
	}

	// Reset lagged movement (undo slow-motion style)
	SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", 1.0);

	// Give a weapon (negev/deagle styles)
	if (newValue == Style_Negev)
	{
		GiveWeapon(client, "weapon_negev", CS_SLOT_PRIMARY);
	}
	else if (newValue == Style_Deagle)
	{
		GiveWeapon(client, "weapon_deagle", CS_SLOT_SECONDARY);
	}

	// Remove ATCONTROLS flag (w only)
	SetEntityFlags(client, GetEntityFlags(client) & ~FL_ATCONTROLS);
}

public void Movement_OnChangeMovetype(int client, MoveType oldMovetype, MoveType newMovetype)
{
	if (newMovetype == MOVETYPE_LADDER)
	{
		gI_LadderGrabTick[client] = GetGameTickCount();
	}

	// Keep track of when the player is performing a ladder jump.
	bool onGround = (GetEntityFlags(client) & FL_ONGROUND) != 0;
	bool ladderHop = (GetGameTickCount() - gI_LastJumpTick[client] <= MAX_LAH_GROUND_TICKS) && (GetGameTickCount() - gI_LadderGrabTick[client] > MAX_LAH_GROUND_TICKS);
	if (oldMovetype == MOVETYPE_LADDER && !onGround && !ladderHop)
	{
		gB_LadderJump[client] = true;
		gF_LadderJumpTime[client] = GetEngineTime();
	}
}

public void Movement_OnStartTouchGround(int client)
{
	// Touched the ground, so not perforing a ladder jump anymore.
	gB_LadderJump[client] = false;

	gF_OnGroundChangedTime[client] = GetEngineTime();
}

public void Movement_OnStopTouchGround(int client, bool jumped)
{
	gF_OnGroundChangedTime[client] = GetEngineTime();

	if (jumped)
	{
		gI_LastJumpTick[client] = GetGameTickCount();
	}
}

public void OnClientPreThink_Post(int client)
{
	if (!IsPlayerAlive(client))
	{
		return;
	}

	if (GetStyle(client) == Style_SlowMotion)
	{
		float laggedMovement = GetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue");
		if (FloatAbs(laggedMovement) > EPSILON) 
		{
			SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", 0.5);
		}
	}
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if (!IsPlayerAlive(client))
	{
		return Plugin_Continue;
	}

	int style = GetStyle(client);
	if (style == Style_WOnly)
	{
		int flags = GetEntityFlags(client) & ~FL_ATCONTROLS;
		MoveType moveType = GetEntityMoveType(client);
		
		int badButtons = (buttons & IN_BACK) | (buttons & IN_MOVELEFT) | (buttons & IN_MOVERIGHT);
		bool noclip = (moveType == MOVETYPE_NOCLIP);
		bool ladder = (moveType == MOVETYPE_LADDER);
		bool ladderJump = (gB_LadderJump[client] && (GetEngineTime() <= gF_LadderJumpTime[client] + MAX_LADDERJUMP_TIME));

		if (noclip || ladder || ladderJump)
		{
			return Plugin_Continue;
		}

		if (badButtons != 0)
		{
			flags |= FL_ATCONTROLS;
			buttons &= ~badButtons;
		}

		SetEntityFlags(client, flags);
	}
	else if (style == Style_Sideways)
	{
		int flags = GetEntityFlags(client) & ~FL_ATCONTROLS;
		MoveType moveType = GetEntityMoveType(client);

		bool noclip = (moveType == MOVETYPE_NOCLIP);
		bool ladder = (moveType == MOVETYPE_LADDER);
		bool ladderJump = (gB_LadderJump[client] && (GetEngineTime() <= gF_LadderJumpTime[client] + MAX_LADDERJUMP_TIME));

		if (noclip || ladder || ladderJump)
		{
			return Plugin_Continue;
		}

		if (flags & FL_ONGROUND)
		{
			int badButtons = (buttons & IN_FORWARD) | (buttons & IN_BACK);

			gB_SidewaysBlockGround[client] = false;
			bool blockAirButtons = gB_SidewaysBlockAir[client] || (GetEngineTime() > gF_OnGroundChangedTime[client] + MAX_BAD_BUTTON_TIME);

			if (blockAirButtons)
			{
				if (badButtons != 0)
				{
					flags |= FL_ATCONTROLS;
					//buttons &= ~badButtons;
				}
			}
			else
			{
				if (badButtons == 0)
				{
					gB_SidewaysBlockAir[client] = true;
				}
			}			
		}
		else
		{
			int badButtons = (buttons & IN_MOVELEFT) | (buttons & IN_MOVERIGHT);

			gB_SidewaysBlockAir[client] = false;
			bool blockGroundButtons = gB_SidewaysBlockGround[client] || (GetEngineTime() > gF_OnGroundChangedTime[client] + MAX_BAD_BUTTON_TIME);

			if (blockGroundButtons)
			{
				if (badButtons != 0)
				{
					if (gB_TouchingWorld[client])
					{
						vel[1] *= (80.0 / 450.0);
					}
					else
					{
						vel[1] *= (7.0 / 450.0);
					}			
					//buttons &= ~badButtons;
				}
			}
			else
			{
				if (badButtons == 0)
				{
					gB_SidewaysBlockGround[client] = true;
				}
			}	
		}
	
		SetEntityFlags(client, flags);
	}
	else if (style == Style_Negev)
	{
		int primary = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
		if (primary == -1)
		{
			GiveWeapon(client, "weapon_negev", CS_SLOT_PRIMARY);
		}
		else
		{
			int defIndex = GetEntProp(primary, Prop_Send, "m_iItemDefinitionIndex");
			if (defIndex != CS_WeaponIDToItemDefIndex(CSWeapon_NEGEV))
			{
				GiveWeapon(client, "weapon_negev", CS_SLOT_PRIMARY);
			}
		}
	}
	else if (style == Style_Deagle)
	{
		int secondary = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY);
		if (secondary == -1)
		{
			GiveWeapon(client, "weapon_deagle", CS_SLOT_SECONDARY);
		}
		else
		{
			int defIndex = GetEntProp(secondary, Prop_Send, "m_iItemDefinitionIndex");
			if (defIndex != CS_WeaponIDToItemDefIndex(CSWeapon_DEAGLE))
			{
				GiveWeapon(client, "weapon_deagle", CS_SLOT_SECONDARY);
			}
		}
	}

	return Plugin_Continue;
}

public Action OnClientWeaponCanSwitchTo(int client, int weapon)
{
	int style = GetStyle(client);
	if (style == Style_Negev)
	{
		int defIndex = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
		if (defIndex != CS_WeaponIDToItemDefIndex(CSWeapon_NEGEV))
		{
			return Plugin_Stop;
		}
	}
	else if (style == Style_Deagle)
	{
		int defIndex = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
		if (defIndex != CS_WeaponIDToItemDefIndex(CSWeapon_DEAGLE))
		{
			return Plugin_Stop;
		}
	}
	return Plugin_Continue;
}

public Action OnClientWeaponDrop(int client, int weapon)
{
	int style = GetStyle(client);
	if (style == Style_Negev || style == Style_Deagle)
	{
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public void OnClientStartTouch(int client, int other)
{
	if (other == 0)
	{
		gB_TouchingWorld[client] = true;
	}
}

public void OnClientEndTouch(int client, int other)
{
	if (other == 0)
	{
		gB_TouchingWorld[client] = false;
	}
}



// =====[ GENERAL ]=====

int GetMode(int client)
{
	return GOKZ_GetCoreOption(client, Option_Mode);
}

int GetStyle(int client)
{
	return GOKZ_GetCoreOption(client, Option_Style);
}

int GiveWeapon(int client, const char[] classname, int weaponSlot, int weaponTeam = CS_TEAM_NONE)
{
	if (!IsValidClient(client) || !IsPlayerAlive(client) || GetClientTeam(client) == CS_TEAM_NONE)
	{
		return 0;
	}        

	// Switch team the weapon belongs to (glock for T etc), so player gets the skin
	int playerTeam = GetClientTeam(client);
	if (playerTeam != weaponTeam && weaponTeam != CS_TEAM_NONE)
	{
		SetEntProp(client, Prop_Data, "m_iTeamNum", weaponTeam);
	}        

	int currentWeapon = GetPlayerWeaponSlot(client, weaponSlot);
	if (currentWeapon != -1)
	{
		AcceptEntityInput(currentWeapon, "kill");
		RemovePlayerItem(client, currentWeapon);
	}        

	int weapon = GivePlayerItem(client, classname);
	if (weapon == -1)
	{
		return 0;
	}

	// Switch back to original team
	if (playerTeam != GetClientTeam(client))
	{
		SetEntProp(client, Prop_Data, "m_iTeamNum", playerTeam);
	}        

	// Switch to the weapon
	FakeClientCommand(client, "use %s", classname);

	return weapon;
}



// =====[ CONVARS ]=====

void CreateConVars()
{
	gCV_AutoBunnyHopping = FindConVar("sv_autobunnyhopping");
	gCV_Accelerate = FindConVar("sv_accelerate");
	gCV_Friction = FindConVar("sv_friction");
	gCV_JumpImpulse = FindConVar("sv_jump_impulse");

	// Styles replicate it manually
	gCV_AutoBunnyHopping.Flags &= ~(FCVAR_NOTIFY | FCVAR_REPLICATED);
	gCV_Accelerate.Flags &= ~(FCVAR_NOTIFY | FCVAR_REPLICATED);
	gCV_Friction.Flags &= ~(FCVAR_NOTIFY | FCVAR_REPLICATED);
	gCV_JumpImpulse.Flags &= ~(FCVAR_NOTIFY | FCVAR_REPLICATED);
}

void ReplicateConVars(int client)
{
	if (IsFakeClient(client))
	{
		return;
	}
	
	int mode = GetMode(client);
	int style = GetStyle(client);

	if (style == Style_AutoBhop)
	{
		gCV_AutoBunnyHopping.ReplicateToClient(client, "1");
	}
	else
	{
		gCV_AutoBunnyHopping.ReplicateToClient(client, "0");
	}

	if (style == Style_Ice)
	{
		if (mode == Mode_Classic)
		{
			gCV_Accelerate.ReplicateToClient(client, "0.975");
			gCV_Friction.ReplicateToClient(client, "0.78");
		}
		else
		{
			gCV_Accelerate.ReplicateToClient(client, "0.825");
			gCV_Friction.ReplicateToClient(client, "0.78");
		}
	}
}

void TweakConVars(int client)
{
	int mode = GetMode(client);
	int style = GetStyle(client);

	if (style == Style_AutoBhop)
	{
		gCV_AutoBunnyHopping.BoolValue = true;
	}
	else
	{
		gCV_AutoBunnyHopping.BoolValue = false;
	}

	if (style == Style_Ice)
	{ 
		if (mode == Mode_Classic)
		{
			gCV_Accelerate.FloatValue = 0.975;
			gCV_Friction.FloatValue = 0.78;

			bool onGround = (GetEntityFlags(client) & FL_ONGROUND) != 0;
			if (onGround)
			{
				float timeOnGround = FloatMax(0.0, GetEngineTime() - gF_OnGroundChangedTime[client]);
				float impulseMultiplier = 0.75 + 0.25 * (FloatMin(1.0, timeOnGround / 0.15));
				gCV_JumpImpulse.FloatValue = 301.993377 * impulseMultiplier;
			}
		}
		else
		{
			gCV_Accelerate.FloatValue = 0.825;
			gCV_Friction.FloatValue = 0.78;
		}
	}
}



// =====[ PRIVATE ]=====

static void HookEvents()
{
	HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Post);
}

static void HookClientEvents(int client)
{
	SDKHook(client, SDKHook_PreThinkPost, OnClientPreThink_Post);

	SDKHook(client, SDKHook_WeaponCanSwitchTo, OnClientWeaponCanSwitchTo);
	SDKHook(client, SDKHook_WeaponDrop, OnClientWeaponDrop);

	SDKHook(client, SDKHook_StartTouchPost, OnClientStartTouch);
	SDKHook(client, SDKHook_EndTouchPost, OnClientEndTouch);
} 
