#!/bin/bash
#: Name         : shaft.sh
#: Author       : John Lehr <slo.sleuth@gmail.com>
#: Date         : 09/15/2011
#: Version      : 0.1.1
#: Description  : Install miscellaneous projects to support forensics
#: Options      : None
#: License      : GPLv3

#: 09/15/2011   : fixed rbfstab install, added shaft.sh update notice
#: 08/15/2011   : initial release

## To do
#: add uninstall option
#: clean up code after testing

## Variables
PYTSK_DEPS="mercurial python-dev uuid-dev libtsk-dev"
LINUXSLEUTHING_DEPS="ipod sqlite3 python3 libimobiledevice-utils yad"
LINUXSLEUTHING_TOOLS="nautilus-scripts iphone_tools blackberry_tools miscellaneous"
SHERAN_DEPS="git"
SHERAN_TOOLS="ConParse bbt evt2sqlite"

PROJECTS_DIR=/opt
INSTALL_DIR=/usr/local/bin
SCRIPTS_DIR=$HOME/.gnome2/nautilus-scripts

## Functions
install_pytsk()
{
    cd pytsk
    rm -rf build
    python setup.py build
    python setup.py install
    cp samples/tskfuse.py /usr/local/bin
    chmod +x /usr/local/bin/tskfuse.py
    cd $PROJECTS_DIR
}

install_linuxsleuthing()
{
    [ "$(md5sum /$PROJECTS_DIR/linuxsleuthing/shaft.sh)" = "$(md5sum /$INSTALL_DIR/shaft.sh)" ] || \
    UPDATED="shaft.sh updated, please rerun with 'sudo shaft.sh'"
    cp "$PROJECTS_DIR/linuxsleuthing/shaft.sh" "$INSTALL_DIR"
    for tool in $LINUXSLEUTHING_TOOLS
    do
        if [ "$tool" = "nautilus-scripts" ]
        then
            cp -R "$PROJECTS_DIR"/linuxsleuthing/nautilus-scripts/* $SCRIPTS_DIR
            cp -R "$PROJECTS_DIR"/linuxsleuthing/nautilus-scripts/* /root/.gnome2/nautilus-scripts
        else 
            cp "$PROJECTS_DIR"/linuxsleuthing/$tool/* "$INSTALL_DIR"
            [ "$tool" = "miscellaneous" ] && mv $INSTALL_DIR/rbfstab /usr/sbin
        fi
    done
}

install_sheran()
{
    [ "$tool" = "ConParse" ] && ln -s /opt/$tool/cparse.sh $INSTALL_DIR/cparse.sh
    [ "$tool" = "bbt" ] && ln -s /opt/$tool/bbt.py $INSTALL_DIR/bbt.py
    [ "$tool" = "evt2sqlite" ] && ln -s /opt/$tool/e2s.py $INSTALL_DIR/e2s.py
}

## Main Script

#: Check for proper permissions
if [ $UID -ne 0 ]
then
    echo "Must be run as root!" >&2
    exit 1
fi

#: Pull dependencies
echo -e "Updating sources and installing dependencies..."


grep -q slavino /etc/apt/sources.list #Check of yad repo and add if missing
if [ $? -gt 0 ]
then
    apt-add-repository 'deb http://debs.slavino.sk testing main non-free'
    wget -q http://debs.slavino.sk/repo.asc
    sudo apt-key add repo.asc && rm repo.asc
fi

apt-get -y -qq update
apt-get -y install $PYTSK_DEPS $LINUXSLEUTHING_DEPS $SHERAN_DEPS

#: Create directory for source packages
mkdir -p $PROJECTS_DIR
cd $PROJECTS_DIR

#: Install projects
for project in pytsk linuxsleuthing sheran
do
    if [ "$project" = "sheran" ]
    then
        for tool in $SHERAN_TOOLS
        do
            if [ -d "$PROJECTS_DIR/$tool" ]
            then
                echo -e "\nUpdating $tool..." >&2
                cd $PROJECTS_DIR/$tool
                status=$(git pull)
                [[ $status =~ up-to-date ]] && echo $status || install_sheran
            else
                echo -e "n\Downloading and installing $tool..." >&2
                cd $PROJECTS_DIR
                git clone https://github.com/sheran/${tool}.git
                install_sheran
            fi
        done
    else
        if [ -d "$PROJECTS_DIR/$project" ]
        then
            echo -e "\nUpdating $project..." >&2
            cd $PROJECTS_DIR/$project
            hg incoming 
            if [ $? = 0 ]
            then 
                hg pull
                hg update
                install_$project
            fi
        else
            echo -e "\nDownloading and installing $project..." >&2
            cd $PROJECTS_DIR
            hg clone http://code.google.com/p/$project $project
            install_$project
        fi
     fi
done

echo -e "\t$UPDATED"
exit 0
