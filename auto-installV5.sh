#!/bin/bash

# Debug MODE
DEBUG="off"

# 	Author: 	Manet Jérémy <support@flashmodz.fr>
#				Emodyz Team
#
#	This file is part of Emodyz / Ezgames Team
#
#	Emodyz/EzGames release a free software: You can distribute it and/or modify
#	it under the terms of the GNU General Public License as published by
#	the Free Software Foundation, either version 3 of the license, or
#	(At your option) any later version
#
#    Emodyz/EzGames distribute in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with Emodyz/EzGames.  If not, see <http://www.gnu.org/licenses/>.
#
# Function (DO NOT MODIFY)

if [ "$DEBUG" == "on" ] || [ "$1" == "--debug" ]; then
	set -x
fi

greenMess() {
	echo -e "\\033[32;1m${@}\033[0m"
}

redMess() {
	echo -e "\\033[31;1m${@}\033[0m"
}

cyanMess() {
	echo -e "\\033[36;1m${@}\033[0m"
}

greenoMess() {
	echo -en "\\033[32;1m${@}\033[0m"
}

redoMess() {
	echo -en "\\033[31;1m${@}\033[0m"
}

cyanoMess() {
	echo -en "\\033[36;1m${@}\033[0m"
}

removeIfExists() {
	if [ -n "$1" ] && [ -f "$1" ]; then
		rm -f "$1"
	fi
}

errorAndExit() {
	cyanMessage " "
	redMessage "${@}"
	cyanMessage " "
	exit 1
}

errorAndContinue() {
	redMessage "Invalid option."
}

runSpinner() {
	SPINNER=("-" "\\" "|" "/")

	for SEQUENCE in $(seq 1 "$1"); do
		for I in "${SPINNER[@]}"; do
			echo -ne "\b$I"
			sleep 0.1
		done
	done
}

okAndSleep() {
	greenMessage "$1"
	sleep 1
}

checkInstall() {
	if [ "$OS" == "debian" ] || [ "$OS" == "ubuntu" ]; then
		if [ -z "$(dpkg-query -s "$1" 2>/dev/null)" ]; then
			cyanMessage " "
			okAndSleep "Installing package $1"
			$INSTALLER -y install "$1"
		fi
	elif [ "$OS" == "centos" ]; then
		if [ -z "$(rpm -qa "$1")" ]; then
			cyanMessage " "
			okAndSleep "Installing package $1"
			$INSTALLER -y install "$1"
		fi
	elif [ "$OS" == "slackware" ]; then
		if [ -z "$(slackpkg search "$1" 2>/dev/null)" ]; then
			cyanMessage " "
			okAndSleep "Installing package $1"
			$INSTALLER install "$1"
		fi

	fi

	if [ "$?" -ne 0 ]; then
		errorAndExit "\nPlease check Output!\nInstallation abort!\n"
	fi
}

checkUnInstall() {
	if [ "$OS" == "debian" ] || [ "$OS" == "ubuntu" ]; then
		if [ -z "$(dpkg-query -s "$1" 2>/dev/null)" ]; then
			cyanMessage " "
			okAndSleep "Uninstalling package $1"
			$INSTALLER -y remove "$1"
		fi
	elif [ "$OS" == "centos" ]; then
		if [ -z "$(rpm -qa "$1")" ]; then
			cyanMessage " "
			okAndSleep "Uninstalling package $1"
			$INSTALLER -y remove "$1"
		fi
	elif [ "$OS" == "slackware" ]; then
		if [ -z "$(slackpkg search "$1")" ]; then
			cyanMessage " "
			okAndSleep "Uninstalling package $1"
			$INSTALLER remove "$1"
		fi
	fi
}

importKey() {
	if [ "$OS" == "debian" ] || [ "$OS" == "ubuntu" ]; then
		apt-key adv --recv-keys --keyserver "$1" "$2"
	elif [ "$OS" == "centos" ]; then
		rpm --import "$1"
	elif [ "$OS" == "slackware" ]; then
		slackpkg update gpg
	fi
}

# VARS

INSTALLERVERSION="2.0"
IP=$(hostname -I | awk '{print $1}')
PKILL=$(which pkill)
MACHINE=$(uname -m)
if [ "$MACHINE" == "x86_64" ]; then
	ARCH="amd64"
elif [ "$MACHINE" == "i386" ] || [ "$MACHINE" == "i686" ]; then
	ARCH="x86"
fi

cyanMess ""
greenMess "Emodyz verify your system.. Please be patient"
cyanMess ""

if [ -f /etc/debian_version ]; then
	INSTALLER="apt-get"
	OS="debian"
	OSVERSION=$(sed 's/\..*//' /etc/debian_version)
	$INSTALLER -y update
	if [ -z "$(which wget)" ]; then
		checkInstall wget
	fi
	if [ -z "$(which dialog)" ]; then
		checkInstall dialog
	fi
	if [ -z "$(which logger)" ]; then
		apt-get --reinstall install bsdutils
	fi
	if [ -z "$(which apt-utils)" ]; then
		checkInstall apt-utils
	fi
else
	SPINNER 10
	errorAndQuit "Your version is not currently supported by EMODYZ, please read the wiki or buy an hosting at https://ezgames.fr"
fi

if [ -z "$IP" ] || [ "$IP" == "0" ] || [ "$IP" == "localhost" ]; then
	IP=$(ip route get 8.8.8.8 | awk '{print $7; exit}')
fi

cyanMess
cyanMess "Check for the latest Auto-installer version"
LATEST_V=$(wget -q --timeout=60 -O - https://api.github.com/repos/emodyz/bashv5/releases/latest | grep -Po '(?<="tag_name": ")([0-9]\.[0-9]+)')

if [ "$(printf "${LATEST_V}\n${INSTALLERVERSION}" | sort -V | tail -n 1)" != "$INSTALLERVERSION" ]; then
	errorAndExit "You are using the old version ${INSTALLERVERSION}. Please upgrade to version ${LATEST_V} and retry."
else
	okAndSleep "You are using the up to date version ${INSTALLERVERSION}"
fi

if [ "$(id -u)" != "0" ]; then
	cyanMess "Upgrade to root required"
	su -
fi

if [ "$(id -u)" != "0" ]; then
	errorAndExit "You are not still in root, ABORT NOW"
fi

cyanMess " "
okAndSleep "Update the system packages to the latest version ? Its required, as otherwise dependencies might break !"

OPTIONS=("Yes" "Quit")
select UPDATE_UPGRADE_SYSTEM in "${OPTIONS[@]}"; do
	case "$REPLY" in
	1) break ;;
	2) errorAndQuit ;;
	*) errorAndContinue ;;
	esac
done

function jumpto {
    	label=$1
    	cmd=$(sed -n "/$label:/{:a;n;p;ba};" $0 | grep -v ':$')
    	eval "$cmd"
    	exit 0
}

if [[ $lang == 'fr' ]]; then
	function ask_y_or_n() {
		read -p 'Demande du serveur Emodyz ([O]ui ou [N]on): '
		case $(echo -e $REPLY | tr '[A-Z]' '[a-z]') in
		o|O|oui) echo 'oui';;
		*) echo 'non';;
		esac
	}

	#Before Install
	confirm='Merci de confirmer votre choix'
	installprog='Merci d avoir accepter, nous effectuons l installation \n soyez patient :) \n \n \e[95mL equipe EMODYZ'
	a=' \n  \e[95mBienvenu(e) sur le script auto-install de la V5 \n \e[97mnous vous demanderons de choisir certaines option \n qui nous permet ainsi de determiner les meilleurs paramètres pour vous. \n .. \n \e[91mSoyez le plus attentif possible et consencieux dans vos réponse ...'
	b=' \n \e[95mEmodyz vérifie votre OS et votre configuration, veuillez patienté ...'
	lastcheck='\n \e[91m Vérification OK, Tout est à jour et nous allons continuer :)'
	
	#During Install
	checkdep='Nous vérifions les dépendances ...'
	checkdist='Nous vérifions et mettons à jour votre distribution ..'
	donotforgetv='N oubliez pas de bien séléctionner la Version 5.7 puis OK !!!!'
	selectapache2='Dans le menu Suivant, veuillez Séléctionner Apache2 en appuyant sur espace.'
	donotforgete='N oubliez pas de bien appuyer sur ENTER !!!!!!!!!!!!!!!!!!!!!!!!!!'

	#fix
	mysqldf='\n \e[92m L équipe Emodyz fixe l erreur mysql en ce moment, soyez patient ...'
	mysqldfs='\n Erreur fixer avec succès !'

	#Install Success
	successinstall='Installation Finalisé avec Succès !'
	successinstalladress='Ouvrez un nouvel onglet dans votre navigateur \n \n Mettez-y l adresse IP de votre serveur \n \n ENJOY !!'

	#Error
	notimpl='N a pas été implémenté pour le moment, soyez patient :)'
	cancel='Vous avez annulé la procédure, vous n avez pas acceptez que EMODYZ effectue l installation automatiquement...'
fi

if [[ $lang == 'en' ]]; then
	function ask_y_or_n() {
		read -p 'Request Emodyz Server ([Y]es or [N]o): '
		case $(echo $REPLY | tr '[A-Z]' '[a-z]') in
		y|Y|yes) echo 'yes';;
		*) echo 'no';;
		esac
	}

	#Before Install
	confirm='Please confirm your choice'
	installprog='Thank you for accepting, we are doing the installation \n be patient :) \n \n \e[95mThe EMODYZ team'
	a=' \n  \e[95mWelcome to the auto-install script of the V5 \n \e[97mwe will ask you to choose some option \n which allows us to determine the best parameters for you. \n .. \n \e[91mBe as attentive as possible and conscientious in your answers ...'
	b=' \n \e[95mEmodyz checks your OS and your configuration, please wait ...'
	lastcheck='\n \e[91m Check Ok and All has Up2Date ! :)'

	#During Install
	checkdep='We check dependencies ...'
	checkdist='We check and update your distribution ..'
	donotforgetv='Do not forget to select Version 5.7 and OK !!!!'
	selectapache2='In the Next menu, please select Apache 2 by pressing space.'
	donotforgete='Do not forget to press ENTER !!!!!!!!!!!!!!!!!!!!!!!!!!'

	#fix
	mysqldf='\n \e[92m The Emodyz team fix the mysql error right now, be patient ...'
	mysqldfs='Mysql has Fixed correctly !'

	#Install Success
	successinstall='Installation Finalized with Success !'
	successinstalladress='Open a new tab in your browser \n \n Put in it the IP address of your server \n \n ENJOY !!'

	#Error
	cancel='You canceled the procedure, you do not agree that EMODYZ performs the installation automatically ...'
	notimpl='has not been implemented yet, be patient :)'
fi

sleep 3
echo -e $a
sleep 5
echo -e $b

function version { echo "$@" | gawk -F. '{ printf("%03d%03d%03d\n", $1,$2,$3); }'; }

if [[ "$OSTYPE" == "linux-gnu" ]]; then
        os='linux'
	if [[ $(lsb_release -is) = 'Debian' ]]; then
		outh=9.0
		ost=$(lsb_release -is)
		auth=1
		if [[ '$(version '$outh')' <  '$(version '$(lsb_release --release | awk '{ print $2 }')')' ]]; then
			vers=$(lsb_release --release | awk '{ print $2 }')
                        echo -e '\n \e[92mYour OS Has Authorized to proceed'
                        auth=1
                        echo -e '\n ************************* \n Informations Trouvée : \n *************************'
                        echo -e '\n Type de Distribution : '$os
                        echo -e '\n Nom de L OS : '$ost
                        echo -e '\n Version : '$vers
                        echo -e '\n Autorisé à installer ? OUI'

			startdebian9x=${1:-"st19x"}
			finishdebian9x=${1:-"finishdebian9x"}

			if [[ $os == 'linux' || $auth == 1 ]]; then
				echo -e '\n \e[39mPlease Confirm to accept auto Install ?'
				startdebian9x=${1:-"st19x"}

				if [[ $lang == 'fr' ]]; then
					if [[ "non" == $(ask_y_or_n "Are you sure?") ]]; then
						echo -e '\n \e[39m '$confirm
						sleep 2
						if [[ "non" == $(ask_y_or_n "Are you *really* sure?") ]]; then
    							echo -e '\n \e[91m '$cancel
    							exit 0
						else
							echo -e '\n \e[39m '$installprog
							jumpto $startdebian9x
						fi
					else
						echo -e '\n \e[39m '$confirm
						sleep 2;
						if [[ "non" == $(ask_y_or_n "Are you *really* sure?") ]]; then
							echo -e '\n \e[91m '$cancel
    							exit 0
						else
							echo -e '\n \e[39m '$installprog
							jumpto $startdebian9x
						fi
					fi
				else
					if [[ "no" == $(ask_y_or_n "Are you sure?") ]]; then
						echo -e '\n \e[39m '$confirm
						sleep 2
						if [[ "no" == $(ask_y_or_n "Are you *really* sure?") ]]; then
    							echo -e '\n \e[91m '$cancel
    							exit 0
						else
							echo -e '\n \e[39m '$installprog
							jumpto $startdebian9x
						fi
					else
						echo -e '\n \e[39m ${confirm}'
						sleep 2;
						if [[ "no" == $(ask_y_or_n "Are you *really* sure?") ]]; then
							echo -e '\n \e[91m '$cancel
    							exit 0
						else
							echo -e '\n \e[39m '$installprog
							jumpto $startdebian9x
						fi
					fi
				fi
				
				st19x:
				echo -e '\n \e[39m'$checkdep
				sudo apt update && sudo apt upgrade -y
				echo -e '\n \e[91m'$checkdist
				sudo apt update && sudo apt dist-upgrade -y
			
				cd /tmp
				ls
				wget https://dev.mysql.com/get/mysql-apt-config_0.8.11-1_all.deb
				echo -e '\n \e[91m'$donotforgetv
				sleep 5
				sudo dpkg -i mysql-apt-config*
				sudo apt update
				cd /
				echo -e $lastcheck
			
				sleep 5
				sudo apt install apache2 unzip php7.0 php7.0-mysql php7.0-curl git -y
				echo -e $selectapache2
				sleep 5
				sudo apt install mysql-server -y
				echo -e $selectapache2
				sleep 5
				sudo apt install phpmyadmin -y
				sudo apt install libfcgi-dev libfcgi0ldbl libjpeg62-turbo-dev libmcrypt-dev libssl-dev libc-client2007e libc-client2007e-dev libxml2-dev -y
				sudo apt install libbz2-dev libcurl4-openssl-dev libjpeg-dev libpng-dev libfreetype6-dev libkrb5-dev libpq-dev libxml2-dev libxslt1-dev -y
				sleep 5
			
				sudo sed -i '/<Directory \/var\/www\/>/,/<\/Directory>/ s/AllowOverride None/AllowOverride all/' /etc/apache2/apache2.conf
				sudo a2enmod rewrite
				sudo service apache2 restart
				sudo rm -rf /var/www/html
				cd /var/www && git clone https://github.com/MrDarkSkil/Launcher_Multigaming.git -b webpanel-test html
				chown -R www-data:www-data /var/www/html/games/
				chmod -R 777 /var/www/html/configs/
				echo -e $mysqldf
				set global sql_mode=""
				echo "sql_mode=\"\"" > /etc/mysql/conf.d/webpanel_mysql_disable.cnf
				sudo systemctl restart mysql.service
				sleep 5
				echo -e $mysqldfs
			
				echo -e '\n \e[92m'$successinstall
				echo -e '\n \e[92m'$successinstalladress
				exit 0
			fi
		else
			vers='ufo'
		fi
	elif [[ $(lsb_release -is) = 'Ubuntu' ]]; then
		outh=18.0
		ost=$(lsb_release -is)
		auth=0
		if [[ '$(version '$outh')' <  '$(version '$(lsb_release --release | awk '{ print $2 }')')' ]]; then
			vers=$(lsb_release --release | awk '{ print $2 }')
			echo -e '\n \e[92mYour OS Has Authorized to proceed'
			auth=1
			echo -e '\n ************************* \n Informations Trouvée : \n *************************'
			echo -e '\n Type de Distribution : '$os' ...'
			echo -e '\n Nom de L OS : '$ost' ...'
			echo -e '\n Version : '$vers' ...'
			echo -e '\n Autorisé à installer ? OUI'

			startubuntu18x=${1:-"startubuntu18x"}

			if [[ $os == 'linux' || $auth == 1 ]]; then
				echo -e '\n \e[39mPlease Confirm to accept auto Install ?'
				if [[ "non" == $(ask_y_or_n "Are you sure?") ]]; then
					echo -e '\n \e[39m'$confirm
					sleep 2
					if [[ "non" == $(ask_y_or_n "Are you *really* sure?") ]]; then
    						echo -e '\n \e[91m'$cancel
    						exit 0
					else
						echo -e '\n \e[39m'$installprog
						jumpto $startubuntu18x
					fi
				else
					echo -e '\n \e[39m'$confirm
					sleep 2
					if [[ "non" == $(ask_y_or_n "Are you *really* sure?") ]]; then
						echo -e '\n \e[91m'$cancel
    						exit 0
					else
						echo -e '\n \e[39m'$installprog
						jumpto $startubuntu18x
					fi
				fi
			fi

			startubuntu18x:
			echo -e '\n \e[39m'$checkdep
				sudo apt update && sudo apt upgrade -y
				echo -e '\n \e[91m'$checkdist
				sudo apt update && sudo apt dist-upgrade -y
			
				cd /tmp
				ls
				wget https://dev.mysql.com/get/mysql-apt-config_0.8.11-1_all.deb
				echo -e '\n \e[91m'$donotforgetv
				sleep 5
				sudo dpkg -i mysql-apt-config*
				sudo apt update
				cd /
				echo -e $lastcheck
			
				sleep 5
				echo -e '\n \e[91m'$donotforgete
				sudo add-apt-repository ppa:ondrej/php
				sudo apt update
				sleep 2
				sudo apt-cache policy php7.0
				sleep 5
				sudo apt install openssl libssl-dev cl-plus-ssl
				sudo apt install apache2 unzip php7.0 php7.0-mbstring php7.0-mysql php7.0-curl php7.0-dev libmcrypt-dev php-pear git -y
				echo -e $selectapache2
				sleep 5
				sudo apt install mysql-server -y
				echo -e $selectapache2
				sleep 5
				sudo apt install phpmyadmin -y
				sudo apt install libfcgi-dev libfcgi0ldbl libmcrypt-dev libssl-dev libc-client2007e libc-client2007e-dev libxml2-dev -y
				sudo apt install libbz2-dev libcurl4-openssl-dev libjpeg-dev libpng-dev libfreetype6-dev libkrb5-dev libpq-dev libxml2-dev libxslt1-dev -y
				sleep 5
			
				sudo sed -i '/<Directory \/var\/www\/>/,/<\/Directory>/ s/AllowOverride None/AllowOverride all/' /etc/apache2/apache2.conf
				sudo a2enmod rewrite
				sudo service apache2 restart
				sudo rm -rf /var/www/html
				cd /var/www && sudo git clone https://github.com/MrDarkSkil/Launcher_Multigaming.git -b webpanel-test html
				sudo chown -R www-data:www-data /var/www/html/games/
				sudo chmod -R 777 /var/www/html/configs/
				echo -e $mysqldf
				sudo set global sql_mode=""
				sudo printf '[mysqld]\n sql_mode=' > /etc/mysql/conf.d/webpanel_mysql_disable.cnf
				sudo systemctl restart mysql.service
				sleep 5
				echo -e $mysqldfs
			
				echo -e '\n \e[92m'$successinstall
				echo -e '\n \e[92m'$successinstalladress
				exit 0
		else
			vers=$(lsb_release --release | awk '{ print $2 }')
                        echo -e '\n \e[91mYour OS Has not Authorized to proceed'
			echo -e '\n \e[91mYour Version \e[39m'$vers' \e[91mRequired Version : \e[39m'$outh' \e[91mCheck if Update has Available on Github'
			auth=0
		fi
	else
		auth='unknow'
	fi
elif [[ "$OSTYPE" == "darwin" ]]; then
        os='MacOS'
	vers=$(lsb_release --release | awk '{ print $2 }')
        echo -e '\n \e[91mYour OS Has not Authorized to proceed'
        auth=0

elif [[ "$OSTYPE" == "cygwin" ]]; then
        os='Cygwin'
	vers=$(lsb_release --release | awk '{ print $2 }')
        echo -e '\n \e[91mYour OS Has not Authorized to proceed' 
        auth=0

elif [[ "$OSTYPE" == "msys" ]]; then
        os='lol'
	vers=$(lsb_release --release | awk '{ print $2 }')
        echo -e '\n \e[91mYour OS Has not Authorized to proceed' 
        auth=0

elif [[ "$OSTYPE" == "freebsd" ]]; then
        os='lool'
	vers=$(lsb_release --release | awk '{ print $2 }')
        echo -e '\n \e[91mYour OS Has not Authorized to proceed' 
        auth=0

else
        os='ufo'
	vers=$(lsb_release --release | awk '{ print $2 }')
        echo -e '\n \e[91mYour OS Has not Authorized to proceed' 
        auth=0

fi

echo -e $s

echo -e "\n \e[39m"$os
echo -e $ost
echo -e $auth
echo -e $vers
echo -e $res
echo -e $lang
