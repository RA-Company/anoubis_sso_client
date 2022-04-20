admin_group = AnoubisSsoClient::Group.create_group({ ident: 'admin', translate: 'anoubis.install.groups.admin' })
user_group = AnoubisSsoClient::Group.create_group({ ident: 'user', translate: 'anoubis.install.groups.user' })
visitor_group = AnoubisSsoClient::Group.create_group({ ident: 'visitor', translate: 'anoubis.install.groups.visitor' })

## Menu setup

## Dashboard
menu_0 = AnoubisSsoClient::Menu.create_menu({ mode: 'dashboard', action: 'dashboard', group: [visitor_group, user_group] })
menu_0.add_group( { group: admin_group, access: 'write' })

## Settings
menu_0 = AnoubisSsoClient::Menu.create_menu({ mode: 'settings', action: 'menu', group: admin_group, access: 'write' })

## Settings -> Menu
menu_1 = AnoubisSsoClient::Menu.create_menu({ mode: 'settings/menu', action: 'data', group: admin_group, access: 'write', parent: menu_0 })