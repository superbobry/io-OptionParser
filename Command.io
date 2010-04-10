# -*- coding: utf-8 -*-

OptionParser

Command := Object clone do(
    newSlot("body")
    newSlot("arguments")
    newSlot("parser")

    execute := method(
        args := System args
        parser setDescription(doc)

        exc := try(parsedOptions := parser parse(args, true))
        # The help string is displayed in three cases:
        # a) an exception was raised during argument parsing.
        # b) --help / -h option is provided,
        # c) number of positional arguments doesn't match the
        # number of command arguments,
        if(exc or parsedOptions at("help") or \
            (arguments isEmpty not and arguments size != args size),
            # FIXME: probably an appropriate error message should be
            # displayed, like "Invalid arguments" or smth.
            parser help
        ,
            createContext(args, parsedOptions) doMessage(body)
        )
    )

    createContext := method(args, keywords,
        # Creating the context object, the command body will
        # be executed in. Postional arguments get binded to
        # the corresponding command arguments, f.ex.
        #     command(arg1, ...) and args := list(1)
        # where arg1 will be set to 1, once the command is
        # executed.
        context := Object clone

        # Adding positional ...
        arguments foreach(arg,
            context setSlot(arg, args removeFirst)
        )

        # ... and keyword arguments to the context object.
        if(keywords isNil not,
            keywords foreach(keyword, value,
                context setSlot(keyword, value)
            )
        )
        context
    )

    with := method(
        parser = OptionParser performWithArgList("with", call evalArgs)
        self setIsActivatable(true)
    )

    activate := method(
        cmd := call sender getSlot(call message name)
        if(call argCount == 0,
            # Yep, nasty hack, really :(
            getSlot("cmd") execute
        ,
            getSlot("cmd") createContext(
                call evalArgs, getSlot("cmd") parser parse
            ) doMessage(getSlot("cmd") body)
        )
    )
) doc(
    """
    Command object is responsible for marshaling arguments from the command
    line to the locals of the command body.
    """
)

command := method(
    body := call argAt(call argCount - 1)
    arguments := call message arguments slice(0, call argCount - 1) map(asString)
    Command clone setBody(body) setArguments(arguments)
) doc("Shortcut method, creating a Command with a given message body and arguments.")