# consts
kcsFrameSize = 11

procedure kcsConfig:
    .freqHi = 2400
    .freqLo = 1200
    .baud = 300
endproc
@kcsConfig()

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

procedure decodeKCS(.soundObj, .freqHi, .freqLo, .baud)
    
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
