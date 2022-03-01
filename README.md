# breakbeat

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
 
    breakbeat.lua - create a breakbeat from a drum loop  
 
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