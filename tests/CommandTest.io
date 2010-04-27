#!/usr/bin/env io
# -*- coding: utf-8 -*-

CommandTest := UnitTest clone do(
    testCreateContext := method(
        c := Command clone setArguments(list("arg1", "arg2"))

        # Test case with both positional and keyword arguments
        # provided.
        context := c createContext(list(1, 2), Map with("kwarg", "kwvalue"))
        assertNotNil(context)
        assertTrue(context isKindOf(Object))
        assertEquals(list("kwarg", "arg1", "arg2") sort, context slotNames sort)
        assertEquals(1, context getSlot("arg1"))
        assertEquals(2, context getSlot("arg2"))
        assertEquals("kwvalue", context getSlot("kwarg"))

        # Test case with positional arguments only, expecting
        # no exceptions to occur whatsoever.
        context := c createContext(list(1, 2))
        assertNotNil(context)
        assertTrue(context isKindOf(Object))
        assertEquals(list("arg1", "arg2") sort, context slotNames sort)
        assertEquals(1, context getSlot("arg1"))
        assertEquals(2, context getSlot("arg2"))
    )

    testWith := method(
        c := Command clone with(list("t", "test"))
        assertTrue(getSlot("c") isActivatable)

        parser := getSlot("c") getSlot("parser")
        assertNotNil(parser)
        assertTrue(parser isKindOf(OptionParser))
        assertEquals(2, parser options size) # + help option
        assertEquals(list("t", "test"), parser options last)
    )

    testExecute := method(
        c := Command clone setArguments(list("x")) setBody(
            message(x asNumber + num)
        ) with(list(nil, "num", 1)) doc("Test")

        # A little trick: preventing the help message from
        # being actually displayed.
        getSlot("c") parser help := method("help")

        # Checking that option parser's description was taken
        # from the command's doc.
        System args := list("1")
        assertNil(try(c)) # Activating command
        assertEquals("Test", getSlot("c") parser description)

        # Checking that all exceptions are handled silently
        # and help message gets shown.
        System args := list("--unrecognized=X")
        assertNil(try(result := c))
        assertEquals("help", result)

        # Checking that help message is also displayed if
        # the number of provided positional arguments differs
        # from the number of arguments the command takes.
        System args := list("1", "2")
        assertNil(try(result := c))
        assertEquals("help", result)

        # Checking that positional arguments are binded correctly.
        System args := list("3")
        assertNil(try(result := c))
        assertEquals(1 + 3, result)

        # Checking that keyword arguments are marshaled to the command's
        # locals.
        System args := list("--num", "5", "10")
        assertNil(try(result := c))
        assertEquals(5 + 10, result)

        # If an option has no default value it won't appear in the locals.
        # FIXME: change this?
        getSlot("c") parser options append(Option with(nil, "hack"))
        getSlot("c") setBody(message(hack))
        System args := list("1")
        assertRaisesException(c)
    )
)

if(isLaunchScript, CommandTest run)