
## h3-cli: Automated NodeZero deployment using a NodeZero Runner

Part of the process of running an _internal_ pentest involves launching the NodeZero Docker container on a 
Docker Host within your private network.  This is typically done by signing in to your Docker Host and 
manually running the Nodezero Launch Script provided in the Portal.

**A NodeZero Runner enables automated deployment of the NodeZero Docker container.** This allows you to provision and deploy pentests 
fully from the Portal, without having to manually run the NodeZero Launch Script. The NodeZero Runner is a 
background process running on your Docker Host that listens for newly provisioned pentests and runs the NodeZero 
Launch Script automatically. 

> A NodeZero Runner is used for _internal_ pentests only. For _external_ pentests, NodeZero is automatically deployed in the H3 cloud.

Spinning up a NodeZero Runner is easy.  At a high-level the steps are:

1. Create an API key for the Runner 
2. Install h3-cli on your Docker Host
3. Spin up the Runner using h3-cli

Once the NodeZero Runner is running, you can assign new pentests to it in the Portal (or via h3-cli).
A NodeZero Runner launches NodeZero only for pentests assigned to it.  

As your pentesting needs grow, you can spin up multiple NodeZero Runners across your network and assign pentests
to each of them, enabling autonomous pentesting from various subnets and perspectives within your environment.

The rest of this article walks through how to install and run a NodeZero Runner on your Docker Host.

## Installing and running a NodeZero Runner

There are two ways to install a Runner: 

1. The easy way, using the new easy_install.sh script that does most of the work for you.
2. The slightly more manual way of walking thru the installation steps.


## Install option #1: The easy way

Follow the steps below to install a NodeZero Runner on your Docker Host.

1. Visit the [Runners](https://portal.horizon3ai.com/runners) page in the Portal.
2. Click the **Install Runner** button, specify a name for the Runner, then click **Submit**.
3. Copy the provided installation command and run it on your Docker Host.

Barring any errors, **your NodeZero Runner is now up and running**.  The Runner will register itself
with the Portal and will be listed on the Runners page (you may need to refresh the page).  

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

### 1. Create an API key for the Runner

The NodeZero Runner communicates with the H3 API using h3-cli.  As such, it requires an API key.
API keys can be provisioned in the Portal [here](https://portal.horizon3ai.com/account-settings) (or [here](https://portal.horizon3ai.eu/account-settings) for EU).

We recommend setting the permission level to **NodeZero Runner**.  This is a specialized role created
just for NodeZero Runners, with very restricted access to your account.  The role 
**CANNOT** read existing pentest data, nor can it provision new pentests.  The only thing it 
can do is poll the API to detect when a pentest has been assigned to it, and then run the NodeZero Launch Script.


### 2. Install h3-cli on your Docker Host

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

### 3. Spin up the Runner using h3-cli

Use the following h3-cli command to spin up the NodeZero Runner:

```shell
h3 start-runner my-nodezero-runner /tmp/my-nodezero-runner.log
```

The NodeZero Runner process runs in the background and logs its output to the provided 
logfile, in this case `/tmp/my-nodezero-runner.log`.  The process is disconnected from 
the shell session, so it will continue to run in the background after you sign out.

Each NodeZero Runner is given a name, in this case `my-nodezero-runner`.  The name can 
be anything you want.  The name helps you identify the Runner when assigning pentests 
to it, especially if you spin up multiple Runners across your network.

To verify the Runner has connected to the H3 API and registered itself, run the command below:

```shell
h3 runners
```

You should see an entry for the Runner `my-nodezero-runner` that you just started.

You can now assign pentests to your NodeZero Runner and the Runner will automatically launch 
NodeZero.  You can tail the logfile to see it in action:

```shell
tail -f /tmp/my-nodezero-runner.log
```

## Additional notes about the Runner

* **Runs as:** The Runner process runs as the user that invoked `h3 start-runner`.
* **Background process:** The Runner process is disconnected from the shell session and runs in the background. It continues to run after the shell session is closed.
* **System reboot:** The Runner will NOT restart itself after a system reboot. To enable this, you can wire up `h3 start-runner` to your system launcher, eg. systemd, launchd, cron, etc.
* **Stop Runner:** To terminate the Runner process, use `h3 stop-runner`.
* **Delete Runner:** To delete a Runner, use `h3 delete-runner {name}`.
    * If a deleted Runner is still running, it will be recreated upon the next heartbeat.
* **Rename Runner:** You can NOT rename an existing Runner; however you can stop (and optionally delete) a Runner, then start a new Runner with a different name.
    * ❗ **NOTE:** if you saved the old Runner name to an op template, the template will need to be updated to use the new Runner name.


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
tail -f /tmp/my-nodezero-runner.log
```


### View Runner command errors

Use the following to list out the last 5 comands executed by the Runner.  The output includes the exit status and output from the command:

```shell
h3 runner-commands {runner_name}
```


### Docker permission errors

If your Docker Host requires `sudo` to run `docker` commands, then you may need to start the Runner using `sudo` as well.


### Retry

After resolving issues with your Runner, you can retry a NodeZero deployment by directly queuing a request to the Runner
using the following command.  Substitute `{op_id}` and `{runner_name}` for your specific usage.  

```shell
h3 run-nodezero-on-runner {op_id} {runner_name}
```

> You can use `h3 pentest` to get the `op_id` for the most recently created pentest.