

## h3-cli: Paginating results

Queries that return potentially a lot of results can be paginated
by using the optional `page_input` on the GraphQL request.  

For example [action_logs.graphql](queries/action_logs.graphql) is parameterized
to accept `page_num` and `page_size` as parameters.  These parameters are passed
to `page_input` within the query file.

```shell
h3 gql action_logs '{"op_id":"your-op-id-here", "page_num":1, "page_size":100}' | jq .
```

Here's an example shell script that paginates thru the full result set.
It exits the loop when the query returns no further results.

```shell
#!/bin/bash

#
# Helper function for building the JSON parameters 
# for the GraphQL request.
#
function build_json_params {
    op_id=$1
    page_num=$2
    page_size=$3
    cat <<HERE
{"op_id":"$op_id", "page_num":$page_num, "page_size":$page_size}
HERE
}

#
# 1. take the op_id as a param to the shell script. 
#
op_id=$1
page_num=1
page_size=100

#
# 2. read page by page until the request returns no further results.
# 
while [ 1 ]; do
    json_params=`build_json_params $op_id $page_num $page_size`
    res=`h3 gql action_logs "$json_params"`
    len=`cat <<<$res | jq '.data.action_logs_page.action_logs | length'`
    echo "Read $len records on page $page_num"
    if [ -z "$len" -o $len -eq 0 ]; then
        break
    fi
    (( page_num++ ))
done
```


