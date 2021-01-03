#include <sourcemod>

#include <cstrike>
#include <sdktools>
#include <clientprefs>

#include <gokz/core>

#include <autoexecconfig>

#undef REQUIRE_EXTENSIONS
#undef REQUIRE_PLUGIN
#include <updater>

#pragma newdecls required
#pragma semicolon 1



public Plugin myinfo = 
{
	name = "GOKZ Player Models", 
	author = "DanZay", 
	description = "Sets player's model upon spawning", 
	version = GOKZ_VERSION, 
	url = "https://bitbucket.org/kztimerglobalteam/gokz"
};

#define UPDATER_URL GOKZ_UPDATER_BASE_URL..."gokz-playermodels.txt"
#define CFG_CUSTOM_MODELS "cfg/sourcemod/gokz/gokz-playermodels-custom.cfg"
#define DEFAULT_PLAYER_MODEL "models/player/ctm_idf_variantc.mdl"

enum struct PlayerModel
{
	char Name[64];
	char Path[256];
}

ArrayList gH_PlayerModels;
Cookie gH_PlayerModelCookie;
ConVar gCV_gokz_player_models_alpha;
ConVar gCV_sv_disable_immunity_alpha;



// =====[ PLUGIN EVENTS ]=====

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	RegPluginLibrary("gokz-playermodels");
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslations("gokz-playermodels.phrases");

	gH_PlayerModelCookie = new Cookie("gokz-playermodel", "", CookieAccess_Private);

	CreateConVars();
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

public void OnClientCookiesCached(int client)
{
	UpdatePlayerModel(client);
}

public void OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast) // player_spawn post hook 
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (IsValidClient(client))
	{
		// Can't use a timer here because it's not precise enough. We want exactly 2 ticks of delay!
		// 2 ticks is the minimum amount of time after which gloves will work.
		// The reason we need precision is because SetEntityModel momentarily resets the
		// player hull to standing (or something along those lines), so when a player
		// spawns/gets reset to a crouch tunnel where there's a trigger less than 18 units from the top
		// of the ducked player hull, then they touch that trigger! SetEntityModel interferes with the
		// fix for that (JoinTeam in gokz-core/misc calls TeleportPlayer in gokz.inc, which fixes that bug).
		RequestFrame(RequestFrame_UpdatePlayerModel, GetClientUserId(client));
	}
}



// =====[ OTHER EVENTS ]=====

public void OnMapStart()
{
	LoadPlayerModels();
}



// =====[ GENERAL ]=====

void HookEvents()
{
	HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Post);
}



// =====[ CONVARS ]=====

void CreateConVars()
{
	AutoExecConfig_SetFile("gokz-playermodels", "sourcemod/gokz");
	AutoExecConfig_SetCreateFile(true);
	
	gCV_gokz_player_models_alpha = AutoExecConfig_CreateConVar("gokz_player_models_alpha", "255", "Amount of alpha (transparency) to set player models to.", _, true, 0.0, true, 255.0);
	gCV_gokz_player_models_alpha.AddChangeHook(OnConVarChanged);
	
	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();
	
	gCV_sv_disable_immunity_alpha = FindConVar("sv_disable_immunity_alpha");
}

public void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (convar == gCV_gokz_player_models_alpha)
	{
		for (int client = 1; client <= MaxClients; client++)
		{
			if (IsClientInGame(client) && IsPlayerAlive(client))
			{
				UpdatePlayerModelAlpha(client);
			}
		}
	}
}



// =====[ PLAYER MODELS ]=====

public void RequestFrame_UpdatePlayerModel(int userid)
{
	RequestFrame(RequestFrame_UpdatePlayerModel2, userid);
}

public void RequestFrame_UpdatePlayerModel2(int userid)
{
	int client = GetClientOfUserId(userid);
	if (!IsValidClient(client) || !IsPlayerAlive(client))
	{
		return;
	}
	
	char playerModel[256];
	GetDesiredPlayerModel(client, playerModel, sizeof(playerModel));

	if (IsModelPrecached(playerModel))
	{
		SetEntityModel(client, playerModel);
	}
	
	UpdatePlayerModelAlpha(client);
}

void UpdatePlayerModelAlpha(int client)
{
	SetEntityRenderMode(client, RENDER_TRANSCOLOR);
	SetEntityRenderColor(client, _, _, _, gCV_gokz_player_models_alpha.IntValue);
}

bool LoadPlayerModels()
{
	gCV_sv_disable_immunity_alpha.IntValue = 1; // Ensures player transparency works

	KeyValues kv = new KeyValues("models");
	if (!kv.ImportFromFile(CFG_CUSTOM_MODELS) || !kv.GotoFirstSubKey(true))
	{
		SetFailState("playermodels config missing");
	}

	delete gH_PlayerModels;
	gH_PlayerModels = new ArrayList(sizeof(PlayerModel));

	ArrayList tempFiles = new ArrayList(256);
	char fileName[256];
	PlayerModel playerModel;

	// Add default player model
	playerModel.Name = "Default";
	playerModel.Path = DEFAULT_PLAYER_MODEL;
	gH_PlayerModels.PushArray(playerModel, sizeof(playerModel));
	PrecacheModel(DEFAULT_PLAYER_MODEL, true);

	do
	{
		if (!kv.GetSectionName(playerModel.Name, sizeof(playerModel.Name)) || !kv.GotoFirstSubKey(false))
		{
			continue;
		}

		tempFiles.Clear();
		bool failed = false;
		bool hasMdl = false;

		do
		{
			if (!kv.GetSectionName(fileName, sizeof(fileName)) || !FileExists(fileName))
			{
				failed = true;
				break;
			}

			if (!hasMdl)
			{
				int length = strlen(fileName);
				int dotpos = 0;
				for (int i = 0; i < length; i++)
				{
					if (fileName[i] == '.')
					{
						dotpos = i;
					}
				}
				if (StrEqual(fileName[dotpos + 1], "mdl", false))
				{
					hasMdl = true;
					playerModel.Path = fileName;
				}
			}

			tempFiles.PushString(fileName);
		}
		while (kv.GotoNextKey(false));

		if (!failed && hasMdl)
		{
			gH_PlayerModels.PushArray(playerModel, sizeof(playerModel));

			PrecacheModel(playerModel.Path, true);
			for (int i = 0; i < tempFiles.Length; i++)
			{
				tempFiles.GetString(i, fileName, sizeof(fileName));
				AddFileToDownloadsTable(fileName);
			}
		}
		else
		{
			LogError("Failed loading model: %s", playerModel.Name);
		}

		kv.GoBack();
	}
	while (kv.GotoNextKey(true));

	delete tempFiles;
	delete kv;
	return true;
}

void GetDesiredPlayerModel(int client, char[] path, int maxlength)
{
	char cookieValue[256];
	gH_PlayerModelCookie.Get(client, cookieValue, sizeof(cookieValue));

	if (cookieValue[0] == 0 || !IsModelPrecached(cookieValue))
	{
		strcopy(path, maxlength, DEFAULT_PLAYER_MODEL);
	}
	else
	{
		strcopy(path, maxlength, cookieValue);
	}
}



// =====[ MODEL MENU ]=====

void DisplayPlayerModelMenu(int client)
{
	Menu menu = new Menu(MenuHandler_PlayerModel);
	menu.SetTitle("%T", "Player Model Menu - Title", client);
	PlayerModelMenuAddItems(client, menu);
	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_PlayerModel(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		char info[256];
		menu.GetItem(param2, info, sizeof(info));

		gH_PlayerModelCookie.Set(param1, info);
		UpdatePlayerModel(param1);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
}

void PlayerModelMenuAddItems(int client, Menu menu)
{
	char currentModel[256];
	GetDesiredPlayerModel(client, currentModel, sizeof(currentModel));

	PlayerModel playerModel;
	for (int i = 0; i < gH_PlayerModels.Length; i++)
	{
		gH_PlayerModels.GetArray(i, playerModel);

		bool star = StrEqual(currentModel, playerModel.Path);
		if (star)
		{
			char line[256];
			Format(line, sizeof(line), "%s*", playerModel.Name);

			menu.AddItem(playerModel.Path, line);
		}
		else
		{
			menu.AddItem(playerModel.Path, playerModel.Name);
		}
	}
}



// =====[ COMMANDS ]=====

void RegisterCommands()
{
	RegConsoleCmd("sm_model", CommandModel);
}

public Action CommandModel(int client, int argc)
{
	DisplayPlayerModelMenu(client);
	return Plugin_Handled;
}

