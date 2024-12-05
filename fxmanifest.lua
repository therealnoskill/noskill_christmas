-- christmas by noskillarmy

fx_version 'adamant'
games {'gta5'}

author 'noskill'
description 'christmas'

version '0.1'
lua54 'yes'

shared_scripts {
    'config.lua',
    -- '@ox_lib/init.lua'

}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server.lua',
   

}

client_scripts {
    'client.lua',
    'config.lua',

}

escrow_ignore {
    'config.lua',
    
}