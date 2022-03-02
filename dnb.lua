#!/usr/bin/env lua

math.randomseed(os.time())

local debugging=false
local charset={}

-- qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM1234567890
for i=48,57 do table.insert(charset,string.char(i)) end
for i=65,90 do table.insert(charset,string.char(i)) end
for i=97,122 do table.insert(charset,string.char(i)) end

function string.random(length)
  if length>0 then
    return string.random(length-1)..charset[math.random(1,#charset)]
  else
    return ""
  end
end

function string.random_filename(suffix,prefix)
  suffix=suffix or ".wav"
  prefix=prefix or "/tmp/breaktemp-"
  return prefix..string.random(8)..suffix
end

function math.round(number,quant)
  if quant==0 then
    return number
  else
    return math.floor(number/(quant or 1)+0.5)*(quant or 1)
  end
end

function math.std(numbers)
  local mu=math.average(numbers)
  local sum=0
  for _,v in ipairs(numbers) do
    sum=sum+(v-mu)^2
  end
  return math.sqrt(sum/#numbers)
end

function math.average(numbers)
  if next(numbers)==nil then
    do return end
  end
  local total=0
  for _,v in ipairs(numbers) do
    total=total+v
  end
  return total/#numbers
end

function math.trim(numbers,std_num)
  local mu=math.average(numbers)
  local std=math.std(numbers)
  local new_numbers={}
  for _,v in ipairs(numbers) do
    if v>mu-(std*std_num) and v<mu+(std*std_num) then
      table.insert(new_numbers,v)
    end
  end
  return math.average(new_numbers)
end

function table.clone(org)
  return {table.unpack(org)}
end

function table.merge(t1,t2)
  n=#t1
  for i=1,#t2 do
    t1[n+i]=t2[i]
  end
end

function table.reverse(t)
  local len=#t
  for i=len-1,1,-1 do
    t[len]=table.remove(t,i)
  end
end

function table.permute(t,n,count)
  n=n or #t
  for i=1,count or n do
    local j=math.random(i,n)
    t[i],t[j]=t[j],t[i]
  end
end

function table.shuffle(tbl)
  for i=#tbl,2,-1 do
    local j=math.random(i)
    tbl[i],tbl[j]=tbl[j],tbl[i]
  end
end

function table.add(t,scalar)
  for i,_ in ipairs(t) do
    t[i]=t[i]+scalar
  end
end

function table.is_empty(t)
  return next(t)==nil
end

function table.get_rotation(t)
  local t2={}
  local v1=0
  for i,v in ipairs(t) do
    if i>1 then
      table.insert(t2,v)
    else
      v1=v
    end
  end
  table.insert(t2,v1)
  return t2
end

function table.average(t)
  local sum=0
  for _,v in pairs(t) do
    sum=sum+v
  end
  return sum/#t
end

function table.rotate(t)
  for i,v in ipairs(table.get_rotation(t)) do
    t[i]=v
  end
end

function table.rotatex(t,d)
  if d<0 then
    table.reverse(t)
  end
  local d_abs=math.abs(d)
  if d_abs>0 then
    for i=1,d_abs do
      table.rotate(t)
    end
  end
  if d<0 then
    table.reverse(t)
  end
end

function table.clone(org)
  return {table.unpack(org)}
end

function table.copy(t)
  local t2={}
  for i,v in ipairs(t) do
    table.insert(t2,v)
  end
  return t2
end

function table.print(t)
  for i,v in ipairs(t) do
    print(i,v)
  end
end

function table.print_matrix(m)
  for _,v in ipairs(m) do
    local s=""
    for _,v2 in ipairs(v) do
      s=s..v2.." "
    end
    print(s)
  end
end

function table.get_change(m)
  local total_change=0
  for col=1,#m[1] do
    local last_val=0
    for row=1,#m do
      local val=m[row][col]
      if row>1 then
        total_change=total_change+math.abs(val-last_val)
      end
      last_val=val
    end
  end
  return total_change
end

function table.minimize_row_changes(m)
  local m_=table.clone(m)
  -- generate random rotations
  local best_change=100000
  local best_m={}
  for i=1,10000 do
    -- rotate a row randomly
    local random_row=math.random(1,#m)
    m_[random_row]=table.get_rotation(m_[random_row])
    local change=table.get_change(m_)
    if change<best_change then
      best_change=change
      best_m=table.clone(m_)
    end
  end
  return best_m
  -- table.print_matrix(best_m)
end

function table.contains(t,x)
  for _,v in ipairs(t) do
    if v==x then
      do return true end
    end
  end
  return false
end

-- lfo goes from 0 to 1
function math.lfo(t,period,phase)
  return (math.sin(2*3.14159265/period+phase)+1)/2
end

local audio={}

function audio.tempo(fname)
  s=os.capture("aubioonset -i "..fname.." -O hfc -f -s -60 -t 0.1 -B 256 -H 128")
  local last_val=0
  local bpms={}
  for v in s:gmatch("%S+") do
    v=tonumber(v)
    if v~=nil then
      if v>0 then
        local bpm=60/(v-last_val)
        while bpm>200 do
          bpm=bpm/2
        end
        table.insert(bpms,bpm)
      end
      last_val=v
    end
  end

  return math.round(math.trim(bpms,1.5))
end

function audio.length(fname)
  local s=os.capture("sox "..fname.." -n stat 2>&1  | grep Length | awk '{print $3}'")
  return tonumber(s)
end

function audio.mean_norm(fname)
  local s=os.capture("sox "..fname.." -n stat 2>&1  | grep Mean | grep norm | awk '{print $3}'")
  return tonumber(s)
end

function audio.quantize(fname,fname2,tempo,beat_division,excess)
  local duration=audio.length(fname)
  beat=beat or 1/16 -- defaults to sixteenth note
  excess=excess or 0.005 -- add 0.005 excess for joining
  local beat_sec=(60/tempo*4)*beat
  local beats=duration/beat_sec
  local beats_ideal=math.round(beats)
  if (beats_ideal*beat_sec+excess)>(beats*beat_sec+excess) then
    -- stretch
    local v=string.random_filename()
    os.cmd("sox "..fname.." "..v.." stretch "..(beats_ideal/beats*1.05))
    fname=v
  end
  -- trim
  os.cmd("sox "..fname.." "..fname2.." trim 0 "..(beats_ideal*beat_sec+excess))
end

function audio.stretch(fname,fname2,newlength)
  local duration=audio.length(fname)
  if newlength>duration then
    local v=string.random_filename()
    os.cmd("sox "..fname.." "..v.." stretch "..(newlength/duration*1.05))
    fname=v
  end
  -- trim
  os.cmd("sox "..fname.." "..fname2.." trim 0 "..newlength)
end

function audio.stutter(fname,fname2,tempo,count,beat_division,gain,gainpitch)
  count=count or 4
  beat=beat or 1/16 -- defaults to sixteenth note
  excess=excess or 0.005 -- add 0.005 excess for joining
  local beat_sec=(60/tempo*4)*beat
  local foo1=string.random_filename()
  local foo2=string.random_filename()
  local foo3=string.random_filename()
  audio.quantize(fname,foo1,tempo,1/16,0)
  -- trim to beat
  local gain_amt=0
  if gain>0 then
    -- increase
    gain_amt=-1*2*count
  elseif gain<0 then
    gain_amt=-2
  else
    gain_amt=-2
  end
  os.cmd("sox "..foo1.." "..foo2.." gain "..gain_amt.." trim 0 "..(beat_sec+0.005))
  os.cmd("sox "..foo2.." "..fname2)
  local pitch_amt=0
  gainpitch=gainpitch or 0
  for i=2,count do
    local gain_amt=0
    if gain>0 then
      -- increase
      gain_amt=-1*2*(count-i)
    elseif gain<0 then
      gain_amt=-1*i*2
    else
      gain_amt=-2
    end
    pitch_amt=pitch_amt+(100*gainpitch)
    os.cmd("sox "..foo1.." "..foo2.." gain "..gain_amt.." pitch "..pitch_amt.." trim 0 "..(beat_sec+0.005))
    os.cmd("sox "..fname2.." "..foo2.." "..foo3.." splice "..audio.length(fname2))
    os.cmd("sox "..foo3.." "..fname2)
  end
end

-- audio.silent_end will make the last silence_length seconds into silence
function audio.silent_end(fname,fname2,silence_length,fade_out)
  fade_out=fade_out or 0.005
  silence_length=silence_length or 0.1
  local sample_rate,channels=audio.get_info(fname)
  local silence_file=string.random_filename()
  local faded_file=string.random_filename()
  -- first create the silence
  os.cmd("sox -n -r "..sample_rate.." -c "..channels.." "..silence_file.." trim 0.0 "..silence_length)
  -- create faded file
  local e=audio.length(fname)-silence_length
  os.cmd("sox "..fname.." "..faded_file.." fade 0 "..e.." "..fade_out)
  -- combine the two
  os.cmd("sox "..faded_file.." "..silence_file.." "..fname2)
end

function audio.get_info(fname)
  local sample_rate=tonumber(os.capture("sox --i "..fname.." | grep 'Sample Rate' | awk '{print $4}'"))
  local channels=tonumber(os.capture("sox --i "..fname.." | grep 'Channels' | awk '{print $3}'"))
  return sample_rate,channels
end

function os.capture(cmd,raw)
  local f=assert(io.popen(cmd,'r'))
  local s=assert(f:read('*a'))
  f:close()
  if raw then return s end
  s=string.gsub(s,'^%s+','')
  s=string.gsub(s,'%s+$','')
  s=string.gsub(s,'[\n\r]+',' ')
  return s
end

function os.cmd(cmd)
  if debugging then
    print(cmd)
  end
  os.execute(cmd.." 2>&1")
end

local Beat={}

function Beat:new (o)
  o=o or {}
  setmetatable(o,self)
  self.__index=self

  -- determine tempo
  o.tempo=audio.tempo(o.fname)
  -- if o.tempo==nil then
  --   local s=os.capture("aubio tempo "..o.fname)
  --   o.tempo=math.round(tonumber(s:match("%S+")))
  --   if o.tempo==nil then
  --     do return end
  --   end
  -- end

  -- determine channels
  o.sample_rate,o.channels=audio.get_info(o.fname)

  -- determine onsets
  o.onsets={}
  local threshold=0.5
  while #o.onsets<4 and threshold>0 do
    o.onsets={}
    s=os.capture("aubioonset -i "..o.fname.." -O hfc -f -M "..(60/o.tempo/4).." -s -60 -t "..threshold.." -B 128 -H 128")
    for v in s:gmatch("%S+") do
      table.insert(o.onsets,tonumber(v))
    end
    threshold=threshold-0.1
  end
  print("found "..#o.onsets.." onsets")

  o:onset_split()

  return o
end

function Beat:onset_split()
  self.onset_files={}
  self.onset_files_bd={}
  self.onset_files_sd={}
  self.onset_stats={}
  self.onset_is_kick={}
  self.onset_is_snare={}
  local lowpass_file=string.random_filename()
  local pad_left=string.random_filename()
  local pad_right=string.random_filename()
  local concat_file=string.random_filename()
  local sample_rate,channels=audio.get_info(self.fname)
  local duration=audio.length(self.fname)
  if self.make_movie then
    os.cmd("sox "..self.fname.." "..concat_file)
    os.cmd("audiowaveform -i "..concat_file.." -o /tmp/breaktemp-onsetall.png --background-color ffffff --waveform-color d3d3d3 -w 960 -h 512 --no-axis-labels --pixels-per-second "..math.floor(960/duration).." > /dev/null 2>&1")
  end
  for i,v in ipairs(self.onsets) do
    if i>1 then
      local s=self.onsets[i-1]
      local onset_name=string.random_filename(s..".wav")
      local e=(self.onsets[i]-self.onsets[i-1])
      if i==#self.onsets then
        os.cmd("sox "..self.fname.." "..onset_name.." trim "..s)
        if self.make_movie then
          os.cmd("sox -n -r "..sample_rate.." -c "..channels.." "..pad_left.." trim 0.0 "..self.onsets[i-1])
          os.cmd("sox "..pad_left.." "..onset_name.." "..concat_file)
          os.cmd("audiowaveform -i "..concat_file.." -o "..onset_name..".png --background-color ffffff00 --waveform-color 545454 -w 960 -h 512 --no-axis-labels --pixels-per-second "..math.floor(960/duration).." > /dev/null 2>&1")
        end
      else
        os.cmd("sox "..self.fname.." "..onset_name.." trim "..s.." "..e)

        if self.make_movie then
          -- create an image
          os.cmd("sox -n -r "..sample_rate.." -c "..channels.." "..pad_left.." trim 0.0 "..self.onsets[i-1])
          os.cmd("sox -n -r "..sample_rate.." -c "..channels.." "..pad_right.." trim 0.0 "..(duration-self.onsets[i]))
          os.cmd("sox "..pad_left.." "..onset_name.." "..pad_right.." "..concat_file)
          os.cmd("audiowaveform -i "..concat_file.." -o "..onset_name..".png --background-color ffffff00 --waveform-color 545454 -w 960 -h 512 --no-axis-labels --pixels-per-second "..math.floor(960/duration).." > /dev/null 2>&1")
        end
      end
      -- os.cmd("cp "..onset_name.." onset"..i..".wav")
      os.cmd("sox "..onset_name.." "..lowpass_file.." lowpass 200")
      onset_stat={bd=false,sd=false,bd_metric=audio.mean_norm(lowpass_file) or 0}
      os.cmd("sox "..onset_name.." "..lowpass_file.." lowpass 400 highpass 200")
      onset_stat.sd_metric=audio.mean_norm(lowpass_file) or 0
      if onset_stat.sd_metric>0.01 and onset_stat.sd_metric>onset_stat.bd_metric then
        onset_stat.sd=true
        table.insert(self.onset_files_sd,onset_name)
        self.onset_is_snare[onset_name]=true
      elseif onset_stat.bd_metric>0.02 then
        onset_stat.bd=true
        table.insert(self.onset_files_bd,onset_name)
        self.onset_is_kick[onset_name]=true
      end
      table.insert(self.onset_stats,onset_stat)
      table.insert(self.onset_files,onset_name)
    end
  end

end

function Beat:generate(fname,beats,new_tempo,p_reverse,p_stutter,p_pitch,p_trunc,p_deviation,p_kick,p_snare,p_half,p_reverb,kick_mix,snare_mix)
  new_tempo=new_tempo or self.tempo
  local kick_merge=string.random_filename()
  local snare_merge=string.random_filename()
  local p_global_lfo={math.random(16,32),0}
  local p_reverse_lfo={math.random(12,24),math.random(1,100)}
  local p_stutter_lfo={math.random(12,18),math.random(1,100)}
  local p_pitch_lfo={math.random(12,24),math.random(1,100)}
  local p_trunc_lfo={math.random(12,24),math.random(1,100)}
  local p_deviation_lfo={math.random(4,12),math.random(1,100)}
  local p_half_lfo={math.random(12,18),math.random(1,100)}

  os.cmd("sox -r "..self.sample_rate.." -c "..self.channels.." kick.wav "..kick_merge.." gain "..kick_mix)
  os.cmd("sox -r "..self.sample_rate.." -c "..self.channels.." snare.wav "..snare_merge.." gain "..snare_mix)
  local movie_files={}
  beats=beats or 8
  local final_length=(60/self.tempo*beats)
  local joined_file=string.random_filename()
  local vfinal=string.random_filename()
  local excess_difference=0.005
  local current_beat=0
  local duration_last=0
  local duration_differences={}
  for i=1,(beats*3) do
    -- TODO make global lfo an option
    local p_global=1--beats>16 and math.lfo(current_beat,p_global_lfo[1],p_global_lfo[2]) or 1
    local vi=((i-1)%#self.onset_files)+1
    if math.random()<p_global*p_deviation/100 then
      vi=math.random(#self.onset_files)
    end
    local v=self.onset_files[vi]
    if math.round(current_beat)%8==0 and math.random()<p_kick/100 and next(self.onset_files_bd)~=nil then
      v=self.onset_files_bd[math.random(#self.onset_files_bd)]
    end
    if math.round(current_beat)%12==0 and math.random()<p_snare/100 and next(self.onset_files_sd)~=nil then
      v=self.onset_files_sd[math.random(#self.onset_files_sd)]
    end
    local v_original=v

    if self.onset_is_kick[v_original] then
      -- mix the sound with a kick
      local original_length=audio.length(v)
      local vnew=string.random_filename()
      os.cmd("sox -m "..kick_merge.." "..v.." "..vnew.." trim 0 "..original_length)
      v=vnew
    end
    if self.onset_is_snare[v_original] then
      -- mix the sound with a kick
      local original_length=audio.length(v)
      local vnew=string.random_filename()
      os.cmd("sox -m "..snare_merge.." "..v.." "..vnew.." trim 0 "..original_length)
      v=vnew
    end

    if math.random()<p_global*p_pitch/100*math.lfo(current_beat,p_pitch_lfo[1],p_pitch_lfo[2])*2 then
      -- increase pitch the segment
      local vnew=string.random_filename()
      os.cmd("sox "..v.." "..vnew.." pitch "..(200*math.random(1,4)))
      v=vnew
    end
    if math.random()<p_global*p_half/100*math.lfo(current_beat,p_half_lfo[1],p_half_lfo[2])*2 then
      -- slow down
      local vnew=string.random_filename()
      os.cmd("sox "..v.." "..vnew.." speed "..(0.5))
      v=vnew
    end
    if math.random()<p_global*p_reverse/100*math.lfo(current_beat,p_reverse_lfo[1],p_reverse_lfo[2])*2/2 then
      -- reverse the segment
      local vnew=string.random_filename()
      os.cmd("sox "..v.." "..vnew.." reverse")
      v=vnew
    end
    if math.random()<p_global*p_stutter/100/4*math.lfo(current_beat,p_stutter_lfo[1],p_stutter_lfo[2])*2 and math.round(current_beat)%4==0 then
      local vnew=string.random_filename()
      audio.stutter(v,vnew,self.tempo,12,1/16,1,math.random(1,10)<7 and 0 or math.random(-1,1))
      v=vnew
    end
    if math.random()<p_global*p_stutter/100/4*math.lfo(current_beat,p_stutter_lfo[1],p_stutter_lfo[2])*2 and math.round(current_beat)%4==1 then
      local vnew=string.random_filename()
      audio.stutter(v,vnew,self.tempo,8,1/16,math.random(-1,5),math.random(1,10)<7 and 0 or math.random(-1,1))
      v=vnew
    end
    if math.random()<p_global*p_stutter/100/4*math.lfo(current_beat,p_stutter_lfo[1],p_stutter_lfo[2])*2 and math.round(current_beat)%4==2 then
      local vnew=string.random_filename()
      audio.stutter(v,vnew,self.tempo,4,1/16,math.random(-2,6),math.random(1,10)<7 and 0 or math.random(-1,1))
      v=vnew
    end
    if math.random()<p_global*p_stutter/100/4*math.lfo(current_beat,p_stutter_lfo[1],p_stutter_lfo[2])*2 and math.round(current_beat)%4==3 then
      local vnew=string.random_filename()
      audio.stutter(v,vnew,self.tempo,2,1/16,math.random(-3,7),math.random(1,10)<7 and 0 or math.random(-1,1))
      v=vnew
    end
    if math.random()<p_global*p_trunc/100*math.lfo(current_beat,p_trunc_lfo[1],p_trunc_lfo[2])*2 and audio.length(v)>(60/self.tempo/4) then
      local vnew=string.random_filename()
      audio.silent_end(v,vnew,60/self.tempo/8)
      v=vnew
    end
    if math.random()<p_global*p_reverb/100 and (self.onset_is_snare[v_original] or self.onset_is_kick[v_original]) then
      -- add reverb to snare
      local vnew=string.random_filename()
      local vduration=audio.length(v)
      os.cmd("sox "..v.." "..vnew.." gain 0 pad 0 "..(vduration*math.random(1,3)/2).." reverb")
      v=vnew
    end
    if math.random()<p_global*p_reverse/100*math.lfo(current_beat,p_reverse_lfo[1],p_reverse_lfo[2])*2/2 then
      local vnew=string.random_filename()
      os.cmd("sox "..v.." "..vnew.." reverse")
      v=vnew
    end

    local v_duration=0
    if i==1 then
      local new_beats=(audio.length(v))/(60/self.tempo/2)
      local new_beats_ideal=math.round(new_beats)
      local difference_time=(new_beats_ideal-new_beats)*(60/self.tempo/2)
      local vstretch=string.random_filename()
      audio.stretch(v,joined_file,audio.length(v)+difference_time+0.01)
    else
      -- try to keep it in time
      local new_beats=(audio.length(joined_file)+audio.length(v))/(60/self.tempo/2)
      local new_beats_ideal=math.round(new_beats)
      local difference_time=(new_beats_ideal-new_beats)*(60/self.tempo/2)
      local vstretch=string.random_filename()
      audio.stretch(v,vstretch,audio.length(v)+difference_time+0.01)
      if debugging then
        print("debug: new_beats: ",new_beats,new_beats_ideal)
        print("debug: difference_time: "..difference_time)
      end
      os.cmd("sox "..joined_file.." "..vstretch.." "..vfinal.." splice "..audio.length(joined_file)..",0.005,0.001")
      os.cmd("mv "..vfinal.." "..joined_file)
    end

    local v_duration=audio.length(joined_file)
    table.insert(duration_differences,v_duration-duration_last)
    if v_duration-duration_last>0 and self.make_movie then
      local vv_duration=v_duration-duration_last
      local movie_file=string.random_filename(".mp4")
      os.cmd('composite -gravity center '..v_original..'.png /tmp/breaktemp-onsetall.png /tmp/breaktemp-1.png')
      os.cmd('ffmpeg -hide_banner -loglevel error -y -loop 1 -i /tmp/breaktemp-1.png -c:v libx264 -t '..vv_duration*self.tempo/new_tempo..' -pix_fmt yuv420p '..movie_file)
      table.insert(movie_files,movie_file)
    end
    duration_last=v_duration

    current_beat=(audio.length(joined_file))/(60/self.tempo/2)
    if debugging then
      print("debug: current_beats: ",current_beat)
    end
    if audio.length(joined_file)>=(60/self.tempo*beats+0.005) then
      break
    end
  end

  -- -- make chords
  -- local cur_dur=0
  -- local total_duration=audio.length(joined_file)
  -- local chord_file=string.random_filename()
  -- local f=io.open(sox_effects,"w")
  -- io.output(f)
  -- while cur_dur<total_duration do
  --   local new_dur=60/self.tempo*16
  --   io.write(string.format("synth sin B2 sawtooth B3 sawtooth D4 sawtooth G4 lowpass 1400 chorus 0.7 0.9 55 0.4 0.2 2 -t remix - gain -6 reverb -w fade 0.1 %f 0.1\n",new_dur))
  --   cur_dur=cur_dur+new_dur
  -- end
  -- io.close(f)
  -- os.cmd("sox -n -c2 -r "..self.sample_rate.." "..fname..".chords.wav --effects-file="..sox_effects)

  -- trim to X beats
  os.cmd("sox "..joined_file.." "..fname.." trim 0 "..final_length.." highpass 80 contrast")
  if new_tempo~=self.tempo then
    local v=string.random_filename()
    os.cmd("sox "..fname.." "..v.." speed "..new_tempo/self.tempo)
    os.cmd("mv "..v.." "..fname)
  end
  print("generated "..beats.." beats into '"..fname.."' @ "..(new_tempo or self.tempo).." bpm")
  final_length=audio.length(fname)

  -- make bassline
  local bass_notes={1,1,1,1,1,1,27/25,27/25}
  local bass_note_patterns={
    {1/8,1/8,1/8,1/8,1/8,1/8,1/8,1/8},
    {1,1},
    {3/16,3/16,3/16,1/4},
    {3/8,3/8,1/4},
    {1/8,1/8,1/8,1/8,1/8,3/8},
  }
  local bass_note_pattern=bass_note_patterns[math.random(#bass_note_patterns)]
  local pattern_i=0
  local freq=61.74
  local sox_effects=string.random_filename()
  local f=io.open(sox_effects,"w")
  io.output(f)
  local cur_dur=0
  for i=0,1000 do
    pattern_i=pattern_i+1
    if pattern_i>#bass_note_pattern then
      pattern_i=1
      bass_note_pattern=bass_note_patterns[math.random(#bass_note_patterns)]
    end
    local dur=bass_note_pattern[pattern_i]*4*60/new_tempo
    local freq1=freq*bass_notes[math.random(#bass_notes)]
    local freq2=freq1+new_tempo/60*math.random(1,2)
    local freq3=freq1*2+new_tempo/60/2
    io.write(string.format("synth sin %f sin %f sin %f remix - gain -32 bass +6 overdrive %d %d fade p 0.002 %f 0.1\n",
    freq1,freq2,freq3,math.random(20,30),math.random(20,30),dur))
    cur_dur=cur_dur+dur
    if cur_dur>final_length then
      do break end
    end
  end
  io.close(f)
  local bass_file=string.random_filename()
  os.cmd("sox -n -c2 -r "..self.sample_rate.." "..bass_file.." --effects-file="..sox_effects)
  os.cmd("sox "..bass_file.." "..fname..".bass.wav trim 0 "..final_length.." chorus 0.7 0.9 55 0.4 0.25 2 -t deemph highpass 40 lowpass 400 contrast")

  -- combine
  os.cmd("sox -m "..fname..".bass.wav "..fname.." "..fname..".dnb.wav contrast")

  -- make movie
  if self.make_movie then
    local movie_list=string.random_filename(".txt")
    local f=io.open(movie_list,"a")
    io.output(f)
    for _,m in ipairs(movie_files) do
      io.write("file '"..m.."'\n")
    end
    io.close(f)
    local movie_noaudio=string.random_filename(".mp4")
    os.cmd("ffmpeg -hide_banner -loglevel error -y -f concat -safe 0 -i "..movie_list.." -c copy "..movie_noaudio)
    os.cmd("ffmpeg -hide_banner -loglevel error -y -i "..fname..".dnb.wav -i "..movie_noaudio.." "..fname..".mp4")
    print("generated movie "..fname..".mp4")
  end

end

function Beat:clean()
  for _,v in ipairs(self.onset_files) do
    os.cmd("rm "..v)
  end
end

function Beat:str()
  print("filename: "..self.fname)
  print("sample rate: "..self.sample_rate)
  print("channels: "..self.channels)
  print("tempo: "..self.tempo.." bpm")
  if debugging then
    print("onsets: ")
    for i,v in ipairs(self.onset_files) do
      local vtype="(?)"
      if self.onset_stats[i].bd then
        vtype="(bd)"
      elseif self.onset_stats[i].sd then
        vtype="(sd)"
      end
      print(v.."  "..self.onsets[i].."s"..", bd: "..self.onset_stats[i].bd_metric..", sd: "..self.onset_stats[i].sd_metric.." "..vtype)
    end
  end
end

local fname="sample.aiff"
local fname_out="result.wav"
local beats=16
local new_tempo=nil
local input_tempo=nil
local p_reverse=10
local p_stutter=5
local p_pitch=10
local p_trunc=5
local p_deviation=30
local p_kick=70
local p_snare=50
local p_half=1
local p_reverb=2
local kick_mix=-6
local snare_mix=-6
local make_movie=false
for i,v in ipairs(arg) do
  if string.find(v,"input") and string.find(v,"tempo") then
    input_tempo=tonumber(arg[i+1]) or input_tempo
  elseif string.find(v,"make") and string.find(v,"movie") then
    make_movie=true
  elseif string.find(v,"-i") and fname=="sample.aiff" then
    fname=arg[i+1]
  elseif string.find(v,"-o") then
    fname_out=arg[i+1]
  elseif string.find(v,"reverse") then
    p_reverse=tonumber(arg[i+1]) or p_reverse
  elseif string.find(v,"half") then
    p_half=tonumber(arg[i+1]) or p_half
  elseif string.find(v,"stutter") then
    p_stutter=tonumber(arg[i+1]) or p_stutter
  elseif string.find(v,"pitch") then
    p_pitch=tonumber(arg[i+1]) or p_pitch
  elseif string.find(v,"trunc") then
    p_trunc=tonumber(arg[i+1]) or p_trunc
  elseif string.find(v,"deviation") then
    p_deviation=tonumber(arg[i+1]) or p_deviation
  elseif string.find(v,"kick") and string.find(v,"mix") then
    kick_mix=tonumber(arg[i+1]) or kick_mix
  elseif string.find(v,"kick") then
    p_kick=tonumber(arg[i+1]) or p_kick
  elseif string.find(v,"snare") and string.find(v,"mix") then
    snare_mix=tonumber(arg[i+1]) or snare_mix
  elseif string.find(v,"snare") then
    p_snare=tonumber(arg[i+1]) or p_snare
  elseif string.find(v,"reverb") then
    p_reverb=tonumber(arg[i+1]) or p_reverb
  elseif string.find(v,"-b") then
    beats=tonumber(arg[i+1])
  elseif string.find(v,"-t") then
    new_tempo=tonumber(arg[i+1]) or new_tempo
  elseif string.find(v,"-d") then
    debugging=true
  end
end

if #arg<2 then
  print([[NAME
 
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
]])
else
  local b=Beat:new({fname=fname,tempo=input_tempo,make_movie=make_movie})
  b:str()
  b:generate(fname_out,beats,new_tempo,p_reverse,p_stutter,p_pitch,p_trunc,p_deviation,p_kick,p_snare,p_half,p_reverb,kick_mix,snare_mix)
  os.cmd("rm /tmp/breaktemp-*")
end
