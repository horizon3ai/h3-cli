
## h3-cli: Automated NodeZero deployment using a NodeZero Runner

Part of the process of running an _internal_ pentest involves launching the NodeZero Docker container on a 
Docker Host within your private network.  This is typically done by manually signing in to your Docker Host and 
running the NodeZero Launch Script provided in the Portal.

**A NodeZero Runner enables automated deployment of the NodeZero Docker container.** The NodeZero Runner is a 
background process running on your Docker Host that listens for newly provisioned pentests and runs the NodeZero 
Launch Script automatically. 

This allows you to provision and deploy pentests fully from the Portal, without having to manually sign in and run the NodeZero Launch Script.
It also enables you to run pentests on an [automated schedule](recurring-pentests.md).

> A NodeZero Runner is used for _internal_ pentests only. For _external_ pentests, NodeZero is automatically deployed in the H3 cloud.

Once a NodeZero Runner is up and running, you can assign new pentests to it from the Portal (or via h3-cli).
The Runner will launch NodeZero for the pentests assigned to it.  

As your pentesting needs grow, you can spin up multiple NodeZero Runners across your network and assign pentests
to each of them, enabling autonomous pentesting from various subnets and perspectives within your environment.


## Installing and running a NodeZero Runner

There are two ways to install a Runner: 

1. The easy way, using the new `easy_install.sh` script that does most of the work for you (recommended).
2. The slightly more manual way of walking thru the installation steps.


## Install option #1: The easy way (recommended)

Follow the steps below to install a NodeZero Runner on your Docker Host.

1. Visit the [Runners](https://portal.horizon3ai.com/runners) page in the Portal.
2. Click the **Install Runner** button, specify a name for the Runner, then click **Submit**.
3. Copy the provided installation command and run it on your Docker Host.

Barring any errors, **your NodeZero Runner is now up and running**.  The Runner will register itself
with the Portal and will be listed on the Runners page (you may need to refresh the page).  

**Auto-Restart:** If your Docker Host runs on a Linux system that supports `systemd`, the install script will attempt to 
register the Runner as a system service with `systemd`.  Once registered, `systemd` will automatically restart the Runner 
upon a system reboot. See [Auto-start Runner at system startup](#auto-start-runner-at-system-startup) for more info.

Behind the scenes, the above steps perform the following actions:

1. **Create an API key for the Runner.** The API key is granted **NodeZero Runner** permissions to the API.
This is a specialized role created just for NodeZero Runners, with very restricted access to your account. 
The role **CANNOT** read existing pentest data, nor can it provision new pentests.  The only thing it 
can do is poll the API to detect when a pentest has been assigned to it, and then run the NodeZero Launch Script.
2. **Install h3-cli on your Docker Host.** h3-cli is installed in a new `h3-cli` directory within the directory
where you ran the installation command.
3. **Spin up the Runner using h3-cli.** The NodeZero Runner process is started via the `h3 start-runner` command.


## Install option #2: The slightly more manual way

The steps below accomplish the same thing as install option #1, in a slightly more manual and transparent way. 

#### 1. Create an API key for the Runner

The NodeZero Runner communicates with the H3 API using h3-cli.  As such, it requires an API key.
API keys can be provisioned in the Portal [here](https://portal.horizon3ai.com/account-settings) (or [here](https://portal.horizon3ai.eu/account-settings) for EU).

We recommend setting the permission level to **NodeZero Runner**.  This is a specialized role created
just for NodeZero Runners, with very restricted access to your account.  The role 
**CANNOT** read existing pentest data, nor can it provision new pentests.  The only thing it 
can do is poll the API to detect when a pentest has been assigned to it, and then run the NodeZero Launch Script.


#### 2. Install h3-cli on your Docker Host

The NodeZero Runner process is started via the h3-cli.  Therefore, the h3-cli must be installed 
on your Docker Host.  

The quick-and-easy install steps are below.  Simply copy+paste the commands into a shell on your Docker Host.
For reference, full installation instructions are available [here](https://github.com/horizon3ai/h3-cli#installation-and-initial-setup).

```shell
git clone https://github.com/horizon3ai/h3-cli
cd h3-cli
bash install.sh {your-api-key-here}
export H3_CLI_HOME=`pwd`
export PATH="$H3_CLI_HOME/bin:$PATH"
```

The above steps will:

1. Install h3-cli from the public git repo
2. `cd` into the h3-cli dir
3. Run the install.sh script, substituting `{your-api-key-here}` with the API key you created in step 1 above.
4. Add h3-cli to your command `$PATH`

Once installed, run the command below to verify h3-cli is working and is using your newly provisioned API key:

```shell
h3 whoami
```

#### 3. Spin up the Runner using h3-cli

Use the following h3-cli command to spin up the NodeZero Runner:

```shell
h3 start-runner my-nodezero-runner /tmp/my-nodezero-runner.log
```

The NodeZero Runner process runs in the background and logs its output to the provided 
log file, in this case `/tmp/my-nodezero-runner.log`.  The process is disconnected from 
the shell session, so it will continue to run in the background after you sign out.

**Auto-Restart:** If your Docker Host runs on a Linux system that supports `systemd`, you can optionally 
register the Runner as a system service with `systemd`.  Once registered, `systemd` will automatically restart the Runner 
upon a system reboot. See [Auto-start Runner at system startup](#auto-start-runner-at-system-startup) for more info.

**Naming:** Each NodeZero Runner is given a name, in this case `my-nodezero-runner`.  The name can 
be anything you want, but it should be unique if you spin up multiple Runners across your network.
The name helps you identify the Runner when assigning pentests to it.

To verify the Runner has connected to the H3 API and registered itself, run the command below:

```shell
h3 runners
```

You should see an entry for the Runner `my-nodezero-runner` that you just started.
You can now assign pentests to your NodeZero Runner from the Portal and the Runner will automatically launch NodeZero.  

## Additional notes about the Runner

* **Runs as:** The Runner process runs as the user that invoked `h3 start-runner`.
* **Background process:** The Runner process is disconnected from the shell session and runs in the background. It continues to run after the shell session is closed.
* **Auto-Restart:** To enable auto-restart of the Runner on system reboot, see [Auto-start Runner at system startup](#auto-start-runner-at-system-startup).
* **Runner Log**: To view the Runner log, use `h3 tail-runner {name}`
* **Stop Runner:** To terminate the Runner process, use `h3 stop-runner {name}`.
* **Delete Runner:** To delete a Runner, use `h3 delete-runner {name}`.
    * This only deletes its registration record with H3. If a deleted Runner is still active, it will be re-registered upon its next heartbeat.
* **Unique Runner names:** Runner names should be treated as unique identifiers. Avoid re-using the same name for different Runners in your account.
* **Rename Runner:** You can NOT rename an existing Runner; however you can stop (and optionally delete) a Runner, then start a new Runner with a different name.
    * ❗ **NOTE:** if you saved the old Runner name to an op template, the template will need to be updated to use the new Runner name.
* **Auto-Injecting Credentials:** Runners can also be used to [auto-inject credentials](auto-inject-creds.md) into a pentest. 

## Troubleshooting

The NodeZero Runner polls the H3 API every 60s.  The last polling time is reported in the output
of `h3 runners`, in the `last_heartbeat_at` field.  If the Runner's last heartbeat is more than 
a minute ago, then the Runner process has either terminated or lost connectivity to the H3 API.
In which case, sign-in to your Docker Host and check the health and connectivity of the Runner.

Check if the Runner process is alive:

```shell
h3 ps-runner
```

This will list the Runner processes on the local machine.

Look for errors in the log: 

```shell
h3 tail-runner {runner_name}
```


### View Runner command errors

Use the following to list out the last 5 commands executed by the Runner.  The output includes the exit status and output from the command:

```shell
h3 runner-commands {runner_name}
```


### Docker permission errors

Example:
```shell
[#] Checking Docker functionality by running the hello-world test container:
[+] PASSED: Docker version installed meets the minimum required version 20.10.
[!] FAILED: Failed to validate Docker. Verify this account has permissions to run Docker and retry.
```

If your Docker Host requires `sudo` to run `docker` commands, then you may need to start the Runner using `sudo` as well.

Alternatively, you try adding the user that invokes `h3 start-runner` to the `docker` group, for example (using `ubuntu` user):
```shell
sudo usermod -aG docker ubuntu
sudo systemctl restart docker
```
(Note: Make sure to log out and back in after changing groups for the actively logged on user)


### Retry

After resolving issues with your Runner, you can retry a NodeZero deployment by directly queuing a request to the Runner
using the following command.  Substitute `{op_id}` and `{runner_name}` for your specific usage.  

```shell
h3 run-nodezero-on-runner {op_id} {runner_name}
```

> You can use `h3 pentest` to get the `op_id` for the most recently created pentest.



## Auto-start Runner at system startup

A common use case is to register your Runner to start automatically at system startup. 
This ensures that your Runner will continue working even after the system is rebooted.

In order to do this you must register the Runner with the system's boot service. 
Different systems have different boot services, but the most popular one used by various
Linux distributions is `systemd`.  

**h3-cli provides built-in support for `systemd`.**  To register your Runner with `systemd`, 
use the `h3 start-runner-service` command, example below.  Note the command will attempt 
to use `sudo` for running the necessary `systemd`/`systemctl` commands. 

```shell
h3 start-runner-service my-nodezero-runner /tmp/my-nodezero-runner.log
```

> If your system uses a different boot service than `systemd`, contact us for assistance with setting up your NodeZero Runner service. 

If all goes well, your NodeZero Runner is now registered as a service with `systemd`.  This means the Runner will...

* automatically start up at boot time
* automatically be restarted if it fails for any reason

The Runner service will be registered with `systemd` under the name `nodezero-runner-{runner-name}`.  For example the command above 
will register the service as `nodezero-runner-my-nodezero-runner`.


### Helpful `systemctl` commands for managing the Runner service

To view the status of the Runner service, use `systemctl status`, for example:

```shell
systemctl status nodezero-runner-my-nodezero-runner
```

To stop the Runner service:

```shell
sudo systemctl stop nodezero-runner-my-nodezero-runner
```

Note this will stop the current Runner service, but it will not de-register it from `systemd`.
This means the Runner service will be started again upon the next system boot.  To disable the Runner service such that 
it no longer starts at boot time, use `systemctl disable`, for example:

```shell
sudo systemctl disable nodezero-runner-my-nodezero-runner
```

To re-register the Runner service and re-enable it to start at boot time:

```shell
sudo systemctl enable nodezero-runner-my-nodezero-runner
```

To start the Runner service:

```shell
sudo systemctl start nodezero-runner-my-nodezero-runner
```

For more information related to `systemd` and `systemctl`, check out these resources:

* [How to use systemctl to manage Linux services](https://www.redhat.com/sysadmin/linux-systemctl-manage-services)
* [`systemctl` man page](https://www.freedesktop.org/software/systemd/man/systemctl.html)
* [`systemd` wiki](https://en.wikipedia.org/wiki/Systemd)



### Troubleshooting

* **209/STDOUT Error**: This typically means `systemd` could not start the service because it did not have 
permission to write to the log file (`/tmp/my-nodezero-runner.log` in the examples above).  Try chmod'ing the
log file or simply delete it and let `systemd` create a new one.

