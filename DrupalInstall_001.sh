#!/bin/bash

get_install_files()
{

yum -y install wget expect
tempFilesDir=/opt/tempFilesDir
installFilesURL=http://www.ninedivines.club/islarepo/
installFilesTball=islandoraStackPackages.tar.gz


if [ -d $tempFilesDir ] ; then
	slowecho "folder $tempFilesDir exists"
else
	slowecho "folder $tempFilesDir does not exist. Creating..."
	mkdir $tempFilesDir 
	slowecho "folder $tempFilesDir created."
fi

cd $tempFilesDir

wget $installFilesURL$installFilesTball

}







slowecho ()
{
slowout="$1";
export slowout;
expect -c 'set send_human {.01 .02 5 .005 .005};
spawn -noecho echo $::env(slowout);
interact -indices -o -re ".+" { send_user -h -- "$interact_out(0,string)" }'
}

get_install_files
