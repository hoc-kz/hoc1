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
	if (experience >= 691200)
	{
		level = 31 + ((experience - 691200) / 86400);
	}
	else if (experience >= 259200) 
	{
        level = 21 + ((experience - 259200) / 43200);
    }
	else if (experience >= 21600)
	{
		level = 10 + ((experience - 21600) / 21600);
	}
	else
	{
		level = experience / 2160;
	}
	return IntMin(level, GOKZ_LV_MAX_LEVEL);
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
