#pragma semicolon 1;

#include <sourcemod>
#include <tf2_stocks>

#define PLUGIN_VERSION "1.3.0"

ConVar
	  hChat
	, hLog;

public Plugin myinfo = {
	name = "TF2 Set Class",
	author = "Tylerst, avi9526, JoinedSenses",
	description = "Set the target(s) class",
	version = PLUGIN_VERSION,
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
	char Game[32];
	GetGameFolderName(Game, sizeof(Game));
	if (!StrEqual(Game, "tf")) {
		Format(error, err_max, "This plugin only works for Team Fortress 2");
		return APLRes_Failure;
	}
	return APLRes_Success;
}

public void OnPluginStart() {
	CreateConVar("sm_setclass_version", PLUGIN_VERSION, "Set the target(s) class, Usage: sm_setclass \"target\" \"class\"", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	hChat = CreateConVar("sm_setclass_chat", "1", "Enable/Disable(1/0) Showing setclass changes in chat", FCVAR_NOTIFY);
	hLog = CreateConVar("sm_setclass_log", "1", "Enable/Disable(1/0) Logging of setclass changes", FCVAR_NOTIFY);
	
	RegAdminCmd("sm_setclass", Command_Setclass, ADMFLAG_GENERIC, "Usage: sm_setclass \"target\" \"class\"");
	RegAdminCmd("sm_class", Command_SetMyClass, ADMFLAG_GENERIC, "Usage: sm_class \"class\"");

	LoadTranslations("common.phrases");
}

public Action Command_Setclass(int client, int args) {
	if (args != 2) {
		ReplyToCommand(client, "[SM] Usage: sm_setclass \"target\" \"class\"");
	}
	else {
		char setclasstarget[MAX_NAME_LENGTH];
		char strclass[10];
		TFClassType class;
		char target_name[MAX_TARGET_LENGTH];
		int target_list[MAXPLAYERS];

		int target_count;
		bool tn_is_ml;

		GetCmdArg(1, setclasstarget, sizeof(setclasstarget));
		GetCmdArg(2, strclass, sizeof(strclass));

		if ((target_count = ProcessTargetString(
				setclasstarget,
				client,
				target_list,
				MAXPLAYERS,
				COMMAND_FILTER_CONNECTED,
				target_name,
				sizeof(target_name),
				tn_is_ml)) <= 0) {
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}
		if ((class = GetClassArg(client, strclass, sizeof(strclass))) == TFClass_Unknown) {
			return Plugin_Handled;
		}
		for (int i = 0; i < target_count; i++) {
			if (IsValidEntity(target_list[i])) {
				TF2_SetPlayerClass(target_list[i], class);
				if (IsPlayerAlive(target_list[i])) {
					SetEntityHealth(target_list[i], 25);
					TF2_RegeneratePlayer(target_list[i]);
					int weapon = GetPlayerWeaponSlot(target_list[i], TFWeaponSlot_Primary);
					if (IsValidEntity(weapon)) {
						SetEntPropEnt(target_list[i], Prop_Send, "m_hActiveWeapon", weapon);
					}
				}
				Event event = CreateEvent("player_changeclass", true);
				event.SetInt("userid", GetClientUserId(client));
				event.SetInt("class", view_as<int>(class));
				event.Fire();
			}
			if (hLog.BoolValue) {
				LogAction(client, target_list[i], "\"%L\" set class of  \"%L\" to (class %s)", client, target_list[i], strclass);
			}
		}
		if (hChat.BoolValue) {
			ShowActivity2(client, "[SM] ","Set class of %s to %s", target_name, strclass);
		}
	}
	return Plugin_Handled;
}

public Action Command_SetMyClass(int client, int args) {
	if (args != 1) {
		ReplyToCommand(client, "[SM] Usage: sm_class \"class\"");
	}
	else {
		char strclass[10];
		TFClassType class;
		GetCmdArg(1, strclass, sizeof(strclass));
		if ((class = GetClassArg(client, strclass, sizeof(strclass))) == TFClass_Unknown) {
			return Plugin_Handled;
		}
		if (IsValidEntity(client)) {
			TF2_SetPlayerClass(client, class);
			if (IsPlayerAlive(client)) {
				SetEntityHealth(client, 25);
				TF2_RegeneratePlayer(client);
				int weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
				if (IsValidEntity(weapon)) {
					SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
				}
			}
			Event event = CreateEvent("player_changeclass", true);
			event.SetInt("userid", GetClientUserId(client));
			event.SetInt("class", view_as<int>(class));
			event.Fire();
		}
		if (hLog.BoolValue) {
			LogAction(client, client, "\"%L\" set class to (class %s)", client, strclass);
		}
		if (hChat.BoolValue) {
			PrintToChat(client, "[SM] Your class was set to %s", strclass);
		}
	}
	return Plugin_Handled;
}

TFClassType GetClassArg(int client, char[] strClass, int size) {
	TFClassType class;

	if (StrEqual(strClass, "scout", false)) {
		class = TFClass_Scout;
		Format(strClass, size, "Scout");
	}
	else if (StrEqual(strClass, "soldier", false)) {
		class = TFClass_Soldier;
		Format(strClass, size, "Soldier");
	}
	else if (StrEqual(strClass, "pyro", false)) {
		class = TFClass_Pyro;
		Format(strClass, size, "Pyro");
	}
	else if (StrEqual(strClass, "demoman", false) || StrEqual(strClass, "demo", false)) {
		class = TFClass_DemoMan;
		Format(strClass, size, "Demoman");
	}
	else if (StrEqual(strClass, "heavy", false)) {
		class = TFClass_Heavy;
		Format(strClass, size, "Heavy");
	}
	else if (StrEqual(strClass, "engineer", false)) {
		class = TFClass_Engineer;
		Format(strClass, size, "Engineer");
	}
	else if (StrEqual(strClass, "medic", false)) {
		class = TFClass_Medic;
		Format(strClass, size, "Medic");
	}
	else if (StrEqual(strClass, "sniper", false)) {
		class = TFClass_Sniper;
		Format(strClass, size, "Sniper");
	}
	else if (StrEqual(strClass, "spy", false)) {
		class = TFClass_Spy;
		Format(strClass, size, "Spy");
	}
	else if (StrEqual(strClass, "random", false)) {
		class = view_as<TFClassType>(GetRandomInt(1, 9));
		Format(strClass, size, "Random");
	}
	else {
		ReplyToCommand(client, "[SM] Invalid Class (\"%s\")", strClass);
		return TFClass_Unknown;
	}
	return class;
}