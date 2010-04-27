#!/usr/bin/env io
# -*- coding: utf-8 -*-

OptionParser

OptionTest := UnitTest clone do(
    testWith := method(
        opt := Option with("h", "hw", nil, "hello world")
        assertEquals(4, opt size)
        assertEquals("h", opt short)
        assertEquals("hw", opt long)
        assertNil(opt default)
        assertEquals("hello world", opt description)

        # Error cases:
        # a) short option provided is not a single character
        assertRaisesException(Option with("hw", "hw"))
        # b) long option is not provided
        assertRaisesException(Option with("h"))

        # Test case where short option is nil.
        assertNil(try(Option with(nil, "hw")))
    )
)

# Since Map doesn't have a proper compare function, we have to
# use this stub.
Map compare := method(other,
    if(size != other size, return false)
    foreach(key, value,
        if(other at(key) != value, return false)
    )
    true
)

OptionParserTest := UnitTest clone do(
    setUp := method(
        self parser := OptionParser with(
            list("a", "abc", "a"),
            list(nil, "def", list()),
            list(nil, "ghi", 1),
            list(nil, "jkl", block(arg, arg asNumber + 5)),
            # Flag options, one for each possible value:
            # flag nil, flag true and flag false.
            list(nil, "fn", nil),
            list(nil, "ft", true),
            list(nil, "ff", false)
        )
    )

    testParse := method(
        # Test case where no arguments were provided. Expecting an empty
        # Map to be returned, both for a POSIX and GNU modes.
        assertTrue(
            Map clone compare(
                OptionParser with(list("a", "abc")) parse(list())
            )
        )
        assertTrue(
            Map clone compare(
                OptionParser with(list("a", "abc")) parse(list(), true)
            )
        )

        # Test case where no arguments were provided and the defaults
        # are used.
        assertTrue(Map with(
            "abc", "a",
            "def", list(),
            "ghi", 1,
            # Note: true / false flags showed up, yay :)
            "ff", false,
            "ft", true
            ) compare(parser parse(list()))
            # Note: block defaults don't act as actual "default"
            # values, they are only used on the option value,
            # before it gets added to the state map.
        )

        # Testing that command line arguments are procced correctly
        # for each supported type.
        parsedOptions := parser parse(
            list("-a1", "--def=1", "--def=2", "--ghi=3", "--jkl=4",
                 "--ft", "--ff", "--fn")
        )
        # a) Number
        value := parsedOptions at("ghi")
        assertTrue(value isKindOf(Number))
        assertEquals(3, value)
        # b) List
        value := parsedOptions at("def")
        assertTrue(value isKindOf(List))
        assertEquals(2, value size)
        assertEquals(list("1", "2"), value)
        # Note: list elements are added as sequencies, if you need to
        # do type conversion, try using block() as the default value.
        # с) Sequence (nothing fancy here)
        value := parsedOptions at("abc")
        assertTrue(value isKindOf(Sequence))
        assertEquals("1", value)
        # d) Block
        value := parsedOptions at("jkl")
        assertFalse(value isKindOf(Block))
        assertFalse(value isKindOf(Sequence))
        assertTrue(value isKindOf(Number))
        assertEquals(4 + 5, value)
        # e) Flag
        assertTrue(parsedOptions at("ft"))
        assertTrue(parsedOptions at("ff"))
        assertTrue(parsedOptions at("fn"))
    )
)

if(isLaunchScript, FileCollector clone run)