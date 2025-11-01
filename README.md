# xperience | 经验系统
XP Ranking System for FiveM | FiveM 经验排名系统

[English](#english) | [中文](#中文)

---

## English

* Designed to emulate the native GTA:O system
* Saves and loads players XP / rank
* Add / remove XP from your own script / job
* Allows you listen for rank changes to reward players
* Fully customisable UI
* Framework agnostic, but supports `ESX` and `QBCore`

##### Increasing XP

![Demo Image 1](https://i.imgur.com/CpACt9s.gif)

##### Rank Up

![Demo Image 2](https://i.imgur.com/uNPRGo5.gif)

## Table of Contents
* [Install](#install)
* [Transitioning from esx_xp](#transitioning-from-esx_xp)
* [Usage](#usage)
* [Client Side](#client-side)
  - [Client Exports](#client-exports)
  - [Client Events](#client-events)
* [Server Side](#server-side)
  - [Server Exports](#server-exports)
  - [Server Triggers](#server-triggers)
  - [Server Events](#server-events)
* [Rank Actions](#rank-actions)
* [QBCore Integration](#qbcore-integration)
* [ESX Integration](#esx-integration)
* [Admin Commands](#admin-commands)
* [Themes](#themes)
* [Custom Themes](#custom-themes)
* [FAQ](#faq)
* [License](#license)

## Install

Select an option:
* Option 1 - If you want to use `xperience` as a standalone resource then import `xperience_standalone.sql` only
* Option 2 - If using `ESX` with `Config.UseESX` set to `true` then import `xperience_esx.sql` only. This adds the `xp` and `rank` columns to the `users` table
    - If you're transitioning from `esx_xp`, then don't import `xperience_esx.sql`, instead see [Transitioning from esx_xp](#transitioning-from-esx_xp)
* Option 3 - If using `QBCore` with `Config.UseQBCore` set to `true` then there's no need to import any `sql` files as the xp and rank are saved to the player's metadata - see [QBCore Integration](#qbcore-integration)

then:

* Drop the `xperience` directory into you `resources` directory
* Add `ensure xperience` to your `server.cfg` file

By default this resource uses `oxmysql`, but if you don't want to use / install it then you can use `mysql-async` by following these instructions:

* Uncomment the `'@mysql-async/lib/MySQL.lua',` line in `fxmanifest.lua` and comment out the `'@oxmysql/lib/MySQL.lua'` line

## Transitioning from esx_xp
If you previously used `esx_xp` and are still using `es_extended` then do the following to make your current stored xp / rank data compatible with `xperience` 
* Rename the `rp_xp` column in the `users` table to `xp`
* Rename the `rp_rank` column in the `users` table to `rank`
* Set `Config.UseESX` to `true`

## Usage

### Client Side

#### Client Exports
Give XP to player
```lua
exports.xperience:AddXP(xp --[[ integer ]])
```

Take XP from player
```lua
exports.xperience:RemoveXP(xp --[[ integer ]])
```

Set player's XP
```lua
exports.xperience:SetXP(xp --[[ integer ]])
```

Set player's rank
```lua
exports.xperience:SetRank(rank --[[ integer ]])
```

Get player's XP
```lua
exports.xperience:GetXP()
```

Get player's rank
```lua
exports.xperience:GetRank()
```

Get XP required to rank up
```lua
exports.xperience:GetXPToNextRank()
```

Get XP required to reach defined rank
```lua
exports.xperience:GetXPToRank(rank --[[ integer ]])
```

#### Client Events

Listen for rank up event on the client
```lua
AddEventHandler("xperience:client:rankUp", function(newRank, previousRank, player)
    -- do something when player ranks up
end)
```

Listen for rank down event on the client
```lua
AddEventHandler("xperience:client:rankDown", function(newRank, previousRank, player)
    -- do something when player ranks down
end)
```

### Server Side

#### Server Exports
Get player's XP
```lua
exports.xperience:GetPlayerXP(playerId --[[ integer ]])
```

Get player's rank
```lua
exports.xperience:GetPlayerRank(playerId --[[ integer ]])
```

Get player's required XP to rank up
```lua
exports.xperience:GetPlayerXPToNextRank(playerId --[[ integer ]])
```

Get player's required XP to reach defined rank
```lua
exports.xperience:GetPlayerXPToRank(playerId --[[ integer ]], rank --[[ integer ]])
```

#### Server Triggers
```lua
TriggerClientEvent('xperience:client:addXP', playerId --[[ integer ]], xp --[[ integer ]])

TriggerClientEvent('xperience:client:removeXP', playerId --[[ integer ]], xp --[[ integer ]])

TriggerClientEvent('xperience:client:setXP', playerId --[[ integer ]], xp --[[ integer ]])

TriggerClientEvent('xperience:client:setRank', playerId --[[ integer ]], rank --[[ integer ]])
```

#### Server Events
```lua
RegisterNetEvent('xperience:server:rankUp', function(newRank, previousRank)
    -- do something when player ranks up
end)

RegisterNetEvent('xperience:server:rankDown', function(newRank, previousRank)
    -- do something when player ranks down
end)
```

## Rank Actions
You can define callbacks on each rank by using the `Action` function.

The function will be called both when the player reaches the rank and drops to the rank.

You can check whether the player reached or dropped to the new rank by utilising the `rankUp` parameter.

```lua
Config.Ranks = {
    [1] = { XP = 0 },
    [2] = {
        XP = 800, -- The XP required to reach this rank
        Action = function(rankUp, prevRank, player)
            -- rankUp: boolean      - whether the player reached or dropped to this rank
            -- prevRank: number     - the player's previous rank
            -- player: integer      - The current player            
        end
    },
    [3] = { XP = 2100 },
    [4] = { XP = 3800 },
    ...
}
```

# QBCore Integration

If `Config.UseQBCore` is set to `true` then the player's xp and rank are stored in their metadata. The metadata is saved whenever a player's xp / rank changes.

#### Client
```lua
local PlayerData = QBCore.Functions.GetPlayerData()
local xp = PlayerData.metadata.xp
local rank = PlayerData.metadata.rank
```

#### Server
```lua
local Player = QBCore.Functions.GetPlayer(src)
local xp = Player.PlayerData.metadata.xp
local rank = Player.PlayerData.metadata.rank
```

# ESX Integration

#### Server
```lua
local xPlayer = ESX.GetPlayerById(src)
local xp = xPlayer.get('xp')
local rank = xPlayer.get('rank')
```


# Commands
```lua
-- Set the theme
/setXPTheme [theme]
```

# Admin Commands

These require ace permissions: e.g. `add_ace group.admin command.addXP allow`

```lua
-- Award XP to player
/addXP [playerId] [xp]

-- Deduct XP from player
/removeXP [playerId] [xp]

-- Set a player's XP
/setXP [playerId] [xp]

-- Set a player's rank
/setRank [playerId] [rank]
```

# Themes
The theme can be set by the player using the `/setXPTheme [theme]` command. The `theme` argument must exist in the `Config.Themes` table in `config.lua` for it to work:

```lua
Config.Theme  = 'native'  -- Set the default theme (must exist in the Config.Themes table)
 
Config.Themes = {
    native = {
        segments = 10,  -- Sets the number of segments the XP bar has. Native = 10, Max = 20
        width = 532     -- Sets the width of the XP bar in px
    },

    hitman = {
        segments = 80,
        width = 800
    },
    
    hexagon = {
        segments = 16,
        width = 400
    },
}
```

# Custom Themes

Let's say you want to add a theme called `myTheme`:

* Add the theme table to the `Config.Themes` table using the name of the theme as the index:

```lua
Config.Themes = {
    ...
    
    myTheme = {
        segments = 20,
        width = 650
    }
}
```

* Create the theme's `.css` file in `ui/css` directory with the `theme-` prefix:
```
ui/css/theme-myTheme.css
```

* Set `Config.Theme` to read your new theme:
```lua
Config.Theme = 'myTheme'
```

#### Markup for making themes:
```html
<div class="xperience">
    <div class="xperience-inner">
        <div class="xperience-rank">
            <div>XXXX</div> <!-- CURRENT RANK -->
        </div>
        <div class="xperience-progress"> <!-- MAIN PROGRESS BAR -->
            <div class="xperience-segment"> <!-- BAR SEGMENT (IF YOU'VE SET THE THEME'S SEGMENTS TO 10 THEN THERE'LL BE 10 OF THESE) -->
                <div class="xperience-indicator--bar"></div> <!-- SEGMENT INDICATOR (ONLY USED WHEN XP IS UPDATING)-->
                <div class="xperience-progress--bar"></div> <!-- SEGMENT PROGRESS -->
            </div>
            ...
        </div>
        <div class="xperience-rank">
            <div>XXXX</div> <!-- NEXT RANK -->
        </div>
    </div>
    <div class="xperience-data">
        <span>XXXX</span> <!-- CURRENT XP -->
        <span>XXXX</span> <!-- XP REQUIRED FOR NEXT RANK -->
    </div>
</div>
```

# FAQ

### How do I award players XP for X amount of playtime?

Example of awarding players 100XP for every 30mins of playtime
```lua
-- Server side
CreateThread(function()
    local interval = 30   -- interval in minutes
    local xp = 100        -- XP amount to award every interval

    while true do
        for i, src in pairs(GetPlayers()) do
            TriggerClientEvent('xperience:client:addXP', src, xp)
        end
        
        Wait(interval * 60 * 1000)
    end
end)
```

### How do I give XP to a player when they've done something?

Example of giving a player 100 XP for shooting another player
```lua
AddEventHandler('gameEventTriggered', function(event, data)
    if event == "CEventNetworkEntityDamage" then
        local victim      = tonumber(data[1])
        local attacker    = tonumber(data[2])
        local weaponHash  = tonumber(data[5])
        local meleeDamage = tonumber(data[10]) ~= 0 and true or false 

        -- Don't register melee damage
        if not meleeDamage then
            -- Check victim and attacker are both players
            if (IsEntityAPed(victim) and IsPedAPlayer(victim)) and (IsEntityAPed(attacker) and IsPedAPlayer(attacker)) then
                if attacker == PlayerPedId() then -- We are the attacker
                    exports.xperience:AddXP(100) -- Give player 100 xp for getting a hit
                end
            end
        end
    end
end)
```

### How do I do something when a player's rank changes?

You can either utilise [Rank Events](#client-events) or [Rank Actions](#rank-actions).

Example of giving a minigun with `500` bullets to a player for reaching rank `10`:

#### Rank Event
```lua
AddEventHandler("xperience:client:rankUp", function(newRank, previousRank, player)
    if newRank == 10 then
        local weapon = `WEAPON_MINIGUN`
        
        if not HasPedGotWeapon(player, weapon, false) then
            -- Player doesn't have weapon so give it them loaded with 500 bullets
            GiveWeaponToPed(player, weapon, 500, false, false)
        else
            -- Player has the weapon so give them 500 bullets for it
            AddAmmoToPed(player, weapon, 500)
        end
    end
end)
```

#### Rank Action
```lua
Config.Ranks = {
    [1] = { XP = 0 },
    [2] = { XP = 800 },
    [3] = { XP = 2100 },
    [4] = { XP = 3800 },
    [5] = { XP = 6100 },
    [6] = { XP = 9500 },
    [7] = { XP = 12500 },
    [8] = { XP = 16000 },
    [9] = { XP = 19800 },
    [10] = {
        XP = 24000,
        Action = function(rankUp, prevRank, player)
            if rankUp then -- only run when player moved up to this rank
                local weapon = `WEAPON_MINIGUN`
        
                if not HasPedGotWeapon(player, weapon, false) then
                    -- Player doesn't have weapon so give it them loaded with 500 bullets
                    GiveWeaponToPed(player, weapon, 500, false, false)
                else
                    -- Player has the weapon so give them 500 bullets for it
                    AddAmmoToPed(player, weapon, 500)
                end
            end
        end
    },
    [11] = { XP = 28500 },
    ...
}
```

# License

```
xperience - XP Ranking System for FiveM

Copyright (C) 2021 Karl Saunders

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>
```

---

## 中文

* 设计用于模拟原生 GTA:O 系统
* 保存和加载玩家经验值/等级
* 从您自己的脚本/工作中添加/移除经验值
* 允许您监听等级变化以奖励玩家
* 完全可定制的用户界面
* 框架无关，但支持 `ESX` 和 `QBCore`

##### 增加经验值

![演示图片 1](https://i.imgur.com/CpACt9s.gif)

##### 升级

![演示图片 2](https://i.imgur.com/uNPRGo5.gif)

## 目录
* [安装](#安装)
* [从 esx_xp 迁移](#从-esx_xp-迁移)
* [使用方法](#使用方法)
* [客户端](#客户端)
  - [客户端导出](#客户端导出)
  - [客户端事件](#客户端事件)
* [服务端](#服务端)
  - [服务端导出](#服务端导出)
  - [服务端触发器](#服务端触发器)
  - [服务端事件](#服务端事件)
* [等级操作](#等级操作)
* [QBCore 集成](#qbcore-集成)
* [ESX 集成](#esx-集成)
* [管理员命令](#管理员命令)
* [主题](#主题)
* [自定义主题](#自定义主题)
* [常见问题](#常见问题)
* [许可证](#许可证)

## 安装

选择一个选项：
* 选项 1 - 如果您想将 `xperience` 作为独立资源使用，则只导入 `xperience_standalone.sql`
* 选项 2 - 如果使用 `ESX` 并将 `Config.UseESX` 设置为 `true`，则只导入 `xperience_esx.sql`。这会将 `xp` 和 `rank` 列添加到 `users` 表中
    - 如果您正在从 `esx_xp` 迁移，则不要导入 `xperience_esx.sql`，而是参见 [从 esx_xp 迁移](#从-esx_xp-迁移)
* 选项 3 - 如果使用 `QBCore` 并将 `Config.UseQBCore` 设置为 `true`，则无需导入任何 `sql` 文件，因为 xp 和 rank 会被保存到玩家的元数据中 - 参见 [QBCore 集成](#qbcore-集成)

然后：

* 将 `xperience` 目录放入您的 `resources` 目录中
* 将 `ensure xperience` 添加到您的 `server.cfg` 文件中

默认情况下，此资源使用 `oxmysql`，但如果您不想使用/安装它，则可以按照以下说明使用 `mysql-async`：

* 在 `fxmanifest.lua` 中取消注释 `'@mysql-async/lib/MySQL.lua',` 行并注释掉 `'@oxmysql/lib/MySQL.lua'` 行

## 从 esx_xp 迁移
如果您之前使用过 `esx_xp` 并且仍在使用 `es_extended`，则执行以下操作使您当前存储的 xp/rank 数据与 `xperience` 兼容：
* 将 `users` 表中的 `rp_xp` 列重命名为 `xp`
* 将 `users` 表中的 `rp_rank` 列重命名为 `rank`
* 将 `Config.UseESX` 设置为 `true`

## 使用方法

### 客户端

#### 客户端导出
给予玩家经验值
```lua
exports.xperience:AddXP(xp --[[ 整数 ]])
```

从玩家处移除经验值
```lua
exports.xperience:RemoveXP(xp --[[ 整数 ]])
```

设置玩家的经验值
```lua
exports.xperience:SetXP(xp --[[ 整数 ]])
```

设置玩家的等级
```lua
exports.xperience:SetRank(rank --[[ 整数 ]])
```

获取玩家的经验值
```lua
exports.xperience:GetXP()
```

获取玩家的等级
```lua
exports.xperience:GetRank()
```

获取升级所需的经验值
```lua
exports.xperience:GetXPToNextRank()
```

获取达到指定等级所需的经验值
```lua
exports.xperience:GetXPToRank(rank --[[ 整数 ]])
```

#### 客户端事件

在客户端监听升级事件
```lua
AddEventHandler("xperience:client:rankUp", function(newRank, previousRank, player)
    -- 当玩家升级时执行某些操作
end)
```

在客户端监听降级事件
```lua
AddEventHandler("xperience:client:rankDown", function(newRank, previousRank, player)
    -- 当玩家降级时执行某些操作
end)
```

### 服务端

#### 服务端导出
获取玩家的经验值
```lua
exports.xperience:GetPlayerXP(playerId --[[ 整数 ]])
```

获取玩家的等级
```lua
exports.xperience:GetPlayerRank(playerId --[[ 整数 ]])
```

获取玩家升级所需的经验值
```lua
exports.xperience:GetPlayerXPToNextRank(playerId --[[ 整数 ]])
```

获取玩家达到指定等级所需的经验值
```lua
exports.xperience:GetPlayerXPToRank(playerId --[[ 整数 ]], rank --[[ 整数 ]])
```

#### 服务端触发器
```lua
TriggerClientEvent('xperience:client:addXP', playerId --[[ 整数 ]], xp --[[ 整数 ]])

TriggerClientEvent('xperience:client:removeXP', playerId --[[ 整数 ]], xp --[[ 整数 ]])

TriggerClientEvent('xperience:client:setXP', playerId --[[ 整数 ]], xp --[[ 整数 ]])

TriggerClientEvent('xperience:client:setRank', playerId --[[ 整数 ]], rank --[[ 整数 ]])
```

#### 服务端事件
```lua
RegisterNetEvent('xperience:server:rankUp', function(newRank, previousRank)
    -- 当玩家升级时执行某些操作
end)

RegisterNetEvent('xperience:server:rankDown', function(newRank, previousRank)
    -- 当玩家降级时执行某些操作
end)
```

## 等级操作
您可以使用 `Action` 函数在每个等级上定义回调。

当玩家达到该等级或降到该等级时，都会调用该函数。

您可以通过使用 `rankUp` 参数来检查玩家是达到还是降到了新等级。

```lua
Config.Ranks = {
    [1] = { XP = 0 },
    [2] = {
        XP = 800, -- 达到此等级所需的经验值
        Action = function(rankUp, prevRank, player)
            -- rankUp: 布尔值      - 玩家是达到还是降到了此等级
            -- prevRank: 数字     - 玩家之前的等级
            -- player: 整数      - 当前玩家            
        end
    },
    [3] = { XP = 2100 },
    [4] = { XP = 3800 },
    ...
}
```

# QBCore 集成

如果 `Config.UseQBCore` 设置为 `true`，则玩家的 xp 和 rank 存储在他们的元数据中。每当玩家的 xp/rank 发生变化时，元数据都会被保存。

#### 客户端
```lua
local PlayerData = QBCore.Functions.GetPlayerData()
local xp = PlayerData.metadata.xp
local rank = PlayerData.metadata.rank
```

#### 服务端
```lua
local Player = QBCore.Functions.GetPlayer(src)
local xp = Player.PlayerData.metadata.xp
local rank = Player.PlayerData.metadata.rank
```

# ESX 集成

#### 服务端
```lua
local xPlayer = ESX.GetPlayerById(src)
local xp = xPlayer.get('xp')
local rank = xPlayer.get('rank')
```


# 命令
```lua
-- 设置主题
/setXPTheme [主题]
```

# 管理员命令

这些需要 ace 权限：例如 `add_ace group.admin command.addXP allow`

```lua
-- 奖励玩家经验值
/addXP [玩家ID] [经验值]

-- 扣除玩家经验值
/removeXP [玩家ID] [经验值]

-- 设置玩家的经验值
/setXP [玩家ID] [经验值]

-- 设置玩家的等级
/setRank [玩家ID] [等级]
```

# 主题
玩家可以使用 `/setXPTheme [主题]` 命令设置主题。`theme` 参数必须存在于 `config.lua` 中的 `Config.Themes` 表中才能工作：

```lua
Config.Theme  = 'native'  -- 设置默认主题（必须存在于 Config.Themes 表中）
 
Config.Themes = {
    native = {
        segments = 10,  -- 设置经验条的分段数。原生 = 10，最大 = 20
        width = 532     -- 以像素为单位设置经验条的宽度
    },

    hitman = {
        segments = 80,
        width = 800
    },
    
    hexagon = {
        segments = 16,
        width = 400
    },
}
```

# 自定义主题

假设您想添加一个名为 `myTheme` 的主题：

* 使用主题名称作为索引将主题表添加到 `Config.Themes` 表中：

```lua
Config.Themes = {
    ...
    
    myTheme = {
        segments = 20,
        width = 650
    }
}
```

* 在 `ui/css` 目录中创建主题的 `.css` 文件，前缀为 `theme-`：
```
ui/css/theme-myTheme.css
```

* 设置 `Config.Theme` 以读取您的新主题：
```lua
Config.Theme = 'myTheme'
```

#### 制作主题的标记：
```html
<div class="xperience">
    <div class="xperience-inner">
        <div class="xperience-rank">
            <div>XXXX</div> <!-- 当前等级 -->
        </div>
        <div class="xperience-progress"> <!-- 主进度条 -->
            <div class="xperience-segment"> <!-- 条形分段（如果您将主题的分段设置为 10，那么将有 10 个这样的分段） -->
                <div class="xperience-indicator--bar"></div> <!-- 分段指示器（仅在经验值更新时使用）-->
                <div class="xperience-progress--bar"></div> <!-- 分段进度 -->
            </div>
            ...
        </div>
        <div class="xperience-rank">
            <div>XXXX</div> <!-- 下一等级 -->
        </div>
    </div>
    <div class="xperience-data">
        <span>XXXX</span> <!-- 当前经验值 -->
        <span>XXXX</span> <!-- 下一等级所需的经验值 -->
    </div>
</div>
```

# 常见问题

### 如何为玩家奖励一定游戏时间的经验值？

每 30 分钟奖励玩家 100XP 的示例
```lua
-- 服务端
CreateThread(function()
    local interval = 30   -- 间隔时间（分钟）
    local xp = 100        -- 每次间隔奖励的经验值

    while true do
        for i, src in pairs(GetPlayers()) do
            TriggerClientEvent('xperience:client:addXP', src, xp)
        end
        
        Wait(interval * 60 * 1000)
    end
end)
```

### 当玩家做了某事后如何给予经验值？

给予玩家 100 经验值以射击另一个玩家的示例
```lua
AddEventHandler('gameEventTriggered', function(event, data)
    if event == "CEventNetworkEntityDamage" then
        local victim      = tonumber(data[1])
        local attacker    = tonumber(data[2])
        local weaponHash  = tonumber(data[5])
        local meleeDamage = tonumber(data[10]) ~= 0 and true or false 

        -- 不记录近战伤害
        if not meleeDamage then
            -- 检查受害者和攻击者都是玩家
            if (IsEntityAPed(victim) and IsPedAPlayer(victim)) and (IsEntityAPed(attacker) and IsPedAPlayer(attacker)) then
                if attacker == PlayerPedId() then -- 我们是攻击者
                    exports.xperience:AddXP(100) -- 给予玩家 100 经验值以获得命中
                end
            end
        end
    end
end)
```

### 当玩家等级变化时如何做某些事情？

您可以使用 [等级事件](#客户端事件) 或 [等级操作](#等级操作)。

为达到等级 `10` 的玩家提供一把带 `500` 发子弹的迷你枪的示例：

#### 等级事件
```lua
AddEventHandler("xperience:client:rankUp", function(newRank, previousRank, player)
    if newRank == 10 then
        local weapon = `WEAPON_MINIGUN`
        
        if not HasPedGotWeapon(player, weapon, false) then
            -- 玩家没有武器，所以给他们一把装满 500 发子弹的武器
            GiveWeaponToPed(player, weapon, 500, false, false)
        else
            -- 玩家有武器，所以给他们 500 发子弹
            AddAmmoToPed(player, weapon, 500)
        end
    end
end)
```

#### 等级操作
```lua
Config.Ranks = {
    [1] = { XP = 0 },
    [2] = { XP = 800 },
    [3] = { XP = 2100 },
    [4] = { XP = 3800 },
    [5] = { XP = 6100 },
    [6] = { XP = 9500 },
    [7] = { XP = 12500 },
    [8] = { XP = 16000 },
    [9] = { XP = 19800 },
    [10] = {
        XP = 24000,
        Action = function(rankUp, prevRank, player)
            if rankUp then -- 仅在玩家升级到此等级时运行
                local weapon = `WEAPON_MINIGUN`
        
                if not HasPedGotWeapon(player, weapon, false) then
                    -- 玩家没有武器，所以给他们一把装满 500 发子弹的武器
                    GiveWeaponToPed(player, weapon, 500, false, false)
                else
                    -- 玩家有武器，所以给他们 500 发子弹
                    AddAmmoToPed(player, weapon, 500)
                end
            end
        end
    },
    [11] = { XP = 28500 },
    ...
}
```

# 许可证

```
xperience - FiveM 经验排名系统

版权所有 (C) 2021 Karl Saunders

本程序是自由软件：您可以根据自由软件基金会发布的 GNU 通用公共许可证的条款重新分发和/或修改它，无论是许可证的第 3 版还是（根据您的选择）任何更高版本。

分发本程序是希望它会有用，但没有任何保证；甚至没有对适销性或特定用途适用性的暗示保证。有关更多详细信息，请参阅 GNU 通用公共许可证。

您应该随本程序收到一份 GNU 通用公共许可证。如果没有，请参见 <https://www.gnu.org/licenses/>
```

---

[English](#english) | [中文](#中文)
