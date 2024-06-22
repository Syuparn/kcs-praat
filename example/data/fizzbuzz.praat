clearinfo
for i from 1 to 30
    if i mod 15 == 0
        appendInfoLine("fizzbuzz")
    elsif i mod 3 == 0
        appendInfoLine("fizz")
    elsif i mod 5 == 0
        appendInfoLine("buzz")
    else
        appendInfoLine(i)
    endif
endfor
