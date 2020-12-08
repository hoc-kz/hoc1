/*
	Opens a menu with player profile.
*/

void DB_DisplayProfile(int client, int targetSteamID)
{
	char query[1024];

	Transaction txn = SQL_CreateTransaction();

	// Select generic profile information
	FormatEx(query, sizeof(query), sql_players_profile, targetSteamID);
	txn.AddQuery(query);
	// Select main course count
	txn.AddQuery(sql_getcount_maincourses);
	// Select NUB completed main courses 
	FormatEx(query, sizeof(query), sql_getcount_maincoursescompletedany, targetSteamID);
	txn.AddQuery(query);
	// Select PRO completed main courses
	FormatEx(query, sizeof(query), sql_getcount_maincoursescompletedproany, targetSteamID);
	txn.AddQuery(query);

	SQL_ExecuteTransaction(gH_DB, txn, DB_TxnSuccess_DisplayProfile, DB_TxnFailure_Generic, GetClientUserId(client), DBPrio_Low);
}

public void DB_TxnSuccess_DisplayProfile(Handle db, int userid, int numQueries, Handle[] results, any[] queryData)
{
	int client = GetClientOfUserId(userid);

	if (!IsValidClient(client))
	{
		return;
	}

	if (!SQL_FetchRow(results[0]) || !SQL_FetchRow(results[1]) || !SQL_FetchRow(results[2]) || !SQL_FetchRow(results[3]))
	{
		return;
	}

	char alias[MAX_NAME_LENGTH];
	char country[64];
	char lastPlayedDate[64];
	char createdDate[64];
	SQL_FetchString(results[0], 0, alias, sizeof(alias));
	SQL_FetchString(results[0], 1, country, sizeof(country));
	SQL_FetchString(results[0], 2, lastPlayedDate, sizeof(lastPlayedDate));
	SQL_FetchString(results[0], 3, createdDate, sizeof(createdDate));

	int mapsTotal = SQL_FetchInt(results[1], 0);
	int mapsCompletedNub = SQL_FetchInt(results[2], 0);
	int mapsCompletedPro = SQL_FetchInt(results[3], 0);

	DisplayProfile(client, alias, country, lastPlayedDate, createdDate, mapsTotal, mapsCompletedNub, mapsCompletedPro);
}

void DB_DisplayProfile_FindPlayer(int client, const char[] target)
{
	DataPack data = new DataPack();
	data.WriteCell(GetClientUserId(client));
	data.WriteString(target);

	DB_FindPlayer(target, DB_TxnSuccess_DisplayProfile_FindPlayer, data, DBPrio_Low);
}

public void DB_TxnSuccess_DisplayProfile_FindPlayer(Handle db, DataPack data, int numQueries, Handle[] results, any[] queryData)
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
		DB_DisplayProfile(client, SQL_FetchInt(results[0], 0));
	}
}

static void DisplayProfile(int client, char[] alias, char[] country, char[] lastPlayedDate, char[] createdDate, int mapsTotal, int mapsCompletedNub, int mapsCompletedPro)
{
	char buffer[64];
	Panel menu = new Panel();

	FormatEx(buffer, sizeof(buffer), "%t: %s", "Profile - Profile For", alias);
	menu.DrawText(buffer);
	FormatEx(buffer, sizeof(buffer), "%t: %s", "Profile - From", country);
	menu.DrawText(buffer);
	menu.DrawText(" ");

	FormatEx(buffer, sizeof(buffer), "%t: %s", "Profile - First Seen", createdDate);
	menu.DrawText(buffer);
	FormatEx(buffer, sizeof(buffer), "%t: %s", "Profile - Last Seen", lastPlayedDate);
	menu.DrawText(buffer);
	menu.DrawText(" ");

	float mapsCompletedNubPercent = 100.0 * (mapsCompletedNub / float(mapsTotal));
	float mapsCompletedProPercent = 100.0 * (mapsCompletedPro / float(mapsTotal));
	FormatEx(buffer, sizeof(buffer), "%t: %d/%d (%0.1f%%)", "Profile - NUB Completion", mapsCompletedNub, mapsTotal, mapsCompletedNubPercent);
	menu.DrawText(buffer);
	FormatEx(buffer, sizeof(buffer), "%t: %d/%d (%0.1f%%)", "Profile - PRO Completion", mapsCompletedPro, mapsTotal, mapsCompletedProPercent);
	menu.DrawText(buffer);
	menu.DrawText(" ");

	menu.CurrentKey = 9;
	menu.DrawItem("Exit", ITEMDRAW_DEFAULT);

	menu.Send(client, MenuHandler_Profile, MENU_TIME_FOREVER);
}

public int MenuHandler_Profile(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
	{
		delete menu;
	}
}

