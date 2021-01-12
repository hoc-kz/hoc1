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
	VIPOption_PlayerModel, 
	VIPOption_ChatNameColor,
	VIPOption_HookColor,
	VIPOPTION_COUNT
};

enum
{
	ChatNameColor_Grey = 0,
	ChatNameColor_Lime,
	ChatNameColor_Green,
	ChatNameColor_LightBlue, 
	ChatNameColor_Blue,
	ChatNameColor_Red,
	ChatNameColor_Purple,
	ChatNameColor_Orchid,
	CHATNAMECOLOR_COUNT
};

enum
{
	HookColor_Grey = 0, 
	HookColor_White,
	HookColor_Red, 
	HookColor_Green,
	HookColor_Blue,
	HookColor_Purple,
	HookColor_Yellow,
	HOOKCOLOR_COUNT
}



// =====[ CONSTANTS ]=====

#define VIP_OPTION_CATEGORY "VIP"

stock char gC_VIPOptionNames[VIPOPTION_COUNT][] = 
{
	"GOKZ VIP - Player Model",
	"GOKZ VIP - Chat Name Color",
	"GOKZ VIP - Hook Color"
};

stock char gC_VIPOptionDescriptions[VIPOPTION_COUNT][] = 
{
	"Player Model",
	"Chat Name Color",
	"Hook Color"
};

stock char gC_VIPOptionPhrases[VIPOPTION_COUNT][] = 
{
	"Options Menu - Player Model",
	"Options Menu - Chat Name Color",
	"Options Menu - Hook Color"
};

stock int gI_VIPOptionCounts[VIPOPTION_COUNT] = 
{
	999999,
	CHATNAMECOLOR_COUNT,
	HOOKCOLOR_COUNT
};

stock int gI_VIPOptionDefaults[VIPOPTION_COUNT] = 
{
	0,
	ChatNameColor_Grey,
	HookColor_Grey
};

stock char gC_ChatNameColorPhrases[CHATNAMECOLOR_COUNT][] = 
{
	"Options Menu - Grey", 
	"Options Menu - Lime", 
	"Options Menu - Green",
	"Options Menu - Light Blue", 
	"Options Menu - Blue",
	"Options Menu - Red",
	"Options Menu - Purple",
	"Options Menu - Orchid"
};

stock int gI_ChatNameColorValues[CHATNAMECOLOR_COUNT] =
{
	0x0A, // Grey
	0x06, // Lime
	0x04, // Green
	0x0B, // Light Blue
	0x0C, // Blue
	0x07, // Red
	0x03, // Purple
	0x0E, // Orchid
};

stock char gC_HookColorPhrases[HOOKCOLOR_COUNT][] = 
{
	"Options Menu - Grey", 
	"Options Menu - White", 
	"Options Menu - Red", 
	"Options Menu - Green",
	"Options Menu - Blue",
	"Options Menu - Purple",
	"Options Menu - Yellow"
};

stock int gI_HookColorValues[HOOKCOLOR_COUNT][4] =
{
	{128, 128, 128, 255}, // Grey
	{255, 255, 255, 255}, // White
	{255, 0,   0,   255}, // Red
	{0,   255, 0,   255}, // Green
	{0,   0,   255, 255}, // Blue
	{255, 0,   255, 255}, // Purple
	{255, 255, 0,   255}, // Yellow
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
