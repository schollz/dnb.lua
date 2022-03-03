
# dnb.lua

using aubio and sox to generate breakbeats

## demo

[![demo](https://videoapi-muybridge.vimeocdn.com/animated-thumbnails/image/f78931b5-e28b-4202-a6ac-3cb7feff294c.gif?ClientID=vimeo-core-prod&Date=1646096543&Signature=9bd8c270fcf9d7edf744c05afddd25839629fe0f)](https://vimeo.com/683086129)

## install

must install aubio and sox first.
also you need lua (5.1+).

```bash
> sudo apt install aubio-tools sox
```

to make movies you also need `ffmpeg`, `imagemagick`, and `audiowaveform`.


```bash
> sudo apt install ffmpeg audiowaveform imagemagick
```

## usage

```
NAME
 
    dnb.lua - generative drum & bass
 
DESCRIPTION
 
  -i, --input string
      input filename
 
  --input-tempo value
      tempo of input file (defaults to determine automatically)
 
  -o, --output string
      output filename
 
  --make-movie
      creates movie (SLOW, and requires audiowaveform, ffmpeg, imagemagick)
 
  -b, --beats value
      number of beats
 
  -t, --tempo value
      tempo of generated beat
 
  -d, --debug
      debug mode
 
  --no-logo
      don't show logo
 
  --global-lfo
      modulate every probability by a global lfo (random)
 
  --reverse value
      probability of reversing (0-100%, default 10%)
 
  --stutter value
      probability of stutter (0-100%, default 5%)
 
  --pitch value
      probability of pitch up (0-100%, default 10%)
 
  --trunc value
      probability of truncation (0-100%, default 5%)
 
  --half value
      probability of slow down (0-100%, default 1%)
 
  --reverb value
      probability of adding reverb tail to kick/snare (0-100%, default 2%)
 
  --deviation value
      probability of deviating from base pattern (0-100%, default 30%)
 
  --kick value
      probability of snapping a kick to down beat (0-100%, default 80%)
 
  --kick-mix value
      volume of added kick in dB (default -6)
 
  --snare value
      probability of snapping a snare to up beat (0-100%, default 50%)
 
  --snare-mix value
      volume of added snare in dB (default -6)
 
  --bassline
      add bassline

```

## example

```
> ./dnb.lua -b 16 -i amen_resampled.wav -o something.wav -trunc 5 -stutter 40 -kick 50 -deviation 20 --snare 30 --reverse 10 --pitch 5 --kick-mix -6 --snare-mix -6 --reverb 2 --tempo 160 --bassline
```