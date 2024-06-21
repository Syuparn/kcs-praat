include ../kcs.praat

# command-line (or form arguments)
form: "Arguments"
    sentence: "srcFileName", ""
endform

if srcFileName$ == ""
    exitScript("usage: praat encode.praat foo.txt")
endif

# change config if you want
# kcsConfig.freqHi = 880
# kcsConfig.freqLo = 440
# kcsConfig.baud = 8

wavFileName$ = srcFileName$ - ".txt" + ".wav"
@encodeKCSFromFile(srcFileName$, wavFileName$)
