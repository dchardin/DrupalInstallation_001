#!/bin/bash


tempFilesDir=/opt/tempFilesDir/
installFilesURL=http://www.ninedivines.club/islarepo/
installFilesTball=islandoraStackPackages.tar.gz

yum -y install expect epel-release

turn_off_selinux()
{
sed -i -e's/SELINUX=enforcing/SELINUX=permissive/' /etc/selinux/config
setenforce 0
slowecho "selinux set to permissive"
getenforce
}

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



installing_apache()
{

yum -y groupinstall web-server
systemctl start httpd
systemctl enable httpd
firewall-cmd --permanent --add-service=http
firewall-cmd --reload

slowecho "apache web server installed, enabled, and activated. Port 80 opened."

}



installing_mysql()
{

yum -y localinstall /opt/tempFilesDir/mysql80-community-release-el7-1.noarch.rpm

cp /etc/yum.repos.d/mysql-community.repo /etc/yum.repos.d/mysql-community.repo.original

awk -vRS='\n\n' -vORS='\n\n' '/\[mysql80-community/{sub(/enabled=1/,"enabled=0")}1;' /etc/yum.repos.d/mysql-community.repo

awk -vRS='\n\n' -vORS='\n\n' '/\[mysql57-community/{sub(/enabled=0/,"enabled=1")}1;' /etc/yum.repos.d/mysql-community.repo

yum -y install mysql mysql-community-server

systemctl start mysqld
systemctl enable mysqld

grep 'temporary password' /var/log/mysqld.log

slowecho "please enter the default password for mysql root user. You'll see it above."

mysqladmin -u root -p password

mysql_secure_installation <<EOF
n
y
y
y
y
EOF

slowecho "please enter your new DB password once more:"

read sqlrootpasswd 

mysql -u root -p$sqlrootpasswd -e "CREATE DATABASE drupaldbone CHARACTER SET utf8 COLLATE utf8_general_ci"
### SpartanDrupalAdm#1!


read drupaldbadminpwd


##This doesnt work yet
#mysql -u root -p$sqlrootpasswd -D drupaldbone -e "CREATE USER 'drupaldbadmin'@'localhost' IDENTIFIED BY $drupaldbadminpwd"

#CREATE USER 'drupaldbadmin'@'localhost' IDENTIFIED BY 'SpartanDrupaldbadmin#1!';

GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, INDEX, ALTER, CREATE TEMPORARY TABLES, LOCK TABLES ON drupaldbone.* TO 'drupaldbadmin'@'localhost';


}


install_drupal()
{
unzip /opt/tempFilesDir/drupal-7.59.zip -d /var/www/html/
mv /var/www/html/drupal-7.59/ drupal/
chown -R apache:apache /var/www/html/drupal/
semanage fcontext -a -t httpd_sys_rw_content_t "/var/www/html/drupal(/.*)?"
restorecon -RFv /var/www/html/drupal/
cp -p /var/www/html/drupal/sites/default/default.settings.php /var/www/html/drupal/sites/default/settings.php
chmod a+w /var/www/html/drupal/sites/default/settings.php 
chmod a+w /var/www/html/drupal/sites/default/
}




#lcr()
#{
#last=$(echo `history |tail -n2 |head -n1` | sed 's/[0-9]* //')
#slowecho "COMMAND: [$last] "
#}

#lcsf()
#{
#if [ $? -eq 0 ]
#then
#  lcr 
#  slowecho "SUCCESS::"
#else
#  lcr
#  slowecho "FAILURE::" >&2
#fi
#}


slowecho ()
{
slowout="$1";
export slowout;
expect -c 'set send_human {.01 .02 5 .005 .005};
spawn -noecho echo $::env(slowout);
interact -indices -o -re ".+" { send_user -h -- "$interact_out(0,string)" }'
}

get_install_files
