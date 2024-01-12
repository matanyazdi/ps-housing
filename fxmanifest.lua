fx_version 'cerulean'

game "gta5"

author "Xirvin#0985 and Project Sloth"
version '1.1.1'

repository 'Project-Sloth/ps-housing'

lua54 'yes'

ui_page 'html/index.html'

dependency 'fivem-freecam'

shared_script {
  '@ox_lib/init.lua',
  "shared/config.lua",
}

client_script {
  'client/modeler.lua',
}

files {
  'html/**',
  'stream/starter_shells_k4mb1.ytyp'
}

this_is_a_map 'yes'
data_file 'DLC_ITYP_REQUEST' 'starter_shells_k4mb1.ytyp'

file 'stream/**.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/**.ytyp'
