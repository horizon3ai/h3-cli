#!/bin/bash 
# 
# deps: git, unzip or tar
#
# This script can be downloaded and executed using a single command:
#   $ curl https://raw.githubusercontent.com/horizon3ai/h3-cli/public/easy_install.sh | bash -s [ {api-key} [ {runner-name} [ {h3-env} [ {h3-download-url} ] ] ] ]
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

# Use $TMPDIR if defined, otherwise fallback to /tmp
TEMP_DIR=${TMPDIR:-/tmp}

function echoerr {
    echo "[`date`] $@" 1>&2;   
}

function echolog {
    if [ "$H3_CLI_VERBOSE" = "1" ]; then
        echo "[`date`] $@" 1>&2;   
    fi
}

function is_systemd_running {
    if ! command -v systemctl &> /dev/null; then
        return 1
    fi
    if ! command -v systemd-notify &> /dev/null; then
        return 1
    fi
    # below returns non-zero if "degraded" (some services did not start)
    # systemctl is-system-running --quiet
    systemd-notify --booted
    return $?
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

# :returns: download dir
function via_unzip_ng {
    # Set default download URL
    if ! command -v unzip &> /dev/null; then
        echoerr "ERROR: h3-cli requires unzip to download."
        return 1
    fi
    echoerr "INFO: Downloading via curl + unzip"
    zip_url="$H3_CLI_DOWNLOAD_URL"
    curl -sL $zip_url -o h3-cli.zip
    rc=$?
    if [ $rc -ne 0 ]; then
        echoerr "ERROR: curl $zip_url failed"
        exit 1
    fi
    unzip -qo h3-cli.zip -d h3-cli
    rc=$?
    if [ $rc -ne 0 ]; then
        echoerr "ERROR: unzip h3-cli.zip failed"
        exit 1
    fi
    echo "`pwd`/h3-cli"
}

# downloads into $H3_CLI_HOME
function download_h3_cli {
    echoerr "INFO: Downloading h3-cli into $H3_CLI_HOME ..."

    if [ -n "$H3_CLI_SKIP_DOWNLOAD" ]; then
        echoerr "WARN: Skipping h3-cli download due to H3_CLI_SKIP_DOWNLOAD=$H3_CLI_SKIP_DOWNLOAD"
        return 0
    fi

    if [ -n "$H3_CLI_DOWNLOAD_URL" ]; then
        echoerr "INFO: Attempting to download h3-cli via NodeZero Gateway (NG) into $H3_CLI_HOME ..."

        install_tmp_basedir="$TEMP_DIR/.h3-cli-install-tmp"
        mkdir -p "$install_tmp_basedir"
        cd "$install_tmp_basedir"
        tmp_d=`via_unzip_ng`
        rc=$?
        if [ $rc -ne 0 ]; then
            echoerr "ERROR: Failed to download h3-cli. Please check that your network has a connection to $H3_CLI_DOWNLOAD_URL, and try again."
            exit 1
        fi

    else
        echoerr "INFO: Attempting to download h3-cli via git into $H3_CLI_HOME ..."
        via_git_pull
        rc=$?
        if [ $rc -eq 0 ]; then
            return 0
        fi
        # download into tmp dir first, to handle diffs between download methods,
        # eg. how git creates h3-cli dir and the zip download creates h3-cli-public dir.
        install_tmp_basedir="$TEMP_DIR/.h3-cli-install-tmp"
        mkdir -p "$install_tmp_basedir"
        cd "$install_tmp_basedir"
        echoerr "INFO: Attempting to downloading h3-cli via GitHub into $H3_CLI_HOME ..."
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
    cp -R "$tmp_d/." "$H3_CLI_HOME" &>/dev/null
    rc=$?
    if [ $rc -ne 0 ]; then
        echoerr "cp of new files failed, trying with sudo..."
        sudo cp -R "$tmp_d/." "$H3_CLI_HOME"
    fi

    # clean up tmp dir (cd out of it first)
    cd "$H3_CLI_HOME"
    rm -Rf "$install_tmp_basedir"
}

# create empty profile if it does not exist
function ensure_profile {
    profile_file="$1"
    if [ ! -e "$profile_file" ]; then
        profile_dir=`dirname "$profile_file"`
        mkdir -p "$profile_dir"
        touch "$profile_file"
        chmod -R 700 "$profile_dir"
    fi
}

# add var_name=var_value to profile, or update if it already exists
# note: dup'ed in easy_install.sh
function upsert_profile_var {
    profile_file="$1"
    var_name="$2"
    var_value="$3"
    if [ -z "$var_value" ]; then
        return
    fi
    # make backup, remove old setting, add new setting
    mv "$profile_file" "$profile_file.tmp"
    cat "$profile_file.tmp" | grep -v "$var_name=" > "$profile_file"
    echo "$var_name=$var_value" >> "$profile_file"
    rm -f "$profile_file.tmp"
}

# check if necessary programs are installed
function check_deps {
    # Library checks for using NodeZero Gateway (NG) for h3-cli installation
    if [ -n "$H3_CLI_DOWNLOAD_URL" ]; then

        # Only .zip is supported for the NG
        if ! command -v unzip &> /dev/null; then
            echoerr "ERROR: h3-cli requires unzip to download."
            exit 1
        fi

    # Library checks for using GitHub for h3-cli installation
    else
        if ! command -v git &> /dev/null; then
            if ! command -v unzip &> /dev/null; then
                if ! command -v tar &> /dev/null; then
                    echoerr "ERROR: h3-cli requires git, unzip or tar to download."
                    exit 1
                fi
            fi
        fi
    fi
}

# ensure H3_CLI_HOME is set.
function ensure_h3_cli_home {
    if [ -z "$H3_CLI_HOME" ]; then
        path_to_h3=`which h3`
        if [ -n "$path_to_h3" ]; then
            H3_CLI_HOME=`dirname $(dirname "$path_to_h3")`
        fi
        if [ -z "$H3_CLI_HOME" ]; then
            H3_CLI_HOME="`pwd`/h3-cli"
        fi
    fi
    # ensure abs path
    if [[ "$H3_CLI_HOME" != "/"* ]]; then
        H3_CLI_HOME="$(cd "$(dirname "$H3_CLI_HOME")"; pwd)/$(basename "$H3_CLI_HOME")"
    fi
    mkdir -p "$H3_CLI_HOME"
}

function start_runner {
    runner_name="$1"
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
}

function ensure_H3_CLI_PROFILES_DIR {
    if [ -z "$H3_CLI_PROFILES_DIR" ]; then
        # check $HOME is defined and exists
        if [ -z "$HOME" -o ! -e "$HOME" ]; then 
            echoerr "ERROR: This script requires the HOME environent variable to be set to the user's home directory."
            exit 1
        fi
        H3_CLI_PROFILES_DIR="$HOME/.h3"
    fi
}

echoerr "INFO: Installing h3-cli ..."
api_key=$1
runner_name=$2
h3_env=$3
h3_download_url=$4

# x.
# ensure H3_CLI_PROFILES_DIR is set 
ensure_H3_CLI_PROFILES_DIR

# x.
# ensure global config file exists and update H3_CLI_DOWNLOAD_URL if provided
global_file="$H3_CLI_PROFILES_DIR/__global__.env"
ensure_profile "$global_file"
upsert_profile_var "$global_file" "H3_CLI_DOWNLOAD_URL" "$h3_download_url"
source "$global_file"

# x.
# ensure profile exists and update H3_CLI_DOWNLOAD_URL if provided
if [ -z "$H3_CLI_PROFILE" ]; then
    H3_CLI_PROFILE="default"
fi
profile_file="$H3_CLI_PROFILES_DIR/$H3_CLI_PROFILE.env"
ensure_profile "$profile_file"
upsert_profile_var "$profile_file" "H3_CLI_DOWNLOAD_URL" "$h3_download_url"
source "$profile_file"

# x.
# Check that dependencies are installed
check_deps

# x.
# determine H3_CLI_HOME, where h3-cli will be downloaded/upgraded.
ensure_h3_cli_home

# x.
# download/upgrade h3-cli
download_h3_cli

# x.
# run bash install.sh
cd "$H3_CLI_HOME"
echoerr "INFO: Running h3-cli install.sh in `pwd` ..."
bash install.sh $api_key $h3_env
rc=$?
if [ $rc -ne 0 ]; then 
    echoerr "ERROR: Failed to install h3-cli"
    exit 1
fi
export PATH="$H3_CLI_HOME/bin:$PATH"
echoerr "INFO: h3-cli installation complete. h3 version:"
h3 version

# x.
# Restart existing runners 
h3 restart-runner-services

# x.
# start runner (if specified)
start_runner "$runner_name"

echoerr "INFO: NodeZero Runner installation complete."

