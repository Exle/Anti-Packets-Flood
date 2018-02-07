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

int inaccuracy,
	maxpackets;
NetFlow nf;

bool ban[MAXPLAYERS + 1];

public Plugin myinfo =
{
	name		= "Anti Packets Flood",
	author		= "HlMod.Ru Community",
	version		= "1.0.0.3",
	url			= "http://hlmod.ru/threads/fix-sendnetmsg-kostyl-ot-lagov-chitami.43719/"
};

public void OnPluginStart()
{
	ConVar cvar;
	(cvar = CreateConVar("sm_apf_inaccuracy", "100", "Inaccuracy of the number of packets", _, true, 0.0)).AddChangeHook(OnInaccuracyChanged);
	inaccuracy = cvar.IntValue;

	(cvar = CreateConVar("sm_apf_netflow", "2", "0 - outgoing traffic / 1 - incoming traffic / 2 - both values", _, true, 0.0, true, 2.0)).AddChangeHook(OnNetFlowChanged);
	maxpackets = GetMaxPackets((nf = view_as<NetFlow>(cvar.IntValue)));
}

// It is necessary that the maximum number of packets would be correct
public void OnConfigsExecuted()
{
	maxpackets = GetMaxPackets(nf);
}

int GetMaxPackets(NetFlow netfl)
{
	// sv_maxcmdrate - Max number of packets sent to server per second.
	if (netfl == NetFlow_Outgoing)		return FindConVar("sv_maxcmdrate").IntValue;
	// sv_maxupdaterate - Number of packets per second of updates you are requesting from the server.
	else if (netfl == NetFlow_Incoming)	return FindConVar("sv_maxupdaterate").IntValue;

	// Outgoing + incoming traffic.
	return FindConVar("sv_maxcmdrate").IntValue + FindConVar("sv_maxupdaterate").IntValue;
}

public void OnInaccuracyChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	inaccuracy = convar.IntValue;
}

public void OnNetFlowChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	maxpackets = GetMaxPackets((nf = view_as<NetFlow>(convar.IntValue)));
}

public void OnClientPutInServer(int client)
{
	ban[client] = false;
}

public Action OnPlayerRunCmd(int client)
{
	// If player is a fake client, there wills be an error in GetClientAvgPackets
	if (IsFakeClient(client))
	{
		return;
	}

	if (!ban[client])
	{
		// Get client average packet frequency in packets/sec. Check it
		Ban(client, GetClientAvgPackets(client, nf));
	}
	// Kick client if sm_ban not working
	//else KickClient(client, "You were banned for ddos by cheat");
}

void Ban(int client, float frequency)
{
	if (frequency > maxpackets + inaccuracy)
	{
		ban[client] = true;
		LogToFileEx("addons/apf.log", "%L Packet frequency exceeding (%.2f) out - (%.2f) inc - (%.2f) latency - (%.2f) loss - (%.2f) choke - (%.2f)",
			client, frequency, GetClientAvgPackets(client, NetFlow_Outgoing), GetClientAvgPackets(client, NetFlow_Incoming), GetClientAvgLatency(client, NetFlow_Outgoing), GetClientAvgLoss(client, NetFlow_Outgoing), GetClientAvgChoke(client, NetFlow_Outgoing));

		// Ban via command
		ServerCommand("sm_ban #%d 0 \"Packet frequency exceeding\"", GetClientUserId(client));
	}
}