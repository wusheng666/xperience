local MySQLReady, QBCore, ESX = false, nil, nil
local Xperience = {}

MySQL.ready(function()
    MySQLReady = true
end)

function Xperience:Init()
    while not MySQLReady do Wait(5) end

    self.ready = false

    local Ranks = self:CheckRanks()
    
    if #Ranks > 0 then
        PrintTable(Ranks)
        return
    end

    -- Initialize framework based on Config.Framework
    if Config.Framework == 'qbcore' then
        local status = GetResourceState('qb-core')
        if status ~= 'started' then
            return printError(string.format('QBCORE is %s!', status))
        end

        QBCore = exports['qb-core']:GetCoreObject()
    elseif Config.Framework == 'esx' then
        local status = GetResourceState('es_extended')
        if status ~= 'started' then
            return printError(string.format('ESX is %s!', status))
        end

        ESX = exports['es_extended']:getSharedObject()
    elseif Config.Framework ~= 'standalone' then
        return printError(string.format('Invalid framework "%s"! Valid options are: qbcore, esx, standalone', Config.Framework))
    end

    self.ready = true
end

function Xperience:Load(src)
    src = tonumber(src)

    if self.ready then
        local resp, result = false, false

        if Config.Framework == 'qbcore' then
            local Player = QBCore.Functions.GetPlayer(src)
            if Player then
                result = {}
                result.xp = tonumber(Player.PlayerData.metadata.xp) or 0
                result.rank = tonumber(Player.PlayerData.metadata.rank) or 1
                
                resp = true
            end
        else
            local license = self:GetPlayer(src)
            
            if Config.Framework == 'esx' then
                local statement = 'SELECT * FROM users WHERE license = @license'

                if Config.ESXIdentifierColumn == 'identifier' then
                    statement = 'SELECT * FROM users WHERE identifier = @license'
                end
                
                MySQL.Async.fetchAll(statement, { ['@license'] = license }, function(res)
                    if res[1] then
                        result = {}
                        result.xp = tonumber(res[1].xp) or 0
                        result.rank = tonumber(res[1].rank) or 1

                        local Player = ESX.GetPlayerFromId(src)
                        Player.set("xp", result.xp)
                        Player.set("rank", result.rank)
                    else
                        -- Create default values for new players
                        result = {
                            xp = 0,
                            rank = 1
                        }
                        
                        -- Insert default values for new player
                        local insertStatement = 'INSERT INTO users (license, xp, rank) VALUES (@license, @xp, @rank)'
                        if Config.ESXIdentifierColumn == 'identifier' then
                            insertStatement = 'INSERT INTO users (identifier, xp, rank) VALUES (@license, @xp, @rank)'
                        end
                        
                        MySQL.Async.execute(insertStatement, {
                            ['@license'] = license,
                            ['@xp'] = 0,
                            ['@rank'] = 1
                        })
                        
                        local Player = ESX.GetPlayerFromId(src)
                        Player.set("xp", 0)
                        Player.set("rank", 1)
                    end
                    
                    resp = true
                end)
            else -- Standalone mode
                MySQL.Async.fetchAll('SELECT * FROM user_experience WHERE identifier = @license', { ['@license'] = license }, function(res)
                    if res[1] then
                        result = {}
                        result.xp = tonumber(res[1].xp) or 0
                        result.rank = tonumber(res[1].rank) or 1
                    else
                        -- Create default values for new players
                        result = {
                            xp = 0,
                            rank = 1
                        }
                        
                        -- Insert default values for new player
                        MySQL.Async.execute('INSERT INTO user_experience (identifier, xp, rank) VALUES (@identifier, @xp, @rank)', {
                            ['@identifier'] = license,
                            ['@xp'] = 0,
                            ['@rank'] = 1
                        })
                    end
                    
                    resp = true
                end)
            end
        end

        -- Add timeout to prevent infinite blocking
        local timeout = 0
        while not resp and timeout < 100 do 
            Wait(100) 
            timeout = timeout + 1
        end
        
        -- If still not responding after timeout, set default values
        if not resp then
            result = {
                xp = 0,
                rank = 1
            }
            print(string.format("^1LOAD TIMEOUT FOR PLAYER: %s - Using default values^7", GetPlayerName(src)))
        end

        if Config.Debug then
            print(string.format("^5LOADED DATA FOR PLAYER: %s (XP %s, Rank %s)^7", GetPlayerName(src), result.xp, result.rank))
        end

        TriggerClientEvent('xperience:client:init', src, result)
    end
end

function Xperience:Save(src, xp, rank)
    if Config.Framework == 'qbcore' then
        local Player = QBCore.Functions.GetPlayer(src)

        Player.Functions.SetMetaData('xp', tonumber(xp))
        Player.Functions.SetMetaData('rank', tonumber(rank))
        Player.Functions.Save()
    else
        local license = self:GetPlayer(src)
        if Config.Framework == 'esx' then
            local Player = ESX.GetPlayerFromId(src)

            Player.set("xp", tonumber(xp))
            Player.set("rank", tonumber(rank))

            local statement = 'UPDATE users SET xp = @xp, rank = @rank WHERE license = @license'

            if Config.ESXIdentifierColumn == 'identifier' then
                statement = 'UPDATE users SET xp = @xp, rank = @rank WHERE identifier = @license'
            end

            MySQL.Async.execute(statement, { ['@xp'] = xp, ['@rank'] = rank, ['@license'] = license }, function(affectedRows)
                if not affectedRows or affectedRows == 0 then
                    -- If no rows were affected, try to insert (for new players)
                    local insertStatement = 'INSERT INTO users (license, xp, rank) VALUES (@license, @xp, @rank)'
                    if Config.ESXIdentifierColumn == 'identifier' then
                        insertStatement = 'INSERT INTO users (identifier, xp, rank) VALUES (@license, @xp, @rank)'
                    end
                    
                    MySQL.Async.execute(insertStatement, { 
                        ['@license'] = license, 
                        ['@xp'] = xp, 
                        ['@rank'] = rank 
                    }, function(insertSuccess)
                        if not insertSuccess then
                            printError('There was a problem inserting the user\'s data!')
                        end
                    end)
                end
            end)
        else -- Standalone mode
            -- For standalone mode, use INSERT ... ON DUPLICATE KEY UPDATE or try UPDATE then INSERT
            MySQL.Async.execute('INSERT INTO user_experience (identifier, xp, rank) VALUES (@identifier, @xp, @rank) ON DUPLICATE KEY UPDATE xp = @xp, rank = @rank', 
                { ['@identifier'] = license, ['@xp'] = xp, ['@rank'] = rank }, function(affectedRows)
                if not affectedRows then
                    -- If the above query fails, try the UPDATE then INSERT approach
                    MySQL.Async.execute('UPDATE user_experience SET xp = @xp, rank = @rank WHERE identifier = @identifier', 
                        { ['@xp'] = xp, ['@rank'] = rank, ['@identifier'] = license }, function(updateSuccess)
                        if not updateSuccess or updateSuccess == 0 then
                            -- If no rows were affected, try to insert (for new players)
                            MySQL.Async.execute('INSERT INTO user_experience (identifier, xp, rank) VALUES (@identifier, @xp, @rank)', 
                                { ['@identifier'] = license, ['@xp'] = xp, ['@rank'] = rank }, function(insertSuccess)
                                if not insertSuccess then
                                    printError('There was a problem inserting the user\'s data!')
                                end
                            end)
                        end
                    end)
                end
            end)
        end
    end

    if Config.Debug then
        print(string.format("^5SAVED DATA FOR PLAYER: %s (XP %s, Rank %s)^7", GetPlayerName(src), xp, rank))
    end
end

function Xperience:GetPlayerXP(playerId)
    if Config.Framework == 'qbcore' then
        local Player = QBCore.Functions.GetPlayer(playerId)

        if Player then
            return Player.PlayerData.metadata.xp
        end
    elseif Config.Framework == 'esx' then
        local Player = ESX.GetPlayerFromId(playerId)

        if Player then
            return tonumber(Player.get("xp"))
        end
    else -- Standalone mode
        local license = self:GetPlayer(playerId)
        local xp = MySQL.Sync.fetchScalar('SELECT xp FROM user_experience WHERE identifier = @license', {['@license'] = license })

        return tonumber(xp)
    end

    return false
end

function Xperience:GetPlayerRank(playerId)
    if Config.Framework == 'qbcore' then
        local Player = QBCore.Functions.GetPlayer(playerId)

        if Player then
            return Player.PlayerData.metadata.rank
        end
    elseif Config.Framework == 'esx' then
        local Player = ESX.GetPlayerFromId(playerId)
    
        if Player then
            return tonumber(Player.get("rank"))
        end
    else -- Standalone mode
        local license = self:GetPlayer(playerId)
        local rank = MySQL.Sync.fetchScalar('SELECT rank FROM user_experience WHERE identifier = @license', { ['@license'] = license })
    
        return tonumber(rank)
    end
end

function Xperience:GetPlayerXPToNextRank(playerId)
    local currentXP = self:GetPlayerXP(playerId)
    local currentRank = self:GetPlayerRank(playerId)

    -- Check if player is already at max rank
    if currentRank == #Config.Ranks then
        return 0
    end

    return tonumber(Config.Ranks[currentRank + 1].XP) - tonumber(currentXP)   
end

function Xperience:GetPlayerXPToRank(playerId, rank)
    local currentXP = self:GetPlayerXP(playerId)
    local rank = tonumber(rank)

    -- Check for valid rank
    if not rank or (rank < 1 or rank > #Config.Ranks) then
        printError('Invalid rank ('.. rank ..') passed to GetPlayerXPToRank method')
        return
    end

    local goalXP = tonumber(Config.Ranks[rank].XP)

    return goalXP - currentXP
end

-- Get player identifier function
-- Modified by: KamuNanyakk (cfx forum)
function Xperience:GetPlayer(src)
    if Config.Framework == 'esx' then 
        local xPlayer = ESX.GetPlayerFromId(src) 
        if xPlayer then 
            return xPlayer.identifier --  return steam:xxxx 
        end 
    elseif Config.Framework == 'qbcore' then
        local Player = QBCore.Functions.GetPlayer(src)
        if Player then
            return Player.PlayerData.citizenid -- return QBCore citizenid
        end
    else -- Standalone mode
        -- For standalone mode, get license identifier
        for _, identifier in ipairs(GetPlayerIdentifiers(src)) do
            if string.find(identifier, "license:") then
                return identifier
            end
        end
    end

    return false 
end


function Xperience:CheckRanks()
    local Limit = #Config.Ranks
    local InValid = {}

    for i = 1, Limit do
        local RankXP = Config.Ranks[i].XP

        if not isInt(RankXP) then
            table.insert(InValid, string.format('Rank %s: %s', i,  RankXP))
            printError(string.format('Invalid XP (%s) for Rank %s', RankXP, i))
        end
        
    end

    return InValid
end

function Xperience:RunCommand(src, type, args)
    local playerId = tonumber(args[1])
    local value = tonumber(args[2])
    
    if playerId ~= nil and value ~= nil then
        -- Check if player is online
        local playerName = GetPlayerName(playerId)
        if not playerName then
            return self:PrintError(src, 'Player is offline')
        end
        
        -- For ESX mode, we need to check GetPlayer
        -- For QBCore and Standalone modes, we already verified the player is online with GetPlayerName
        if Config.Framework == 'esx' then
            local player = self:GetPlayer(playerId)
            if not player then
                return self:PrintError(src, 'Player is offline')
            end
        end
        
        TriggerClientEvent('xperience:client:' .. type, playerId, value)
        
        -- Notify admin that command was executed
        if src ~= 0 then
            self:Notify(src, string.format('Executed %s on %s with value %s', type, playerName, value), 'success')
        end
    else
        return self:PrintError(src, 'Invalid arguments. Usage: /' .. type .. ' [playerId] [value]')
    end

    if Config.Debug then
        if src ~= 0 then
            print(string.format("^5PLAYER %s EXECUTED COMMAND %s^7", GetPlayerName(src), type))
        end
    end
end

function Xperience:Notify(src, message, type)
    if Config.Framework == 'qbcore' then
        TriggerClientEvent('QBCore:Notify', src, message, type)
    elseif Config.Framework == 'esx' then
        TriggerClientEvent('esx:showNotification', src, message)
    end  
end

function Xperience:Restart()
    CreateThread(function()
        for i, src in pairs(GetPlayers()) do
            self:Load(src)
        end
    end)
end

function Xperience:PrintError(src, message)
    if src > 0 then
        TriggerClientEvent('chat:addMessage', src, {
            color = { 255, 0, 0 },
            args = { "xperience", message }
        })

        self:Notify(src, message, 'error')
    else
        print(string.format("^1%s^7", message))
    end
end

CreateThread(function() Xperience:Init() end)


----------------------------------------------------
--                 EVENT HANDLERS                 --
----------------------------------------------------

RegisterNetEvent('xperience:server:load')
AddEventHandler('xperience:server:load', function() Xperience:Load(source) end)
RegisterNetEvent('xperience:server:save')
AddEventHandler('xperience:server:save',function(xp, rank) Xperience:Save(source, xp, rank) end)

----------------------------------------------------
--                    EXPORTS                     --
----------------------------------------------------

exports('GetPlayerXP', function(playerId) return Xperience:GetPlayerXP(playerId) end)
exports('GetPlayerRank', function(playerId) return Xperience:GetPlayerRank(playerId) end)
exports('GetPlayerXPToRank', function(playerId, rank) return Xperience:GetPlayerXPToRank(playerId, rank) end)
exports('GetPlayerXPToNextRank', function(playerId) return Xperience:GetPlayerXPToNextRank(playerId) end)


----------------------------------------------------
--                   COMMANDS                     --
----------------------------------------------------

-- Requires ace permissions: e.g. add_ace group.admin command.addXP allow

-- Allows for restarting the resource
RegisterCommand('restartXP', function(source, args) Xperience:Restart() end, true)

-- Award XP to player
RegisterCommand('addXP', function(source, args) Xperience:RunCommand(source, 'addXP', args) end, true)

-- Deduct XP from player
RegisterCommand('removeXP', function(source, args) Xperience:RunCommand(source, 'removeXP', args) end, true)

-- Set a player's XP
RegisterCommand('setXP', function(source, args) Xperience:RunCommand(source, 'setXP', args) end, true)

-- Set a player's rank
RegisterCommand('setRank', function(source, args) Xperience:RunCommand(source, 'setRank', args) end, true)
