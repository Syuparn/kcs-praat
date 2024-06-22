# consts
kcsFrameSize = 11

procedure kcsConfig:
    .freqHi = 2400
    .freqLo = 1200
    .baud = 300
endproc
@kcsConfig()

# HACK: used for early return
endproc$ = "endproc"

# service locator
locator$["genSound"] = "genKCSSound"
locator$["concatSound"] = "concatKCSSound"

procedure encodeKCSFromFile(.fileName$, .soundFileName$)
    .data$ = readFile$(.fileName$)
    @encodeKCS(.data$, kcsConfig.freqHi, kcsConfig.freqLo, kcsConfig.baud)
    .soundObj = encodeKCS.return
    selectObject(.soundObj)
    do("Save as WAV file...", .soundFileName$)
endproc

procedure encodeKCS(.data$, .freqHi, .freqLo, .baud)
    .soundObjects# = zero#(length(.data$) * kcsFrameSize)

    for .i from 1 to length(.data$)
        # ith character of .data$
        .char$ = right$(left$(.data$, .i), 1)
        @toKCSFrame(unicode(.char$))
        .frame# = toKCSFrame.return#

        for .j from 1 to kcsFrameSize
            .bit = .frame#[.j]
            .bitIndex = (.i - 1) * kcsFrameSize + .j
            @'locator$["genSound"]'(.freqHi, .freqLo, .baud, .bit, .bitIndex)

            .soundObj = 'locator$["genSound"]'.return
            .soundObjects#[.bitIndex] = .soundObj
        endfor
    endfor

    @'locator$["concatSound"]'(.soundObjects#)
    .return = 'locator$["concatSound"]'.return
endproc

procedure decodeKCSFromFile(.soundFileName$, .txtFileName$)
    .soundObj = do("Read from file...", .soundFileName$)
    @decodeKCS(.soundObj, kcsConfig.freqHi, kcsConfig.freqLo, kcsConfig.baud)
    # HACK: remove trailing "\n" because "Save as raw text file" appends new "\n" after text
    .text$ = decodeKCS.return$ - newline$

    # HACK: use dummy separator that never be used
    #                                   title(dummy)      text    separator
    do("Create Strings from tokens...", "encoded string", .text$, unicode$(28))
    do("Save as raw text file...", .txtFileName$)
endproc

procedure decodeKCS(.soundObj, .freqHi, .freqLo, .baud)
    @extractBits(.soundObj, .freqHi, .freqLo, .baud)
    .bits# = extractBits.return#

    # detect start of frames and trim noise before them
    @trimFrames(.bits#)
    .bits# = trimFrames.bits#

    @framesToString(.bits#)
    .return$ = framesToString.return$
endproc

procedure toKCSFrame(byte)
    .frame# = zero#(kcsFrameSize)

    # data format
    # [1]: 0
    # [2]~[9]: bits
    # [10], [11]: 1

    mask = 1
    for .i from 2 to 9
        .frame#[.i] = floor(byte / mask) mod 2
        mask *= 2
    endfor

    .frame#[10] = 1
    .frame#[11] = 1

    # HACK: use pseudo-return
    .return# = .frame#
endproc

procedure genKCSSound(.freqHi, .freqLo, .baud, .bit, .bitIndex)
    if .bit == 1
        .freq = .freqHi
    else
        .freq = .freqLo
    endif

    .period = 1 / .baud
    .tStart = (.bitIndex - 1) * .period
    .tEnd = .bitIndex * .period

    # name, channels(mono), tstart, tend, sampling[Hz], freq[Hz], amp[Pa], fade-in[s], fade-out[s]
    .sound = do("Create Sound as pure tone...", "tone", 1, .tStart, .tEnd, 44100, .freq, 0.2, 1e-14, 1e-14)

    .return = .sound
endproc

procedure concatKCSSound(.soundObjects#)
    # deselect
    selectObject()

    for .i from 1 to size(.soundObjects#)
        plusObject(.soundObjects#[.i])
    endfor

    .concatenated = do("Concatenate")

    # remove unused sounds
    for .i from 1 to size(.soundObjects#)
        removeObject(.soundObjects#[.i])
    endfor

    .return = .concatenated
endproc

procedure extractBits(.soundObj, .freqHi, .freqLo, .baud)
    .duration = do("Get total duration")
    .period = 1 / .baud
    .nBits = ceiling(.duration / .period)
    .bits# = zero#(.nBits)

    selectObject(.soundObj)
    # step, nFormants, ceilingHz(default), windowLength, pre-emphasis[Hz](default)
    do("To Formant (burg)...", .period, 1, 5000, .period / 3, 50)

    .threshold = (.freqHi + .freqLo) / 2

    for .i from 1 to .nBits
        # index(nth formant), time, unit(default), interpolation(default)
        .t = (.i - 0.5) * .period
        .formant = do("Get value at time...", 1, .t, "hertz", "linear")
        if .formant > .threshold
            .bit = 1
        else
            .bit = 0
        endif
        .bits#[.i] = .bit
    endfor

    .return# = .bits#
endproc

procedure trimFrames(.bits#)
    @detectFrameStart(.bits#)
    .iStart = detectFrameStart.return

    if .iStart > size(.bits#)
        exitScript("failed to detect start of frames (sound may be broken or wrong frequency/baud is used)")
    endif

    .trimmedLen = size(.bits#) - .iStart + 1
    .trimmedBits# = zero#(.trimmedLen)
    for .i from 1 to .trimmedLen
        .trimmedBits#[.i] = .bits#[.i + .iStart - 1]
    endfor

    .return# = .trimmedBits#
endproc

procedure detectFrameStart(.bits#)
    for .i from 1 to size(.bits#)
        @canBeFrameStartBit(.bits#, .i)
        .isStart = canBeFrameStartBit.return
        if .isStart
            if .i + kcsFrameSize * 2 > size(.bits#)
                .return = .i
                'endproc$'
            endif

            # see next two frames to check this is actually frame start
            @canBeFrameStartBit(.bits#, .i + kcsFrameSize)
            .isStart2 = canBeFrameStartBit.return
            @canBeFrameStartBit(.bits#, .i + kcsFrameSize * 2)
            .isStart3 = canBeFrameStartBit.return
            if .isStart2 && .isStart3
                .return = .i
                'endproc$'
            endif
        endif
    endfor

    # not found
    .return = size(.bits#) + 1
endproc

procedure canBeFrameStartBit(.bits#, .i)
    .return = 0 ; false

    # out of range
    if .i + kcsFrameSize - 1 > size(.bits#)
        'endproc$'
    endif

    # does not meet frame#[1] = 0, frame#[10] = 1, frame#[11] = 1
    if .bits#[.i] != 0 || .bits#[.i+9] != 1 || .bits#[.i+10] != 1
        'endproc$'
    endif

    .return = 1 ; true
endproc

procedure framesToString(.bits#)
    .str$ = ""

    for .i from 0 to floor(size(.bits#) / kcsFrameSize) - 1
        byte = 0
        mask = 1

        # data format
        # [1]: 0
        # [2]~[9]: bits
        # [10], [11]: 1
        for .j from 2 to 9
            byte += .bits#[.i * kcsFrameSize + .j] * mask
            mask *= 2
        endfor

        .str$ = .str$ + unicode$(byte)
    endfor

    .return$ = .str$
endproc
