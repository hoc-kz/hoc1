/*
	Opens a menu with player profile.
*/



static int profileSteamID[MAXPLAYERS + 1];
static char profileAlias[MAXPLAYERS + 1][MAX_NAME_LENGTH];
static char profileCountry[MAXPLAYERS + 1][64];
static char profileLastPlayedDate[MAXPLAYERS + 1][32];
static char profileCreatedDate[MAXPLAYERS + 1][32];
static int profileRank[MAXPLAYERS + 1];
static int profileMaxRank[MAXPLAYERS + 1];
static int profileLevel[MAXPLAYERS + 1];
static int profilePrestige[MAXPLAYERS + 1];
static int profileMapsTotal[MAXPLAYERS + 1];
static int profileMapsCompletedNub[MAXPLAYERS + 1];
static int profileMapsCompletedPro[MAXPLAYERS + 1];



void DB_OpenProfile(int client, int targetSteamID)
{
	char query[1024];

	Transaction txn = SQL_CreateTransaction();

	// Select generic profile information
	FormatEx(query, sizeof(query), sql_players_profile, targetSteamID);
	txn.AddQuery(query);
	// Select main course count
	txn.AddQuery(sql_getcount_maincourses);
	// Select NUB completed main courses 
	FormatEx(query, sizeof(query), sql_getcount_maincoursescompletedoverall, targetSteamID);
	txn.AddQuery(query);
	// Select PRO completed main courses
	FormatEx(query, sizeof(query), sql_getcount_maincoursescompletedprooverall, targetSteamID);
	txn.AddQuery(query);

	if (gB_GOKZLevels)
	{
		// Select level, rank information
		FormatEx(query, sizeof(query), sql_levels_rank_get, targetSteamID);
		txn.AddQuery(query);
		txn.AddQuery(sql_levels_maxrank_get);
		FormatEx(query, sizeof(query), sql_levels_get, targetSteamID);
		txn.AddQuery(query);
	}

	DataPack datapack = new DataPack();
	datapack.WriteCell(GetClientUserId(client));
	datapack.WriteCell(targetSteamID);

	SQL_ExecuteTransaction(gH_DB, txn, DB_TxnSuccess_OpenProfile, DB_TxnFailure_Generic_DataPack, datapack, DBPrio_Low);
}

public void DB_TxnSuccess_OpenProfile(Handle db, DataPack datapack, int numQueries, Handle[] results, any[] queryData)
{
	datapack.Reset();
	int client = GetClientOfUserId(datapack.ReadCell());
	int targetSteamID = datapack.ReadCell();
	delete datapack;

	if (!IsValidClient(client))
	{
		return;
	}

	profileSteamID[client] = targetSteamID;

	if (!SQL_FetchRow(results[0]) || !SQL_FetchRow(results[1]) || !SQL_FetchRow(results[2]) || !SQL_FetchRow(results[3]))
	{
		return;
	}

	SQL_FetchString(results[0], 0, profileAlias[client], sizeof(profileAlias[]));
	SQL_FetchString(results[0], 1, profileCountry[client], sizeof(profileCountry[]));
	SQL_FetchString(results[0], 2, profileLastPlayedDate[client], sizeof(profileLastPlayedDate[]));
	SQL_FetchString(results[0], 3, profileCreatedDate[client], sizeof(profileCreatedDate[]));

	profileMapsTotal[client] = SQL_FetchInt(results[1], 0);
	profileMapsCompletedNub[client] = SQL_FetchInt(results[2], 0);
	profileMapsCompletedPro[client] = SQL_FetchInt(results[3], 0);

	if (gB_GOKZLevels)
	{
		if (!SQL_FetchRow(results[4]) || !SQL_FetchRow(results[5]) || !SQL_FetchRow(results[6]))
		{
			return;
		}

		profileRank[client] = SQL_FetchInt(results[4], 0);
		profileMaxRank[client] = IntMax(profileRank[client], SQL_FetchInt(results[5], 0));
		profileLevel[client] = GOKZ_LV_LevelForExperience(SQL_FetchInt(results[6], 0));
		profilePrestige[client] = SQL_FetchInt(results[6], 1);
	}

	ReopenProfileMenu(client);
}

void DB_OpenProfile_FindPlayer(int client, const char[] target)
{
	DataPack data = new DataPack();
	data.WriteCell(GetClientUserId(client));
	data.WriteString(target);

	DB_FindPlayer(target, DB_TxnSuccess_OpenProfile_FindPlayer, data, DBPrio_Low);
}

public void DB_TxnSuccess_OpenProfile_FindPlayer(Handle db, DataPack data, int numQueries, Handle[] results, any[] queryData)
{
	data.Reset();
	int client = GetClientOfUserId(data.ReadCell());
	char playerSearch[MAX_NAME_LENGTH];
	data.ReadString(playerSearch, sizeof(playerSearch));
	delete data;

	if (!IsValidClient(client))
	{
		return;
	}

	if (SQL_GetRowCount(results[0]) == 0)
	{
		GOKZ_PrintToChat(client, true, "%t", "Player Not Found", playerSearch);
		return;
	}
	else if (SQL_FetchRow(results[0]))
	{
		DB_OpenProfile(client, SQL_FetchInt(results[0], 0));
	}
}

static void ReopenProfileMenu(int client)
{
	Menu menu = new Menu(MenuHandler_Profile);
	ProfileMenuSetTitle(client, menu);
	ProfileMenuAddItems(client, menu);
	menu.Display(client, MENU_TIME_FOREVER);
}

static void ProfileMenuSetTitle(int client, Menu menu)
{
	float mapsCompletedNubPercent = 100.0 * (profileMapsCompletedNub[client] / float(profileMapsTotal[client]));
	float mapsCompletedProPercent = 100.0 * (profileMapsCompletedPro[client] / float(profileMapsTotal[client]));

	if (gB_GOKZLevels)
	{
		menu.SetTitle("%T", "Profile Menu - Title", client, 
			profileAlias[client],
			profileCountry[client],
			profileRank[client], profileMaxRank[client],
			profileLevel[client],
			profilePrestige[client],
			profileCreatedDate[client],
			profileLastPlayedDate[client],
			profileMapsCompletedNub[client], profileMapsTotal[client], mapsCompletedNubPercent,
			profileMapsCompletedPro[client], profileMapsTotal[client], mapsCompletedProPercent);
	}
	else
	{
		menu.SetTitle("%T", "Profile Menu - Title (No Levels)", client, 
			profileAlias[client],
			profileCountry[client],
			profileCreatedDate[client],
			profileLastPlayedDate[client],
			profileMapsCompletedNub[client], profileMapsTotal[client], mapsCompletedNubPercent,
			profileMapsCompletedPro[client], profileMapsTotal[client], mapsCompletedProPercent);
	}
}

static void ProfileMenuAddItems(int client, Menu menu)
{
	char buffer[64];

	FormatEx(buffer, sizeof(buffer), "%T", "Profile Menu - Completed Maps", client, gC_TimeTypeNames[TimeType_Nub]);
	menu.AddItem("", buffer);
	FormatEx(buffer, sizeof(buffer), "%T", "Profile Menu - Completed Maps", client, gC_TimeTypeNames[TimeType_Pro]);
	menu.AddItem("", buffer);
	FormatEx(buffer, sizeof(buffer), "%T", "Profile Menu - Uncompleted Maps", client, gC_TimeTypeNames[TimeType_Nub]);
	menu.AddItem("", buffer);
	FormatEx(buffer, sizeof(buffer), "%T", "Profile Menu - Uncompleted Maps", client, gC_TimeTypeNames[TimeType_Pro]);
	menu.AddItem("", buffer);
}



// =====[ OVERALL MAP COMPLETION ]=====

static void DB_OpenProfileMapCompletion(int client, int targetSteamID, int timeType, bool completed)
{
	char query[1024];
	Transaction txn = SQL_CreateTransaction();

	// Get target name
	FormatEx(query, sizeof(query), sql_players_getalias, targetSteamID);
	txn.AddQuery(query);

	if (completed)
	{
		if (timeType == TimeType_Nub)
		{
			FormatEx(query, sizeof(query), sql_getcompletedmainmapcoursesoverall, targetSteamID);
		}
		else
		{
			FormatEx(query, sizeof(query), sql_getcompletedmainmapcoursesoverall_pro, targetSteamID);
		}
	}
	else
	{
		if (timeType == TimeType_Nub)
		{
			FormatEx(query, sizeof(query), sql_getuncompletedmainmapcoursesoverall, targetSteamID);
		}
		else
		{
			FormatEx(query, sizeof(query), sql_getuncompletedmainmapcoursesoverall_pro, targetSteamID);
		}	
	}	
	txn.AddQuery(query);

	DataPack datapack = new DataPack();
	datapack.WriteCell(GetClientUserId(client));
	datapack.WriteCell(timeType);
	datapack.WriteCell(completed);

	SQL_ExecuteTransaction(gH_DB, txn, DB_TxnSuccess_OpenProfileMapCompletion, DB_TxnFailure_Generic_DataPack, datapack, DBPrio_Low);
}

public void DB_TxnSuccess_OpenProfileMapCompletion(Handle db, DataPack datapack, int numQueries, Handle[] results, any[] queryData)
{
	datapack.Reset();
	int client = GetClientOfUserId(datapack.ReadCell());
	int timeType = datapack.ReadCell();
	bool completed = datapack.ReadCell();
	delete datapack;

	if (!IsValidClient(client))
	{
		return;
	}

	// Get target name
	if (!SQL_FetchRow(results[0]))
	{
		return;
	}
	char alias[MAX_NAME_LENGTH];
	SQL_FetchString(results[0], 0, alias, sizeof(alias));

	if (SQL_GetRowCount(results[1]) == 0)
	{
		if (timeType == TimeType_Nub)
		{
			if (completed)
			{
				GOKZ_PrintToChat(client, true, "%T", "Profile Map Completion - None Completed", client, alias);
			}
			else
			{
				GOKZ_PrintToChat(client, true, "%T", "Profile Map Completion - All Completed", client, alias);
			}
		}
		else
		{
			if (completed)
			{
				GOKZ_PrintToChat(client, true, "%T", "Profile Map Completion - None Completed (PRO)", client, alias);
			}
			else
			{
				GOKZ_PrintToChat(client, true, "%T", "Profile Map Completion - All Completed (PRO)", client, alias);
			}
		}
		ReopenProfileMenu(client);
		return;
	}

	Menu menu = new Menu(MenuHandler_ProfileMapCompletionSubmenu);
	if (completed)
	{
		menu.SetTitle("%T", "Profile Map Completion Submenu - Title (Completed)", client, gC_TimeTypeNames[timeType], alias);
	}
	else
	{
		menu.SetTitle("%T", "Profile Map Completion Submenu - Title (Uncompleted)", client, gC_TimeTypeNames[timeType], alias);
	}

	char buffer[128];
	while (SQL_FetchRow(results[1]))
	{
		SQL_FetchString(results[1], 0, buffer, sizeof(buffer));
		menu.AddItem("", buffer, ITEMDRAW_DISABLED);
	}

	menu.Display(client, MENU_TIME_FOREVER);
}



// =====[ MENU HANDLERS ]=====

public int MenuHandler_Profile(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		switch (param2)
		{
			case 0: DB_OpenProfileMapCompletion(param1, profileSteamID[param1], TimeType_Nub, true);
			case 1: DB_OpenProfileMapCompletion(param1, profileSteamID[param1], TimeType_Pro, true);
			case 2: DB_OpenProfileMapCompletion(param1, profileSteamID[param1], TimeType_Nub, false);
			case 3: DB_OpenProfileMapCompletion(param1, profileSteamID[param1], TimeType_Pro, false);
		}
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
}

public int MenuHandler_ProfileMapCompletionSubmenu(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Cancel && param2 == MenuCancel_Exit)
	{
		ReopenProfileMenu(param1);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
}
