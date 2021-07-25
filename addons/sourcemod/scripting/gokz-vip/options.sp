/*
	Options for controlling VIP features.
*/



// =====[ EVENTS ]=====

void OnOptionsMenuReady_Options()
{
	RegisterOptions();
}



// =====[ PRIVATE ]=====

static void RegisterOptions()
{
	for (VIPOption option; option < VIPOPTION_COUNT; option++)
	{
		GOKZ_RegisterOption(gC_VIPOptionNames[option], gC_VIPOptionDescriptions[option], 
			OptionType_Int, gI_VIPOptionDefaults[option], 0, gI_VIPOptionCounts[option] - 1);
	}
}
