admin_group = AnoubisSsoClient::Group.create_group ident: 'admin', translate: 'anoubis.install.groups.admin'
user_group = AnoubisSsoClient::Group.create_group ident: 'user', translate: 'anoubis.install.groups.user'
visitor_group = AnoubisSsoClient::Group.create_group ident: 'visitor', translate: 'anoubis.install.groups.user'