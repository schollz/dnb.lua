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

local audio={}

function audio.length(fname)
  local s=os.capture("sox "..fname.." -n stat 2>&1  | grep Length | awk '{print $3}'")
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

function audio.stutter(fname,fname2,tempo,count,beat_division,excess)
  count=count or 4
  beat=beat or 1/16 -- defaults to sixteenth note
  excess=excess or 0.005 -- add 0.005 excess for joining
  local beat_sec=(60/tempo*4)*beat
  local foo1=string.random_filename()
  local foo2=string.random_filename()
  local foo3=string.random_filename()
  audio.quantize(fname,foo1,tempo,1/16,0)
  -- trim to beat
  os.cmd("sox "..foo1.." "..foo2.." gain -"..(2*count).." trim 0 "..(beat_sec+0.005))
  os.cmd("sox "..foo2.." "..fname2)
  for i=2,count do
    os.cmd("sox "..foo1.." "..foo2.." gain -"..(2*(count-i)).." trim 0 "..(beat_sec+0.005))
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
  local s=os.capture("aubio tempo "..o.fname)
  o.tempo=math.round(tonumber(s:match("%S+")))
  if o.tempo==nil then
    do return end
  end

  -- determine channels
  o.sample_rate,o.channels=audio.get_info(o.fname)

  -- determine onsets
  s=os.capture("aubioonset -i "..o.fname.." -O hfc -f -M "..(60/o.tempo/4).." -s -60 -t 0.6 -B 128 -H 128")
  o.onsets={}
  for v in s:gmatch("%S+") do
    table.insert(o.onsets,tonumber(v))
  end

  o:onset_split()

  return o
end

function Beat:onset_split()
  self.onset_files={}
  for i,v in ipairs(self.onsets) do
    if i>1 then
      local s=self.onsets[i-1]
      local onset_name=string.random_filename(s..".wav")
      -- if s>0.01 then
      --   s=s-0.01 -- add 0.005 excess + 0.005 leeway
      -- end
      local e=(self.onsets[i]-self.onsets[i-1])
      if i==#self.onsets then
        os.cmd("sox "..self.fname.." "..onset_name.." trim "..s)
      else
        os.cmd("sox "..self.fname.." "..onset_name.." trim "..s.." "..e)
      end
      table.insert(self.onset_files,onset_name)
    end
  end
end

function Beat:generate(fname,beats,new_tempo)
  beats=beats or 8
  local final_length=(60/self.tempo*beats+0.005)
  local joined_file=string.random_filename()
  local vfinal=string.random_filename()
  local excess_difference=0.005
  for i=1,(beats*3) do
    local vi=((i-1)%#self.onset_files)+1
    if math.random()<0.5 then
      vi=math.random(#self.onset_files)
    end
    local v=self.onset_files[vi]
    if math.random()<0.1 then
      -- increase pitch the segment
      local vnew=string.random_filename()
      os.cmd("sox "..v.." "..vnew.." pitch 200")
      v=vnew
    end
    if math.random()<0.1 then
      -- reverse the segment
      local vnew=string.random_filename()
      os.cmd("sox "..v.." "..vnew.." reverse")
      v=vnew
    end
    if math.random()<0.05 then
      local vnew=string.random_filename()
      audio.stutter(v,vnew,self.tempo,8,1/16)
      v=vnew
    end
    if math.random()<0.05 and audio.length(v)>(60/self.tempo/4) then
      local vnew=string.random_filename()
      audio.silent_end(v,vnew,60/self.tempo/4)
      v=vnew
    end
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
    if debugging then
      print("debug: current_beats: ",(audio.length(joined_file))/(60/self.tempo/2))
    end
    if audio.length(joined_file)>=(60/self.tempo*beats+0.005) then
      break
    end
  end

  -- trim to X beats
  os.cmd("sox "..joined_file.." "..fname.." trim 0 "..final_length)
  if new_tempo~=nil then
    local v=string.random_filename()
    os.cmd("sox "..fname.." "..v.." speed "..new_tempo/self.tempo)
    os.cmd("mv "..v.." "..fname)
  end

  print("generated '"..fname.."' @ "..new_tempo.." bpm")
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
  print("onsets: ")
  for _,v in ipairs(self.onsets) do
    print(v.."s")
  end
end

b=Beat:new({fname="sample.aiff"})
b:str()
b:generate("break_generated.wav",64,160)
os.cmd("rm /tmp/breaktemp-*")

-- audio.stutter("onset0.0.wav","stutter.wav",b.tempo,8)
-- audio.quantize("onset0.0.wav","quant.wav",b.tempo)
-- audio.quantize("onset0.21483.wav","quant.wav",b.tempo)
