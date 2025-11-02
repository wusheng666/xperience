fx_version 'cerulean'

game 'gta5'

description '经验系统 - 支持多主题、多框架集成的FiveM等级管理系统，提供完整的XP和等级功能'

author 'wusheng666 和 Mobius1'

version '0.2.0'

shared_scripts {
    'config.lua',
    'common/ranks.lua',
    'common/utils.lua',
}

server_scripts {
    -- '@mysql-async/lib/MySQL.lua',
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

client_scripts {
    'client/main.lua',
}

ui_page 'ui/ui.html'

files {
    'ui/ui.html',
    'ui/fonts/*.ttf',
    'ui/css/*.css',
    'ui/js/*.js'
}