#!/bin/bash

#      PM(project manager)
#  
#      This file is part of PM  
#
#      Copyright 2011 Farid Ahmadian <pesarkhobeee@gmail.com>
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
TITLE="Project manajer"
TMP="/tmp/TMP"
WIDTH="60"
HIGHT="20"
WEB_SERVER_DIRECTORY="/var/www/html/"
SLASH_COUNT_OF_WWW=4
MYSQL_DIRECTORY="/var/lib/mysql/"
SLASH_COUNT_OF_DB=4
BACKUP_DIRECTORY="/home/pesarkhobeee/web_project_manager/"
SLASH_COUNT_OF_BACKUP=4
USER="pesarkhobeee"
############################################################
## Functions ###############################################
############################################################
initial () {
    if [ ! -f $BACKUP_DIRECTORY ]; then
            mkdir $BACKUP_DIRECTORY
    fi
}

welcome() {
    MSG1="\n Welcome to Project Manager"
    MSG2="\n By : Farid Ahmadian"
    MSG="$MSG1$MSG2"

    dialog  --backtitle "$TITLE"    \
            --title " Welcome "     \
            --msgbox "$MSG" 8 0
}

showmenu() {
    dialog  --backtitle "$TITLE"            \
            --title " Main Menu "           \
            --cancel-label "Exit"           \
            --menu                          \
            "May I Help You ?" 0 0 5        \
            "1" "Show Web Site Folders"                     \
            "2" "Show Archive Web Sites"            \
            "3" "Archive a Web Site"                \
            "4" "Enable a Archive Web Site"                 \
            2> $TMP

            if [ "$?" == "1" ]; then
                    rm $TMP
                    clear
                    echo "GoodBye !!!"
                    exit 0;
            fi

            CHOICE=$(cat $TMP)
            rm $TMP
}

show_web_site(){
   
    dialog  --backtitle "$TITLE"    \
            --title " $WEB_SERVER_DIRECTORY "       \
            --msgbox "$(ls $WEB_SERVER_DIRECTORY)" 16 0
}

show_archive_web_site(){
    dialog  --backtitle "$TITLE"    \
            --title " $BACKUP_DIRECTORY "   \
            --msgbox "$(ls $BACKUP_DIRECTORY)" 16 0
}

archive_a_web_site(){
   
   

    dialog --dselect $WEB_SERVER_DIRECTORY $HIGHT $WIDTH  2> $TMP
    SELECTED_WEB_DIRECTORY=$(cat $TMP)
    dialog  --dselect $MYSQL_DIRECTORY $HIGHT $WIDTH  2> $TMP
    SELECTED_DB_DIRECTORY=$(cat $TMP)
    dialog  --yesno "are you sure from your selection ? \n $SELECTED_WEB_DIRECTORY \n $SELECTED_DB_DIRECTORY" 0 0
    if [ "$?" == "1" ]; then
            continue
    fi

    WWW_FOLDER_NAME=$(echo $SELECTED_WEB_DIRECTORY|cut -d/ -f$(($SLASH_COUNT_OF_WWW+1)))
    cd $BACKUP_DIRECTORY
    mkdir $WWW_FOLDER_NAME
    cd $WWW_FOLDER_NAME
    mkdir www
    mkdir db
    cd $WEB_SERVER_DIRECTORY       
    tar -cjf $BACKUP_DIRECTORY$WWW_FOLDER_NAME"/www/"$WWW_FOLDER_NAME $WWW_FOLDER_NAME     
    cd $MYSQL_DIRECTORY
    DB_FOLDER_NAME=$(echo $SELECTED_DB_DIRECTORY|cut -d/ -f$(($SLASH_COUNT_OF_DB+1)))
    tar -cjf $BACKUP_DIRECTORY$WWW_FOLDER_NAME"/db/"$DB_FOLDER_NAME $DB_FOLDER_NAME
    chown $USER":"$USER $BACKUP_DIRECTORY
    rm -rf $SELECTED_WEB_DIRECTORY
    rm -rf $SELECTED_DB_DIRECTORY
    rm $TMP

}

enable_a_archive_web_site(){

    dialog  --dselect $BACKUP_DIRECTORY $HIGHT $WIDTH  2> $TMP
    cd $BACKUP_DIRECTORY
    SELECTED_DIRECTORY=$(cat $TMP)
    FOLDER_NAME=$(echo $SELECTED_DIRECTORY|cut -d/ -f$(($SLASH_COUNT_OF_BACKUP+1)))
    dialog  --yesno "are you sure you want to extract $FOLDER_NAME ?" 0 0
    if [ "$?" == "1" ]; then
            continue
    fi
    cd $WEB_SERVER_DIRECTORY
    tar -xjf "$BACKUP_DIRECTORY$FOLDER_NAME/www/"$(ls "$BACKUP_DIRECTORY$FOLDER_NAME/www/")
    cd $MYSQL_DIRECTORY
    tar -xjf "$BACKUP_DIRECTORY$FOLDER_NAME/db/"$(ls "$BACKUP_DIRECTORY$FOLDER_NAME/www/")
    rm -rf $BACKUP_DIRECTORY$FOLDER_NAME
    rm $TMP
}


############################################################
## Main ####################################################
############################################################
welcome
initial
while [ true ]; do
    showmenu
    case "$CHOICE" in
            "1")
                    show_web_site
                    ;;
            "2")
                    show_archive_web_site
                    ;;

            "3")
                    archive_a_web_site
                    ;;
            "4")
                    enable_a_archive_web_site
                    ;;
    esac
done

