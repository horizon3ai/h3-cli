#!/bin/bash
#
# install script for h3-cli
#
# usage: ./install.sh {h3-api-key}
#
# 1. install jq
# 1b. install yq
# 2. chmod h3-cli/bin
# 3. create ~/.h3 profile
# 4. update ~/.bash_profile
# 

# writes message to stderr
# usage: echoerr "the message"
function echoerr { 
    echo "$@" 1>&2;   
}


# uname examples:
# mac M1:   Darwin MacBook-Pro.local 20.1.0 Darwin Kernel Version 20.1.0: Sat Oct 31 00:07:10 PDT 2020; root:xnu-7195.50.7~2/RELEASE_ARM64_T8101 arm64
# mac x86:  Darwin Roberts-MacBook-Pro-3.local 20.6.0 Darwin Kernel Version 20.6.0: Tue Apr 19 21:04:45 PDT 2022; root:xnu-7195.141.29~1/RELEASE_X86_64 x86_64
# linux:    Linux dev.linuxize.com 4.19.0-6-amd64 #1 SMP Debian 4.19.67-2+deb10u1 (2019-09-20) x86_64 GNU/Linux
function get_system_type {
    u=`uname -s`
    m=`uname -m`
    if [[ "$u" == *"Linux"* ]]; then
        if [[ "$m" == *"64"* ]]; then
            echo "LINUX_64"
            return 0
        else
            echo "LINUX_32"
            return 0
        fi
    fi
    if [[ "$m" == *"64"* ]]; then
        echo "MACOS_64"
        return 0
    else 
        echo "MACOS_32"
        return 0
    fi
}

 
function pick_jq_url {
    system_type=`get_system_type`
    u=`uname -a`
    if [ "$system_type" = "LINUX_64" ]; then
        echo "https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64"
        return 0
    elif [ "$system_type" = "LINUX_32" ]; then
        echo "https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux32"
        return 0
    elif [ "$system_type" = "MACOS_64" ]; then
        echo "https://github.com/stedolan/jq/releases/download/jq-1.6/jq-osx-amd64"
        return 0
    else 
        echo "https://github.com/stedolan/jq/releases/download/jq-1.4/jq-osx-x86"
        return 0
    fi
}


# TODO: improve system identification
function pick_yq_url {
    system_type=`get_system_type`
    u=`uname -a`
    if [ "$system_type" = "LINUX_64" ]; then
        echo "https://github.com/mikefarah/yq/releases/download/v4.30.4/yq_linux_amd64"
        return 0
    elif [ "$system_type" = "LINUX_32" ]; then
        echo "https://github.com/mikefarah/yq/releases/download/v4.30.4/yq_linux_amd64"
        return 0
    elif [ "$system_type" = "MACOS_64" ]; then
        echo "https://github.com/mikefarah/yq/releases/download/v4.30.4/yq_darwin_amd64"
        return 0
    else 
        echo "https://github.com/mikefarah/yq/releases/download/v4.30.4/yq_darwin_amd64"
        return 0
    fi
}


H3_API_KEY=$1
H3_CLI_HOME=`pwd`

if [ -z "$H3_API_KEY" ]; then 
    echoerr "usage: ./install.sh {h3-api-key}"
    exit 1
fi

if [ -z "$H3_CLI_HOME" -o `basename $H3_CLI_HOME` != 'h3-cli' ]; then 
    echoerr "ERROR: This script must be run from the h3-cli directory."
    exit 1
fi

if [ -z "$HOME" -o ! -e "$HOME" ]; then 
    echoerr "ERROR: This script requires the HOME environent variable to be set to the user's home directory."
    exit 1
fi


# 0. chmod executable
chmod -R a+x $H3_CLI_HOME/bin


# 1. install jq 
echo 
echo "[.] checking if jq is already installed ..."
jqv=`jq --version 2>&1`
if [ $? -ne 0 ]; then
    jq_url=`pick_jq_url`
    echo "[.] installing jq from $jq_url ... "
    curl -s -L $jq_url -o $H3_CLI_HOME/bin/jq
    chmod -R a+x $H3_CLI_HOME/bin
   
    # verify
    echo "[.] verifying $H3_CLI_HOME/bin/jq ... "
    jqv=`$H3_CLI_HOME/bin/jq --version`
    if [ $? -ne 0 ]; then
        rm -f $H3_CLI_HOME/bin/jq   # cleanup
        echo "[!] ACTION REQUIRED: failed to install jq"
        echo "[!] Please install jq from https://stedolan.github.io/jq/download/"
        echo "[!] After installing jq, re-run this install script"
        exit 1
    fi
fi
echo "[.] DONE"

# 1b. install yq
# echo "[.] checking if yq is already installed ..."
# yqv=`jy --version 2>&1`
# if [ $? -ne 0 ]; then
#     yq_url=`pick_yq_url`
#     echo "[.] installing yq from $yq_url ... "
#     curl -s -L $yq_url -o $H3_CLI_HOME/bin/yq
#     chmod -R a+x $H3_CLI_HOME/bin
#    
#     # verify
#     echo "[.] verifying $H3_CLI_HOME/bin/yq ... "
#     yqv=`$H3_CLI_HOME/bin/yq --version`
#     if [ $? -ne 0 ]; then
#         rm -f $H3_CLI_HOME/bin/yq   # cleanup
#         echo "[!] ACTION REQUIRED: failed to install yq"
#         echo "[!] Please install yq from https://github.com/mikefarah/yq/#install"
#         echo "[!] After installing yq, re-run this install script"
#         exit 1
#     fi
# fi
# echo "[.] DONE"


# 2. create .h3 profile
echo 
if [ ! -e "$HOME/.h3/default.env" ]; then 
    echo "[.] creating h3-cli profile under $HOME/.h3 ..."
    mkdir -p $HOME/.h3
    cat <<HERE > $HOME/.h3/default.env
H3_API_KEY=$H3_API_KEY
HERE
    chmod -R 700 $HOME/.h3
else 
    echo "[.] h3-cli profile already exists under $HOME/.h3"
fi
echo "[.] DONE"


# 3. profile updates
bash_profile=$HOME/.bash_profile
if [ ! -e "$bash_profile" ]; then 
    bash_profile=$HOME/.bash_login
    if [ ! -e "$bash_profile" ]; then 
        bash_profile=$HOME/.profile
        if [ ! -e "$bash_profile" ]; then 
            bash_profile="your shell login profile"
        fi
    fi
fi
cat <<HERE

[!] ACTION REQUIRED: 
[!] Add the following lines to $bash_profile, then re-login to your shell session to pick up the changes.

export H3_CLI_HOME=$H3_CLI_HOME
export PATH="\$H3_CLI_HOME/bin:\$PATH"

HERE









