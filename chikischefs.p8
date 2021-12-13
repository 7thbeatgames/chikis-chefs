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
statloops = -1
statprev =0
statcap = 16 --stat per pattern
spb = 16  -- stat per beat
bar = 0
calltime = false

notesstr = ""
bbeats = ""

newtick = false

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

	if flagg == true and newtick and calltime and #str_basket_show > 0 and music_state ~= mstate.intro then
		--z = ceil(rnd(#allfruits - 1))
		--pos = flr(tickl / 4) --
		printh(str_basket_show)
		printh(pos)
		ifruit = ord(str_basket_show, pos) - 48
		f = currentfruits[ifruit]
		bubblefruit(f, pos)
	end


	-- scratch!
	if btnp(5) then
		tscratch = 0
		tcatanim = 0
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
	for i = 1, #bubblefruits do
		f = bubblefruits[i]
		if(tick > f.sptick) then
			f.yoffset = f.yoffset + 1/60
		end

	end
end


function _draw()
	cls()

	-- clean screen
	cls(4)

	-- draw the backstage
	map(0, 0, 0, 0, 16, 16)

	bstat = stat(50)

	-- draw fruit texts
	sylcount = 0
	for i = 1, #str_basket_show do
		ifruit = ord(str_basket_show, i) - 48
		f = currentfruits[ifruit]

		sylaudio = 0
		for j = 1, #arr_basket_beats_show do
			if bstat + 1 >= arr_basket_beats_show[j] then
				sylaudio = j
			end	
		end	
		textfruit(f, i - 1, sylaudio - sylcount)
		sylcount = sylcount + #f.syllables
	end

	-- scratch
	if tscratch >= 0 then
		sprnum = flr(tscratch)
		sprind = 149 + sprnum * 2
		spr(sprind, 25, 58, 2, 3)
	end

	-- scratch cat anim
	catx = 3
	if tcatanim >= 0 then
		sprnum = flr(tcatanim)
		sprind = 112 + sprnum * 3
		spr(sprind, catx + sprnum / 1.5, 64, 3, 2)
	else
		spr(32, catx, 64, 2, 2)	
	end	

	drawfruits()

	-- print(z, 0,0)

	-- print("",0,0,7)
	--cls(0)

	-- print("fps ".. stat(7))
	
	-- print("tick " .. tick)
	-- print("str_basket " .. str_basket)
	-- print("")
	-- print("blackboard:")

	-- sss = ""
	-- for i = 1, #arr_basket_beats do
	-- 	sss = sss .. "\n" .. arr_basket_beats[i]	
	-- end
	-- print(sss, 0,10)

	yrabbit = 100
	if tickl % 4 < 1 then yrabbit = yrabbit + 1 end
	spr(199, 100, yrabbit, 4,4)
	print("stat(50) " .. stat(50), 0, 0)
	print("stat(54) " .. stat(54))
	print("state "..music_state)
	print("side prebar "..music_side_prebar)	
	print("side  "..music_side_show)	
	print("round "..round)
end

function bringfruit(fruit)
	currfruits[#currfruits + 1] = {
		x = 120,
		y = 32,
		data = fruit
	}
end

function bubblefruit(fruit, position)
	bubblefruits[#bubblefruits + 1] = {
		x = 20 + position * 8,
		y = 20,
		data = fruit,
		position = position,
		sptick = tick + 16 - 5,
		yoffset = 0
	}
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
		y = f.y - data.size.y * 4 + f.yoffset * f.yoffset * 170 + f.yoffset * 25

		spr(data.sprite, x, y, data.size.x, data.size.y)

		-- bubble
		if f.yoffset == 0 then
			bubblespr = data.size.x == 1 and 37 or 39
			tilesize = data.size.x == 1 and 2 or 3
			tiledifx = tilesize - data.size.x
			tiledify = tilesize - data.size.y
			spr(
				bubblespr, 
				x - tiledifx * 4, 
				y - tiledify * 4, 
				tilesize, 
				tilesize
			)
		end
	end	
end

-->8
-- s is syllable
function textfruit(ff, row, s)

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
		textcolor = (i < s + 1) and 10 or 7

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

str_basket = ""
str_basket_datum = "" --the motif of the round, set every 4 baskets
str_basket_show = "" -- string of 

arr_basket_beats = {} -- linear list of beat numbers, {0,1,4..15}
arr_basket_beats_show = {} --refresh on bar

flag_refreshed_response = true
flag_refreshed_call = true
ticks_in_beat = 4
ticks_in_pattern = 16

-- rhythms of a-side and b-side
startbeats_a = {0,4,8,12}
startbeats_b = {0,6,12}

intro_patterns = 1 -- 4 beats of drum intro

function update_conductor()
	--54 is music pattern
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
		str_basket_show = str_basket
	end

	-- if in first half of call pattern, refresh response flag
	if (tickl < ticks_in_pattern/2 and calltime == true) then
	flag_refreshed_response = true
	end

	-- if second half of call pattern, put notes in response pattern
	if (tickl > ticks_in_pattern/2 and calltime == true and flag_refreshed_call == true) then
	flag_refreshed_call = false
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
		str_basket = "" --tbh should change to array but nvm!
		local lastfruit_id = -1 //previous fruit id
		local rest_num = 0

		have_forced_fruit = false


		--if not new basket, just alter old basket
		local loopsize
		if _is_new_basket then loopsize = _basketsize
		else
		 loopsize = #str_basket_datum
		end



		str_basket = ""

		for i=1,loopsize do

			--fruit_chosen_id = rnd(#currentfruits)\1+1
			--fruit_chosen = currentfruits[fruit_chosen_id]

			--if altering and not new basket, 1/2 probability dont touch it
			if (rnd(1) < 0.3 or _is_new_basket)
			then
				fruit_chosen_id = rnd(#currentfruits)\1+1
				fruit_chosen = currentfruits[fruit_chosen_id]
			else
			 	fruit_chosen_id = ord(str_basket_datum,i)-48
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

			str_basket = str_basket..fruit_chosen_id
			lastfruit_id = fruit_chosen_id
			--print (allfruits[fruit_chosen_id].name)
		end

		--reroll if the forced fruit was not present
		if (forcedfruit ~= nil and have_forced_fruit == false)
		then reroll = true end

		--reroll if exactly the same as datum
		if (_is_new_basket == false and str_basket == str_basket_datum)
		then reroll = true end

		--reroll if there's a rest in a side b
		if (music_side_prebar == mside.b and rest_num > 0) then reroll = true end

		-- reroll if more than 1 rest
		if (rest_num > 1) then reroll = true end

	end

	if (_is_new_basket) then
	str_basket_datum = str_basket
	end

end

function generate_beats_from_basket() --str_basket unboxing to give array of beats
	arr_basket_beats = {}

	for i = 1,#str_basket do -- cause sub is 1-indexed!
		printh("str basket is " .. str_basket)
		local num = ord(str_basket,i)-48
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
-- constants


fruits = 
{
	egg = {
		name = "egg",
		syllables = {"egg"},
		size = {x = 1, y = 1},
		sprite = 1,
		bottom = 0,
		notes = {1}
	},
	grape = {
		name = "grape",
		syllables = {"grape"},
		size = {x = 1, y = 1},
		sprite = 6,
		bottom = 0,
		notes = {1}
	},
	apple = {
		name = "apple",
		syllables = {"ap", "ple"},
		size = {x = 1, y = 1},
		sprite = 11,
		bottom = 0,
		notes = {1,3}
	},
	orange = {
		name = "orange",
		syllables = {"o", "range"},
		size = {x = 1, y = 1},
		sprite = 59,
		bottom = 0,
		notes = {1,2}
	},
	banana = {
		name = "banana",
		syllables = {"ba", "na", "na"},
		size = {x = 2, y = 1},
		sprite = 16,
		bottom = 0,
		notes = {0,1,3}
	},
	papaya = {
		name = "papaya",
		syllables = {"pa", "pa", "ya"},
		size = {x = 2, y = 1},
		sprite = 7,
		bottom = 0,
		notes = {0,1,3}
	},
	coconut = {
		name = "coconut",
		syllables = {"co", "co", "nut"},
		size = {x = 2, y = 1},
		sprite = 7,
		bottom = 0,
		notes = {0,2,3}
	},
	watermelon = {
		name = "watermelon",
		syllables = {"wa", "ter", "me", "lon"},
		size = {x = 2, y = 2},
		sprite = 4,
		bottom = 2,
		notes = {1,2,3,4}
	},
	chirimoya = {
		name = "chirimoya",
		syllables = {"chi", "ri", "mo", "ya"},
		size = {x = 1, y = 1},
		sprite = 23,
		bottom = 0,
		notes = {1,2,3,4}
	},
	pineapple = {
		name = "pineapple",
		syllables = {"pine", "ap", "ple"},
		size = {x = 1, y = 1},
		sprite = 23, --todo
		bottom = 0,
		notes = {1,3,4}
	},
	rest = {
		name = "",
		syllables = {".."},
		size = {x = 1, y = 1},
		sprite = 23, --todo
		bottom = 0,
		notes = {}
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
00000000000000000999999999999999999999900000000000000000000000000000000000000000000000000000000007000000000000000000007000000000
00000000000000009999999999999999999999990000007777000000000000000000000000000000000000000000000000700000700700070000070000000000
000000f000f00000993333333333333333333399000077cccc7700000000000007777770000000003f888888888888fb00070000070770700000700000000000
000000ff00ff00009933333333333333333333990007cc0000cc7000000000077cccccc770000000bf818881881818fb00007700007777000077000000000000
000000fffffff000993333333333333333333399007c00000000c7000000007cc000000cc70000000bf8818888888fb000007770777777770777000000000000
00000fffffffff00993333333333333333333399007c07700000c700000007c0000000000c700000003ff888818ff30000000777777777777770000000000000
00000ffff0ff0ff099333333333333333333339907c0077000000c7000007c000000000000c7000000033ffffff3300000000077777777777700000000000000
00000ffff0ff0ff099333333333333333333339907c0000000000c700007c00770000000000c700000000bb33330000000000777777777777770000000000000
000f88fffff5fff099333333333333333333339907c0000000000c700007c00770000000000c7000000000000005000007007777777777777777007000000000
00fff88fff5f5f0099333333333333333333339907c0000000000c70007c0000000000000000c700000080000995999000707777777777777777070000000000
0fffff88fffff000993333333333333333333399007c00000000c700007c0000000000000000c7000008880099f9999900077777777777777777700000000000
0fffffff88888000993333333333333333333399007c00000000c700007c0000000000000000c700000881009f999f9900777777777777777777777000000000
0ffff5fffaa800009933333333333333333333990007cc0000cc7000007c0000000000000000c700008188809999999907777777777777777777770000000000
0ffff5ffffff0000993333333333333333333399000077cccc770000007c0000000000000000c700008888809999999900077777777777777777700000000000
0fff5ffff5ff00009933333333333333333333990000007777000000007c0000000000000000c70003fffff39999999900707777777777777777070000000000
00ff5fff5ff0000099333333333333333333339900000000000000000007c00000000000000c70000033b3b00999999007007777777777777777007000000000
000000000000000099333333333333333333339900000000000000000007c00000000000000c7000000000000005000000000777777777777770000000000000
0000000000000000993333333333333333333399000000000000000000007c000000000000c700000000000000affa0000000077777777777700000000000000
00000000000000009933333333333333333333990000000000000000000007c0000000000c700000000000000a99f9a000000777777777777770000000000000
000000000000000099333333333333333333339900000000000000000000007cc000000cc700000079977999a9f97f9a00007770777777770777000000000000
00000000000000009933333333333333333333990000000000000000000000077cccccc770000000a9799979f997799f00007700007777000077000000000000
000000000000000099333333333333333333339900000000000000000000000007777770000000000799999af99f9f9f00070000070770700000700000000000
0000000000000000999999999999999999999990000000000000000000000000000000000000000000aaaaa00ff999a000700000700070070000070000000000
000000000000000009999999999999999999999000000000000000000000000000000000000000000000000000affa0007000000000000000000007000000000
00000000000000011111111111111111110000000000000000000000000003000000300000000000000050000000500000000000000000000000000000000000
00000111111111111111111111111111111111111111000000000000000033000003300000000000099affa00affa99000700000000000070000000000000700
0011111111111111111111111111111111111111111111100000000008ff3ff00ff3ff800000000099af99faaf99fa9900070000077770070000000000007000
001111111111111111111111111111111111111111111110000000008ff666ffff666ff8000000009f99f97ff79f99f900007000700007070000000000070000
00ccc111111111111111111111111111111111111111ccc0000000008ff2626ff6262ff8000000009f99779ff97799f900000700700707077000700000700000
00ccccccccccccc1111111111111111111ccccccccccccc0fffffff08ff4646ff6464ff8000000009a9f9f9ff9f9f9a900000077700077077007000077000000
00ccccccccccccccccccccccccccccccccccccccccccccc08fffff808ffffffffffffff80000000099af99faaf99fa9900000077700007777077000777000000
00ccccccccccccccccccccccccccccccccccccccccccccc00888880008ff6ff00ff6ff8000000000099aafa00afaa99000000007777777000770077770000000
000ccccccccccccccccccccccccccccccccccccccccccc0000000000000000000000000000000000000000000000000000000000777000000000777700000000
000ccccccccccccccccccccccccccccccccccccccccccc0000000000000000000000000000000000000000000000000000000000070000000000777700000000
0000ccccccccccccccccccccccccccccccccccccccccc00000000000000000000000000000000000000000000000000000000000700000000007000770007000
0000ccccccccccccccccccccccccccccccccccccccccc00000000000000000000000000000000000000000000000000000000007000000000007007070070000
00000ccccccccccccccccccccccccccccccccccccccc000000000000000000000000000000000000000000000000000000000777000000000007000070000000
000000ccccccccccccccccccccccccccccccccccccc0000000000000000000000000000000000000000000000000000000000070000000000007000070000000
0000000ccccccccccccccccccccccccccccccccccc00000000000000000000000000000000000000000000000000000000007777000000000000777700077000
00000000ccccccccccccccccccccccccccccccccc000000000000000000000000000000000000000000000000000000000777770700000000000000000077770
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000070770700000000000000000070000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000070000700000000000000000700000
000000f000f0000000000000000000f000f0000000000000000000f000f0000000000000000000f000f000000000000000070077700000000000000007000000
000000ff00ff000000000000000000ff00ff000000000000000000ff00ff000000000000000000ff00ff00000000000000007777000000000000000000700000
000000fffffff00000000000000000fffffff00000000000000000fffffff00000000000000000fffffff0000000000000000000000000000000000007000000
00000fffffffff000000000000000fffffffff000000000000000fffffffff000000000000000fffffffff000000000000000000000000000000000007000000
00000ffff0ff0ff00000000000000ffffffffff00fff000000000ffffffffff0000f000000000ffff0ff0ff00000000000000000000000000000007070700000
00000ffff0ff0ff00000000000000ffff0ff0ff05fff000000000ffff0ff0ff00f0f000000000ffff0ff0ff00000000000000000700000000000077700000000
000f88fffff5fff000000000000f88fffff5fff5fff00000000f88fffff5fff00f0f0000000f88fffff5fff00000000000000007770000000000007770000000
00fff88fff5f5ff00000000000fff88fff5f5ff5ff00000000fff88fff5f5ff0f0f0000000fff88fff5f5ff00000000000000077700007077770000777000000
0fffff88ffffff80000000000fffff88ffffff85000000000fffff88ffffff80f0f000000fffff88ffffff800000000000000077000070077707000077000000
0fffffff8888885f000000000fffffff88888850000000000fffffff8888885f0f0000000fffffff888888500000000000000700000000077000000000700000
0ffff5fffaa855ff000000000ffff5fffaa80000000000000ffff5fffaa855ffff0000000ffff5fffaa855ff0000000000007000000000007000000000070000
0ffff5ffff000fff000000000ffff5ffff000000000000000ffff5ffff000ffff00000000ffff5ffff00ffff0000000000070000000000007000000000007000
0fff555fff000ff0000000000fff555fff000000000000000fff555fff000ffff00000000fff555fff00ffff0000000000700000000000000000000000000700
00ff550ffff000000000000000ff550ffff000000000000000ff550ffff000ff0000000000ff550ffff00ff00000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c0000000000000000c0000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c000000077770000c00000000000000000c0
00000000000000000000bb0bbb0000000000000000000c00000000000000000000000000000000000000000000000c000007c000700000000000000000000c00
000bb0bbb00000000000bbbbbb00000000000000cc0000c000000000000000000000000000000000000000000000000000070c7070000000000c00000000c000
000bbbbbbb000000000b0bb0bbb000000000000000cc00cc000000000000000000000000000000000000000000000000000700007000000000c0000000000000
00b0bb0bbbb0000000bb0bb0bbbb999000000000000cc00cc00c0000000000007000000000000000000000000000000000070000700000000000000000000000
0bb0bb0bbbb9900000bbbbbbbbbb9990000000000000cc0ccc00c000000000000700000000000000000000000000000000007777000000000000000000000000
0bbbbbbb3bba990000bb00bbbbbba900000000000000cccccc00cc00000000700770000000000000000000000000000000000000000000000000000000000000
0b333333bbbaa90000bb00bbbbbbaa000000000000000cccccc0ccc0000000070077070000000000000000000000000000000000000000000000000000000000
00bbbbbbbbaaaab0000bbbbbbbbaaaab0000000000000ccccccc0cc0000000077077707000000000000700000000000000000000000000000000000000000000
000bbbbbbaaaaab00000bbbbbbaaaaab00000000000000cccccc0cc0000000077777707000000000000070000000000000000000000000000000000000000000
0000aaaaaa3aabb000000aaaaaa3aabb00000000000000cccccc0cc00000000777777777000000000000700000000c000000000000000000000000000000c000
0000aaaaaa3abbb000000aaaaaa3abbb00000000000000cccccccccc00000000777777770000000000077070000000c0000000000000000000000077770c0000
0000bb3bbbb3bbb000000bb3bbbb3bbb000000000000000ccccccccc000000007777777700000000000770700000000000000000000000000000070000700000
00000bb3bbb3bb00000000bb3bbb3bb0000000000000000ccccccccc000000007777777700000000007707700000000000000000000000000000070070700000
00000000000000000000000000000000000000000000000ccccccccc000000007777777700000000007777700000000000000000000000000000070000700000
00000000000000000000000000000000000000000000000ccccccccc000000007777777000000000077777700000000000000000000000000000070000700000
00000000000000000000000000000000000000000000000cccccccc0000000077777777000000000777777000000000000000000000000000000007777000000
0000000000000000000000000000000000000000000000ccccc0ccc00000000777777700000000077077070007777000000000000000000000000000000000cc
0000000000000000000000000000000000000000000000cc0cc0c000000000770770700000077770077070007cc0070000000000000000000000000000000000
000000000000000000000000000000000000000000000cc0cc0c0000000077007707000000000777700700007007070000000000000000000000000000000000
00000000000000000000000000000000000000000000c00c00000000000000770000000000000000000000007000070000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000007000070000000000000000000000000000000000
00000000000000000000000000777000000000000000000000777000000000000000000000000000007770000777700000000000000000000000000000000000
00000000000000007770000000777000000000007770000000777000000000000000000077700000007770000000000000000000000000000000000000000000
00000000000000077777000007777700000000077777000007777700000000000000000777770000077777000000000000000000000000000000000000c00000
000000000000000777770000077777000000000777770000077777000000000000000007777700000777770000000000000000000000000000000000000c0000
000000000000000777770000077777000000000777770000077777000000000000000007777700000777770000000c0000000000000000000000000000000000
00000000000000077777700007777700000000077777700007777700000000000000000777777000077777000000000000000000000000000000000000000000
00000000000000077777700007777700000000077777700007777700000000000000000777777000077777000000000000000000000000000000000000000000
00000000000000007777700000777700060000007777700000777700000000000000000077777000007777000000000000000000000000000000000000000000
00000000000000007777770000777700060000007777770000777700000000000000000077777700007777000000000000000000000000000000000000000000
00000060000000000777770000777000060000000777770000777000000000600000000007777700007770000000000000000000000000000000000000000000
0000006000000000007777000777700006000000007777000777700000000060000000000077770007777000000000000000000000000000000c000000000000
000000600000000000077777077700000600000000077777077700000000006000000000000777770777000000000000000000c0000000000000c00000000000
00000060000000000005577755770000060000000007777777770000000000600000000000077777777700000000000000000c00000000000000000000000c00
0000000600000000075777777757700006000000075777775777700000000006000000000775577755777000000c00000000000000000c0000000000000000c0
000000060000000077777777777777000600000077757775777777000000000600000000775777777757770000c000000000000000000c000000000000000000
00000006000000077777777777777700006000077777575777777700000000060000000777777777777777000c00000000000000000000000000000000000000
00000006000000077777777777777700006000077755577555777700000000060000000777555775557777000000000000000000000000000000000000000000
00000000600000777755577555777770006050777770777707777775000000006000007777707777077777700000000000000000000000000000000000000000
00000000600000777777777777777770006005577770777707777750000000006000007777707777077777700000000000000000000000000000000000000000
00000000600055555577eee777555555006000755577eee77755557700000000600055555577eee7775555550000000000000000000000000000000000000000
000000006000077777577e77757777770060077777577e7775777777000000006000077777577e77757777770000000000000000000000000000000000000000
00000000060007555577777777555557006007755577777777555577000000000600075555777777775555570000000000000000000000000000000000000000
00000000060055777757757757777775006007577777757777777755000000000600557777777577777777750000000000000000000000000000000000000000
00000000060000777775575577777770076755777777575777777770000000000600007777775757777777700000000000000000000000000000000000000000
00000000067700077777777777777700077770077777000777777700000000000677000777777777777777000000000000000000000000000000000000000000
00000000077770007777777777777000077770007777000777777000000000000777700077777777777770000000000000000000000000000000000000000000
00000000077770000777777777770000007777000777000777770000000000000777700007777777777700000000000000000000000000000000000000000000
00000000007777000007777777777000000777700007777777777000000000000077770000077777777770000000000000000000000000000000000000000000
00000000000777700077777777777000000777770077777777777000000000000007777000777777777770000000000000000000000000000000000000000000
00000000000777777777777777777700000077777777777777777700000000000007777777777777777777000000000000000000000000000000000000000000
00000000000077777777777777777770000007777777777777777770000000000000777777777777777777700000000000000000000000000000000000000000
00000000000000777777777777777770000000777777777777777770000000000000007777777777777777700000000000000000000000000000000000000000
__map__
000000000000000000000000000000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000090910000000000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000a0a10000000000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000002030203020302030b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000012131213121312130b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000002223232323232324000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
020300000000003233333333333334000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
121300000000003233333333333334000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000003233333333333334000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000004243434343434344000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
005051525354550000000000000000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
006061626364650000000000000000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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

