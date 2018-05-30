#!/bin/bash


tempFilesDir=/opt/tempFilesDir/
installFilesURL=http://www.ninedivines.club/islarepo/
installFilesTball=islandoraStackPackages.tar.gz

yum -y install expect epel-release

apt_get_install_apps()
{
	app_packages=( \
		"php " \ 
		"php-mysql " \ 
		"php-gd " \ 
		"php-ldap " \ 
		"php-odbc " \ 
		"php-pear " \ 
		"php-xml" \ 
		"php-xmlrpc " \ 
		"php-mbstring " \ 
		"php-snmp " \ 
		"php-soap " \ 
		"expect" \
		"wget" \
		"curl" \
		"postfix" \
		"cowsay" \
		"dos2unix" \
		"git" \
		"htop" \
		"nmap" \
		"p7zip" \
		"screen" \
		"screenfetch" \
		"unzip" \
		"vim" \
	)

	for i in "${app_packages[@]}"
	do
		echo "Installing: " $i
		yum -y install $i >>~/postinstall_log.txt 2>>~/postinstall_errors.txt
		if [ $? -ne 0 ]; then
			echo "There was a problem installing " $i " see log file "
		fi
	done
}

get_install_files()
{

yum -y install curl postfix wget expect epel-release

if [ -d $tempFilesDir ] ; then
	slowecho "folder $tempFilesDir exists"
else
	slowecho "folder $tempFilesDir does not exist. Creating..."
	mkdir $tempFilesDir 
	slowecho "folder $tempFilesDir created."
fi

}

unpack_install_files()
{
cd $tempFilesDir

input=n

while !  [ -f islandoraStackPackages.tar.gz ] ; do
	slowecho "Please place the file islandoraStackPackages.tar.gz into $tempFilesDir" 
	sleep 4
done

	slowecho "unpacking tarball"

	tar -xzvf $tempFilesDir$installFilesTball
	rm -rf  $tempFilesDir$installFilesTball
	cd $tempFilesDir\islarepo
		
}


installing_php()
{

slowecho "installing php files"

        php_packages=( \
                "php " \ 
                "php-mysql " \ 
                "php-gd " \ 
                "php-ldap " \ 
                "php-odbc " \ 
                "php-pear " \ 
                "php-xml" \ 
                "php-xmlrpc " \ 
                "php-mbstring " \ 
                "php-snmp " \ 
                "php-soap " \ 
        )

        for i in "${php_packages[@]}"
        do
                echo "Installing: " $i
                yum -y install $i >>~/postinstall_log.txt 2>>~/postinstall_errors.txt
                if [ $? -ne 0 ]; then
                        echo "There was a problem installing " $i " see log file "
                fi
        done

}

yum -y install drush




slowecho ()
{
slowout="$1";
export slowout;
expect -c 'set send_human {.01 .02 5 .005 .005};
spawn -noecho echo $::env(slowout);
interact -indices -o -re ".+" { send_user -h -- "$interact_out(0,string)" }'
}

get_install_files
