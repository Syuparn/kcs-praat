include ../kcs.praat

# command-line (or form arguments)
form: "Arguments"
    sentence: "wavFileName", ""
endform

if wavFileName$ == ""
    exitScript("usage: praat decode.praat foo.wav")
endif

# change config if you want
# kcsConfig.freqHi = 880
# kcsConfig.freqLo = 440
# kcsConfig.baud = 8

txtFileName$ = wavFileName$ - ".wav" + "_decoded.txt"
@decodeKCSFromFile(wavFileName$, txtFileName$)
