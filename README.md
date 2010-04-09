io-OptionParser
===============

`OptionParser` is an command line parser object for [Io](http://iolanguage.com), which 
hopefully makes writing command line tools a little easier.

Quick example
-------------
    Io> parser := OptionParser with(
    ...     list("n", "nonewline", false, "don't print a newline")
    ... ) setUsage("%name [-n] MESSAGE")
    
    Io> parser help
    echo.io [-n] MESSAGE
    (no description availible)

    options:

        -h --help       show help
        -n --nonewline  don't print a newline
        
    Io> args := "-n Hello world!" split
    ==> list(-n, Hello, world!)
    Io> parser parse(args) asJson
    ==> {"nonewline":true}
