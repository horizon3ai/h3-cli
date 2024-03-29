
## h3-cli: CLI tool for the Horizon3.ai API

h3-cli is a convenient CLI (command-line interface) for accessing the 
Horizon3.ai API. The Horizon3.ai API provides programmatic access to a subset 
of functionality available through the Horizon3.ai Portal.  At a high level, 
the API allows you to:

* schedule an autonomous pentest
* download and run NodeZero™
* monitor the status of a pentest while it is running
* retrieve a pentest report after it's complete

The API can be used for a variety of use cases such as scheduling periodic assessments 
of your environment or kicking off a pentest as part of a continuous integration build pipeline.

## Installation and initial setup

The steps below will get you up and running quickly with h3-cli. These instructions were tested on 
macOS and Linux machines, and generally should work on any [POSIX-compliant](https://en.wikipedia.org/wiki/POSIX) system with bash support.

If you plan to run _internal_ pentests using h3-cli, you should install h3-cli on the same Docker Host
where you launch NodeZero.

It is assumed you already have an account with Horizon3.ai.  If not, sign up
at [https://portal.horizon3ai.com/](https://portal.horizon3ai.com/).


### 1. Create an API key

An API key is required to access the H3 API.  You can create one in the Portal under the [User -> Account Settings](https://portal.horizon3ai.com/account-settings) menu.

When creating an API key you must assign it a role that controls its permissions.  The available roles are:

* **User:** Basic read/write permissions. The API key can run pentests and read results.
* **Read-only:** The API key can read pentest results, but cannot run pentests.
* **NodeZero Runner:** A specialized, heavily restricted role designed specifically for [NodeZero Runners](guides/touchless-nodezero.md).  

We recommend the **User** role if you're testing out h3-cli and want to experiment with all its features. 
After that, you may want to use more restrictive permissions, based on your use case.  For example, if you only
want to use h3-cli to set up a NodeZero Runner, we recommend using the **NodeZero Runner** role.  

You can easily manage multiple API keys within the same h3-cli install.  Learn more [here](#authentication--h3-cli-profiles).

❗ **Keep your API key secure, as anyone with your API key can access your H3 account.**  Think of an API key as
a username + password rolled into one.  Anyone with the API key can access your account from anywhere.  h3-cli
will store your API key under the `$HOME/.h3` directory.  This directory is created during installation and 
configured with permissions such that only you can read or write to it.  


### 2. Install h3-cli 

Install the [h3-cli git repo](https://github.com/horizon3ai/h3-cli) on your machine by executing the following git command within a shell/terminal session.  

```shell
git clone https://github.com/horizon3ai/h3-cli
```

This will create a new directory, `h3-cli`, and download the contents of the repo to it.  The `h3-cli` directory
will be created in the directory where you run the git command.  You can install h3-cli anywhere on the filesystem.

If you don't have git, you can download the repo as a zip archive from the menu above, and unzip it anywhere on the filesystem.


### 3. Run the h3-cli install script

Run the following commands to install and configure h3-cli.  Substitute `your-api-key-here` with your actual API key.

```shell
cd h3-cli
bash install.sh your-api-key-here
```

The install script will install dependencies (jq) and create your default h3-cli profile under the `$HOME/.h3` directory.
Your API key is stored in your h3-cli profile.  The directory and profile permissions are restricted so that no other
users (besides yourself) can read or write to it.

The install script will ask you to edit your shell profile (`$HOME/.bash_profile` or `$HOME/.bash_login` or `$HOME/.profile`, depending
on your operating system) to set the following environment variables:

* `H3_CLI_HOME`: this environment variable is used by h3-cli to locate itself and its supporting files.
* `PATH`: this environment variable specifies the directories to be searched to find a shell command.

After updating your shell profile, re-login or restart your shell session to pick up the profile changes,
then verify you can invoke h3 by running it from the command prompt:

```shell
h3
```

If everything's installed correctly, you should see the h3-cli help text.


## Upgrading h3-cli

We release new features, bug fixes, and other updates for the h3-cli every month.  Upgrade your installation using
one of the methods below.

#### Option 1: Via the `h3 upgrade` command (recommended)

As of June, 2023, you can use the `h3 upgrade` command to upgrade to the latest version of h3-cli.

If you get an `ERROR: unrecognized command: "upgrade"`, then you are on a previous version of h3-cli that does not 
support the upgrade command.  Use one of the methods below to upgrade h3-cli.

#### Option 2: Via `easy_install.sh` (recommended if `h3 upgrade` is unavailable)

Run this command from h3-cli's parent directory (i.e. the directory that contains the `h3-cli/` directory):

```shell
curl https://raw.githubusercontent.com/horizon3ai/h3-cli/public/easy_install.sh | bash 
```

#### Option 3: Via git

If you used `git clone` to install the repo, then simply run `git pull` to install the latest version.

#### Option 4: Via zip download

If you downloaded the repo as a zip file, then re-download the zip file and unzip it to the same location (in other words replace
your existing h3-cli installation with the new zip).

#### Checking the current version

As of June, 2023, you can view your current version of h3-cli via:

```shell
h3 version
```


## Getting started 

### 1. Verify connectivity with the API

Run the following command to verify connectivity with the API.

```shell
h3 hello-world
```

You should see the response:

```shell
{
  "data": {
    "hello": "world!"
  }
}
```

❗️ If you are getting an error response, please contact H3 via the chat icon in the [Horizon3.ai Portal](https://portal.horizon3ai.com/).


### 2. Query the list of pentests in your account

The command below will return the list of pentests in your account, most recent first.

```shell
h3 pentests 
```

To filter for pentests that match a given search term, pass the search term as a parameter:

```shell
h3 pentests sample
```

### 3. Query a specific pentest from your account

To query the most recent pentest in your account:

```shell
h3 pentest
```

To query any pentest in your account, pass the `op_id` of the pentest as a parameter:

```shell
h3 pentest your-op-id-here
```

Several h3-cli commands will use the most recent pentest as the default,
unless an `op_id` is passed as a parameter.

> The terms "op" and "pentest" are often used interchangeably.


### 4. Run a pentest

Running a pentest requires specifying an _op template_.  An op template specifies a full pentest configuration,
which includes scope, attack parameters, and other (optional) configuration.

Horizon3.ai provides new users with a default op template named `Default 1 - Recommended`.  This template is always 
up-to-date with our latest attack parameters and recommended configuration.  The default template does not define a scope,
in which case NodeZero will use _Intelligent Scope_ - NodeZero's host subnet will provide the initial scope, and it will expand 
organically during the pentest as more hosts and subnets are discovered.  For more information on Intelligent Scope and other 
deployment options, visit our [product documentation](https://docs.horizon3.ai/getting_started/n0_host/deployment/).

For experienced users, custom op template(s) may be created via the [Horizon3.ai Portal](https://portal.horizon3ai.com/).
To create a custom op template, walk through the _Run a Pentest_ modal until you see the 
option to customize the pentest configuration. The op template can be created without actually running the pentest. 

To provision a pentest using the default op template and Intelligent Scope:

```shell
h3 run-pentest
```

The JSON response contains the details for the newly created pentest.
You can verify the pentest is provisioning by checking your [Horizon3.ai Portal](https://portal.horizon3ai.com/pentests),
or by running `h3 pentest`.  

There are several ways to specify additional parameters when creating pentests. For more information [see additional examples here](#running-pentests-with-h3-cli).

❗ **WAIT! YOU'RE NOT DONE!**

For _internal_ pentests (which are the default), additional steps are required before the pentest will begin running.
See the next section about downloading and running NodeZero in order to complete the initiation of your pentest.

> If you are running an _external_ pentest, NodeZero is launched for you automatically in the H3 cloud as part of `h3 run-pentest`,
in which case there are no additional steps on your end to initiate the pentest.


### 5. Run NodeZero

❗ **️The following step applies to _internal_ pentests only; for _external_ pentests, NodeZero is launched for you automatically in the H3 cloud.**

After creating an _internal_ pentest, you then have to run our NodeZero container on a Docker Host inside your network.
This is done by running the NodeZero Launch Script on your Docker Host.  

To run the NodeZero Launch Script for your most recently created pentest:

```shell
h3 run-nodezero
```

**YOUR PENTEST HAS BEEN LAUNCHED!**  Assuming all commands ran without error, then you have 
successfully created and launched your pentest.  You should see output from the NodeZero Launch Script being logged
to the console.  The script will first verify your system is compatible with NodeZero before downloading and running it.
When the pentest is complete, NodeZero will automatically shut itself down.  

NodeZero is a Docker container.  You can view it using `docker ps`.  The container name will be of the form `n0-xxxx`.


### 6. Download pentest reports

After your pentest has finished, use the following command to download a zip file containing all PDF and CSV reports
for the most recently created pentest:

```shell
h3 pentest-reports
```

The above command will download the zip file to `pentest-reports-{op_id}.zip` in the current directory.


## Use cases

* [**Automated NodeZero deployment using a NodeZero Runner.**](guides/touchless-nodezero.md) Learn how to use a NodeZero Runner 
to deploy NodeZero on your Docker Host automatically, without having to manually copy+paste the NodeZero Launch Script.
* [**Automated scheduling.**](guides/recurring-pentests.md) Learn how to run pentests automatically on a regular schedule, 
for example once a week or once a month.
* [**Auto-injected credentials.**](guides/auto-inject-creds.md) Learn how to automatically inject credentials into a 
regularly scheduled pentest using a NodeZero Runner. 
* [**Monitoring pentests.**](guides/monitor-pentests.md) Learn how to monitor pentests using h3-cli.
* [**Paginating results.**](guides/paginate-results.md) Learn how to paginate through large result sets using h3-cli.
* [**JSON Parsing using `jq`.**](guides/json-parsing-with-jq.md) Learn how to leverage the power of `jq` to parse JSON responses 
from h3-cli.  `jq` can parse specific fields, print the structure of a response, and even transform a JSON response to CSV.  



## Authentication & h3-cli profiles

Authentication happens seamlessly and automatically when you invoke the `h3` command.
There's nothing explicit you need to do to authenticate.  This section documents the 
underlying mechanics.

h3-cli reads your `H3_API_KEY` from your h3-cli profile (under `$HOME/.h3`) to authenticate 
to the Horizon3.ai API and establish a (temporary) session.  The session token (a JWT) is 
cached under `$HOME/.h3`. The session token expires after 1 hour, at which point h3-cli will
automatically re-authenticate and re-establish a session.

You can explicitly authenticate using the following command: 

```shell
h3 auth
```

The above command will output the session token (and also cache it under `$HOME/.h3`).
If you already have an established (non-expired) session token, `h3 auth` will continue to use 
that session token rather than re-authenticate. 

If you want to _force_ h3-cli to re-authenticate, use the `force` option:

```shell
h3 auth force
```


### h3-cli profiles

You can manage multiple h3-cli authentication profiles under the same `$HOME/.h3` directory.
Each h3-cli profile has its own API key.

When you first install h3-cli it will automatically create an initial profile named `default`
with the API key you provided to `install.sh`. 

If you wish to create another profile with a different API key, use the following command:

```shell
h3 save-profile my-profile {api-key}
```

This will create a profile named `my-profile` under `$HOME/.h3` for the given `{api_key}`.
To activate the profile in your current shell session, use the following command (note the leading dot `.`): 

```shell
. h3 profile my-profile
```

You can verify the currently active profile using `h3 profile`, and view details about its API key using `h3 whoami`:

```shell
h3 profile
h3 whoami
```

You can save multiple API keys under different h3-cli profiles and switch between them as needed using the command above.
For example, to switch back to the `default` profile:

```shell
. h3 profile default
```

To view the list of h3-cli profiles under your `$HOME/.h3` directory:

```shell
h3 profiles
```

You can delete a profile from your `$HOME/.h3` directory using: 

```shell
h3 delete-profile {name}
```

This will remove the profile named `{name}` and its API key from your `$HOME/.h3` directory on the local machine. 
Note that it will NOT *revoke* the API key; it only deletes it from the local machine. You can revoke the API key from the Portal.



## Running pentests with h3-cli

This section contains additional examples for running pentests using h3-cli.

The simplest way to provision a pentest is to use the default op template and _Intelligent Scope_:

```shell
h3 run-pentest
```

To provision a pentest AND launch NodeZero on the local machine (for _internal_ pentests only):

```shell
h3 run-pentest-and-nodezero
```

Note that this only applies to _internal_ pentests. For _external_ pentests, NodeZero is launched for you automatically in the H3 cloud as part of `h3 run-pentest`.

> If you happen to run `h3 run-pentest-and-nodezero` for an external pentest, it will simply skip the part where it downloads and runs NodeZero, since 
that is handled automatically in the H3 cloud.

To run a pentest using a custom op template, specify it as a parameter to [schedule_op_template.graphql](queries/schedule_op_template.graphql):

```shell
h3 run-pentest '{"op_template_name":"your-op-template-here"}' 
```

To run a pentest using the default op template but assign it a name of your choosing, use the optional `op_name` parameter: 

```shell
h3 run-pentest '{"op_name":"your-op-name-here"}' 
```

To run a pentest using the default op template but specify its name and scope, use the optional `schedule_op_form` parameter:

```shell
h3 run-pentest '{"schedule_op_form":{"op_name":"your-op-name-here", "op_param_max_scope": "192.168.0.0/24"}}' 
```

> Note that `h3 run-pentest` and `h3 run-pentest-and-nodezero` accept all the same optional parameters.


To run a pentest and assign it to a [NodeZero Runner](guides/touchless-nodezero.md) named `my-nodezero-runner`:

```shell
h3 run-pentest '{"schedule_op_form":{"op_name":"Pentest created via h3-cli and launched via runner", "runner_name":"my-nodezero-runner"}}' 
```


### Running external pentests

If you have an op template configured for your external pentest:

```shell
h3 run-pentest '{"op_template_name":"your-op-template-here"}' 
```

If you do NOT have an op template, you can run an external pentest by first looking up your Asset Group's uuid via `h3 asset-groups`:

```shell
h3 asset-groups
```

Then use the command below to run an external pentest against that Asset Group.  Substitute your Asset Group's uuid for `{your-asset-group-uuid}`:

```shell
h3 run-pentest '{"schedule_op_form": {"op_type": "ExternalAttack", "asset_group_uuid": "{your-asset-group-uuid}"}}' 
```



## Powered by GraphQL

The Horizon3.ai API is powered by GraphQL.  In addition to this CLI document, relevant documentation includes:

- [Horizon3.ai Docs](https://docs.horizon3ai.com/)
- [GraphQL.org](https://graphql.org/)


### Advanced: Writing your own GraphQL queries

h3-cli provides a simple mechanism to run your own GraphQL queries.  First you define the 
GraphQL query in a file (typically with a `.graphql` extension, although that is not required).
Then pass the file to `h3 gql`:

```shell
h3 gql {your-query-file}
```

For example, define the following in a file named `my_session.graphql`:

```
query {
    session_user_account {
        email
        name
        company_name
    }
}
```

Then run:

```shell
h3 gql ./my_session.graphql
```

You should see the raw JSON response from the GraphQL server.  You can pretty-print the JSON response using jq:

```shell
h3 gql ./my_session.graphql | jq .
```

**Important!** You must specify the path to the graphql file (full or relative, e.g. `./my_session.graphql` instead of just `my_session.graphql`),
otherwise you risk colliding with graphql files that h3-cli uses internally.



### Advanced: Parameterized GraphQL queries 

GraphQL queries can also define parameters, which are passed to `h3 gql` as a JSON object. 

For example, define the following in a file named `my_pentest.graphql`:

```
query q($op_id: String!) {
    pentest(op_id:$op_id) {
        op_id
        name
        state
    }
}
```

In this example, `$op_id` is a parameter that must be provided in order to run the query.
The parameter is passed to the query within a JSON object:

```shell
h3 gql ./my_pentest.graphql '{"op_id":"your-op-id-here"}' | jq .
```

> Substitute `your-op-id-here` with an actual `op_id`.





