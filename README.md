# breakbeat

using aubio and sox to generate breakbeats


## install

must install aubio and sox first.
also you need lua (5.1+).

```bash
> sudo apt install aubio-tools sox
```

## usage

```
NAME
 
    breakbeat.lua - create a breakbeat from a drum loop  
 
DESCRIPTION
 
  -i, --input string
      input filename
 
  --input-tempo value
      tempo of input file (defaults to determine automatically)
 
  -o, --output string
      output filename
 
  -b, --beats value
      number of beats
 
  -t, --tempo value
      tempo of generated beat
 
  -d, --debug
      debug mode
 
  --reverse value
      probability of reversing (0-100%, default 10%)
 
  --stutter value
      probability of stutter (0-100%, default 5%)
 
  --pitch value
      probability of pitch up (0-100%, default 10%)
 
  --trunc value
      probability of truncation (0-100%, default 5%)
 
  --deviation value
      probability of deviating from base pattern (0-100%, default 30%)
 
  --kick value
      probability of snapping a kick to down beat (0-100%, default 80%)
 
  --snare value
      probability of snapping a snare to up beat (0-100%, default 50%)
```

## example

```
> ./breakbeat.lua -i sample.aiff -o sample-result.wav --beats 64 --tempo 150
```