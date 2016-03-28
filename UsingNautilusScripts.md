## Introduction ##

The Nautilus file manager includes a "nautilus-scripts" folder where scripts are stored. All executable files in this folder will appear in the Scripts menu, accessible from the nautilus browser window by right-clicking on a file, folder, or unused area of the window and selecting "Scripts."

## Details ##
### Installing the Nautilus-Scripts Found on this Site ###
Download the latest tar file from the [Downloads](http://code.google.com/p/linuxsleuthing/downloads/list) page.

```
$ tar xzvf nautilus-scripts-{version}.tar.gz
$ cp -a nautilus-scripts ~/.gnome2/
```

Test that the installation was successful by opening a Nautilus browser, right-clicking a file or folder, and selection "Scripts."  You should see a tree with contents matching the archive you decompressed with the tar command.

If the scripts successfully copied to the ~/.gnome2/nautilus-scripts directory but are not visible in the right-click menu, the issue is most likely that the scripts are not executable.  Make executable with:

```
$ chmod -R +x ~/.gnome2/nautilus-scripts
```

### Installing Your Own Script ###

To install a nautilus script of your own or downloaded from another source, copy the script to the "$HOME/.gnome2/nautilus-scripts" folder and give the user executable permission.  This can be done with the chmod command:

```
$ chmod +x script.sh
```

### Viewing Installed Scripts ###

To view the contents of your scripts folder, if you already have scripts installed, in a Nautilus window, choose **File | Scripts | Open Scripts Folder**.

> Note: You will have to navigate to the scripts folder ( "~/.gnome2/nautilus-scripts" ) with the file manager if you do not yet have any scripts. You may need to show hidden files for this, use **View | Show Hidden Files**.

### Using Scripts ###

In the Nautilus File Manager, select the file(s) or folder(s) on which the script will operate.  Right-click on the selected item(s), and select **Scripts | _Script_**.

> Note: Scripts may be organized in directories and require further navigation.

### Additional Information ###

Additional information can be found about Nautilus scripts in the [GNOME Documentation Library](http://library.gnome.org/users/user-guide/stable/gosnautilus-444.html.en).