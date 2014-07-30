name             'php-expressionengine-env'
maintainer       'IRIS'
maintainer_email 'robertlnewman@gmail.com'
license          'All rights reserved'
description      'Installs/Configures LAMP environment for Expression Engine'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.1.0'

depends "vim"
depends "hostsfile"
depends "simple_iptables"
depends "apache2"
depends "mysql"
depends "php"
depends "database"
depends "dmg"
depends "git"
depends "user"
depends "sudo"
