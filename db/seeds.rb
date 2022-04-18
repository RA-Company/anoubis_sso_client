admin_group = AnoubisSsoClient::Group.create_group({ ident: 'admin', translate: 'anoubis.install.groups.admin' })
user_group = AnoubisSsoClient::Group.create_group({ ident: 'user', translate: 'anoubis.install.groups.user' })
visitor_group = AnoubisSsoClient::Group.create_group({ ident: 'visitor', translate: 'anoubis.install.groups.visitor' })

menu = AnoubisSsoClient::Menu.create_menu({ mode: 'dashboard', action: 'dashboard', group: [visitor_group, user_group] })
AnoubisSsoClient::GroupMenu.add_menu_access( { menu: menu, group: admin_group, access: 'write' })