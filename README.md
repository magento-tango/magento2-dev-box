# Magento 2 Application with Docker Compose for developers

## Prerequisites
- Docker (https://www.docker.com/products/docker#/windows) for windows should be installed.
- Run PowerShell as administrator and give permission to run scripts with command: `Set-ExecutionPolicy Unrestricted`
- For Windows Shared Drivers in Docker Settings should be enabled

## Installation (Windows 10)
1. Clone this repository && run `cd magento2-dev-box` in terminal
2. Run `& ".\install.ps1"` in PowerShell - during command execution you will be asked for your magento repo credentials
3. Open in browser http://localhost:1748/

## Configuring PhpStorm
:information_source: We suggest to make magento2-dev-box directory as your project directory in PhpStorm

If you want to configure PhpStorm automatically, run `configure_php_storm` script. It will set up remote PHP interpreter.

## Debug your PHP in Docker with Intellij/PHPStorm and Xdebug
1. Create new server to PhpStorm Servers:
   - Name: {{your server name}}
   - Host: localhost
   - Port: 1748
   - Use path mappings: Yes
   - File/Directory: magento2-dev-box/webroot-> /var/www/magento2
2. Add PHP Remote Debug to new configurations in PhpStorm:
   - Name: {{your name}}
   - Servers: {{your server name from step 1}}
   - Ide key: PHPSTORM
3. Make sure that you have 9000 Xdebug port in Languages & Frameworks > PHP > Debug

## Static content deploy
To deploy static view files you need:
- Enter docker container by running: `docker exec -it --privileged magento2-devbox-web /bin/bash`
- Enter magento root: `cd \var\www\magento2`
- Deploy static files: `php bin/magento setup:static-content:deploy`

## Compile CSS styles with Grunt
To compile CSS out of LESS via Grunt you need:
- Enter docker container by running: `docker exec -it --privileged magento2-devbox-web /bin/bash`
- Enter magento root: `cd \var\www\magento2`
- Run: `npm install && grunt refresh`

## Configure PhpStorm to run tests:
1. Go to Languages & Frameworks > PHP and add new Interpreter:
 - Select Interpreter path: Remote
 - Name: {{your_name}}
 - Remote: SSH Credentials
 - Host: 127.0.0.1 Port: 2222
 - Username: magento2
 - Password: 
 - PHP executable: /usr/local/bin/php
 
2. Go to Languages & Frameworks > PHP:
 - Interpreter: Remote PHP 7
 - Path mapping: magento2-dev-box/shared/webroot -> /var/www/magento2 <br/>
   :information_source: If your Magento is installed not in default location (/magento2-dev-box/shared/webroot) enter your custom location here.
 
3. Go to Languages & Frameworks > PHP > PHPUnit and click +:
 - Interpreter: Remote PHP 7
 - Path mappings: magento2-dev-box/shared/webroot -> /var/www/magento2
 - PHPUnit Library: Use Composer autoloader
 - Path to script: /var/www/magento2/vendor/autoload.php
 
## Use Magento CLI (bin/magento)
 Go to 'magento2-dev-box' directory and run in command line:
 
 For Linux/Mac OS run:
 `bash m-bin-magento <command_name>`
 e.g.
 `bash m-bin-magento list`

 For Windows run in PowerShell:
 `.\m-bin-magento.ps1 <command_name>`
 e.g.
 `.\m-bin-magento.ps1 list`
 
## FAQ
1. If Xdebug does not work. Solution:
- For Mac OS run in terminal `ifconfig | grep inet` and get your ip address. Windows users check this article: https://support.microsoft.com/en-us/help/15291/windows-find-pc-ip-address
- Go to web container: `docker exec -it --privileged magento2-devbox-web /bin/bash`
- Within container go to: `/usr/local/etc/php/conf.d`
- Open file: `vi docker-php-ext-xdebug.ini`
- Start to edit it by typing: `i`
- Add row: `xdebug.remote_host=<your_ip_from_step_1>`
- Set: `xdebug.remote_connect_back=0`
- Quit vi by typing: `Esc` -> `:wq`
- Restart web container in your terminal: `docker restart magento2-devbox-web`
