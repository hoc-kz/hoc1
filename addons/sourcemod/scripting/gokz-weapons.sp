#include <sourcemod>

#include <cstrike>

#include <gokz/core>

#undef REQUIRE_EXTENSIONS
#undef REQUIRE_PLUGIN
#include <updater>

#pragma newdecls required
#pragma semicolon 1



public Plugin myinfo = 
{
	name = "GOKZ Weapons", 
	author = "Szwagi", 
	description = "Allows players to use any weapon", 
	version = GOKZ_VERSION, 
	url = "https://bitbucket.org/kztimerglobalteam/gokz"
};

#define UPDATER_URL GOKZ_UPDATER_BASE_URL..."gokz-weapons.txt"



// =====[ PLUGIN EVENTS ]=====

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	RegPluginLibrary("gokz-weapons");
	return APLRes_Success;
}

public void OnPluginStart()
{
	HookEvents();
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

public void OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast) // player_spawn post hook 
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (IsValidClient(client))
	{
		GiveWeapon(client, "weapon_usp_silencer", CS_SLOT_SECONDARY, CS_TEAM_CT);
	}
}



// =====[ GENERAL ]=====

void HookEvents()
{
	HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Post);
}



// =====[ WEAPONS ]=====

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



// =====[ COMMANDS ]=====

void RegisterCommands()
{
	RegConsoleCmd("sm_ak47", CommandAK47);
	RegConsoleCmd("sm_aug", CommandAUG);
	RegConsoleCmd("sm_awp", CommandAWP);
	RegConsoleCmd("sm_bizon", CommandBizon);
	RegConsoleCmd("sm_cz75a", CommandCZ75A);
	RegConsoleCmd("sm_deagle", CommandDeagle);
	RegConsoleCmd("sm_elites", CommandDualBerettas);
	RegConsoleCmd("sm_dualies", CommandDualBerettas); // alt
	RegConsoleCmd("sm_berettas", CommandDualBerettas); // alt
	RegConsoleCmd("sm_dualberettas", CommandDualBerettas); // alt
	RegConsoleCmd("sm_famas", CommandFAMAS);
	RegConsoleCmd("sm_fiveseven", CommandFiveSeven);
	RegConsoleCmd("sm_g3sg1", CommandG3SG1);
	RegConsoleCmd("sm_galil", CommandGalilar);
	RegConsoleCmd("sm_glock", CommandGlock);
	RegConsoleCmd("sm_p2000", CommandP2000);
	RegConsoleCmd("sm_m4a4", CommandM4A4);
	RegConsoleCmd("sm_m4a1", CommandM4A1);
	RegConsoleCmd("sm_m249", CommandM249);
	RegConsoleCmd("sm_mac10", CommandMAC10);
	RegConsoleCmd("sm_mag7", CommandMAG7);
	RegConsoleCmd("sm_mp7", CommandMP7);
	RegConsoleCmd("sm_mp9", CommandMP9);
	RegConsoleCmd("sm_negev", CommandNegev);
	RegConsoleCmd("sm_nova", CommandNova);
	RegConsoleCmd("sm_p90", CommandP90);
	RegConsoleCmd("sm_p250", CommandP250);
	RegConsoleCmd("sm_revolver", CommandRevolver);
	RegConsoleCmd("sm_sawedoff", CommandSawedOff);
	RegConsoleCmd("sm_scar20", CommandSCAR20);
	RegConsoleCmd("sm_sg553", CommandSG553);
	RegConsoleCmd("sm_sg556", CommandSG553); // alt
	RegConsoleCmd("sm_ssg08", CommandSSG08);
	RegConsoleCmd("sm_scout", CommandSSG08); // alt
	RegConsoleCmd("sm_tec9", CommandTec9); 
	RegConsoleCmd("sm_ump45", CommandUMP45);
	RegConsoleCmd("sm_usp", CommandUSP);
	RegConsoleCmd("sm_xm1014", CommandXM1014);
	RegConsoleCmd("sm_mp5", CommandMP5);
}

public Action CommandAK47(int client, int argc)
{
	GiveWeapon(client, "weapon_ak47", CS_SLOT_PRIMARY, CS_TEAM_T);
	return Plugin_Handled;
}

public Action CommandAUG(int client, int argc)
{
	GiveWeapon(client, "weapon_aug", CS_SLOT_PRIMARY, CS_TEAM_CT);
	return Plugin_Handled;
}

public Action CommandAWP(int client, int argc)
{
	GiveWeapon(client, "weapon_awp", CS_SLOT_PRIMARY);
	return Plugin_Handled;
}

public Action CommandBizon(int client, int argc)
{
	GiveWeapon(client, "weapon_bizon", CS_SLOT_PRIMARY);
	return Plugin_Handled;
}

public Action CommandCZ75A(int client, int argc)
{
	GiveWeapon(client, "weapon_cz75a", CS_SLOT_SECONDARY);
	return Plugin_Handled;
}

public Action CommandDeagle(int client, int argc)
{
	GiveWeapon(client, "weapon_deagle", CS_SLOT_SECONDARY);
	return Plugin_Handled;
}

public Action CommandDualBerettas(int client, int argc)
{
	GiveWeapon(client, "weapon_elite", CS_SLOT_SECONDARY);
	return Plugin_Handled;
}

public Action CommandFAMAS(int client, int argc)
{
	GiveWeapon(client, "weapon_famas", CS_SLOT_PRIMARY, CS_TEAM_CT);
	return Plugin_Handled;
}

public Action CommandFiveSeven(int client, int argc)
{
	GiveWeapon(client, "weapon_fiveseven", CS_SLOT_SECONDARY, CS_TEAM_CT);
	return Plugin_Handled;
}

public Action CommandG3SG1(int client, int argc)
{
	GiveWeapon(client, "weapon_g3sg1", CS_SLOT_PRIMARY, CS_TEAM_T);
	return Plugin_Handled;
}

public Action CommandGalilar(int client, int argc)
{
	GiveWeapon(client, "weapon_galilar", CS_SLOT_PRIMARY, CS_TEAM_T);
	return Plugin_Handled;
}

public Action CommandGlock(int client, int argc)
{
	GiveWeapon(client, "weapon_glock", CS_SLOT_SECONDARY, CS_TEAM_T);
	return Plugin_Handled;
}

public Action CommandP2000(int client, int argc)
{
	int weapon = GiveWeapon(client, "weapon_hkp2000", CS_SLOT_SECONDARY, CS_TEAM_CT);
	if (weapon == 0)
	{
		return Plugin_Handled;
	}        

	int defIndex = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
	if (defIndex != CS_WeaponIDToItemDefIndex(CSWeapon_HKP2000))
	{
		GiveWeapon(client, "weapon_hkp2000", CS_SLOT_SECONDARY, CS_TEAM_T);
	}

	return Plugin_Handled;
}

public Action CommandM4A4(int client, int argc)
{
	GiveWeapon(client, "weapon_m4a1", CS_SLOT_PRIMARY, CS_TEAM_CT);
	return Plugin_Handled;
}

public Action CommandM4A1(int client, int argc)
{
	GiveWeapon(client, "weapon_m4a1_silencer", CS_SLOT_PRIMARY, CS_TEAM_CT);
	return Plugin_Handled;
}

public Action CommandM249(int client, int argc)
{
	GiveWeapon(client, "weapon_m249", CS_SLOT_PRIMARY);
	return Plugin_Handled;
}

public Action CommandMAC10(int client, int argc)
{
	GiveWeapon(client, "weapon_mac10", CS_SLOT_PRIMARY, CS_TEAM_T);
	return Plugin_Handled;
}

public Action CommandMAG7(int client, int argc)
{
	GiveWeapon(client, "weapon_mag7", CS_SLOT_PRIMARY, CS_TEAM_CT);
	return Plugin_Handled;
}

public Action CommandMP7(int client, int argc)
{
	GiveWeapon(client, "weapon_mp7", CS_SLOT_PRIMARY);
	return Plugin_Handled;
}

public Action CommandMP9(int client, int argc)
{
	GiveWeapon(client, "weapon_mp9", CS_SLOT_PRIMARY, CS_TEAM_CT);
	return Plugin_Handled;
}

public Action CommandNegev(int client, int argc)
{
	GiveWeapon(client, "weapon_negev", CS_SLOT_PRIMARY);
	return Plugin_Handled;
}

public Action CommandNova(int client, int argc)
{
	GiveWeapon(client, "weapon_nova", CS_SLOT_PRIMARY);
	return Plugin_Handled;
}

public Action CommandP90(int client, int argc)
{
	GiveWeapon(client, "weapon_p90", CS_SLOT_PRIMARY);
	return Plugin_Handled;
}

public Action CommandP250(int client, int argc)
{
	GiveWeapon(client, "weapon_p250", CS_SLOT_SECONDARY);
	return Plugin_Handled;
}

public Action CommandRevolver(int client, int argc)
{
	GiveWeapon(client, "weapon_revolver", CS_SLOT_SECONDARY);
	return Plugin_Handled;
}

public Action CommandSawedOff(int client, int argc)
{
	GiveWeapon(client, "weapon_sawedoff", CS_SLOT_PRIMARY, CS_TEAM_T);
	return Plugin_Handled;
}

public Action CommandSCAR20(int client, int argc)
{
	GiveWeapon(client, "weapon_scar20", CS_SLOT_PRIMARY, CS_TEAM_CT);
	return Plugin_Handled;
}

public Action CommandSG553(int client, int argc)
{
	GiveWeapon(client, "weapon_sg556", CS_SLOT_PRIMARY, CS_TEAM_T);
	return Plugin_Handled;
}

public Action CommandSSG08(int client, int argc)
{
	GiveWeapon(client, "weapon_ssg08", CS_SLOT_PRIMARY);
	return Plugin_Handled;
}

public Action CommandTec9(int client, int argc)
{
	GiveWeapon(client, "weapon_tec9", CS_SLOT_SECONDARY, CS_TEAM_T);
	return Plugin_Handled;
}

public Action CommandUMP45(int client, int argc)
{
	GiveWeapon(client, "weapon_ump45", CS_SLOT_PRIMARY);
	return Plugin_Handled;
}

public Action CommandUSP(int client, int argc)
{
	GiveWeapon(client, "weapon_usp_silencer", CS_SLOT_SECONDARY, CS_TEAM_CT);
	return Plugin_Handled;
}

public Action CommandXM1014(int client, int argc)
{
	GiveWeapon(client, "weapon_xm1014", CS_SLOT_PRIMARY);
	return Plugin_Handled;
}

public Action CommandMP5(int client, int argc)
{
	GiveWeapon(client, "weapon_mp5sd", CS_SLOT_PRIMARY);
	return Plugin_Handled;
}
