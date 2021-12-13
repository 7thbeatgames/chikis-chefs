pico-8 cartridge // http://www.pico-8.com
version 34
__lua__


z = 0
currfruits = {}
bubblefruits = {}
tscratch = -1
tcatanim = -1

cls()
music()
last=0
--_set_fps(1000)

-- conductor

tick = 0  -- is stat(50) but always increasing
tickl = 0 -- is stat(50)
tickf = 0 -- is tick but interpolated

statloops = -1
statprev =0
statcap = 16 --stat per pattern
spb = 16  -- stat per beat
bar = 0
calltime = false

notesstr = ""
bbeats = ""

newtick = false
tick_response = 0
tttt = 0
sylaudio = 0
anybtn = false
closestfruit = 0
bubbles_xoffset = 8

function _init()
	
end


function _update60()
	-- conductor
	--detect a stat(50) looping
	statprev = tickl
	tickl =  stat(50)
	if (tickl < statprev)
	then statloops+=1 end

	newtick = tickl ~= statprev
	newbar = newtick and tickl == 0

	tick = stat(50) + statloops * statcap
	tickf = newtick and tick or tickf + 1/60 
	anybtn = btnp(0) or btnp(1) or btnp(2) or btnp(3) or btnp(4) or btnp(5)

	update_conductor()

	-- game logic
	t = time() * 2

	-- appear conveyor belt fruit
	-- if btnp(4) then
	-- 	z = ceil(rnd(#allfruits - 1))
	-- 	bringfruit(allfruits[z])
	-- end

	if newbar and calltime then
		bubblefruits = {}
	end



	-- appear bubble fruit
	-- todo change to depend on rhythm

	--check if current tickl is in the starting beat for a bubble
	local flagg = false
	--wtf ternary
	local _arr = music_side_prebar == mside.a and startbeats_a or startbeats_b

	--fruits character position in string
	pos = -1
	for i=1,#_arr do
	 if _arr[i] == tickl then
	 flagg = true
	 pos = i
	end
	end

	if flagg == true and newtick and calltime and #arr_basket_show > 0 and music_state ~= mstate.intro then
		--z = ceil(rnd(#allfruits - 1))
		--pos = flr(tickl / 4) --
		--printh(arr_basket_show)
		printh(pos)
		ifruit = arr_basket_show[pos]

		beatpos = 1
		for i = 1, pos - 1 do
			f = currentfruits[arr_basket_show[i]]
			beatpos = beatpos + #f.syllables
		end

		beat = arr_basket_beats[beatpos]
		f = currentfruits[ifruit]
		bubblefruit(f, pos, beat)
	end


	if music_state == mstate.response then
		for i = #arr_basket_beats_results + 1, #arr_basket_beats do
			b = arr_basket_beats[i]
			diff = tickf % 16 - b

			if diff > 7 then
				arr_basket_beats_results[i] = false
				printh("bigmiss..")
			end
		end
	end	

	-- scratch!
	if anybtn then
		tscratch = 0
		tcatanim = 0

		nextbeat = #arr_basket_beats_results + 1

		if nextbeat <= #arr_basket_beats_show then

			b = arr_basket_beats_show[nextbeat]
			tickfl = tickf % 16
			diff = b - tickfl

			if diff < tickfl and abs(diff) > 8 then
				b = b + 16
				-- printh("dddd")
			end

			diff = b - tickfl

			printh("b " .. b)
			
			
			closestfruit = 1
			for i = 1, #bubblefruits do
				f1 = bubblefruits[i]
				f2 = bubblefruits[closestfruit]
				if abs(f1.beat - b) < abs(f2.beat - b) then
					closestfruit = i
				end
			end

			absdiff = abs(diff)

			if absdiff < 1 then -- hit correctly
				printh("hit! " .. diff)
				arr_basket_beats_results[nextbeat] = true
				bubblefruits[closestfruit].tglow = 0.1

			elseif absdiff < 7 then
				printh("smallmiss.." .. diff)
				arr_basket_beats_results[nextbeat] = false
			else
				printh("nothing.." .. diff)
			end
		end
	

		
		-- for i = 1, #bubblefruits do
		-- 	f = bubblefruits[i]
		-- 	if abs(yhitcenter - f.y) < yhitwindow then
		-- 		printh("hit")
		-- 	end	
		-- end	
		
	end

	if tscratch >= 0 then
		tscratch += 1/60 * 20
		if tscratch > 3 then tscratch = -1 end
	end

	if tcatanim >= 0 then
		tcatanim += 1/60 * 30
		if tcatanim > 4 then tcatanim = -1 end
	end

	-- update fruits position on conveyor belt
	for i = 1, #currfruits do
		f = currfruits[i]
		f.x = f.x - 0.5

		if f.x < 69 then
			del(currfruits, f)
			break
		end	
	end	

	-- update fruits position on bubbles
	updatefruits()
end


function _draw()

	-- clean screen
	cls(4)

	-- draw the backstage
	map(0, 0, 0, 0, 16, 16)

	-- draw board legs
	xboard = 68
	yboard = 110

	for i = 0, 3 do
		line(
			xboard + 7 + i, 
			yboard + 0, 
			xboard + 0 + i, 
			yboard + 18, 
			9)

		line(
			xboard + 18 + i, 
			yboard + 0, 
			xboard + 18 + i, 
			yboard + 18, 
			9)

		line(
			xboard + 29 + i, 
			yboard + 0, 
			xboard + 36 + i, 
			yboard + 18, 
			9)
	end

	-- draw board marker holder
	rectfill(
		xboard + 12, 
		yboard - 1, 
		xboard + 27, 
		yboard + 1, 
		6)


	bstat = stat(50)

	-- draw fruit texts
	sylcount = 0
	for i = 1, #arr_basket_show do
		ifruit = arr_basket_show[i]
		f = currentfruits[ifruit]

		sylaudio = 0
		for j = 1, #arr_basket_beats_show do
			if bstat + 1 >= arr_basket_beats_show[j] then
				sylaudio = j
			end	
		end




		word_results = {}
		
		-- render text on blackboard
		for j = 1, #f.notes do
			if calltime then -- call time

				result_int = sylaudio - sylcount >= j and 2 or 0
				add(word_results, result_int)

			else -- response time
				
				results_index = sylcount + j 
				if results_index <= #arr_basket_beats_results then
					result = arr_basket_beats_results[results_index]
					result_int = result == true and 2 or 1
					add(word_results, result_int)
				else
					add(word_results, 0)
				end
			end
		end	

		textfruit(f, i - 1, word_results)
		sylcount = sylcount + #f.notes
	end

	-- scratch
	if tscratch >= 0 then
		sprnum = flr(tscratch)
		sprind = 149 + sprnum * 2
		xscratch = 13 + (closestfruit - 1) * bubbles_xoffset
		spr(sprind, xscratch, 58, 2, 3)
	end

	-- scratch cat anim
	altrender(true)
	catx = 3
	if tcatanim >= 0 then
		sprnum = flr(tcatanim)
		sprind = 112 + sprnum * 3
		spr(sprind, catx + sprnum / 1.5, 64, 3, 2)
	else
		spr(32, catx, 64, 2, 2)	
	end	
	altrender(false)

	-- frog
	altrender(true)
	openmouth = calltime == true and tick % 4 == 0 
	sprfrog = openmouth == true and 146 or 144
	spr(sprfrog, 8 * 8, 3 * 8, 2, 2)
	altrender(false)

	-- bowl back
	xbowl = 10
	ybowl = 128 - 2 * 8
	ovalfill(xbowl + 2, ybowl, xbowl + 6 * 8 - 2, ybowl + 4, 1)

	-- fruits
	drawfruits()
	
	-- bowl front
	spr(80, xbowl, ybowl, 6, 2)

	-- rabbit
	altrender(true)
	yrabbit = 100
	if tickl % 4 < 1 then yrabbit = yrabbit + 1 end
	spr(199, 100, yrabbit, 4,4)
	altrender(false)

	-- bubble
	-- t = (sin(time()) + 1) * 5
	-- r = t
	-- drawbubble(25, 25, r)


	-- result squares
	
	for i = 1, #arr_basket_beats_show do
		b = arr_basket_beats_show[i]
		x = 52 + i * 5
		y = 67
		w = 3
		h = 3
		color = 7

		if music_state == mstate.call or i > #arr_basket_beats_results then
			rect(x, y, x + w, y + h, 7)
		else 
			rs = arr_basket_beats_results[i]
			color = rs == true and 11 or 8
			rectfill(x, y, x + w, y + h, color)
		end
	end
	



	-- debug
	-- printdebug()

	-- line(0, yhitcenter - yhitwindow, 128, yhitcenter - yhitwindow, 8)
	linecolor = 7
	rs = arr_basket_beats_results
	if #rs > 0 then
		lastresult = rs[#rs] 
		linecolor = lastresult == true and 11 or 8
	end

	-- line(0, yhitcenter, 128, yhitcenter, linecolor)
	-- line(0, yhitcenter + yhitwindow, 128, yhitcenter + yhitwindow, 8)


	
end

function drawbubble(x, y, r)
	
	circ(x, y, r, 12) -- inner circle
	circ(x, y, r + 1, 7) -- outer circle

	-- specular highlight
	sx = x - r * 0.5
	sy = y - r * 0.5
	rectfill(sx, sy, sx + 1, sy + 1, 7)
end

function altrender(set)
	palt(2, set)
	palt(0, not set)
end

function printdebug()

	-- reset to color white
	print("", 0,0, 7)

	-- print("fps ".. stat(7))
	
	
	-- print("arr_basket " .. arr_basket)
	-- print("")
	-- print("blackboard:")

	-- sss = ""
	-- for i = 1, #arr_basket_beats do
	-- 	sss = sss .. "\n" .. arr_basket_beats[i]	
	-- end
	-- print(sss, 0,10)


	print("stat(50) " .. stat(50), 0, 0)
	print("stat(54) " .. stat(54))
	print("state "..music_state)
	print("side prebar "..music_side_prebar)	
	print("side  "..music_side_show)	
	print("round "..round)
	print("tick " .. tick)
	print("tickf ".. tickf)
	print("sylaudio ".. sylaudio)

end

function bringfruit(fruit)
	currfruits[#currfruits + 1] = {
		x = 120,
		y = 32,
		data = fruit
	}
end

function bubblefruit(fruit, position, beat)
	bubblefruits[#bubblefruits + 1] = {
		x0 = 16 + position * bubbles_xoffset, 
		y0 = ybubble0 + (position % 2) * 2 , -- initial ypos
		x = 16 + position * bubbles_xoffset,
		y = ybubble0 + (position % 2) * 2,
		data = fruit,
		position = position,
		sptick = tick + 16 - 4,
		tick = tick + 16,
		beat = beat,
		pstart = 0,
		toffset = 0,
		tglow = 0
	}
end



function updatefruits()
	local xfrog = 66
	local yfrog = 32

	for i = 1, #bubblefruits do

		f = bubblefruits[i]

		-- initial animation
		if f.pstart < 1 then
			f.pstart = f.pstart + 3/60
			f.x = lerpoutbacksoft(xfrog, f.x0, f.pstart)
			f.y = lerp(yfrog, f.y0, f.pstart)
		end


		-- falling animation
		if(tick >= f.sptick) then
			f.toffset = f.toffset + 1/60
			f.y = f.y0 + f.toffset * f.toffset * 50 + f.toffset * 25
		end

		-- glow animation when hit
		if f.tglow > 0 then
			f.tglow = f.tglow - 1/60
		else
			f.tglow = 0
		end
	end
end	

function drawfruits()

	-- conveyor belt fruit
	for i = 1, #currfruits do
		f = currfruits[i]
		data = currfruits[i].data
		y = f.y - (data.size.y - 1) * 8 + data.bottom
		spr(data.sprite, f.x, y, data.size.x, data.size.y)
	end

	for i = 1, #bubblefruits do
		f = bubblefruits[i]
		data = bubblefruits[i].data
		x = f.x - data.size.x * 4
		y = f.y - data.size.y * 4


		if f.tglow > 0 then
			for c = 1, 15 do
				pal(c, 7)
			end
		end --
		spr(data.sprite, x, y, data.size.x, data.size.y)
		pal()

		-- bubble
		
		tilesize = data.size.x == 1 and 2 or 3


		if f.pstart < 1 then
			rbubble = lerpoutback(1, data.size.x * 6, f.pstart)
			drawbubble(f.x, f.y, rbubble)
		elseif f.toffset < 0.15 then
			bubblespr = data.size.x == 1 and 37 or 39

			-- explosion anims
			if f.toffset > 0.11 then 
				bubblespr = 92
				tilesize = 4
			elseif f.toffset > 0.08 then
				bubblespr = 44
				tilesize = 3
			end

			tiledifx = tilesize - data.size.x
			tiledify = tilesize - data.size.y
			spr(
				bubblespr, 
				f.x - tiledifx * 4 - data.size.x * 4, 
				f.y - tiledify * 4 - data.size.y * 4, 
				tilesize, 
				tilesize
			)
		end

		-- debug
		-- print(f.beat, f.x, f.y, 7)
	end	
end

function textfruit(ff, row, rs)

	arr = ff.syllables

	bbcenterx = 88
	bbtopy = 77 + row * 8

	-- get total string length
	strlen = 0
	for i = 1, #arr do
		strlen = strlen + #arr[i]
	end
	strlen = strlen + (#arr - 1)


	-- print each syllable
	x = bbcenterx - strlen * 4 / 2
	for i = 1, #arr do
		syllable = arr[i]
		if(i ~= #arr) then
			syllable = syllable .. "-"
		end	

		-- determine syllable color
		textcolor = 7
		result = rs[i]
		if result == 1 then -- miss
			textcolor = 8
		elseif result == 2 then -- hit
			textcolor = 11
		end


		-- print syllable
		print(syllable, 
		x, bbtopy, textcolor)

		-- move text cursor forward
		x = x + (#arr[i] + 1) * 4
	end

end



-->8
--chef music engine


mstate = 
{
	intro = "intro",
	call = "call",
	response = "response"
}

mside = 
{
	a = "a",
	b = "b"
}

music_state = mstate.intro

current_level  = 0 -- increase every 4 rounds
prev_level = 0
round = 0 --rounds increase every call phase

arr_basket = {}
arr_basket_datum = {} --the motif of the round, set every 4 baskets
arr_basket_show = {} -- string of 

arr_basket_beats = {} -- linear list of beat numbers, {0,1,4..15}
arr_basket_beats_show = {} --refresh on bar
arr_basket_beats_results = {} -- results for each hit


flag_refreshed_response = true
flag_refreshed_call = true
ticks_in_beat = 4
ticks_in_pattern = 16

-- rhythms of a-side and b-side
startbeats_a = {0,4,8,12}
startbeats_b = {0,6,12}

intro_patterns = 1 -- 4 beats of drum intro

function update_conductor()
	--54 is music pattern: 0 is intro, odd numbers are calls and even are responses
	-- 0 [12] [34] [56] [78] || [9 10] [11 12] ..
	--calltime = (stat(54) - intro_patterns)%2 == 0

	local sm = stat(54)-1

	--update state and side
	if (stat(54) == 0) then
		music_state = mstate.intro
		music_side_prebar = mside.a
		music_side_show = mside.a
	else
		--loop call_a,response_a,call_b,response_b
		-- [12] [34] [56] [78] // [9 10] [11 12] ..
		 if (stat(54) % 2 == 1) then music_state = mstate.call
		else music_state = mstate.response end

		-- 1 to 8 is a, 9 to 15 is b, etc. need sm to do that

		-- of the next bar, so 0-7 = side a , 8-15 = side b
		-- \8 gives 0-0, 1-1!
		if  (stat(54)\8 % 2 == 0) then music_side_prebar = mside.a
		else music_side_prebar = mside.b end

		-- for actual current bar, so 1-8 = side a, 9-16 = side b
		if  ((stat(54)-1)\8 % 2 == 0) then music_side_show = mside.a
		else music_side_show = mside.b end
	end

	calltime = music_state == mstate.call

	tickl = stat(50) //tick but looping. use first channel as reference pos (cause it doesnt loop)
	beatnumber = tickl\4

	--update the 'on new bar' equivalents from the prebar variables for showing
	if(tickl == 0) then
		arr_basket_beats_show = {}

		for i = 1, #arr_basket_beats do
			arr_basket_beats_show[i] = arr_basket_beats[i]
		end

		arr_basket_show = {}
		for i = 1, #arr_basket do
			arr_basket_show[i] = arr_basket[i]
		end
	end

	-- if in first half of call pattern, refresh response flag
	if (tickl < ticks_in_pattern/2 and calltime == true) then
	flag_refreshed_response = true
	end

	-- if second half of call pattern, put notes in response pattern
	if (tickl > ticks_in_pattern/2 and calltime == true and flag_refreshed_call == true) then
	flag_refreshed_call = false
	arr_basket_beats_results = {}
	put_basketbeats_in_pattern(5,4)
	end

	-- if in a second half of a response pattern or intro, generate new beat and put in call pattern
	if (tickl > ticks_in_pattern/2 and flag_refreshed_response == true and
	(music_state == mstate.intro or  music_state == mstate.response)) then
		round+=1
		--check if we're in for a new level
		level = (round-1)\8+1 --round 5 is level 2 etc
		local is_new_level = false

		local is_new_basket = stat(54) % 8 == 0 --[12][34][56][78] if we are on the 8
		local new_basket_size = 4

		if (is_new_basket) then printh("new basket!") end

		if (music_side_prebar == mside.a) then
		new_basket_size = #startbeats_a
		else
		 new_basket_size = #startbeats_b
		 end

		if level ~= prev_level then
			printh("new level!")
			is_new_level = true
			prev_level = level
			newfruit = add_new_fruit(level)

			--add 'rest' in for level 3
			if (level == 3) then add(currentfruits,fruits.rest)
		end
		end

		flag_refreshed_response = false
		flag_refreshed_call = true

		--make sure new level's basket has at least one of the new fruit
		if (is_new_level) then 
			generate_fruit_basket(newfruit,true,new_basket_size)
			else
			generate_fruit_basket(newfruit,is_new_basket,new_basket_size)
		end

		generate_beats_from_basket()
		put_basketbeats_in_pattern(5,3)
	end
end


function has_number_at_least(array,number)
	local flag=false
	for i=1,#array do
		if (array[i] >= number) then flag = true end
	end
	return flag
end

function add_new_fruit(level)
printh("level "..level)
--printh("fruitlevel "..#fruitlevels[level])
	local n = rnd(#fruitlevels[level])\1+1
	--local n = rnd(2)\1+1
	printh("n is " .. n)
	add(currentfruits,fruitlevels[level][n])
	return fruitlevels[level][n]
end

--warning: _basketsize wont be accurate if not is_new_basket
function generate_fruit_basket(forcedfruit, _is_new_basket, _basketsize) --give 3/4 numbers in a string like "1324" (1-index)

	print("----")
	local reroll = true
	local fruit_chosen_id
	local fruit_chosen

	while reroll == true do
		reroll = false
		arr_basket = {}
		local lastfruit_id = -1 //previous fruit id
		local rest_num = 0

		have_forced_fruit = false


		--if not new basket, just alter old basket
		local loopsize
		if _is_new_basket then loopsize = _basketsize
		else
		 loopsize = #arr_basket_datum
		end



		arr_basket = {}

		for i=1,loopsize do

			--fruit_chosen_id = rnd(#currentfruits)\1+1
			--fruit_chosen = currentfruits[fruit_chosen_id]

			--if altering and not new basket, 1/2 probability dont touch it
			if (rnd(1) < 0.3 or _is_new_basket) then
				fruit_chosen_id = rnd(#currentfruits)\1+1
				fruit_chosen = currentfruits[fruit_chosen_id]
			else
			 	fruit_chosen_id = arr_basket_datum[i]
				fruit_chosen = currentfruits[fruit_chosen_id]
			end
			if (#fruit_chosen.notes > 0) then
			if (fruit_chosen.notes[1] < 1) then
				--the papaya exception, avoid overlaps
				if (i == 1) then reroll = true
					else
					--would rather alter the previous id to not reduce probability of papaya but nvm
					if (has_number_at_least(currentfruits[lastfruit_id].notes,4)) then
						reroll = true
					end
				end
			end
			end

			if (fruit_chosen == fruits.rest) then rest_num += 1 end

			if (fruit_chosen == forcedfruit) then have_forced_fruit = true end

			add(arr_basket, fruit_chosen_id)
			lastfruit_id = fruit_chosen_id
			--print (allfruits[fruit_chosen_id].name)
		end

		--reroll if the forced fruit was not present
		if (forcedfruit ~= nil and have_forced_fruit == false)
		then reroll = true end

		--reroll if exactly the same as datum
		equal_arrays = true
		if #arr_basket == #arr_basket_datum then
			for j = 1, #arr_basket do
				if arr_basket[j] ~= arr_basket_datum[j] then
					equal_arrays = false
				end	
			end
		else
			equal_arrays = false
		end

		if (_is_new_basket == false and equal_arrays)
		then reroll = true end

		--reroll if there's a rest in side b
		if (music_side_prebar == mside.b and rest_num > 0) then reroll = true end

		-- reroll if more than 1 rest
		if (rest_num > 1) then reroll = true 
		elseif rest_num == 1 then
			printh("added rest")
		end
	end

	if (_is_new_basket) then
		arr_basket_datum = {}
		for j = 1, #arr_basket do
			arr_basket_datum[j] = arr_basket[j]
		end
	end

end

function generate_beats_from_basket() --arr_basket unboxing to give array of beats
	arr_basket_beats = {}

	for i = 1,#arr_basket do -- cause sub is 1-indexed!
		--printh("str basket is " .. arr_basket)
		local num = arr_basket[i]
		--now add each one to the end
		for j=1,#currentfruits[num].notes do

		if (music_side_prebar == mside.a) then
		bbeat = currentfruits[num].notes[j]+startbeats_a[i]
		else
		bbeat = currentfruits[num].notes[j]+startbeats_b[i]
		end

			--bbeat = currentfruits[num].notes[j]+4*(i-1)
			add (arr_basket_beats, bbeat)
		end
	end

	-- for i=1,#arr_basket_beats do
	-- print (arr_basket_beats[i])
	-- end
end

function put_basketbeats_in_pattern(vol,pattern_num)

	notesstr = ""

	--mute all notes
	for i=1,16 do
		notee =  make_note(2, 2, 0, 0)
		set_note(pattern_num, i, notee)
	end

	--turn on in pattern
	for i=1,#arr_basket_beats do
		--pitch,instr,vol,fx
		--notee =  make_note(rnd(32), 2, vol, 5)
		notee =  make_note(6 + pattern_num*5, 2, vol, 5)
		--sfx,time,note
		set_note(pattern_num, arr_basket_beats[i], notee)
		--cstore()
	end
end



-->8
--eruonna's funcs:
function make_note(pitch, instr, vol, effect)
  return { pitch + 64*(instr%4) , 16*effect + 2*vol + flr(instr/4) } -- flr may be redundant when this is poke'd into memory
end

function set_note(sfx, time, note)
  local addr = 0x3200 + 68*sfx + 2*(time-1)
  poke(addr, note[1])
  poke(addr+1, note[2])
  notesstr = notesstr .. "\n" .. sfx .. "time: " .. time .. " -> " .. note[1] .. "/" .. note[2]
end

function set_speed(sfx, speed)
  poke(0x3200 + 68*sfx + 65, speed)
end

function get_speed(sfx)
  return peek(0x3200 + 68*sfx + 65)
end

-->8
-- utils

function lerp(a,b,t)
	return (1-t)*a + t*b;
end

function lerpquad(a,b,t)
	t = 1-(1-t)*(1-t)
	return (1-t)*a + t*b;
end

function lerpcubic(a,b,t)
	t = 1-(1-t)*(1-t)*(1-t)
	return (1-t)*a + t*b;
end

function lerpoutbacksoft(a,b,t)
	t = (1 - t * 1.15)
	t = 1.02 * (1 - t * t)
	return (1-t)*a + t*b;
end

function lerpoutback(a,b,t)
	t = (1 - t * 1.333)
	t = 1.125 * (1 - t * t)
	return (1-t)*a + t*b;
end


-->8
-- constants


fruits = 
{
	egg = {
		name = "egg",
		syllables = {"egg"},
		size = {x = 1, y = 1},
		sprite = 1,
		slicedsprite = 1,
		bottom = 0,
		notes = {1},
		maincolor = 15
	},
	grape = {
		name = "grape",
		syllables = {"grape"},
		size = {x = 1, y = 1},
		sprite = 6,
		slicedsprite = 22,
		bottom = 0,
		notes = {1},
		maincolor = 13
	},
	apple = {
		name = "apple",
		syllables = {"ap", "ple"},
		size = {x = 1, y = 1},
		sprite = 11,
		slicedsprite = 86,
		bottom = 0,
		notes = {1,3},
		maincolor = 8
	},
	orange = {
		name = "orange",
		syllables = {"o", "range"},
		size = {x = 1, y = 1},
		sprite = 59,
		slicedsprite = 74,
		bottom = 0,
		notes = {1,2},
		maincolor = 9
	},
	banana = {
		name = "banana",
		syllables = {"ba", "na", "na"},
		size = {x = 2, y = 1},
		sprite = 16,
		bottom = 0,
		notes = {0,1,3},
		maincolor = 10
	},
	papaya = {
		name = "papaya",
		syllables = {"pa", "pa", "ya"},
		size = {x = 2, y = 1},
		sprite = 7,
		slicedsprite = 25,
		bottom = 0,
		notes = {0,1,3},
		maincolor = 7
	},
	coconut = {
		name = "coconut",
		syllables = {"co", "co", "nut"},
		size = {x = 2, y = 1},
		sprite = 7,
		slicedsprite = 25,
		bottom = 0,
		notes = {0,2,3},
		maincolor = 7
	},
	watermelon = {
		name = "watermelon",
		syllables = {"wa", "ter", "me", "lon"},
		size = {x = 2, y = 2},
		sprite = 4,
		slicedsprite = 58,
		bottom = 2,
		notes = {1,2,3,4},
		maincolor = 3
	},
	chirimoya = {
		name = "chirimoya",
		syllables = {"chi", "ri", "mo", "ya"},
		size = {x = 1, y = 1},
		sprite = 23,
		slicedsprite = 24, 
		bottom = 0,
		notes = {1,2,3,4},
		maincolor = 3
	},
	pineapple = {
		name = "pineapple",
		syllables = {"pine", "ap", "ple"},
		size = {x = 1, y = 1},
		sprite = 23, --todo
		slicedsprite = 24, --todo
		bottom = 0,
		notes = {1,3,4},
		maincolor = 3
	},
	rest = {
		name = "rest",
		syllables = {".."},
		size = {x = 1, y = 1},
		sprite = 23, --todo
		bottom = 0,
		notes = {},
		maincolor = 0
	},
}

currentfruits = {fruits.grape} --starting fruits
fruitlevels = --repeated is to alter probabilities
{
	{fruits.orange,fruits.apple},
	{fruits.papaya,fruits.banana},
	{fruits.pineapple, fruits.coconut},
	{fruits.watermelon,fruits.watermelon,fruits.chirimoya}
}

ybubble0 = 20
yhitcenter = 72
yhitwindow = 10 -- plus/minus
ticklength = 0.1333 -- constant


__gfx__
00000000000ff0009999999999999999000000000000000000000000000aaaaaaaa00000000aaaaaaaa000000000300000000000000000000000000000000000
0000000000f7ff00999999999999999900000333333000000001000000a7aaaaaaa9000000a99999999a00000003300000000000000000000000000000000000
0000000000f7ff009999999999999999000bbb3bb3b330000001100009aaaaaaaaaa99000a9999999999aa000883880000000000000000000000000000000000
000000000ffffff0999999999999999900b33333333bb3000001010099aaaaaaaaaaa922a990a010100999008988888000000000000000000000000000000000
000000000ffffff000099900000000000b33333333333bb000100100b9aaa9aaaaa99920b9aa010101aa99a08988888000000000000000000000000000000000
000000000ffffff00099999000099900b3bbbbbb3b3bb33b07dd0100bb999aaa99999900b99090109999aa008888888000000000000000000000000000000000
000000000ffffff00999999900999990bb33333333333bbb06dd00100b999999999900000b99999999aa00008888888000000000000000000000000000000000
0000000000ffff000999999909999999bbbb3b33333333330555000000bbbb9bb900000000bbbbaaaa0000000888880000000000000000000000000000000000
0000000000000000099999990999999933333333333bb3bb00000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000099999009999999b33333333333333b00000000033333300066660000000000000000000000000000000000000000000000000000000000
00500000000000d000099900009999900bbb33333333bbb000000000335333330066160000000000000000000000000000000000000000000000000000000000
005a000000000ad000000000000999000033bb3b33bb33000000000035333353061666600099a000000000000000000000000000000000000000000000000000
0099aaaaaaaaa990000000000000000000033333333330000000000033353333366661630a9990101010a9000000000000000000000000000000000000000000
00999aaaaaaa9990000000000000000000000bb33330000007dd000033333533361666630ba99901010a99000000000000000000000000000000000000000000
00099999999999000000000000000000000000000000000006dd000003353330566666630bba999999999a000000000000000000000000000000000000000000
000099999999900000000000000000000000000000000000055500000033330003355330000bbaaaaa9aa0000000000000000000000000000000000000000000
22222222222222220999999999999999999999900000000000000000000000000000000000000000000000000000000007000000000000000000007000000000
22222222222222229999999999999999999999990000007777000000000000000000000000000000000000000000000000700000700700070000070000000000
222222f222f22222993333333333333333333399000077cccc7700000000000007777770000000003f888888888888fb00070000070770700000700000000000
222222ff22ff22229933333333333333333333990007cc0000cc7000000000077cccccc770000000bf818881881818fb00007700007777000077000000000000
222222fffffff222993333333333333333333399007c00000000c7000000007cc000000cc70000000bf8818888888fb000007770777777770777000000000000
22222fffffffff22993333333333333333333399007c07700000c700000007c0000000000c700000003ff888818ff30000000777777777777770000000000000
22222ffff0ff0ff299333333333333333333339907c0077000000c7000007c000000000000c7000000033ffffff3300000000077777777777700000000000000
22222ffff0ff0ff299333333333333333333339907c0000000000c700007c00770000000000c700000000bb33330000000000777777777777770000000000000
222f88fffff5fff299333333333333333333339907c0000000000c700007c00770000000000c7000000000000005000007007777777777777777007000000000
22fff88fff5f5f2299333333333333333333339907c0000000000c70007c0000000000000000c700000080000995999000707777777777777777070000000000
2fffff88fffff222993333333333333333333399007c00000000c700007c0000000000000000c7000008880099f9999900077777777777777777700000000000
2fffffff88888222993333333333333333333399007c00000000c700007c0000000000000000c700000881009f999f9900777777777777777777777000000000
2ffff5fffaa822229933333333333333333333990007cc0000cc7000007c0000000000000000c700008188809999999907777777777777777777770000000000
2ffff5ffffff2222993333333333333333333399000077cccc770000007c0000000000000000c700008888809999999900077777777777777777700000000000
2fff5ffff5ff22229933333333333333333333990000007777000000007c0000000000000000c70003fffff39999999900707777777777777777070000000000
22ff5fff5ff2222299333333333333333333339900000000000000000007c00000000000000c70000033b3b00999999007007777777777777777007000000000
000000000000000099333333333333333333339900000000000000000007c00000000000000c7000000000000005000000000777777777777770000000000000
0000000000000000993333333333333333333399000000000000000000007c000000000000c700000000000000affa0000000077777777777700000000000000
00000000000000009933333333333333333333990000000000000000000007c0000000000c700000000000000a99f9a000000777777777777770000000000000
000000000000000099333333333333333333339900000000000000000000007cc000000cc700000079977999a9f97f9a00007770777777770777000000000000
00000000000000009933333333333333333333990000000000000000000000077cccccc770000000a9799979f997799f00007700007777000077000000000000
000000000000000099333333333333333333339900000000000000000000000007777770000000000799999af99f9f9f00070000070770700000700000000000
0000000000000000999999999999999999999990000000000000000000000000000000000000000000aaaaa00ff999a000700000700070070000070000000000
000000000000000009999999999999999999999000000000000000000000000000000000000000000000000000affa0007000000000000000000007000000000
00000000000000000000000000000000000000000000000000000000000003000000300000000000000050000000500000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000033000003300000000000099affa00affa99000700000000000070000000000000700
0000000000000000000000000000000000000000000000000000000008ff3ff00ff3ff800000000099af99faaf99fa9900070000077770070000000000007000
0077cccc00000000000000000000000000000000ccccc110000000008ff666ffff666ff8000000009f99f97ff79f99f900007000700007070000000000070000
0077cccccccccc0000000000000000000cccccccccccc110000000008ff2626ff6262ff8000000009f99779ff97799f900000700700707077000700000700000
0077ccccccccccccccccccccccccccccccccccccccccc110fffffff08ff4646ff6464ff8000000009a9f9f9ff9f9f9a900000077700077077007000077000000
0077ccccccccccccccccccccccccccccccccccccccccc1108fffff808ffffffffffffff80000000099af99faaf99fa9900000077700007777077000777000000
00077ccccccccccccccccccccccccccccccccccccccc11000888880008ff6ff00ff6ff8000000000099aafa00afaa99000000007777777000770077770000000
44477ccccccccccccccccccccccccccccccccccccccc114400000000000000000000000000000000000000000000000000000000777000000000777700000000
44447ccccccccccccccccccccccccccccccccccccccc144400000000000000000000000000000000000000000000000000000000070000000000777700000000
444477ccccccccccccccccccccccccccccccccccccc1144400000000000000000000000000000000000000000000000000000000700000000007000770007000
4444477ccccccccccccccccccccccccccccccccccc11444400000000000000000000000000000000000000000000000000000007000000000007007070070000
44444477ccccccccccccccccccccccccccccccccc114444400000000000000000000000000000000000000000000000000000777000000000007000070000000
444444477cccccccccccccccccccccccccccccc11144444400000000000000000000000000000000000000000000000000000070000000000007000070000000
444444444cccccccccccccccccccccccccccc1114444444400000000000000000000000000000000000000000000000000007777000000000000777700077000
4444444444444cccccccccccccccccccccc114444444444400000000000000000000000000000000000000000000000000777770700000000000000000077770
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222200070770700000000000000000070000
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222200070000700000000000000000700000
222222f222f2222222222222222222f222f2222222222222222222f222f2222222222222222222f222f222222222222200070077700000000000000007000000
222222ff22ff222222222222222222ff22ff222222222222222222ff22ff222222222222222222ff22ff22222222222200007777000000000000000000700000
222222fffffff22222222222222222fffffff22222222222222222fffffff22222222222222222fffffff2222222222200000000000000000000000007000000
22222fffffffff222222222222222fffffffff222222222222222fffffffff222222222222222fffffffff222222222200000000000000000000000007000000
22222ffff0ff0ff22222222222222ffffffffff22fff222222222ffffffffff2222f222222222ffff0ff0ff22222222200000000000000000000007070700000
22222ffff0ff0ff22222222222222ffff0ff0ff25fff222222222ffff0ff0ff22f2f222222222ffff0ff0ff22222222200000000700000000000077700000000
222f88fffff5fff222222222222f88fffff5fff5fff22222222f88fffff5fff20f0f2222222f88fffff5fff22222222200000007770000000000007770000000
22fff88fff5f5ff22222222222fff88fff5f5ff5ff22222222fff88fff5f5ff2f0f2222222fff88fff5f5ff22222222200000077700007077770000777000000
2fffff88ffffff82222222222fffff88ffffff85222222222fffff88ffffff82f0f222222fffff88ffffff822222222200000077000070077707000077000000
2fffffff8888885f222222222fffffff88888852222222222fffffff8888885f0f2222222fffffff888888522222222200000700000000077000000000700000
2ffff5fffaa855ff222222222ffff5fffaa82222222222222ffff5fffaa855ffff2222222ffff5fffaa855ff2222222200007000000000007000000000070000
2ffff5ffff222fff222222222ffff5ffff222222222222222ffff5ffff222ffff22222222ffff5ffff22ffff2222222200070000000000007000000000007000
2fff555fff222ff2222222222fff555fff222222222222222fff555fff222ffff22222222fff555fff22ffff2222222200700000000000000000000000000700
22ff552ffff222222222222222ff552ffff222222222222222ff552ffff222ff2222222222ff552ffff22ff22222222200000000000000000000000000000000
22222222222222222222222222222222000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2222222222222222222222222222222200000000000000000000000000000000000000000000000000000000000c0000000000000000c0000000000000000000
22222222222222222222222222222222000000000000000000000000000000000000000000000000000000000000c000000077770000c00000000000000000c0
22222222222222222222bb2bbb2222220000000000000c00000000000000000000000000000000000000000000000c000007c000700000000000000000000c00
222bb2bbb22222222222bbbbbb22222200000000cc0000c000000000000000000000000000000000000000000000000000070c7070000000000c00000000c000
222bbbbbbb222222222b0bb0bbb222220000000000cc00cc000000000000000000000000000000000000000000000000000700007000000000c0000000000000
22b0bb0bbbb2222222bb0bb0bbbb999200000000000cc00cc00c0000000000007000000000000000000000000000000000070000700000000000000000000000
2bb0bb0bbbb9922222bbbbbbbbbb9992000000000000cc0ccc00c000000000000700000000000000000000000000000000007777000000000000000000000000
2bbbbbbb3bba992222bb00bbbbbba922000000000000cccccc00cc00000000700770000000000000000000000000000000000000000000000000000000000000
2b333333bbbaa92222bb00bbbbbbaa220000000000000cccccc0ccc0000000070077070000000000000000000000000000000000000000000000000000000000
22bbbbbbbbaaaab2222bbbbbbbbaaaab0000000000000ccccccc0cc0000000077077707000000000000700000000000000000000000000000000000000000000
222bbbbbbaaaaab22222bbbbbbaaaaab00000000000000cccccc0cc0000000077777707000000000000070000000000000000000000000000000000000000000
2222aaaaaa3aabb222222aaaaaa3aabb00000000000000cccccc0cc00000000777777777000000000000700000000c000000000000000000000000000000c000
2222aaaaaa3abbb222222aaaaaa3abbb00000000000000cccccccccc00000000777777770000000000077070000000c0000000000000000000000077770c0000
2222bb3bbbb3bbb222222bb3bbbb3bbb000000000000000ccccccccc000000007777777700000000000770700000000000000000000000000000070000700000
22222bb3bbb3bb22222222bb3bbb3bbe000000000000000ccccccccc000000007777777700000000007707700000000000000000000000000000070070700000
00000000000000000000000000000000000000000000000ccccccccc000000007777777700000000007777700000000000000000000000000000070000700000
00000000000000000000000000000000000000000000000ccccccccc000000007777777000000000077777700000000000000000000000000000070000700000
00000000000000000000000000000000000000000000000cccccccc0000000077777777000000000777777000000000000000000000000000000007777000000
0000000000000000000000000000000000000000000000ccccc0ccc00000000777777700000000077077070007777000000000000000000000000000000000cc
0000000000000000000000000000000000000000000000cc0cc0c000000000770770700000077770077070007cc0070000000000000000000000000000000000
000000000000000000000000000000000000000000000cc0cc0c0000000077007707000000000777700700007007070000000000000000000000000000000000
00000000000000000000000000000000000000000000c00c00000000000000770000000000000000000000007000070000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000007000070000000000000000000000000000000000
22222222222222222222222222777222222222222222222222777222222222222222222222222222227772220777700000000000000000000000000000000000
22222222222222227772222222777222222222227772222222777222222222222222222277722222227772220000000000000000000000000000000000000000
22222222222222277777222227777722222222277777222227777722222222222222222777772222277777220000000000000000000000000000000000c00000
222222222222222777772222277777222222222777772222277777222222222222222227777722222777772200000000000000000000000000000000000c0000
222222222222222777772222277777222222222777772222277777222222222222222227777722222777772200000c0000000000000000000000000000000000
22222222222222277777722227777722222222277777722227777722222222222222222777777222277777220000000000000000000000000000000000000000
22222222222222277777722227777722222222277777722227777722222222222222222777777222277777220000000000000000000000000000000000000000
22222222222222227777722222777722262222227777722222777722222222222222222277777222227777220000000000000000000000000000000000000000
22222222222222227777772222777722262222227777772222777722222222222222222277777722227777220000000000000000000000000000000000000000
22222262222222222777772222777222262222222777772222777222222222622222222227777722227772220000000000000000000000000000000000000000
2222226222222222227777222777722226222222227777222777722222222262222222222277772227777222000000000000000000000000000c000000000000
222222622222222222277777277722222622222222277777277722222222226222222222222777772777222200000000000000c0000000000000c00000000000
22222262222222222225577755772222262222222227777777772222222222622222222222277777777722220000000000000c00000000000000000000000c00
2222222622222222275777777757722226222222275777775777722222222226222222222775577755777222000c00000000000000000c0000000000000000c0
222222262222222277777777777777222622222277757775777777222222222622222222775777777757772200c000000000000000000c000000000000000000
22222226222222277777777777777722226222277777575777777722222222262222222777777777777777220c00000000000000000000000000000000000000
22222226222222277777777777777722226222277755577555777722222222262222222777555775557777220000000000000000000000000000000000000000
22222222622222777755577555777772226252777770777707777775222222226222227777707777077777720000000000000000000000000000000000000000
22222222622222777777777777777772226225577770777707777752222222226222227777707777077777720000000000000000000000000000000000000000
22222222622255555577eee777555555226222755577eee77755557722222222622255555577eee7775555550000000000000000000000000000000000000000
222222226222277777577e77757777772262277777577e7775777777222222226222277777577e77757777770000000000000000000000000000000000000000
22222222262227555577777777555557226227755577777777555577222222222622275555777777775555570000000000000000000000000000000000000000
22222222262255777757757757777775226227577777757777777755222222222622557777777577777777750000000000000000000000000000000000000000
22222222262222777775575577777772276755777777575777777772222222222622227777775757777777720000000000000000000000000000000000000000
22222222267722277777777777777722277772277777000777777722222222222677222777777777777777220000000000000000000000000000000000000000
22222222277772227777777777777222277772227777000777777222222222222777722277777777777772220000000000000000000000000000000000000000
22222222277772222777777777772222227777222777000777772222222222222777722227777777777722220000000000000000000000000000000000000000
22222222227777222227777777777222222777722227777777777222222222222277772222277777777772220000000000000000000000000000000000000000
22222222222777722277777777777222222777772277777777777222222222222227777222777777777772220000000000000000000000000000000000000000
22222222222777777777777777777722222277777777777777777722222222222227777777777777777777220000000000000000000000000000000000000000
22222222222277777777777777777772222227777777777777777772222222222222777777777777777777720000000000000000000000000000000000000000
22222222222222777777777777777772222222777777777777777772222222222222227777777777777777720000000000000000000000000000000000000000
__map__
000000000000000000000000000000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000002030203020302030b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000012131213121312130b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000002223232323232324000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
020300000000003233333333333334000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
121300000000003233333333333334000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000003233333333333334000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000004243434343434344000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100001507015070123700f3700e3000c3000a30008300073000630005300033000430004300043000330003300033000330003300023000230002300013000230002300033000330003300033000230001300
010100001a150131500d1700616002150041300112000130001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
010100021827018470003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
011010000a2000e2001e2000220017200022000d20009200162000220018200022001920019200022000220002200000000000000000000000000000000000000000000000000000000000000000000000000000
011010000a2000e2001e2000220017200022000d20009200162000220018200022001920019200022000220002200000000000000000000000000000000000000000000000000000000000000000000000000000
011010003072535725377253a7253072535725377253a7253272535725377253a7253272635725377253a72535725377253a7253c72535726377253a7253c72533725377253a7263c7253a72537725357253a725
0110000018d7018d73376153761518f700020018d700c20018d70376053761518d7018f7024f402b6153762518d7018d732b6153761518f703761518d700c20018d70376253761518d7018f7024f403761537605
01010000293701a3601a35019630136300c6200030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
01100000183501835000000000001825018250000000000018450184500000000000183501835000000000001385013850138500000018f751385013850138501385313850138501880018f700cf701f85018f30
0110000018350000000000000000182500000000000000001845000000000000000018350000000c0000c0001385013850138501a80018f7513850138501385013853138501ff500cf3018f700cf701f85018f30
0110000013850138501835318325189751385013850138501385318d7318850353251897018d7324d72183251385013800183530c3251897513850138501f80013850138500c3531835318f7318f731f8501ff20
011410003072535725377253a7253072535725377253a7253272535725377253a7253272635725377253a72535725377253a7253c72535726377253a7253c72533725377253a7263c7253a72537725357253a725
bd1000003777500000377753c775377753c7750070500705007050070500705007050070500705377753c775377753c775377753c775377753c77500705007050070500705007050070500705007050000000000
011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0010865a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000100a20002200062000220017200022000d20009200162000220018200022001920019200022000220002200000000000000000000000000000000000000000000000000000000000000000000000000000
91100000241753c105301750c1053c1750c1052417530105301750c1052417530105301750c1053c1750c105241750c105301750c1053c1750c105241750c105301750c105241750c105301750c1053c1750c105
__music__
01 05434040
01 05034a52
00 05044a52
00 05034a52
00 05044a52
00 05034a52
00 05044a52
00 05034a52
00 05044a52
00 05034a52
00 05044a52
00 05034a52
00 05044a52
00 05034a52
00 05044a52
00 05034a52
02 05044a52

