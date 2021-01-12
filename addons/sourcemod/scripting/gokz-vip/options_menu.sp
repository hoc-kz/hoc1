static TopMenu optionsTopMenu;
static TopMenuObject catVIP;
static TopMenuObject itemsVIP[VIPOPTION_COUNT];



// =====[ EVENTS ]=====

void OnOptionsMenuCreated_OptionsMenu(TopMenu topMenu)
{
	if (optionsTopMenu == topMenu && catVIP != INVALID_TOPMENUOBJECT)
	{
		return;
	}
	
	catVIP = topMenu.AddCategory(VIP_OPTION_CATEGORY, TopMenuHandler_Categories);
}

void OnOptionsMenuReady_OptionsMenu(TopMenu topMenu)
{
	// Make sure category exists
	if (catVIP == INVALID_TOPMENUOBJECT)
	{
		GOKZ_OnOptionsMenuCreated(topMenu);
	}
	
	if (optionsTopMenu == topMenu)
	{
		return;
	}
	
	optionsTopMenu = topMenu;
	
	// Add VIP option items	
	for (int option = 0; option < view_as<int>(VIPOPTION_COUNT); option++)
	{
		itemsVIP[option] = optionsTopMenu.AddItem(gC_VIPOptionNames[option], TopMenuHandler_VIP, catVIP);
	}
}

public void TopMenuHandler_Categories(TopMenu topmenu, TopMenuAction action, TopMenuObject topobj_id, int param, char[] buffer, int maxlength)
{
	if (action == TopMenuAction_DisplayOption || action == TopMenuAction_DisplayTitle)
	{
		if (topobj_id == catVIP)
		{
			Format(buffer, maxlength, "%T", "Options Menu - VIP", param);
		}
	}
}

public void TopMenuHandler_VIP(TopMenu topmenu, TopMenuAction action, TopMenuObject topobj_id, int param, char[] buffer, int maxlength)
{
	VIPOption option = VIPOPTION_INVALID;
	for (int i = 0; i < view_as<int>(VIPOPTION_COUNT); i++)
	{
		if (topobj_id == itemsVIP[i])
		{
			option = view_as<VIPOption>(i);
			break;
		}
	}
	
	if (option == VIPOPTION_INVALID)
	{
		return;
	}
	
	if (action == TopMenuAction_DisplayOption)
	{
		switch (option)
		{
			case VIPOption_PlayerModel:
			{
				char modelName[64];
				GOKZ_PM_GetPlayerModelDisplayName(param, modelName, sizeof(modelName));

				FormatEx(buffer, maxlength, "%T - %s", 
					gC_VIPOptionPhrases[option], param,
					modelName);
			}
			case VIPOption_ChatNameColor:
			{
				FormatEx(buffer, maxlength, "%T - %T", 
					gC_VIPOptionPhrases[option], param, 
					gC_ChatNameColorPhrases[GOKZ_VIP_GetOption(param, option)], param);
			}
			case VIPOption_HookColor:
			{
				FormatEx(buffer, maxlength, "%T - %T", 
					gC_VIPOptionPhrases[option], param, 
					gC_HookColorPhrases[GOKZ_VIP_GetOption(param, option)], param);
			}
			default:FormatToggleableOptionDisplay(param, option, buffer, maxlength);
		}
	}
	else if (action == TopMenuAction_SelectOption)
	{
		if (option == VIPOption_PlayerModel)
		{
			GOKZ_PM_DisplayPlayerModelMenu(param, true);
		}
		else 
		{
			GOKZ_VIP_CycleOption(param, option);
			optionsTopMenu.Display(param, TopMenuPosition_LastCategory);
		}
	}
}



// =====[ PRIVATE ]=====

static void FormatToggleableOptionDisplay(int client, VIPOption option, char[] buffer, int maxlength)
{
	if (GOKZ_VIP_GetOption(client, option) == 0)
	{
		FormatEx(buffer, maxlength, "%T - %T", 
			gC_VIPOptionPhrases[option], client, 
			"Options Menu - Disabled", client);
	}
	else
	{
		FormatEx(buffer, maxlength, "%T - %T", 
			gC_VIPOptionPhrases[option], client, 
			"Options Menu - Enabled", client);
	}
} 