#!/bin/bash


tempFilesDir=/opt/tempFilesDir/
installFilesURL=http://www.ninedivines.club/islarepo/
installFilesTball=islandoraStackPackages.tar.gz
optBin=/opt/bin/

mkdir $tempFilesDir
mkdir $optBin


yum -y install expect epel-release

installChrome()
{

cat << EOF > /etc/yum.repos.d/google-chrome.repo
[google-chrome]
name=google-chrome
baseurl=http://dl.google.com/linux/chrome/rpm/stable/x86_64
enabled=1
gpgcheck=1
gpgkey=https://dl.google.com/linux/linux_signing_key.pub
EOF

yum -y install google-chrome-stable
#may have to turn off gpg checking if needed

}

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

install_flash()
{

wget http://linuxdownload.adobe.com/adobe-release/adobe-release-x86_64-1.0-1.noarch.rpm
yum -y localinstall adobe-release-x86_64-1.0-1.noarch.rpm

yum -y install flash-plugin alsa-plugins-pulseaudio libcurl


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

clean_urls()
{

}


increase_max_upload()

{

cp /etc/php.ini /etc/php.ini.original
sed -i -e's/upload_max_filesize = 2M/upload_max_filesize = 2048M/' /etc/php.ini
sed -i -e's/post_max_filesize = 8M/post_max_filesize = 2048M/' /etc/php.ini
sed -i -e's/memory_limit = 128M/memory_limit = 256M/' /etc/php.ini

}


java_install()

{

yum -y localinstall jdk-8u162-linux-x64.rpm
alternatives --install /usr/bin/java java /usr/java/jdk1.8.0_162/bin/java 200000
alternatives --install /usr/bin/javaws javaws /usr/java/jdk1.8.0_162/bin/javaws 200000

#now use alternatives --config java

cat << EOF >> /etc/profile.d/fedora-profile.sh

JAVA_HOME=/usr/java/jdk1.8.0_162
FEDORA_HOME=/usr/local/fedora
CLASSPATH=$JAVA_HOME/jre/lib
CATALINA_HOME=$FEDORA_HOME/tomcat
JAVA_OPTS="$JAVA_OPTS -Djavax.net.ssl.trustStore=$FEDORA_HOME/server/truststore"
JAVA_OPTS="$JAVA_OPTS -Djavax.net.ssl.trustStorePassword=tomcat"
JAVA_OPTS="$JAVA_OPTS -Xmx512m"
PATH="$PATH:$FEDORA_HOME/server/bin:$FEDORA_HOME/client/bin:/opt/apache-maven-3.5.3/bin"
LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$CATALINA_HOME/lib
JRE_HOME=/usr/java/jdk1.8.0_162/jre
J2SDKDIR=/usr/java/jdk1.8.0_162
J2REDIR=/usr/java/jdk1.8.0_162/jre
KAKADU_LIBRARY_PATH=/usr/local/djatoka/lib/Linux-x86-64
export JAVA_HOME CLASSPATH CATALINA_HOME JAVA_OPTS FEDORA_HOME LD_LIBRARY_PATH JRE_HOME J2SDKDIR J2REDIR KAKADU_LIBRARY_PATH PATH

EOF

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

install_fedoracommons()
{
mysql -u root -p
create database fedora3;
create user 'fedora3dbadmin'@'%' identified by 'password';
grant all on fedora3.* to 'fedora3dbadmin'@'%';
alter database fedora3 default character set utf8;
alter database fedora3 default collate utf8_bin;
flush privileges;
exit;

[root@libdev-f tempFilesDir]# java -jar /opt/tempFilesDir/fcrepo-installer-3.8.1.jar 

***********************
  Fedora Installation 
***********************

To install Fedora, please answer the following questions.
Enter CANCEL at any time to abort the installation.
Detailed installation instructions are available online:

            https://wiki.duraspace.org/display/FEDORA/All+Documentation

Installation type
-----------------
The 'quick' install is designed to get you up and running with Fedora    
as quickly and easily as possible. It will install Tomcat and an         
embedded version of the Derby database. SSL support and XACML policy     
enforcement will be disabled.                                            
For more options, including the choice of hostname, ports, security,     
and databases, select 'custom'.                                          
To install only the Fedora client software, enter 'client'.

Options : quick, custom, client

Enter a value ==> custom


Fedora home directory
---------------------
This is the base directory for Fedora scripts, configuration files, etc.  
Enter the full path where you want to install these files.


Enter a value [default is /usr/local/fedora] ==> 


Fedora administrator password
-----------------------------
Enter the password to use for the Fedora administrator (fedoraAdmin) account.

Enter a value ==> SpartanFedoraAdmin#1!


Fedora server host
------------------
The host Fedora will be running on.                                        
If a hostname (e.g. www.example.com) is supplied, a lookup will be         
performed and the IP address of the host (not the host name) will be used  
in the default Fedora XACML policies.


Enter a value [default is localhost] ==> libdev-f.uncg.edu                                


Fedora application server context
---------------------------------
The application server context Fedora will be running in.                  
If 'fedora' (default) is supplied, the resulting context path              
will be http://www.example.com/fedora.                                     
It must be ensured that the configured application server context          
matches this path if explicitly configured.


Enter a value [default is fedora] ==> 


Authentication requirement for API-A
------------------------------------
Fedora's management (API-M) interface always requires user authentication. 
Require user authentication for Fedora's access (API-A) interface?

Options : true, false

Enter a value [default is false] ==> 


SSL availability
----------------
Should Fedora be available via SSL?  Note: this does not preclude   
regular HTTP access; it just indicates that it should be possible for     
Fedora to be accessed over SSL.

Options : true, false

Enter a value [default is true] ==> 


SSL required for API-A
----------------------
Should API-A be accessible exclusively via SSL?  If true, requests 
to access API-A URLs will be automatically redirected to the secure port.

Options : true, false

Enter a value [default is false] ==> 


SSL required for API-M
----------------------
Should API-M be accessible exclusively via SSL?  If true, requests 
to access API-M URLs will be automatically redirected to the secure port.

Options : true, false

Enter a value [default is true] ==> false


Servlet engine
--------------
Which servlet engine will Fedora be running in?                          
Enter 'included' to use the bundled Tomcat 6.0.35 server.                
To use your own, existing installation of Tomcat, enter 'existingTomcat'.
Enter 'other' to use a different servlet container.

Options : included, existingTomcat, other

Enter a value [default is included] ==> 


Tomcat home directory
---------------------
Please provide the full path to your existing Tomcat installation, or  
the path where you plan to install the bundled Tomcat.


Enter a value [default is /tomcat] ==> 


Tomcat HTTP port
----------------
Which HTTP port (non-SSL) should Tomcat listen on?  This can be changed   
later in Tomcat's server.xml file.


Enter a value [default is 8080] ==> 


Tomcat shutdown port
--------------------
Which port should Tomcat use for shutting down?  Make sure this doesn't   
conflict with an existing service.  This can be changed later in Tomcat's 
server.xml file.


Enter a value [default is 8005] ==> 


Tomcat Secure HTTP port
-----------------------
Which port (SSL) should Tomcat listen on?  This can be changed            
later in Tomcat's server.xml file.


Enter a value [default is 8443] ==> 


Keystore file
-------------
For SSL support, Tomcat requires a keystore file.                         
If the keystore file is located in the default location expected by       
Tomcat (a file named .keystore in the user home directory under which     
Tomcat is running), enter 'default'.                                      
Otherwise, please enter the full path to your keystore file, or, enter    
'included' to  use the the  sample, self-signed certificate) provided by  
the installer.                                                            
For more information about the keystore file, please consult:             
http://tomcat.apache.org/tomcat-6.0-doc/ssl-howto.html.

Enter a value ==> included


Database
--------
Please select the database you will be using with   
Fedora. The supported databases are Derby, MySQL, Oracle and Postgres.     
If you do not have a database ready for use by Fedora or would prefer to   
use the embedded version of Derby bundled with Fedora, enter 'included'.

Options : derby, mysql, oracle, postgresql, included

Enter a value ==> mysql


MySQL JDBC driver
-----------------
You may either use the included JDBC driver or your own copy.              
Enter 'included' to use the included JDBC driver, or, enter the location   
(full path) of the driver.


Enter a value [default is included] ==> 


Database username
-----------------
Enter the database username Fedora will use to connect to the Fedora database.

Enter a value ==> fedora3dbadmin


Database password
-----------------
Enter the database password Fedora will use to connect to the Fedora database.

Enter a value ==> SpartanFedora3dbAdmin#1!


JDBC URL
--------
Please enter the JDBC URL.


Enter a value [default is jdbc:mysql://localhost/fedora3?useUnicode=true&amp;characterEncoding=UTF-8&amp;autoReconnect=true] ==> 


JDBC DriverClass
----------------
Please enter the JDBC driver class.


Enter a value [default is com.mysql.jdbc.Driver] ==> 


Validating database connection...Successfully connected to MySQL
OK

Use upstream HTTP authentication (Experimental Feature)
-------------------------------------------------------
You may wish to rely on a local SSO or other external source for HTTP 
authentication and subject attributes. 
WARNING: This is an experimental feature and should be enabled only with the
understanding that integration with external authentication will require 
further configuration and that this is not yet a stable Fedora feature. 
We invite you to try it out and give us feedback.  
Use upstream authentication?

Options : true, false

Enter a value [default is false] ==> 


Enable FeSL AuthZ (Experimental Feature)
----------------------------------------
Enable FeSL Authorization? This is an experimental replacement for Fedora's 
legacy authorization module, and is still under development.                
Production repositories should NOT enable this, but we invite you to try it 
out and give us feedback.


Enter a value [default is false] ==> 


Policy enforcement enabled
--------------------------
Should XACML policy enforcement be enabled?  Note: This will put a set of 
default security policies in play for your Fedora server.

Options : true, false

Enter a value [default is true] ==> 


Low Level Storage
-----------------
Which low-level (file) storage plugin do you want to use?                  
We recommend akubra-fs for new installs.  If you are upgrading Fedora from 
version 3.3 or below, you should use legacy-fs for compatibility with your 
existing storage.  Other plugins are also available, but they must be      
configured after installation.

Options : akubra-fs, legacy-fs

Enter a value [default is akubra-fs] ==> 


Enable Resource Index
---------------------
Enable the Resource Index?

Options : true, false

Enter a value [default is false] ==> true


Enable Messaging
----------------
Enable Messaging? Messaging sends notifications of API-M events via JMS.

Options : true, false

Enter a value [default is false] ==> true


Messaging Provider URI
----------------------
Please enter the messaging provider URI. For more information about        
using ActiveMQ broker URIs, see                                            
http://activemq.apache.org/broker-uri.html


Enter a value [default is vm:(broker:(tcp://localhost:61616))] ==> 


Deploy local services and demos
-------------------------------
Several sample back-end services are included with this distribution.      
These are required if you want to use the demonstration objects.           
If you'd like these to be automatically deployed, enter 'true'.            
Otherwise, the installer will put the files in your FEDORA_HOME/install    
directory in case you want to deploy them later.

Options : true, false

Enter a value [default is true] ==> 


Preparing FEDORA_HOME...
	Configuring fedora.fcfg
	Installing beSecurity
Installing Tomcat...
Preparing fedora.war...
Deploying fedora.war...
Deploying fop.war...
Deploying imagemanip.war...
Deploying saxon.war...
Deploying fedora-demo.war...
Installation complete.

----------------------------------------------------------------------
Before starting Fedora, please ensure that any required environment
variables are correctly defined
	(e.g. FEDORA_HOME, JAVA_HOME, JAVA_OPTS, CATALINA_HOME).
For more information, please consult the Installation & Configuration
Guide in the online documentation.
----------------------------------------------------------------------

}


fedora3xcaml()
{
rm -rf /usr/local/fedora/data/fedora-xacml-policies/repository-policies/default/deny-purge-*

#command below should place a directory called islandora
tar -xvf /opt/tempFilesDir/fedIslaXacml.tar.gz /usr/local/fedora/data/fedora-xacml-policies/repository-policies/
}


drupalFilterInstall()
{

cp -v /opt/tempFilesDir/fcrepo-drupalauthfilter-3.8.1.jar $FEDORA_HOME/tomcat/webapps/fedora/WEB-INF/lib


####

# vim $FEDORA_HOME/server/config/jaas.conf

##Find the section similar to the one below 


#fedora-auth
#{
#        org.fcrepo.server.security.jaas.auth.module.XmlUsersFileModule required
#        debug=true;
#};



and make it look exactly like this.

#fedora-auth
#{
#org.fcrepo.server.security.jaas.auth.module.XmlUsersFileModule required
#debug=true;
#ca.upei.roblib.fedora.servletfilter.DrupalAuthModule required
#debug=true;
#};

####

cp /opt/tempFilesDir/filter-drupal.xml
chown apache:apache filter-drupal.xml

#exit the file and input drupal db name, user name, and password for drupal's database


tar -xzvf /opt/tempFilesDir/drupal_filter_validator.tar.gz 
mv drupal_filter_validator /opt/bin/

# use drupal filter validator to see if it works.

}


moduleInstall()
{

tar -xzvf drupalIslaLibsModules.tar.gz -C /var/www/html/drupal/sites/

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
