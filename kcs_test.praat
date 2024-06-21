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
    @encodeKCS(.data$, .freqHi, .freqLo, .baud)
    .actual# = mockgenKCSSound.frames#

    appendInfoLine("actual=[", .actual#, "], expected=[", .expected#, "]")
    assert .actual# == .expected#
endproc

procedure mockgenKCSSound(.freqHi, .freqLo, .baud, .bit, .bitIndex)
    # skip generating sound and just concatenate frames
    if !variableExists(".frames#") || .bitIndex = 1
        .frames# = zero#(0) ; NOTE: {} is syntax error
    endif
    .frames# = combine#(.frames#, .bit)
endproc

@testEncodeKCS()
