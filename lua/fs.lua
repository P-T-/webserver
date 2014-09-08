local exists={}
local isdir={}
local isfile={}
local list={}
local rd={}
local size={}
local last={}
local modified={}
local function update(tbl,ind)
	local tme=socket.gettime()
	local dt=tme-(last[tbl] or tme)
	last[tbl]=tme
	for k,v in tpairs(tbl) do
		v.time=v.time-dt
		if v.time<=0 then
			tbl[k]=nil
		end
	end
	return (tbl[ind] or {}).value
end
local function set(tbl,ind,val)
	tbl[ind]={time=10,value=val}
	return val
end
fs={
	exists=function(file)
		return lfs.attributes(file)~=nil
	end,
	isDir=function(file)
		local res=update(isdir,file)
		if res~=nil then
			return res
		end
		local dat=lfs.attributes(file)
		if not dat then
			return set(isdir,file,nil)
		end
		return set(isdir,file,dat.mode=="directory")
	end,
	isFile=function(file)
		local res=update(isfile,file)
		if res~=nil then
			return res
		end
		local dat=lfs.attributes(file)
		if not dat then
			return set(isfile,file,nil)
		end
		return set(isfile,file,dat.mode=="file")
	end,
	split=function(file)
		local t={}
		for dir in file:gmatch("[^/]+") do
			t[#t+1]=dir
		end
		return t
	end,
	combine=function(filea,fileb)
		local o={}
		for k,v in pairs(fs.split(filea)) do
			table.insert(o,v)
		end
		for k,v in pairs(fs.split(fileb)) do
			table.insert(o,v)
		end
		return filea:match("^/?")..table.concat(o,"/")..fileb:match("/?$")
	end,
	resolve=function(file)
		local b,e=file:match("^(/?).-(/?)$")
		local t=fs.split(file)
		local s=0
		for l1=#t,1,-1 do
			local c=t[l1]
			if c=="." then
				table.remove(t,l1)
			elseif c==".." then
				table.remove(t,l1)
				s=s+1
			elseif s>0 then
				table.remove(t,l1)
				s=s-1
			end
		end
		return b..table.concat(t,"/")..e
	end,
	list=function(dir)
		local res=update(list,dir)
		if res~=nil then
			return res
		end
		dir=dir or ""
		local o={}
		for fn in lfs.dir(dir) do
			if fn~="." and fn~=".." then
				table.insert(o,fn)
			end
		end
		return set(list,dir,o)
	end,
	read=function(file)
		local res=update(rd,file)
		if res~=nil then
			return res
		end
		local data=io.open(file,"rb"):read("*a")
		if (rd[file] or {}).data~=data then
			modified[file]=os.date()
		end
		return set(rd,file,data)
	end,
	modified=function(file)
		local res=modified[file]
		if not res then
			fs.read(file)
		end
		return modified[file]
	end,
	size=function(file)
		local res=update(size,file)
		if res then
			return res
		end
		local dat=lfs.attributes(file)
		return set(size,file,dat and dat.size)
	end,
}
