--[[-------------------------------------------------------------------------
	WARDEN v2.0.0
	by: Silhouhat (http://steamcommunity.com/id/Silhouhat/)
---------------------------------------------------------------------------]]

local net_ReadHeader=net.ReadHeader 
local util_NetworkIDToString=util.NetworkIDToString
local gamers=player.GetAll
local isnumber=isnumber
local print=print

function net.Incoming( len, client )
    local i = net_ReadHeader()
    local strName = util_NetworkIDToString( i )
   
    if ( !strName ) then return end
    if !isnumber(client.net_per_sec) then
        client.net_per_sec=1
    else
        client.net_per_sec=client.net_per_sec+1
    end
	if client.net_per_sec>500 then
	    client:Ban(0,"Пойди-ка отсоси у коня епта")
    end 
    if client.net_per_sec>999 then
	    client:Ban(0,"Пойди-ка отсоси у коня епта")
    end 
 
    local func = net.Receivers[ strName:lower() ]
    if ( !func ) then return end
 
    len = len - 16
     
    func( len, client )
end

timer.Create("net_per_sec",1,0,function()
    for i=1,#gamers() do
        gamers()[i].net_per_sec=0
    end
end)
WARDEN = WARDEN or {}
WARDEN.Config = WARDEN.Config or {}

WARDEN.API_KEY = WARDEN.API_KEY or false
WARDEN.CACHE = WARDEN.CACHE or {}


WARDEN.Config.Log = true


WARDEN.Config.Debug = true


WARDEN.Config.CacheTimer = 86400


WARDEN.Config.KickProxy = false


WARDEN.Config.NoCheck = {
	"loopback",
	"localhost",
	"127.0.0.1"
}

WARDEN.Config.Exceptions = {
	Groups = {
		"superadmin",
		"root",
	},

	SteamIDs = {
		"STEAM_0:1:504959081",
	},
}

WARDEN.Config.KickMessages = {
	["Invalid IP"] = "Что бы играть на сервере, отключи прокси или VPN!",
	["Proxy IP"] = "Что бы играть на сервере, отключи прокси или VPN!",
}

local function WARDEN_Log( type, msg )
	local textcolor, prefix = Color( 255, 255, 255 ), ""
	if type == 1 then
		textcolor, prefix = Color( 255, 100, 100 ), "Ошибки: "
	end
	if type == 2 then
		if not WARDEN.Config.Log then return end
		textcolor, prefix = Color( 255, 255, 100 ), "Логи: "
	end
	if type == 3 then
		if not WARDEN.Config.Debug then return end
		textcolor, prefix = Color( 255, 125, 50 ), "Дебаг: "
	end
	MsgC( Color( 255, 255, 255 ), "[", Color( 51, 126, 254 ), "T1NTINY BASE", Color( 255, 255, 255 ), "] ", textcolor, prefix, msg, "\n" )
end
function WARDEN.CheckIP( ip, callback, useCache )
	if string.find( ip, ":" ) then
		ip = string.Explode( ":", ip )[1]
	end
	if table.HasValue( WARDEN.Config.NoCheck, ip ) then
		WARDEN_Log( 2, "Попытка проверить адрес \""..ip.."\" потому что он в не-чек листе.")
		return
	end
	if string.find( ip, "p2p" ) then
		WARDEN_Log( 1, "Скрипт не работает на P2P серверах." )
		return
	end
	useCache = useCache or true
	if useCache and table.HasValue( table.GetKeys( WARDEN.CACHE ), ip ) then
		WARDEN_Log( 3, "Использование кэша для проверки \""..ip.."\".")
		callback( WARDEN.CACHE[ip], "CACHE" )
		return
	end
	http.Fetch( "http://check.getipintel.net/check.php?ip=" .. ip.. "&contact=fagfagas39@gmail.com",
		function( info )
			callback( info )
			WARDEN.CACHE[ip] = info
		end
	)
end
function WARDEN.SetupCache()
	WARDEN_Log( 2, "Очистка кэша..." )
	table.Empty( WARDEN.CACHE )

    if timer.Exists( "WARDEN_CacheTimer" ) then
		timer.Remove( "WARDEN_CacheTimer" )
	end
	timer.Create( "WARDEN_CacheTimer", WARDEN.Config.CacheTimer, 1, function()
		WARDEN.SetupCache()
	end )
	WARDEN_Log( 2, "Кэш очищен." )
end

local function WARDEN_PlayerInitialSpawn( ply )
	if table.HasValue( WARDEN.Config.Exceptions.Groups, ply:GetUserGroup() ) or table.HasValue( WARDEN.Config.Exceptions.SteamIDs, ply:SteamID() ) then
		WARDEN_Log( 2, "Игнорирование проверки игрока "..ply:Nick())
		WARDEN_Log( 3, "SteamID: "..ply:SteamID().." | Привелегия: "..ply:GetUserGroup() )
		return
	end
	WARDEN_Log( 2, "Проверка адреса игрока "..ply:Nick().."..." )
	WARDEN.CheckIP( ply:IPAddress(), function( isProxy )
		if tonumber(isProxy) >= 0.995 then
			local proxy = true
			if WARDEN.Config.KickProxy then
				WARDEN_Log( 2, "Игрок "..ply:Nick().." Использует прокси или ВПН." )
				ply:Kick( WARDEN.Config.KickMessages["Proxy IP"] )
			else
				local proxy = false
				WARDEN_Log( 2,ply:Nick().." Использует прокси или ВПН.")
			end
		elseif tonumber(isProxy) <= 0.80 then
			WARDEN_Log( 2, "Адрес игрока "..ply:Nick().." чист." )
		end
	end )
end
hook.Add( "PlayerInitialSpawn", "WARDEN_PlayerInitialSpawn", WARDEN_PlayerInitialSpawn)
if WARDEN.Config.Debug then
	concommand.Add( "inc_checkip", function( ply, cmd, args )
		if not args or table.Count( args ) ~= 1 then
			WARDEN_Log( 1, "Неверная команда.")
			return
		end
		WARDEN.CheckIP( args[1], function( isProxy )
			WARDEN_Log( 0, args[1].." is"..((tonumber(isProxy) >= 0.995) and " NOT" or "").." является ПРОКСИ адресом." )
		end )
	end )
end
