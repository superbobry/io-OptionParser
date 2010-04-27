#!/usr/bin/env io
# -*- coding: utf-8 -*-

Importer addSearchPath("..")

Command

echo := command(msg,
    msg perform(if(nonewline, "print", "println"))
) with(
    list("n", "nonewline", false, "don't print a newline")
) doc("A simple echo command.")

if(isLaunchScript,
    echo
    "^\n| Running `echo` with no arguments." println
    "\n" println
    echo("Hello world!")
    "^\n| Running `echo` as method." println
)