#!/bin/bash
#
# install script for h3-cli
#
# usage: bash install.sh [{h3-api-key}]
#
# 1. install jq
# 1b. install yq (currently disabled)
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


# 0.
# verify this script is being run from the h3-cli dir.
H3_CLI_HOME=`pwd`

if [ -z "$H3_CLI_HOME" -o ! -e "$H3_CLI_HOME/bin/h3-env" ]; then 
    echoerr "ERROR: This script must be run from the h3-cli root directory."
    exit 1
fi

if [ -z "$HOME" -o ! -e "$HOME" ]; then 
    echoerr "ERROR: This script requires the HOME environent variable to be set to the user's home directory."
    exit 1
fi

# chmod executable
chmod -R a+x $H3_CLI_HOME/bin


# 1. 
# install jq 
echo 
echo "[.] Checking if jq is already installed ..."
jqv=`jq --version 2>&1`
if [ $? -ne 0 ]; then
    jq_url=`pick_jq_url`
    echo "[.] Installing jq from $jq_url ... "
    curl -s -L $jq_url -o $H3_CLI_HOME/bin/jq
    chmod -R a+x $H3_CLI_HOME/bin
   
    # verify
    echo "[.] Verifying $H3_CLI_HOME/bin/jq ... "
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

# 1b. 
# install yq
# echo "[.] Checking if yq is already installed ..."
# yqv=`jy --version 2>&1`
# if [ $? -ne 0 ]; then
#     yq_url=`pick_yq_url`
#     echo "[.] Installing yq from $yq_url ... "
#     curl -s -L $yq_url -o $H3_CLI_HOME/bin/yq
#     chmod -R a+x $H3_CLI_HOME/bin
#    
#     # verify
#     echo "[.] Verifying $H3_CLI_HOME/bin/yq ... "
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


# 2. 
# create .h3 profile.
# allow no API key to be specified.  in which case, we'll check if the {profile}.env already exists, and if it doesn't, 
# we'll create it and prompt the user to populate it. 
echo 
API_KEY_UNSPECIFIED="your-api-key-here"     # NOTE: keep in sync with h3-env.
H3_API_KEY=$1
if [ -z "$H3_API_KEY" ]; then 
    H3_API_KEY=$API_KEY_UNSPECIFIED
fi

# if H3_CLI_PROFILE is already set, use it, otherwise set to "default".
if [ -z "$H3_CLI_PROFILE" ]; then
    H3_CLI_PROFILE="default"
fi

# if ~/.h3/{profile}.env does not exist, create it and populate it with H3_API_KEY.
profile_file="$HOME/.h3/$H3_CLI_PROFILE.env"
if [ ! -e "$profile_file" ]; then 
    echo "[.] Creating h3-cli profile [$H3_CLI_PROFILE] under $HOME/.h3 ..."
    mkdir -p $HOME/.h3
    cat <<HERE > "$profile_file"
H3_API_KEY=$H3_API_KEY
HERE
    chmod -R 700 $HOME/.h3

# if ~/.h3/{profile}.env does exist, AND an api key was provided, then update the profile.
elif [ "$H3_API_KEY" != "$API_KEY_UNSPECIFIED" ]; then
    echo "[.] Updating h3-cli profile [$H3_CLI_PROFILE] under $HOME/.h3 ..."
    mv "$profile_file" "$profile_file.bak"
    cat "$profile_file.bak" | sed "s/H3_API_KEY=.*/H3_API_KEY=$H3_API_KEY/" > "$profile_file"

# the profile exists, and H3_API_KEY was not provided.
# read it in so H3_API_KEY gets set.  
# down below we check if it's set to API_KEY_UNSPECIFIED and prompt the user to set it.
else
    echo "[.] h3-cli profile [$H3_CLI_PROFILE] already defined under $HOME/.h3 "
    source "$profile_file"
fi

# delete existing cached jwt, if any
jwt_file="$HOME/.h3/$H3_CLI_PROFILE.jwt"
rm -f "$jwt_file"

# prompt the user if no API key was specified
if [ "$H3_API_KEY" = "$API_KEY_UNSPECIFIED" ]; then
    cat <<HERE

[!] ACTION REQUIRED: 
[!] Please set your API key in $profile_file. 
[!] Or you can re-run this script and provide the API key as a parameter:  
        $ bash install.sh {h3-api-key}

HERE
else
    echo "[.] DONE"
fi


# 3. 
# profile updates
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
[!] Run the following commands to add h3 to your command PATH. 
[!] We also recommend adding them to $bash_profile, so that h3 is automatically added to the PATH when you login.

export H3_CLI_HOME=$H3_CLI_HOME
export PATH="\$H3_CLI_HOME/bin:\$PATH"

HERE




