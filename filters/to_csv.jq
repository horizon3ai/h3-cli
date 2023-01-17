def tocsv:
    (map(keys)
        |add
        |unique
        |sort
    ) as $cols
    |map(. as $row
        |$cols
        |map($row[.]//""|tostring)
    ) as $rows
    |$cols,$rows[]
    | @csv;

tocsv
