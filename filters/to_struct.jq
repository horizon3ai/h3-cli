[
    path(..)
    | map(
        if type == "number" then
            "[]"
        else
            tostring
        end
    )
    | join(".")
    | split(".[]")
    | join("[]")
]
| unique
| map("." + .)
| .[]
