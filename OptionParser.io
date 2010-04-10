# -*- coding: utf-8 -*-

GetOpt

Sequence do(
    trim := method(size,
        if(self size > size,
            self slice(0, size - 3) .. "..."
        ,
            self)
    )
)

Option := List clone do(
    short       := method(at(0))
    long        := method(at(1))
    default     := method(at(2))
    description := method(at(3))

    with := method(
        option := resend
        if(option short isNil not and option short size > 1,
            Exception raise(
                "Short option name should be a single character only: " .. option short))
        if(option long isNil or option long ?size == 0,
            Exception raise("Long name should be defined for every option"))
        option
    )

    asString := method(
        # Helper method, processing outputed value, if the value is true
        # and not empty, it will be wrapped in before-after pair and returned.
        wrap := method(value, before, after,
            if(getSlot("value") isKindOf(Block) or value not or value ?size == 0,
                ""
            ,
                before .. value .. if(after isNil, "", after)
            )
        )

        # Uh, the numbers...
        # a) short option is 3 places wide, 1 for the "-" sign
        #    and 2 for the right margin,
        # b) long option is justified to the max + 4 places, 2
        #    for the "--" sign + 2 for the right margin,
        # c) description is trimmed so that the resulting option
        #    string, including short and long version won't be
        #    longer then 80 places.
        max := if(call argCount > 0, call evalArgAt(0), long size)
        "  " .. wrap(short, "-") alignLeft(1 + 2) \
             .. wrap(long, "--") alignLeft(max + 2 + 2) \
             .. description trim(80 - max - 7) \
             .. wrap(default, " (default: ", ")")
    )
) doc("Option object.")


OptionList := List clone do(
    asString := method(
        # Figuring out maximum long name length for the contained
        # options, for pretty printing :)
        max := self map(long size) max
        self sort map(option, option asString(max)) join("\n")
    )
)

OptionParser := Object clone do(
    description ::= "(no description availible)"
    usage ::= ""

    init := method(
        self options := OptionList clone with(
            Option with("h", "help", nil, "show help")
        )
    )

    with := method(
        parser := self clone
        parser options appendSeq(
            call evalArgs map(option, Option performWithArgList("with", option))
        )
        parser
    ) doc(
        """
        Creates a new OptionParser object with a given option list. Each option
        is defined by a list of four arguments: short name (ex. "d"), long name
        (ex. "debug"), default value (ex. true) and the description string,
        used for help output.

        Example:
        Io> OptionParser with(
            list("a", "arg", 20, "an example argument")
            list("d", "debug", nil, "show debug output")
        )
        """
    )

    help := method(
        usage asMutable replaceSeq("%name", System launchScript) println
        description println
        "\noptions:\n" println
        options println
        System exit
    ) doc("Prints out help string.")

    parse := method(args, gnu,
        # Extracting args from the System object if they aren't provided
        # and removing script filename from the resulting list.
        args = if(args isNil, System args, args) remove(System launchScript)

        # Using mercurial approach: read args, parse options and store
        # options in a state.
        longopts  := list()
        shortopts := list()
        argmap := Map clone
        defmap := Map clone
        state  := Map clone

        options foreach(option,
            ioname := option long asMutable replaceSeq("-", "_")

            argmap atPut("-" .. option short, ioname)
            argmap atPut("--" .. option long, ioname)
            defmap atPut(ioname, option default)

            # Copying defaults to state.
            default := option default
            if(default isKindOf(List)) then(
                state atPut(ioname, default itemCopy)
            ) elseif((default isNil or default isKindOf(Block)) not) then(
                state atPut(ioname, default)
            )

            # Preparing options for getopt, each short option, which
            # requires an argument, is followed by a semicolon, each
            # long option is followed by an equal sign.
            short := option short
            long := option long
            if((default isKindOf(nil) or \
                default isKindOf(true) or \
                default isKindOf(false)) not,
                if(short, short = short .. ":")
                if(long, long = long .. "=")
            )

            if(short, shortopts append(short))
            if(long, longopts append(long))
        )

        Object perform(if(gnu, "getoptGNU", "getopt"),
            shortopts join(""), longopts, args
        ) foreach(pair,
            # Transfering parse results to state.
            option := argmap at(pair at(0))
            value  := pair at(1)

            default := defmap at(option)
            if(default isKindOf(Block)) then(
                state atPut(option, default call(value))
            ) elseif(default isKindOf(Number)) then(
                state atPut(option, value asNumber)
            ) elseif(default isKindOf(Sequence)) then(
                state atPut(option, value)
            ) elseif(default isKindOf(List)) then(
                state atPut(option, state at(option) append(value))
            ) elseif(default isKindOf(nil) or \
                     default isKindOf(true) or \
                     default isKindOf(false)) then(
                state atPut(option, true)
            )
        )
        state
    ) doc(
        """
        Parses a given argument list using either getopt() if the gnu flag wasn't
        set or getoptGNU() otherwise. Parsed option values have the same types as
        their defaults, except for special cases (see tests). Returns a Map, where
        the keys are option long names, and the values are the ones, returned by
        getopt*(), backed up, by the predefined defaults.
        """
    )
)

Command := Object clone do(
    newSlot("body")
    newSlot("arguments")
    newSlot("options", list())

    execute := method(
        args := System args
        parser := OptionParser performWithArgList(
            "with", options
        ) setDescription(doc)

        exc := try(parsedOptions := parser parse(args, true))
        # The help string is displayed in three cases:
        # a) an exception was raised during argument parsing.
        # b) --help / -h option is provided,
        # c) number of positional arguments doesn't match the
        # number of command arguments,
        help := exc or parsedOptions at("help") or \
           (arguments isEmpty not and arguments size != args size)
        if(help,
            # FIXME: probably an appropriate error message should be
            # displayed, like "Invalid arguments" or smth.
            parser help
        ,
            # Creating the context object, the command body will
            # be executed in. Postional arguments get binded to
            # the corresponding command arguments, f.ex.
            #     command(arg1, ...) and args := list(1)
            # where arg1 will be set to 1, once the command is
            # executed.
            context := Object clone
            context args := args

            # Adding positional arguments to the context object.
            arguments foreach(arg,
                context setSlot(arg, args removeFirst)
            )

            # Adding parsed options to the context object ...
            parsedOptions foreach(option, value,
                context setSlot(option, value)
            )

            # ... and executing command body.
            context doMessage(body)
        )
    )

    with := method(
        setOptions(call evalArgs)
        self setIsActivatable(true)
    )

    activate := method(
        # Yep, nasty hack, really :(
        call sender getSlot(call message name) execute
    )
) doc(
    """
    Command object is responsible for marshaling arguments from the command
    line to the locals of the command body.
    """
)

command := method(
    body := call argAt(call argCount - 1)
    arguments := call message arguments slice(
        0, call argCount - 1
    ) map(asString)
    Command clone setBody(body) setArguments(arguments)
) doc("Shortcut method, creating a Command with a given message body and arguments.")