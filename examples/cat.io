#!/usr/bin/env io
# -*- coding: utf-8 -*-

Importer addSearchPath("..")

cat := method(
    parser := OptionParser with(
        list("n", "number", false, "show line numbers")
    ) setDescription("A very simplified version of Unix `cat` command.")

    args := System args rest
    opts := parser parse(args, true)
    if(opts at("help"),
        parser help
    ,
        if(args size == 1,
            file := File with(args first)
            if(file exists not,
                parser error("file `#{file path}` doesn't exist." interpolate)
            )

            file open foreachLine(number, line,
                if(opts at("number"),
                    ((number + 1) .. "  ") alignRight(8) print
                )
                line println
            )
        ,
            parser error
        )
    )
)

if(isLaunchScript, cat)