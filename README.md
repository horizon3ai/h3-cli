
## h3-cli: CLI tool for the Horizon3.ai API

h3-cli is a convenient CLI (command-line interface) for accessing the 
Horizon3.ai API.  The Horizon3.ai API provides programmatic access to a subset 
of functionality available through the Horizon3.ai Portal.  At a high level, 
the API allows you to:

* schedule an autonomous pentest
* download and run NodeZero™
* monitor the status of a pentest while it is running
* retrieve a pentest report after it's complete

The API can be used for a variety of use cases such as periodically scheduling assessments 
of your environment or kicking off a pentest as part of a continuous integration build pipeline.

[[_TOC_]]

## Installation and initial setup

The steps below will get you up and running quickly with h3-cli. These instructions were tested on 
MacOS and Linux machines, and generally should work on any [POSIX-compliant](https://en.wikipedia.org/wiki/POSIX) system with bash support.

If you plan to run _internal_ pentests using h3-cli, you should install h3-cli on the same Docker Host
where you launch NodeZero.

It is assumed you already have an account with Horizon3.ai.  If not, sign up
at [https://portal.horizon3ai.com/](https://portal.horizon3ai.com/).


### 1. Obtain an API key

An API key is required to access the H3 API.  Obtain one from the Portal under the User -> Settings menu: [https://portal.horizon3ai.com/settings/api](https://portal.horizon3ai.com/settings/api).

Keep your API key secure, as anyone with your API key can access your H3 account.  


### 2. Install this git repo

First, install this repo on your machine using the following git command within a shell/terminal.  

```shell
git clone git@gitlab.com:h3upperbounds/data/h3-cli.git
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

The install script will install dependencies (jq) and create your h3-cli profile under the `$HOME/.h3` directory.
Your API key is stored in your h3-cli profile.  The profile permissions are restricted so that no other
users (besides yourself) can read it.

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

⚠️ If you are getting an error response, please contact H3 via the chat icon in the [Horizon3.ai Portal](https://portal.horizon3ai.com/).


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


### 4. Schedule a pentest

Scheduling a pentest requires specifying an _op template_.  An op template specifies a full pentest configuration,
which includes scope, attack parameters, and other (optional) configuration.

Horizon3.ai provides new users with a default op template named `Default 1 - Recommended`.  This template is always 
up-to-date with our latest attack parameters and recommended configuration.  The default template does not define a scope,
in which case NodeZero will use _Intelligent Scope_ - NodeZero's host subnet will provide the initial scope, and it will expand 
organically during the pentest as more hosts and subnets are discovered.  For more information on Intelligent Scope and other 
deployment options, visit our [product documentation](https://portal.horizon3ai.com/documentation/nodezero-deployment-options).

For experienced users, custom op template(s) may be created via the [Horizon3.ai Portal](https://portal.horizon3ai.com/).
To create a custom op template, walk through the _Run a Pentest_ modal until you see the 
option to customize the pentest configuration. The op template can be created without actually running the pentest. 

To schedule a pentest using the default op template and Intelligent Scope:

```shell
h3 schedule-pentest
```

The JSON response contains the details for the newly scheduled pentest.
You can verify the pentest is provisioning by checking your [Horizon3.ai Portal](https://portal.horizon3ai.com/pentests),
or by running `h3 pentest`.  

There are several ways to specify additional parameters when scheduling pentests. For more information see additional examples [here](#scheduling-and-running-pentests-with-h3-cli).

**WAIT! YOU'RE NOT DONE!**: For internal pentests (which are the default), additional steps are required before the pentest will begin running.
See the next section about downloading and running NodeZero in order to complete the initiation of your pentest.


### 5. Run NodeZero

**⚠️ The following instructions apply to _internal_ pentests only, not _external_ pentests.**

After scheduling an _internal_ pentest, you then have to run our NodeZero container on a Docker Host inside your network.
This is done by running the NodeZero Launch Script on your Docker Host.  

To run the NodeZero Launch Script for your most recently scheduled pentest:

```shell
h3 run-nodezero
```

**YOUR PENTEST HAS BEEN LAUNCHED!**  Assuming all commands ran without error, then you have 
successfully scheduled and launched your pentest.  You should see output from the NodeZero Launch Script being logged
to the console.  The script will first verify your system is compatible with NodeZero before downloading and running it.
When the pentest is complete, NodeZero will automatically shut itself down.  

NodeZero is a Docker container.  You can view it using `docker ps`.  The container name will be of the form `n0-xxxx`.


### 6. Download pentest reports

After your pentest has finished, use the following command to download a zip file containing all PDF and CSV reports
for the most recently scheduled pentest:

```shell
h3 pentest-reports
```

The above command will download the zip file to `pentest-reports-{op_id}.zip` in the current directory.


## Use cases

[**Schedule recurring pentests.**](guides/recurring-pentests.md) A common use case for h3-cli is running pentests automatically on a recurring basis, for example once a week or once a month.
See [this guide](guides/recurring-pentests.md) to learn how to set up recurring pentests using h3-cli.

[**Monitoring pentests.**](guides/monitor-pentests.md) See [this guide](guides/monitor-pentests.md) to learn how to monitor pentests using h3-cli.

[**Paginating results.**](guides/paginate-results.md) See [this guide](guides/paginate-results.md) to learn how to paginate through large result sets using h3-cli.


## Authentication

Authentication happens seamlessly and automatically when you invoke the `h3` command.
There's nothing explicit you need to do to authenticate.  This section documents the 
underlying mechanics.

h3-cli reads your `H3_API_KEY` from your h3-cli profile (under `$HOME/.h3`) to authenticate 
to the Horizon3.ai API and establishes a (temporary) session.  The session token (a JWT) is stored 
in `$HOME/.h3/jwt`.  The session token expires after 1 hour, at which point h3-cli will
automatically re-authenticate and re-establish a session.

You can explicitly authenticate using the following command: 

```shell
h3 auth
```

The above command will output the session token (and also write it to `$HOME/.h3/jwt`).
If you already have an established (non-expired) session token, `h3 auth` will continue to use 
that session token rather than re-authenticate. 

If you want to _force_ h3-cli to re-authenticate, use the `force` option:

```shell
h3 auth force
```

This can be useful if you're switching from one `H3_API_KEY` to another and 
want to force authentication against the new `H3_API_KEY`.


## Scheduling and running pentests with h3-cli

This section contains additional examples for scheduling and running pentests using h3-cli.

The simplest way to schedule a pentest is to use the default op template and _Intelligent Scope_:

```shell
h3 schedule-pentest
```

To schedule a pentest AND launch NodeZero (if it's an _internal_ pentest; for external pentests it skips the launch step):

```shell
h3 run-pentest
```

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


## Powered by GraphQL

The Horizon3.ai API is powered by GraphQL.  In addition to this CLI document, 
relevant documentation includes:

- [Horizon3.ai GraphQL API Reference](https://h3-graphql-docsite.horizon3ai.com/)
- [Learn about GraphQL](https://graphql.org/)


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

**Important!** You must specify the path to the graphql file (full or relative, ie. `./my_session.graphql` instead of just `my_session.graphql`),
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





