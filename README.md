# kcs-praat
Kansas City standard encoder/decoder written in Praat script

# usage

```praat
include kcs.praat

# encode text to wav file
@encodeKCSFromFile("message.txt", "message.wav")

# decode wav file to text
# message.txt and message_decoded.txt have same contents
@decodeKCSFromFile("message.wav", "message_decoded.txt")
```

See example for details.

# requirement

- Praat (checked in 6.4.13)
