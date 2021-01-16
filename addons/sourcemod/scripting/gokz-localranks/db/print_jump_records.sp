/*
	Prints all of player's pb jumps, current and previous.
*/



void DB_PrintJumpRecords(int client, int targetSteamID, int jumpType, int mode, int isBlock)
{
	char query[1024];

	DataPack data = new DataPack();
	data.WriteCell(GetClientUserId(client));
	data.WriteCell(targetSteamID);
	data.WriteCell(jumpType);
	data.WriteCell(mode);
	data.WriteCell(isBlock);

	Transaction txn = SQL_CreateTransaction();

	// Retrieve name of target
	FormatEx(query, sizeof(query), sql_players_getalias, targetSteamID);
	txn.AddQuery(query);
	FormatEx(query, sizeof(query), sql_jumpstats_getallrecords, targetSteamID, jumpType, mode, isBlock);
	txn.AddQuery(query);

	SQL_ExecuteTransaction(gH_DB, txn, DB_TxnSuccess_PrintJumpRecords, DB_TxnFailure_Generic_DataPack, data, DBPrio_Low);
}

public void DB_TxnSuccess_PrintJumpRecords(Handle db, DataPack data, int numQueries, Handle[] results, any[] queryData)
{
	data.Reset();
	int client = GetClientOfUserId(data.ReadCell());
	int targetSteamID = data.ReadCell();
	int jumpType = data.ReadCell();
	int mode = data.ReadCell();
	int isBlock = data.ReadCell();
	delete data;
	
	if (!IsValidClient(client))
	{
		return;
	}

	char alias[33];
	if (SQL_FetchRow(results[0]))
	{
		SQL_FetchString(results[0], 0, alias, sizeof(alias));
	}

	char buffer[128];
	if (isBlock)
	{
		FormatEx(buffer, sizeof(buffer), "%T", "Print Jump Records - Block Jump Console Header", client, gC_ModeNames[mode], alias, targetSteamID & 1, targetSteamID >> 1);
	}
	else
	{
		FormatEx(buffer, sizeof(buffer), "%T", "Print Jump Records - Jump Console Header", client, gC_ModeNames[mode], alias, targetSteamID & 1, targetSteamID >> 1);
	}
	PrintToConsole(client, "%s", buffer);
	int titleLength = strlen(buffer);
	strcopy(buffer, sizeof(buffer), "----------------------------------------------------------------");
	buffer[titleLength] = '\0';
	PrintToConsole(client, "%s", buffer);

	char createdDate[32];
	while (SQL_FetchRow(results[1]))
	{
		float distance = SQL_FetchFloat(results[1], 0) / GOKZ_DB_JS_DISTANCE_PRECISION;
		int block = SQL_FetchInt(results[1], 1);
		int strafes = SQL_FetchInt(results[1], 2);
		float sync = SQL_FetchFloat(results[1], 3) / GOKZ_DB_JS_SYNC_PRECISION;
		float pre = SQL_FetchFloat(results[1], 4) / GOKZ_DB_JS_PRE_PRECISION;
		float max = SQL_FetchFloat(results[1], 5) / GOKZ_DB_JS_MAX_PRECISION;
		int overlap = SQL_FetchInt(results[1], 6);
		int deadair = SQL_FetchInt(results[1], 7);
		int releaseW = SQL_FetchInt(results[1], 8);
		float airtime = SQL_FetchFloat(results[1], 9) / GOKZ_DB_JS_AIRTIME_PRECISION;
		SQL_FetchString(results[1], 10, createdDate, sizeof(createdDate));

		if (isBlock)
		{
			if (jumpType == JumpType_LongJump || jumpType == JumpType_LadderJump || jumpType == JumpType_WeirdJump)
			{
				PrintToConsole(client, "%s  %d %t (%0.4f)  [%d %t | %.2f%% %t | %.2f %t | %.2f %t | %.4f %t | %d %t | %d %t | %d %t]", 
					createdDate, block, "Block", distance, strafes, "Strafes", sync, "Sync", pre, "Pre", max, "Max", 
					airtime, "Air", overlap, "Overlap", deadair, "DeadAir", releaseW, "ReleaseW");
			}
			else
			{
				PrintToConsole(client, "%s  %d %t (%0.4f)  [%d %t | %.2f%% %t | %.2f %t | %.2f %t | %.4f %t | %d %t | %d %t]", 
					createdDate, block, "Block", distance, strafes, "Strafes", sync, "Sync", pre, "Pre", max, "Max", 
					airtime, "Air", overlap, "Overlap", deadair, "DeadAir");
			}
		}
		else
		{
			if (jumpType == JumpType_LongJump || jumpType == JumpType_LadderJump || jumpType == JumpType_WeirdJump)
			{
				PrintToConsole(client, "%s  %0.4f  [%d %t | %.2f%% %t | %.2f %t | %.2f %t | %.4f %t | %d %t | %d %t | %d %t]", 
					createdDate, distance, strafes, "Strafes", sync, "Sync", pre, "Pre", max, "Max", 
					airtime, "Air", overlap, "Overlap", deadair, "DeadAir", releaseW, "ReleaseW");
			}
			else
			{
				PrintToConsole(client, "%s  %0.4f  [%d %t | %.2f%% %t | %.2f %t | %.2f %t | %.4f %t | %d %t | %d %t]", 
					createdDate, distance, strafes, "Strafes", sync, "Sync", pre, "Pre", max, "Max", 
					airtime, "Air", overlap, "Overlap", deadair, "DeadAir");
			}
		}
	}

	PrintToConsole(client, "");	
}

