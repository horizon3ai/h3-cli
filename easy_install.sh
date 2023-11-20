#!/bin/bash 
# 
# deps: git, unzip or tar
#
# This script can be downloaded and executed using a single command:
#   $ curl https://raw.githubusercontent.com/horizon3ai/h3-cli/public/easy_install.sh | bash -s [{api-key}] [{runner-name}]
#
# The script downloads h3-cli and runs the install script (install.sh), passing in the {api-key}, if provided.
#
# If h3-cli is already installed, this script will upgrade it to the latest version.
#
# By default the script installs into a new h3-cli directory under the current directory.
# If env var H3_CLI_HOME is defined, the script installs/upgrades into that directory.
#
# If a {runner-name} is provided, the script starts a NodeZero Runner with the given name.
#
# By default the script creates/updates the default h3-cli profile (~/.h3/default.env).
# If H3_CLI_PROFILE is defined, the script will instead create/update the h3-cli profile 
# with that name (~/.h3/$H3_CLI_PROFILE.env).
# 
#


function echoerr { 
    echo "[`date`] $@" 1>&2;   
}

function echolog { 
    if [ "$H3_CLI_VERBOSE" = "1" ]; then
        echo "[`date`] $@" 1>&2;   
    fi
}

# :dep H3_CLI_HOME:
function via_git_pull {
    if ! command -v git &> /dev/null; then
        return 1
    fi
    if [ ! -d "$H3_CLI_HOME/.git" ]; then 
        return 1
    fi
    echoerr "INFO: $H3_CLI_HOME/.git detected; upgrading via git pull"
    cd $H3_CLI_HOME
    git pull
}

# :returns: download dir
function via_git_clone {
    if ! command -v git &> /dev/null; then
        return 1
    fi
    echoerr "INFO: Downloading via git "
    git clone https://github.com/horizon3ai/h3-cli.git
    rc=$?
    if [ $rc -ne 0 ]; then 
        echoerr "ERROR: git clone failed"
        exit 1
    fi
    echo "`pwd`/h3-cli"
}

# :returns: download dir
function via_unzip {
    if ! command -v unzip &> /dev/null; then
        return 1
    fi
    echoerr "INFO: Downloading via curl + unzip"
    zip_url=https://github.com/horizon3ai/h3-cli/archive/refs/heads/public.zip
    curl -sL $zip_url -o h3-cli-public.zip
    rc=$?
    if [ $rc -ne 0 ]; then 
        echoerr "ERROR: curl $zip_url failed"
        exit 1
    fi
    unzip -qo h3-cli-public.zip 
    rc=$?
    if [ $rc -ne 0 ]; then 
        echoerr "ERROR: unzip h3-cli-public.zip failed"
        exit 1
    fi
    echo "`pwd`/h3-cli-public"
}

# :returns: download dir
function via_tar {
    if ! command -v tar &> /dev/null; then
        return 1
    fi
    echoerr "INFO: Downloading via curl + tar"
    tar_url=https://github.com/horizon3ai/h3-cli/archive/refs/heads/public.tar.gz 
    curl -sL $tar_url | tar -zx
    rc=$?
    if [ $rc -ne 0 ]; then 
        echoerr "ERROR: curl $tar_url | tar failed"
        exit 1
    fi
    echo "`pwd`/h3-cli-public"
}

# downloads into $H3_CLI_HOME
function download_h3_cli {
    echoerr "INFO: Downloading h3-cli into $H3_CLI_HOME ..."
    via_git_pull
    rc=$?
    if [ $rc -eq 0 ]; then 
        return 0
    fi
    # download into tmp dir first, to handle diffs between download methods,
    # eg. how git creates h3-cli dir and the zip download creates h3-cli-public dir.
    install_tmp_basedir="`pwd`/.h3-cli-install-tmp"
    mkdir -p "$install_tmp_basedir"
    cd "$install_tmp_basedir"
    tmp_d=`via_git_clone`
    rc=$?
    if [ $rc -ne 0 ]; then 
        tmp_d=`via_unzip`
        rc=$?
        if [ $rc -ne 0 ]; then 
            tmp_d=`via_tar`
            rc=$?
            if [ $rc -ne 0 ]; then 
                echoerr "ERROR: Failed to download h3-cli repo"
                exit 1
            fi
        fi
    fi
    # move into the target dir 
    cp -R "$tmp_d/." "$H3_CLI_HOME"
    # clean up tmp dir
    rm -Rf "$install_tmp_basedir"
}


echoerr "INFO: Installing h3-cli ..."
api_key=$1
runner_name=$2


# 0.
# check deps
if ! command -v git &> /dev/null; then
    if ! command -v unzip &> /dev/null; then
        if ! command -v tar &> /dev/null; then
            echoerr "ERROR: h3-cli requires git, unzip or tar to download."
            exit 1
        fi 
    fi
fi


# 1. 
# determine H3_CLI_HOME, where h3-cli will be downloaded/upgraded.
if [ -z "$H3_CLI_HOME" ]; then
    H3_CLI_HOME=`dirname $(dirname $(which h3))`
    if [ -z "$H3_CLI_HOME" ]; then
        H3_CLI_HOME="`pwd`/h3-cli"
    fi
fi
mkdir -p "$H3_CLI_HOME"


# 2.
# download/upgrade h3-cli
download_h3_cli 


# 3. 
# run bash install.sh
cd "$H3_CLI_HOME"
echoerr "INFO: Running h3-cli install.sh in `pwd` ..."
bash install.sh $api_key
rc=$?
if [ $rc -ne 0 ]; then 
    echoerr "ERROR: Failed to install h3-cli"
    exit 1
fi
export PATH="$H3_CLI_HOME/bin:$PATH"
echoerr "INFO: h3-cli installation complete. h3 version:"
h3 version


# 4.
# start runner (if specified)
if [ -z "$runner_name" ]; then 
    echolog "DEBUG: runner_name not provided, will not start a NodeZero Runner"
    exit 0
fi
h3 start-runner-service "$runner_name" 
rc=$?
if [ $rc -ne 0 ]; then 
    echoerr "INFO: Failed to start the NodeZero Runner as a systemd service."
    echoerr "      Starting the NodeZero Runner as a standalone background process instead ..."
    h3 start-runner "$runner_name" 
fi

echoerr "INFO: NodeZero Runner installation complete."

