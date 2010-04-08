#!/usr/bin/env io
# -*- coding: utf-8 -*-

GetOptTest := UnitTest clone do(
    setUp := method(
        self getopt := GetOpt with(
            "a:b:c", list("abc=", "def")
        )
    )

    testShortHasArg := method(
        assertTrue(getopt shortHasArg("a"))
        assertTrue(getopt shortHasArg("b"))
        assertFalse(getopt shortHasArg("c"))
        assertRaisesException(getopt shortHasArg("z"))
    )

    testLongHasArg := method(
        assertEquals(list(true, "abc"), getopt longHasArg("abc"))
        assertEquals(list(false, "def"), getopt longHasArg("def"))
        assertEquals(list(true, "abc"), getopt longHasArg("ab"))
        assertEquals(list(false, "def"), getopt longHasArg("de"))
        assertRaisesException(getopt longHasArg("xyz"))

        # Adding a extra long option to the longopts list
        # to test ambigous options exception. Never do that :)
        getopt longopts append("abd")
        assertRaisesException(getopt longHasArg("ab"))
        assertEquals(list(true, "abc"), getopt longHasArg("abc"))
    )

    testHasArg := method(
        # Since hasArg is a simple wrapper method, all we have
        # to test is that the switching is done right.
        assertFalse(getopt hasArg("a") isKindOf(List))
        assertTrue(getopt hasArg("abc") isKindOf(List))
    )

    testDoShort := method(
        # Normal test case, given option requires an argument
        # and the argument is present in the args list.
        args := list("1")
        assertEquals(list("-a", "1"), getopt doShort("a", args))
        assertTrue(args isEmpty)

        # Another normal test case, with one difference, option
        # value is extracted from a given optstring, not from
        # the args list.
        args := list()
        assertEquals(list("-a", "1"), getopt doShort("a1", args))
        assertTrue(args isEmpty)

        # Test case, where there are multiple positional arguments
        # for an option. Only the first is taken. However, this
        # is most likely to change in the future.
        args := list("1", "2")
        assertEquals(list("-a", "1"), getopt doShort("a", args))
        assertFalse(args isEmpty)
        assertEquals(list("2"), args)

        # Test cases where the option doesn't require the argument.
        # а) expecting the args list to stay unchaged
        args := list("1")
        assertEquals(list("-c", nil), getopt doShort("c", args))
        assertFalse(args isEmpty)
        assertEquals(list("1"), args)
        # b) expecting a "not recognized" exception
        assertRaisesException(getopts doShort("c1", list()))

        # Test case where the option requires an argument but it's
        # not present. Expecting an exception to be raised.
        assertRaisesException(getopts doShort("a", list()))
    )

    testDoLong := method(
        # Normal test case, nothing special here.
        assertEquals(list("--abc", "1"), getopt doLong("abc=1", list()))
        assertEquals(list("--def", nil), getopt doLong("def", list()))

        # Test case, where the option's name is matched from a known
        # long options list.
        assertEquals(list("--abc", "1"), getopt doLong("ab=1", list()))
        assertEquals(list("--def", nil), getopt doLong("de", list()))

        # Error cases:
        # a) option requires a value, but it's not provided
        assertRaisesException(getopt doLong("abc", list()))
        # b) option doesn't require a value...
        assertRaisesException(getopt doLong("def=1", list()))
        # c) option not recognized
        assertRaisesException(getopt doLong("xyz=1", list()))
    )

    testGetopt := method(
        # Note: the empty string between "-b" and '-c' is significant:
        # it simulates an empty string option argument (-a "") on the
        # command line.
        args := list("-a", "1", "-b2", "--abc=3", "--def", "-a", "3", "-b",
                     "", "-c", "arg1", "arg2")

        assertEquals(list(list("-a", "1"),
                          list("-b", "2"),
                          list("--abc", "3"),
                          list("--def", nil),
                          list("-a", "3"),
                          list("-b", ""),
                          list("-c", nil)), getopt getopt(args))

        # The positional arguments should stay unchaged.
        assertEquals(list("arg1", "arg2"), args)
    )

    testGetoptGNU := method(
        # Note: theese tests will fail if POSIXLY_CORRECT variable
        # is present in the shell environment. But since System
        # doesn't provide a way to remove a variable from the
        # environment, there's nothing we can do.

        # Test case with GNU style parsing.
        args := list("-a", "1", "arg1", "-b2", "arg2", "--def")
        assertEquals(list(list("-a", "1"),
                          list("-b", "2"),
                          list("--def", nil)), getopt getoptGNU(args))

        assertEquals(list("arg1", "arg2"), args)

        # Test case with "-" as an argument.
        args := list("-a", "-", "-c", "-")
        assertEquals(list(list("-a", "-"),
                          list("-c", nil)), getopt getoptGNU(args))

        assertEquals(list("-"), args)

        # Posix style:
        # a) POSIXLY_CORRECT
        System setEnvironmentVariable("POSIXLY_CORRECT", "1")

        args := list("-a", "1", "arg1", "-b2", "arg2", "--def")
        assertEquals(list(list("-a", "1")), getopt getoptGNU(args))
        assertEquals(list("arg1", "-b2", "arg2", "--def"), args)

        # b) +
        getopt shortopts = "+" .. getopt shortopts

        args := list("-a", "1", "arg1", "-b2", "arg2", "--def")
        assertEquals(list(list("-a", "1")), getopt getoptGNU(args))
        assertEquals(list("arg1", "-b2", "arg2", "--def"), args)
    )

    testShortcuts := method(
        opts := Object getopt("a:b", "-a1 -b" split)
        assertEquals(list(list("-a", "1"), list("-b", nil)), opts)

        opts := Object getopt(nil, list("abc="), "--abc=test" split)
        assertEquals(list(list("--abc", "test")), opts)

        # getoptGNU is not tested, since the logic is 100% similar,
        # it's only the method name that changes.
    )

    tearDown := method(
        removeSlot("getopt")
    )
)

if(isLaunchScript, GetOptTest run)