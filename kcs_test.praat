include kcs.praat

clearinfo

procedure _testToFrame(.byte, .expected#)
    @toKCSFrame(.byte)
    .actual# = toKCSFrame.return#
    appendInfoLine("actual=[", .actual#, "], expected=[", .expected#, "]")
    assert .actual# == .expected#
endproc

procedure testToFrame()
    appendInfoLine("testToFrame")
    @_testToFrame(0  , {0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1})
    @_testToFrame(255, {0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1})
    # 80 = (01010000)_2
    @_testToFrame(80 , {0, 0, 0, 0, 0, 1, 0, 1, 0, 1, 1})
endproc

@testToFrame()

procedure testEncodeKCS()
    appendInfoLine("testEncodeKCS")
    #                  freqHi, freqLo, baud
    @_testEncodeKCS("a", 2400, 1200, 300, {0, 1, 0, 0, 0, 0, 1, 1, 0, 1, 1})
    @_testEncodeKCS("ab", 2400, 1200, 300, {0, 1, 0, 0, 0, 0, 1, 1, 0, 1, 1, 0, 0, 1, 0, 0, 0, 1, 1, 0, 1, 1})
endproc

procedure _testEncodeKCS(.data$, .freqHi, .freqLo, .baud, .expected#)
    # HACK: override service locator for test
    locator$["genSound"] = "mockgenKCSSound"
    locator$["concatSound"] = "mockConcatSound"
    @encodeKCS(.data$, .freqHi, .freqLo, .baud)

    .actual# = mockgenKCSSound.frames#
    appendInfoLine("actual=[", .actual#, "], expected=[", .expected#, "]")
    assert .actual# == .expected#

    # generated sound assertion
    .objects# = mockConcatSound.soundObjects#
    appendInfoLine("num of frames=", size(.objects#), ", expected=", size(.expected#))
    assert size(.objects#) == size(.expected#)
endproc

procedure mockgenKCSSound(.freqHi, .freqLo, .baud, .bit, .bitIndex)
    # skip generating sound and just concatenate frames
    if !variableExists(".frames#") || .bitIndex = 1
        .frames# = zero#(0) ; NOTE: {} is syntax error
    endif
    .frames# = combine#(.frames#, .bit)

    # dummy sound object
    .return = .bitIndex
endproc

procedure mockConcatSound(.soundObjects#)
    # dummy sound object
    .return = 1
endproc

@testEncodeKCS()

procedure testFramesToString()
    appendInfoLine("testFramesToString")
    @_testFramesToString({0, 1, 0, 0, 0, 0, 1, 1, 0, 1, 1}, "a")
    @_testFramesToString({0, 1, 0, 0, 0, 0, 1, 1, 0, 1, 1, 0, 0, 1, 0, 0, 0, 1, 1, 0, 1, 1}, "ab")
    # trailing frame is insufficient
    @_testFramesToString({0, 1, 0, 0, 0, 0, 1, 1, 0, 1, 1, 0, 0, 1, 0, 0, 0, 1, 1, 0, 1}, "a")
endproc

procedure _testFramesToString(.bits#, .expected$)
    @framesToString(.bits#)
    .actual$ = framesToString.return$
    appendInfoLine("actual=", .actual$, ", expected=", .expected$)
    assert .actual$ == .expected$
endproc

@testFramesToString()

procedure testDetectFrameStart()
    appendInfoLine("testDetectFrameStart")
    @_testDetectFrameStart({0, 1, 0, 0, 0, 0, 1, 1, 0, 1, 1}, 1)
    @_testDetectFrameStart({0, 0, 1, 0, 0, 0, 0, 1, 1, 0, 1, 1}, 2)
    @_testDetectFrameStart({1, 0, 1, 0, 0, 0, 0, 1, 1, 0, 1, 1}, 2)
    @_testDetectFrameStart({0, 0, 0, 1, 0, 0, 0, 0, 1, 1, 0, 1, 1}, 3)
    @_testDetectFrameStart({1, 1, 0, 0, 0, 0, 1, 1, 0, 1, 1}, 12)
    # longer than two frames
    @_testDetectFrameStart({0, 1, 0, 0, 0, 0, 1, 1, 0, 1, 1, 0, 1, 0, 0, 0, 0, 1, 1, 0, 1, 1, 0, 1, 0, 0, 0, 0, 1, 1, 0, 1, 1}, 1)
    @_testDetectFrameStart({0, 0, 0, 0, 0, 0, 1, 1, 0, 1, 1, 0, 0, 0, 0, 0, 0, 1, 1, 0, 1, 1, 0, 0, 0, 0, 0, 0, 1, 1, 0, 1, 1, 0, 0, 0, 0, 0, 0, 1, 1, 0, 1, 1}, 1)
    @_testDetectFrameStart({0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 1, 1, 0, 0, 0, 0, 0, 0, 1, 1, 0, 1, 1, 0, 0, 0, 0, 0, 0, 1, 1, 0, 1, 1, 0, 0, 0, 0, 0, 0, 1, 1, 0, 1, 1}, 3)
endproc

procedure _testDetectFrameStart(.bits#, .expected)
    @detectFrameStart(.bits#)
    .actual = detectFrameStart.return
    appendInfoLine("actual=", .actual, ", expected=", .expected)
    assert .actual == .expected
endproc

@testDetectFrameStart()

procedure testTrimFrames()
    appendInfoLine("testTrimFrames")
    @_testTrimFrames({0, 1, 0, 0, 0, 0, 1, 1, 0, 1, 1}, {0, 1, 0, 0, 0, 0, 1, 1, 0, 1, 1})
    @_testTrimFrames({0, 0, 1, 0, 0, 0, 0, 1, 1, 0, 1, 1}, {0, 1, 0, 0, 0, 0, 1, 1, 0, 1, 1})
    @_testTrimFrames({1, 0, 1, 0, 0, 0, 0, 1, 1, 0, 1, 1}, {0, 1, 0, 0, 0, 0, 1, 1, 0, 1, 1})
    @_testTrimFrames({0, 0, 0, 1, 0, 0, 0, 0, 1, 1, 0, 1, 1}, {0, 1, 0, 0, 0, 0, 1, 1, 0, 1, 1})
endproc

procedure _testTrimFrames(.bits#, .expected#)
    @trimFrames(.bits#)
    .actual# = trimFrames.return#
    appendInfoLine("actual=[", .actual#, "], expected=[", .expected#, "]")
    assert .actual# == .expected#
endproc

@testTrimFrames()
