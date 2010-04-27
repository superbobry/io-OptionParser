io-OptionParser
===============

`OptionParser` is a command line parser object for [Io](http://iolanguage.com), which 
hopefully makes writing command line tools a little easier.

Command
-------
`Command` object is a convinient wrapper around `OptionParser`, let's get to the usage 
example right away, since there's not much to describe:

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

`Command` objects can also be executed just as `method` objects, in that case the locals object 
of the `command` will be populated from the default option values:

    % io example.io "Hello world\!"
    Hello world!
    ^
    | Running `echo` with no arguments.


    Hello world!
    ^
    | Running `echo` as a method.


OptionParser
------------

If you don't feel like using a `command()` shortcut, there's a more verbose, but yet more flexible
way of adding option parsing functionality to your script. First, you need to clone `OptionParser` 
object with a list of options you want recognized and then manually call `OptionParser parse()` 
later in your code.

Example:

    cat := method(
        parser := OptionParser with(
            list("n", "number", false, "show line numbers")
        ) setDescription(
            "A very simplified version of Unix `cat` command."
        ) setUsage("[-n] FILE")            

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

The example above is a very simplified version of the Unix `cat` command, which is probably clear from the description string. Let's see it in action:

    % ./cat.io cat.io -h
    cat.io [-n] FILE
    
    A very simplified version of Unix `cat` command.

    options:

      -h --help    show help
      -n --number  show line numbers
      
    % echo "Hello world\!" >> test && ./cat.io test 
    Hello world!
    bobry@bobry ~/coding/io-OptionParser/examples
    % echo "World Hello\!" >> test && ./cat.io -n test        
         1  Hello world!
         2  World Hello!

### OptionParser with(option, option, ...) ###
Creates a new OptionParser object for a given option list. Each option is defined by a 
list of four arguments: short name (ex. `"d"`), long name (ex. `"debug"`), default value 
(ex. `true`) and the description string, used for help output.

    Io> OptionParser with(
        list("d", "debug", false, "output debug information")
    )

### OptionParser parse([*args*, [*gnu*]]) ###
Parses a given list of arguments using `GetOpt` object, which is described below. 
Depending on the *gnu* flag value, parsing is done either with `GetOpt getopt()`,
or `GetOpt getoptGNU()` method. Parsed option values are coerced to the same types as
their defaults, except for some special cases (see `tests/` for examples). Method returns 
a `Map`, where the keys are option long names, and the values are the ones, returned by
`getopt*()`, backed up, by the predefined defaults.

__IMPORTANT__: argument list is modified __in place__! 

### OptionParser error([*message*]) ###
If there's something wrong with the arguments, that your script has recieved, you may 
use `OptionParser error()` method to print the error message and exit. If the message
argument is absent `"invalid arguments"` is used.

### OptionParser help ###
Outputs a help string, using `description`, `usage` and a list of `options` the parser
was initialized with.


GetOpt
======

`GetOpt` object helps scripts to parse the command line arguments in `System args`. It supports 
the same conventions as the Unix `getopt()` function. Most of the code was ported from Python's 
[getopt](http://docs.python.org/library/getopt.html) module, which happens to be in the standart
library. 

### GetOpt with(*shortopts*, [*longopts*]) ###

Creates a new option parser object with the arguments given. The first argument is a string of 
option letters that the script wants to recognize, with options that require an argument followed 
by a colon (i.e. the same format that Unix `getopt()` uses). The second argument, if specified, 
is a list of strings with the names of the long options which should be supported. The leading 
`--` characters should not be included in the option name. Options which require an argument 
should be followed by an equal sign (`=`).

Example:

    Io> GetOpt with("a:b", list("abc=", "def")
    ==>  GetOpt_0x8730e60:
      longopts         = list("abc=", "def")
      shortopts        = "a:b"

Option parser defined above supports the following arguments:
`-a <value>`, `-b`, `--abc=<value>`, `--def`.

### Getopt getopt([*args*]) ###

Parses command line options and parameter list from a given argument list (without the running 
program filename). Typically, this means `System args rest`. Returns a list of `(optionName, optionValue)` 
pairs. Each pair returned has the option name as it's first element, prefixed by a hyphen 
(e.g. `"-a"`), and the option argument as its second element or nil, if the option has no argument. 
The options occur in the list in the same order in which they were found, thus allowing multiple 
occurrences for each option. Long an short options may be mixed. The processing stops once the 
first positional (non-option) argument is encountered.

### Getopt getoptGNU([*args*]) ###

Works just like `GetOpt getopt()`, described above,  except that GNU style scanning mode is used 
by default, which means that option and non-option arguments can be intermixed.

__Note__: If the first character of the predefined shortopts string is `"+"` or the environment 
variable `POSIXLY_CORRECT` is set, then option processing stops as soon as first non-option 
argument is encountered.

Examples
--------

Using Unix and GNU style options:

    Io> args := "-a -bfoo -c bar something unparsed" split
    Io> GetOpt with("ab:c:") getopt(args)
    ==> list(list(-a, nil), list(-b, foo), list(-c, bar))
    Io> args
    ==> list(something, unparsed)

    Io> args := "-a -b foo -c bar something unparsed" split
    Io> GetOpt with("abc:") getoptGNU(args)
    ==> list(list(-a, nil), list(-b, nil), list(-c, bar))
    Io> args
    ==> list(foo, something, unparsed)
    
Using long options:

    Io> args := "--foo=bar --cond" split
    ==> list(--foo=bar, --cond)
    Io> GetOpt with("", list("foo=", "cond")) getopt(args)
    ==> list(list(--foo, bar), list(--cond, nil))
