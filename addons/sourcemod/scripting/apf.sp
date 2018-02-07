/**
 * =============================================================================
 * Anti Packets Flood
 * Protecting your server from flood-cheat
 *
 * File: apf.sp
 * Author: HlMod.Ru / http://hlmod.ru
 * =============================================================================
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * As a special exception, AlliedModders LLC gives you permission to link the
 * code of this program (as well as its derivative works) to "Half-Life 2," the
 * "Source Engine," the "SourcePawn JIT," and any Game MODs that run on software
 * by the Valve Corporation.  You must obey the GNU General Public License in
 * all respects for all other code used.  Additionally, AlliedModders LLC grants
 * this exception to all derivative works.  AlliedModders LLC defines further
 * exceptions, found in LICENSE.txt (as of this writing, version JULY-31-2007),
 * or <http://www.sourcemod.net/license.php>.
 *
 * Version: $Id$
 */

#include <sourcemod>

#pragma semicolon 1
#pragma newdecls required

int m_nTickBase;
bool ban[MAXPLAYERS + 1],
	apf_mode;

public Plugin myinfo =
{
	name		= "Anti Packets Flood",
	author		= "HlMod.Ru Community",
	version		= "1.0.1.4",
	url			= "http://hlmod.ru/threads/fix-sendnetmsg-kostyl-ot-lagov-chitami.43719/"
};

public void OnPluginStart()
{
	ConVar cvar;
	(cvar = CreateConVar("sm_apf_mode", "1", "0 - Kick / 1 - Ban", _, true, 0.0, true, 1.0)).AddChangeHook(OnModeChanged);
	apf_mode = cvar.BoolValue;

	if ((m_nTickBase = FindSendPropInfo("CCSPlayer", "m_nTickBase")) == -1)
    {
        SetFailState("Property not found CCSPlayer::m_nTickBase");
    }
}

public void OnModeChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	apf_mode = convar.BoolValue;
}

public void OnClientPutInServer(int client)
{
	ban[client] = false;
}

public Action OnPlayerRunCmd(int client)
{
	// If player is a fake client, there wills be an error in GetClientAvgPackets
	if (IsFakeClient(client) || ban[client])
	{
		return;
	}

	// Get client m_nTickBase. Check it
	Ban(client, GetEntData(client, m_nTickBase));
}

void Ban(int client, int tickbase)
{
	if (tickbase < 0)
	{
		ban[client] = true;
		LogToFileEx("addons/apf.log", "%L Tickbase (%d) is less than 0", client, tickbase);

		// Ban via command
		if (apf_mode)
		{
			ServerCommand("sm_ban #%d 0 \"Tickbase is less than 0\"", GetClientUserId(client));
		}
		// Kick client
		else
		{
			KickClient(client, "Tickbase is less than 0");
		}
	}
}