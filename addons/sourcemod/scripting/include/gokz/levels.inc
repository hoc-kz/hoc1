/*
	gokz-levels Plugin Include
	
	Website: https://bitbucket.org/kztimerglobalteam/gokz
*/

#if defined _gokz_levels_included_
#endinput
#endif
#define _gokz_levels_included_



// =====[ CONSTANTS ]=====

#define GOKZ_LV_MAX_LEVEL 50
#define GOKZ_LV_JUMP_XP 100
#define GOKZ_LV_MAX_JUMPS_ON_ONE_INPUT 5
#define GOKZ_LV_TIME_BETWEEN_JUMPS 0.45

stock int gI_LevelChatColorPrestige0[GOKZ_LV_MAX_LEVEL + 1] = 
{
	0x5, 0x5, 0x5, 0x5, 0x5, 0x5, 0x5, 0x5, 0x5, 0x5, //  0 -  9
	0xB, 0xB, 0xB, 0xB, 0xB, 0xB, 0xB, 0xB, 0xB, 0xB, // 10 - 19
	0x7, 0x7, 0x7, 0x7, 0x7, 0x7, 0x7, 0x7, 0x7, 0x7, // 20 - 29
	0x3, 0x3, 0x3, 0x3, 0x3, 0x3, 0x3, 0x3, 0x3, 0x3, // 30 - 39
	0xE, 0xE, 0xE, 0xE, 0xE, 0xE, 0xE, 0xE, 0xE, 0xE, // 40 - 49
	0x10 // 50
};
#define LEVEL_CHAT_COLOR_PRESTIGE1 0x10



// =====[ FORWARDS ]=====

/**
 * Called when a player's level or prestige changes.
 *
 * @param client		Client index.
 * @param level			The level after the change.
 * @param prestige		The prestige after the change.
 */
forward void GOKZ_LV_OnLevelChanged(int client, int level, int prestige);



// =====[ NATIVES ]=====

/**
 * Gets the player's level experience.
 *
 * @param client		Client index.
 * @return				Player's level experience.
 */
native int GOKZ_LV_GetExperience(int client);

/**
 * Gets the player's level.
 *
 * @param client		Client index.
 * @return				Player's level.
 */
native int GOKZ_LV_GetLevel(int client);

/**
 * Gets the player's level prestige.
 *
 * @param client		Client index.
 * @return				Player's prestige level.
 */
native int GOKZ_LV_GetPrestige(int client);



// =====[ STOCKS ]=====

stock int GOKZ_LV_LevelForExperience(int experience)
{
	// Ported exactly from the original plugin config files.
	// Yes there is a mistake here and I'm keeping it.
	int level;
	if (experience >= 69120000)
	{
		level = 31 + ((experience - 69120000) / 8640000);
	}
	else if (experience >= 25920000) 
	{
        level = 21 + ((experience - 25920000) / 4320000);
    }
	else if (experience >= 2160000)
	{
		level = 10 + ((experience - 2160000) / 2160000);
	}
	else
	{
		level = experience / 216000;
	}
	return IntMin(level, GOKZ_LV_MAX_LEVEL);
}

stock int GOKZ_LV_FormatLevelTag(char[] buffer, int maxlength, int level, int prestige, bool colors)
{
	if (!colors)
	{
		return Format(buffer, maxlength, "[Lv%d]", level);
	}

	if (prestige >= 1)
	{
		int color = LEVEL_CHAT_COLOR_PRESTIGE1;
		return Format(buffer, maxlength, "\8[%cLv%d\8]", color, level);
	}

	int color = gI_LevelChatColorPrestige0[level];
	return Format(buffer, maxlength, "\8[%cLv%d\8]", color, level);
}



// =====[ DEPENDENCY ]=====

public SharedPlugin __pl_gokz_levels = 
{
	name = "gokz-levels", 
	file = "gokz-levels.smx", 
	#if defined REQUIRE_PLUGIN
	required = 1, 
	#else
	required = 0, 
	#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_gokz_levels_SetNTVOptional()
{
	MarkNativeAsOptional("GOKZ_LV_GetExperience");
	MarkNativeAsOptional("GOKZ_LV_GetLevel");
	MarkNativeAsOptional("GOKZ_LV_GetPrestige");
}
#endif
