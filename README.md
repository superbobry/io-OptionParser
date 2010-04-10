io-OptionParser
===============

`OptionParser` is a command line parser object for [Io](http://iolanguage.com), which 
hopefully makes writing command line tools a little easier.

Quick example
-------------
This is a trivial usage example:
    Command

    echo := command(msg,
        msg perform(
            if(nonewline, "print", "println")
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

__Note__: The number of positional arguments should *match* the number of arguments 
declared in the `command` body, since each declared argument gets binded to the corresponding 
command line positional argument.

`command` objects can also be executed just as `method` objects, in that case the locals object 
of the `command` will be populated from the default option values:

    % io example.io "Hello world\!"
    Hello world!
    ^
    | Running `echo` with no arguments.


    Hello world!
    ^
    | Running `echo` as a method.
