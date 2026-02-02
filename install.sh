#!/bin/bash
#
# install script for h3-cli.
#
# usage: bash install.sh [ {h3-api-key} [ {h3-env} ] ]
#
# this script:
# 1. validates env
# 2. installs deps (jq) 
# 3. writes the h3-cli profile to $HOME/.h3/$H3_CLI_PROFILE.env
#       - by default H3_CLI_PROFILE="default"
#       - if you want to install a different profile, export H3_CLI_PROFILE=<profile_name> before running this script.
# 

# x.
# verify this script is being run from the h3-cli dir.
H3_CLI_HOME=`pwd`
if [ -z "$H3_CLI_HOME" -o ! -e "$H3_CLI_HOME/bin/h3-env" ]; then 
    echo "ERROR: This script must be run from the h3-cli root directory." 1>&2
    exit 1
fi

# x.
# load utils
source $H3_CLI_HOME/bin/h3-utils

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

# pick the jq download URL based on system type
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

# pick the jq download URL based on system type, via NG
function pick_jq_url_ng {
    system_type=`get_system_type`
    u=`uname -a`
    if [ "$system_type" = "LINUX_64" ]; then
        echo "https://downloads.horizon3ai.com/utilities/cli/jq/jq-1.6/jq-linux64"
        return 0
    elif [ "$system_type" = "LINUX_32" ]; then
        echo "https://downloads.horizon3ai.com/utilities/cli/jq/jq-1.6/jq-linux32"
        return 0
    elif [ "$system_type" = "MACOS_64" ]; then
        echo "https://downloads.horizon3ai.com/utilities/cli/jq/jq-1.6/jq-osx-amd64"
        return 0
    else
        echo "https://downloads.horizon3ai.com/utilities/cli/jq/jq-1.4/jq-osx-x86"
        return 0
    fi
}

# install jq if not already installed
function install_jq {
    echo 
    echo "[.] Checking if jq is already installed ..."
    jqv=`jq --version 2>&1`
    if [ $? -ne 0 ]; then
        # if H3_CLI_DOWNLOAD_URL is set, we use the ng for jq, else we use the default jq download URL.
        if [ -z "$H3_CLI_DOWNLOAD_URL" ]; then
            jq_url=`pick_jq_url`
        else
            jq_url=`pick_jq_url_ng`
        fi
        echo "[.] Installing jq from $jq_url ... "
        curl -s -L $jq_url -o $H3_CLI_HOME/bin/jq
        chmod -R a+x $H3_CLI_HOME/bin &>/dev/null

        rc=$?
        if [ $rc -ne 0 ]; then
            echoerr "chmod jq failed, trying with sudo..."
            sudo chmod -R a+x $H3_CLI_HOME/bin
        fi
    
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
}

# update H3_AUTH_URL and H3_GQL_URL based on h3_env input parm.
# if h3_env defined, use it.
# otherwise fallback to existing H3_AUTH_URL and H3_GQL_URL values (if any were 
# already sourced from the profile).
function set_auth_urls {
    h3_env=$1
    if [ -z "$h3_env" ]; then
        return

    # if the env starts with https://api, then assume it's a URL and set the H3_AUTH_URL and H3_GQL_URL accordingly.
    elif [[ "$h3_env" == "https://api"* ]]; then
        clean_h3_env="${h3_env%/}"  # remove trailing slash if any
        H3_AUTH_URL="$clean_h3_env/v1/auth"
        H3_GQL_URL="$clean_h3_env/v1/graphql"

    # A non-empty h3_env was provided, try one of the predefined environments.
    else
        case $h3_env in
            "prod")
                H3_AUTH_URL="https://api.horizon3ai.com/v1/auth"
                H3_GQL_URL="https://api.horizon3ai.com/v1/graphql"
                ;;
            "prod_eu")
                H3_AUTH_URL="https://api.horizon3ai.eu/v1/auth"
                H3_GQL_URL="https://api.horizon3ai.eu/v1/graphql"
                ;;
            "fh-prod")
                H3_AUTH_URL="https://api.gateway.gov-horizon3ai.com/v1/auth"
                H3_GQL_URL="https://api.gateway.gov-horizon3ai.com/v1/graphql"
                ;;
            "us")
                H3_AUTH_URL="https://api.gateway.horizon3ai.com/v1/auth"
                H3_GQL_URL="https://api.gateway.horizon3ai.com/v1/graphql"
                ;;
            "eu")
                H3_AUTH_URL="https://api.gateway.horizon3ai.eu/v1/auth"
                H3_GQL_URL="https://api.gateway.horizon3ai.eu/v1/graphql"
                ;;
            "fed-fh")
                H3_AUTH_URL="https://api.gateway.gov-horizon3ai.com/v1/auth"
                H3_GQL_URL="https://api.gateway.gov-horizon3ai.com/v1/graphql"
                ;;
            "fed-h3")
                return
                ;;
        esac
    fi
}

# ensure the bin dir scripts are executable
function chmod_bin_dir {
    chmod -R a+x $H3_CLI_HOME/bin &>/dev/null
    rc=$?
    if [ $rc -ne 0 ]; then
        echoerr "chmod executables failed, trying with sudo..."
        sudo chmod -R a+x $H3_CLI_HOME/bin
    fi
}

# x.
# chmod h3-cli/bin
chmod_bin_dir

# x.
# verify this script is being run from the h3-cli dir.
ensure_H3_CLI_PROFILES_DIR

# x.
# source global profile
global_file="$H3_CLI_PROFILES_DIR/__global__.env"
ensure_profile "$global_file"
source "$global_file"

# x.
# source H3_CLI_PROFILE, if exists
# this may populate H3_API_KEY, H3_AUTH_URL, H3_GQL_URL, H3_CLI_DOWNLOAD_URL, etc,
# which we'll use if they are not overridden by input parms.
# if H3_CLI_PROFILE is already set, use it, otherwise set to "default".
if [ -z "$H3_CLI_PROFILE" ]; then
    H3_CLI_PROFILE="default"
fi
profile_file="$H3_CLI_PROFILES_DIR/$H3_CLI_PROFILE.env"
ensure_profile "$profile_file"
source "$profile_file"

# x.
# install jq 
install_jq

# x. 
# determine H3_API_KEY.
# if provided as input parm, use that.
# if not provided as input parm, AND it's not already set in the profile, then
# set it to H3_API_KEY=your-api-key-here, which is a placeholder we check for and 
# prompt the user to set later.
API_KEY_UNSPECIFIED="your-api-key-here"     # NOTE: keep in sync with h3-env.
h3_api_key=$1
if [ -n "$h3_api_key" ]; then
    H3_API_KEY="$h3_api_key"
elif [ -z "$H3_API_KEY" ]; then
    H3_API_KEY=$API_KEY_UNSPECIFIED
fi

# x.
# determine GQL and AUTH endpoints
# if they are specified on the command line, use those.
# otherwise we'll use what's already in the profile (if any).
h3_env=$2
set_auth_urls "$h3_env"

# x.
# update the profile
echo
echo "[.] Saving h3-cli profile [$H3_CLI_PROFILE] to $profile_file ..."
backup_profile "$profile_file"
upsert_profile_var "$profile_file" "H3_API_KEY" "$H3_API_KEY"
upsert_profile_var "$profile_file" "H3_AUTH_URL" "$H3_AUTH_URL"
upsert_profile_var "$profile_file" "H3_GQL_URL" "$H3_GQL_URL"
upsert_profile_var "$profile_file" "H3_CLI_DOWNLOAD_URL" "$H3_CLI_DOWNLOAD_URL"

# x.
# delete existing cached jwt, if any
jwt_file="$H3_CLI_PROFILES_DIR/$H3_CLI_PROFILE.jwt"
rm -f "$jwt_file"

# x.
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

# x. 
# prompt user to update bash profile 
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




