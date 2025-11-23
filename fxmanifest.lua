fx_version 'cerulean'

game 'gta5'

description 'Experience System - A FiveM level management system with multi-theme and multi-framework integration, providing complete XP and rank features'

author 'wusheng666 和 Mobius1'

version '0.4.0'

shared_scripts {
    'config.lua',
    'common/ranks.lua',
    'common/utils.lua',
}

server_scripts {
    -- '@mysql-async/lib/MySQL.lua',
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/version_checker.lua'
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