/*
	gokz-vip Plugin Include
	
	Website: https://bitbucket.org/kztimerglobalteam/gokz
*/

#if defined _gokz_vip_included_
#endinput
#endif
#define _gokz_vip_included_



// =====[ ENUMS ]=====

enum VIPOption:
{
	VIPOPTION_INVALID = -1, 
	VIPOption_Test, 
	VIPOPTION_COUNT
};

enum
{
	Test_XD = 0, 
	Test_LOL,
	Test_KEKW, 
	TEST_COUNT
};



// =====[ CONSTANTS ]=====

#define VIP_OPTION_CATEGORY "VIP"

stock char gC_VIPOptionNames[VIPOPTION_COUNT][] = 
{
	"GOKZ VIP - Test"
};

stock char gC_VIPOptionDescriptions[VIPOPTION_COUNT][] = 
{
	"Test - 0 = XD, 1 = LOL, 2 = KEKW"
};

stock char gC_VIPOptionPhrases[VIPOPTION_COUNT][] = 
{
	"Options Menu - Test"
};

stock int gI_VIPOptionCounts[VIPOPTION_COUNT] = 
{
	TEST_COUNT
};

stock int gI_VIPOptionDefaults[VIPOPTION_COUNT] = 
{
	Test_XD
};

stock char gC_TestPhrases[TEST_COUNT][] = 
{
	"Options Menu - XD", 
	"Options Menu - LOL", 
	"Options Menu - KEKW"
};



// =====[ STOCKS ]=====

/**
 * Returns whether an option is a gokz-vip option.
 *
 * @param option		Option name.
 * @param optionEnum	Variable to store enumerated gokz-vip option (if it is one).
 * @return				Whether option is a gokz-vip option.
 */
stock bool GOKZ_VIP_IsVIPOption(const char[] option, VIPOption &optionEnum = VIPOPTION_INVALID)
{
	for (VIPOption i; i < VIPOPTION_COUNT; i++)
	{
		if (StrEqual(option, gC_VIPOptionNames[i]))
		{
			optionEnum = i;
			return true;
		}
	}
	return false;
}

/**
 * Gets the current value of a player's gokz-vip option.
 *
 * @param client		Client index.
 * @param option		gokz-vip option.
 * @return				Current value of option.
 */
stock any GOKZ_VIP_GetOption(int client, VIPOption option)
{
	return GOKZ_GetOption(client, gC_VIPOptionNames[option]);
}

/**
 * Sets a player's gokz-vip option's value.
 *
 * @param client		Client index.
 * @param option		gokz-vip option.
 * @param value			New option value.
 * @return				Whether option was successfully set.
 */
stock bool GOKZ_VIP_SetOption(int client, VIPOption option, any value)
{
	return GOKZ_SetOption(client, gC_VIPOptionNames[option], value);
}

/**
 * Increment an integer-type gokz-vip option's value.
 * Loops back to '0' if max value is exceeded.
 *
 * @param client		Client index.
 * @param option		gokz-vip option.
 * @return				Whether option was successfully set.
 */
stock bool GOKZ_VIP_CycleOption(int client, VIPOption option)
{
	return GOKZ_CycleOption(client, gC_VIPOptionNames[option]);
}



// =====[ DEPENDENCY ]=====

public SharedPlugin __pl_gokz_vip = 
{
	name = "gokz-vip", 
	file = "gokz-vip.smx", 
	#if defined REQUIRE_PLUGIN
	required = 1, 
	#else
	required = 0, 
	#endif
};
