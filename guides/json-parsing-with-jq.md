
## h3-cli: JSON parsing with `jq`

`jq` is a useful tool for parsing and transforming JSON responses. 
It is a powerful utility with many options, and is best learned through examples.


## Quick examples

Copy + paste the following commands into your terminal to get an idea of what `jq` can do.

For example, to parse just the `op_id` field from the response:

```shell
h3 gql pentests | jq -r '.data.pentests_page.pentests[].op_id'
```

To parse just the `name` field from the response:

```shell
h3 gql pentests | jq -r '.data.pentests_page.pentests[].name'
```

To parse a set of fields from the response:

```shell
h3 gql pentests \
    | jq -r '.data.pentests_page.pentests[] | {op_id, name, scheduled_at, state}'
```

To parse a set of fields from the response and convert them from JSON to CSV format:

```shell
h3 gql pentests \
    | jq -r '.data.pentests_page.pentests[] | {op_id, name, scheduled_at, state}' \
    | jq -rsf $H3_CLI_HOME/filters/to_csv.jq
```



## View the JSON response structure

It's sometimes useful to view the structure of the JSON response payload:

```shell
h3 gql pentests | jq -rf $H3_CLI_HOME/filters/to_struct.jq 
```

Output:

```shell
.
.data
.data.pentests_count
.data.pentests_page
.data.pentests_page.pentests
.data.pentests_page.pentests[]
.data.pentests_page.pentests[].aws_account_ids
.data.pentests_page.pentests[].canceled_at
.data.pentests_page.pentests[].client_name
.data.pentests_page.pentests[].completed_at
.data.pentests_page.pentests[].credentials_count
.data.pentests_page.pentests[].data_resources_count
.data.pentests_page.pentests[].data_stores_count
.data.pentests_page.pentests[].duration_s
.data.pentests_page.pentests[].etl_completed_at
.data.pentests_page.pentests[].exclude_scope
.data.pentests_page.pentests[].exclude_scope[]
.data.pentests_page.pentests[].external_domains_count
.data.pentests_page.pentests[].git_accounts
.data.pentests_page.pentests[].hosts_count
.data.pentests_page.pentests[].impacts_count
.data.pentests_page.pentests[].launched_at
.data.pentests_page.pentests[].max_scope
.data.pentests_page.pentests[].max_scope[]
.data.pentests_page.pentests[].min_scope
.data.pentests_page.pentests[].name
.data.pentests_page.pentests[].nodezero_ip
.data.pentests_page.pentests[].nodezero_script_url
.data.pentests_page.pentests[].op_id
.data.pentests_page.pentests[].op_type
.data.pentests_page.pentests[].osint_company_names
.data.pentests_page.pentests[].osint_company_names[]
.data.pentests_page.pentests[].osint_domains
.data.pentests_page.pentests[].osint_keywords
.data.pentests_page.pentests[].osint_keywords[]
.data.pentests_page.pentests[].out_of_scope_hosts_count
.data.pentests_page.pentests[].services_count
.data.pentests_page.pentests[].state
.data.pentests_page.pentests[].user_name
.data.pentests_page.pentests[].users_count
.data.pentests_page.pentests[].weakness_types_count
.data.pentests_page.pentests[].weaknesses_count
.data.pentests_page.pentests[].websites_count
```

## Select a field/list from the response

If you want to select only the `pentests` array from the response:

```shell
h3 gql pentests | jq '.data.pentests_page.pentests'
```

This behaves more like a traditional REST API, where responses are often structured as a flat array of JSON objects.

You can also drop the surrounding array brackets `[]` from the response
and convert the output to a stream of JSON objects by adding `[]` to the filter:

```shell
h3 gql pentests | jq '.data.pentests_page.pentests[]'
```

You can then select a single field from the stream of JSON objects by adding it to the filter.
For example if you want just the list of op_ids: 


```shell
h3 gql pentests | jq -r '.data.pentests_page.pentests[].op_id'
```



## Select a subset of fields from an object 

If you want to select a subset of fields from the JSON objects in the `pentests` array:

```shell
h3 gql pentests | jq '.data.pentests_page.pentests[] | {op_id, name, state, scheduled_at}'
```


## Convert a list of JSON objects to CSV

If you want to convert the `pentests` array to a CSV:

```shell
h3 gql pentests | jq '.data.pentests_page.pentests[]' | jq -rsf $H3_CLI_HOME/filters/to_csv.jq
```

> Note: the [to_csv.jq](filters/to_csv.jq) filter will automatically convert lists and objects to JSON-encoded strings in the CSV.



