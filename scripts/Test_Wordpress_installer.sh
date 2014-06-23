#!/bin/bash

#      Test Wordpress installer
#  
#
#      Copyright 2014 Farid Ahmadian <pesarkhobeee@gmail.com>
#      
#      This program is free software; you can redistribute it and/or modify
#      it under the terms of the GNU General Public License as published by
#      the Free Software Foundation; either version 2 of the License, or
#      (at your option) any later version.
#      
#      This program is distributed in the hope that it will be useful,
#      but WITHOUT ANY WARRANTY; without even the implied warranty of
#      MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#      GNU General Public License for more details.
#      
#      You should have received a copy of the GNU General Public License
#      along with this program; if not, write to the Free Software
#      Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
#      MA 02110-1301, USA.
#      
#      
#
############################################################
## Configurations ##########################################
############################################################
TITLE="Test Wordpress installer"
MYSQL_USER="root"
MYSQL_PASSWORD="password"
WORDPRESS_DIRECTORY="/home/farid/htdocs/"
WORDPRESS_VERSION="wordpress-3.8.2-fa_IR.zip"
############################################################
## Functions ###############################################
############################################################
mysql -u $MYSQL_USER "-p$MYSQL_PASSWORD" -e "DROP DATABASE IF EXISTS  WORDPRESS_TEST"
mysql -u $MYSQL_USER "-p$MYSQL_PASSWORD" -e "CREATE DATABASE WORDPRESS_TEST"
cd $WORDPRESS_DIRECTORY
rm -r Test_Wordpress/
unzip $WORDPRESS_VERSION -d Test_Wordpress
cd Test_Wordpress/wordpress
mv * ../
cd ..
mv wp-config-sample.php wp-config.php
sed -i "s/database_name_here/WORDPRESS_TEST/g" wp-config.php
sed -i "s/username_here/$MYSQL_USER/g" wp-config.php
sed -i "s/password_here/$MYSQL_PASSWORD/g" wp-config.php
