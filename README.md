io-OptionParser
===============

`OptionParser` is an command line parser object for [Io](http://iolanguage.com), which 
hopefully makes writing command line tools a little easier.

Quick example
-------------
This is a trivial usage example:
    OptionParser

    echo := command(msg,
        msg perform(
            if(getSlot("nonewline"), "print", "println")
        )
    ) with(
        list("n", "nonewline", false, "don't print a newline")
    ) doc("A simple echo command.")

    if(isLaunchScript, echo)

Running the above script without any argument will bring up the help text:
    % io example.io

    A simple echo command.

    options:

      -h --help       show help
      -n --nonewline  don't print a newline

The number of positional arguments should match the number of arguments declared
in the `command` body, since each declared argument gets binded to the corresponding 
command line positional argument.

Note, that `command`s can be executed as normal `method`s, with one restriction:
default option values don't get added to the locals object, but that's most likely to 
change in the future.

    Io> echo("Hello world")
    Hello world
