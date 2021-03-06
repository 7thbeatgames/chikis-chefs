pico-8 cartridge // http://www.pico-8.com
version 34
__lua__

-- chikis chefs
-- by 7th beat games
-- a fangame of chiki's chase by david fu

-- notes: tick here is mostly used to mean the length of 1 note in the tracker
-- not the way pico uses ticks, which is "every note in the tracker takes [sfx pattern speed] ticks" e.g. 16 ticks per note
-- 1 pico tick = 183/22050 s

-- dsets
-- 0 = high score
-- 1 = last score (pass to ending.p8)
-- 2 = last level reached
-- 3 = difficulty.name
-- 11-20 = fruit array (as id numbers)

testbug1 = false 
testbug1_round = 30
testbug1_level = 1

godmode = false
-- testbug1: if
-- 1) we are on the last set of side b
-- 2) the basket's first fruit is *not* chirimoya/watermelon
-- 3) the next basket's first fruit is chirimoya/watermelon
-- then it will fail the last fruit of the basket early. why?????
-- solved now

fizzd_path = false -- alt path for multicart to work locally

testwin = false

mstate = 
{
	intro = "intro",
	call = "call",
	response = "response"
}

--[[gameresult =
{
	playing = 0,
	gameover = 1,
	won = 2,
	fullwon = 3
}]]--

mside = 
{
	a = "a",
	b = "b"
}

game_difficulties =
{
	very_easy = {
		name = "very easy",
		speed = 20
	},
	easy = {
		name = "easy",
		speed = 18
	},
	normal = {
		name = "normal",
		speed = 16
	},
	hard = {
		name = "hard",
		speed = 14
	},
	very_hard = {
		name = "very hard",
		speed = 12
	},
	very_hard_plus = {
		name = "very hard+",
		speed = 10
	}
}

game_difficulty_ids =
{
game_difficulties.very_easy,
game_difficulties.easy,
game_difficulties.normal,
game_difficulties.hard,
game_difficulties.very_hard,
game_difficulties.very_hard_plus
}

current_speed = 16
default_speed = 16
current_difficulty = game_difficulties.normal
current_difficulty_id = 3
difficulty_selection = false

cartdata("chikischefs")

--outside to save between runs
input_offset = 90 -- in ms
input_offset_default = 90


function _init()
	

poke(0x5f00+92,255) --disable repeat button press
z = 0
currfruits = {}
bubblefruits = {}
slices = {}
tscratch = -1
tcatanim = -1
last=0

-- conductor
tick = 0  -- is stat(50) but always increasing
tickl = 0 -- is stat(50)
tickf = 0 -- is tick but interpolated
game_tick_speed = 16 --set in music tab. 16 means 16'ticks' per note.
game_tick_ui = 0 -- 
single_tick_length = 183/22050 --1 single tick (in pico terms) is 183 samples at 22050hz

hit_margin = 0.8 -- in ticks! plus minus. see change_difficulty() for hardcoded

statloops = -1
statprev =0
statcap = 16 --stat per pattern
spb = 16  -- stat per beat
bar = 0
calltime = false
responsetime = false

notesstr = ""
bbeats = ""

newtick = false
tick_response = 0
sylaudio = 0
anybtn = false
closestfruit = 1
bubbles_xoffset = 8
rabbit_state = 0
headbob = false
perfect_round = false
perfect_rounds_count = 0
playing = false
difficulty_selection = false -- if playing = false, then two menus, depending on this var
trabbitappear = 0
gameover = false
won = false
allwon = false
tgameover = 0

music_state = mstate.intro

current_level  = 0 -- increase every 4 rounds
current_level_show = 0
prev_level = 0
round = testbug1 and testbug_round or 0 --rounds increase every call phase

arr_basket = {}
arr_basket_datum = {} --the motif of the round, set every 4 baskets
arr_basket_show = {} -- arr_basket but updated at start of next bar only

arr_basket_beats = {} -- linear list of beat numbers, {0,1,4..15}
arr_basket_beats_show = {} --refresh on bar
arr_basket_beats_results = {} -- results for each hit

-- false when used
flag_refreshed_response = true
flag_refreshed_call = true
flag_refreshed_newbar = true

lives = maxlives

currentfruits = {fruits.grape} --starting fruits
currentfruits_show = {fruits.grape} --same but updated on bar

slices = {}

--load input offset from save data if available
_input_offset = dget(60)
if (_input_offset ~= 0) then
	input_offset = _input_offset
end

str_last_margin = ""

end

function reset()

end

function change_difficulty(_increase)
	if _increase then
	current_difficulty_id+= 1
	else
	current_difficulty_id-= 1
	end

	if current_difficulty_id  > #game_difficulty_ids then current_difficulty_id = 1 end
	if current_difficulty_id == 0  then current_difficulty_id = #game_difficulty_ids end

	printh ("huh ".. current_difficulty_id)

	current_difficulty = game_difficulty_ids[current_difficulty_id]
	current_speed = current_difficulty.speed

	if current_difficulty_id < 3 then
	 hit_margin = 1
	else
	 hit_margin = 0.85
	end
end

function _update60()


	if playing then
		play_update()
	else
		headbob = time() * 7.5 % 4 < 1
		if difficulty_selection == false then
		--start screen + offset
			if btnp(5) then difficulty_selection = true end
			if btnp(0) then input_offset -= 5
			dset(60,input_offset)
			end
			if btnp(1) then
			input_offset += 5
			dset(60,input_offset)
			end
			if btnp(3) then
			input_offset = input_offset_default
			dset(60,input_offset)
			end


		else
		-- difficulty select screen
			if btnp(0) then change_difficulty(false) end
			if btnp(1) then change_difficulty(true) end

			if (btnp(4)) then difficulty_selection = false end

			if btnp(5) then
				set_all_speeds(current_difficulty.speed)
				if (testbug1) then
				music()
				round = testbug1_round 
				else
				music() end
				playing = true
			end
		end

	end	

	if time() - tgameover > 1 and btnp(5) then
		if gameover then
			_init()
		end

		if won or allwon then
			-- assemble currentfruits into dsets

			allfruits_arr = {fruits.grape,fruits.orange,fruits.apple,
			fruits.papaya,fruits.banana,
			fruits.pineapple, fruits.coconut,
			fruits.watermelon,fruits.chirimoya, fruits.acaiberries}

			--reset all dsets first
			for i=1,10,1 do
			 dset(i+10, 0)
			end

			--if not won all, remove last element of array first
			-- seems to not work hmm, oh yeah cause need to remove fruits.rest
			-- oh yeah2 need to use a on bar updated version
			_currentfruits = currentfruits_show
			del(_currentfruits,fruits.rest)

			if (not allwon and #_currentfruits > 1) then
			deli(_currentfruits)
			end

			for i=1,#_currentfruits do
			_ft = _currentfruits[i]
			for j=1,#allfruits_arr,1 do
			 if _ft == allfruits_arr[j] then
			 dset(i+10,j)
			end
			end
			end

			dset(1, perfect_rounds_count)
			dset(2, current_level_show)
			dset(3, current_difficulty_id)
		end

		if won then
			load(fizzd_path and "chikischefs/ending.p8" or "ending.p8", "back to game", "won")
		end

		if allwon then
			load(fizzd_path and "chikischefs/ending.p8" or "ending.p8", "back to game", "allwon")
		end
	end


end

function get_offset_ticks()
			---s / (s/tick) = tick
			-- the 'tick' we mean is length of a note i.e. 16 pico ticks at normal speed
			return (input_offset / 1000) / (current_speed * single_tick_length)
end

function play_update()
	-- conductor
	--detect a stat(50) looping
	statprev = tickl
	tickl =  stat(50)
	if (tickl < statprev)
	then statloops+=1 end

	newtick = tickl ~= statprev
	newbar = newtick and tickl == 0

	tick = stat(50) + statloops * statcap
	-- find one frame worth in the tick domain
	-- s / (s / tick) = tick
	dtt = dt / (single_tick_length * current_speed)

	tickf = newtick and tick or tickf + dtt
	anybtn = btnp(0) or btnp(1) or btnp(2) or btnp(3) or btnp(4) or btnp(5)
	
	headbob = tickl % 4 < 1

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

	if newbar then
		current_level_show = current_level
		currentfruits_show = currentfruits
	end


	-- if anybtn then
	-- 	load("ending.p8", "back to game", "allwon")
	-- end

	-- appear bubble fruit

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


	--printh("tickl" .. tickl .. " -> flagg " .. (flagg and "true" or "false") .. " pos " .. pos .. "/ newtick " .. (newtick and "true" or "false") .. " #arr_basket_show " .. #arr_basket_show .. " intro? " .. (music_state ~= mstate.intro and "true" or "false"))
	if flagg == true and newtick and calltime and #arr_basket > 0 and music_state ~= mstate.intro then
		
		--z = ceil(rnd(#allfruits - 1))
		--pos = flr(tickl / 4) --
		--printh(arr_basket_show)
		--printh(pos)
		ifruit = arr_basket[pos]

		--finds the starting beat of the first syllable of the fruits
		beatpos = 1
		for i = 1, pos - 1 do
			f = currentfruits[arr_basket_show[i]]
			beatpos = beatpos + #f.syllables
		end

		if beatpos <= #arr_basket_beats then
			beat = arr_basket_beats[beatpos]
			f = currentfruits[ifruit]

			if #f.notes > 0 then -- don't add rests
				addbubblefruit(f, pos, beat)
			end
		end
	end


	-- missed beat
	if music_state == mstate.response then
		for i = #arr_basket_beats_results + 1, #arr_basket_beats_show do
			b = arr_basket_beats_show[i]
			diff = tickf % 16 - b

			if diff > 7 then
				arr_basket_beats_results[i] = false
				printh("bigmiss..")
				str_last_margin = "miss!"
				rabbit_state = 1
			end
		end
	end	

	-- game over
	if gameover == false and won == false and allwon == false and newtick and tickl == 2 then
		if (not testbug1 and not godmode) then
		misses = max(0, (round - 1) - perfect_rounds_count)
		else
		 misses = 0
		end
		lives = maxlives - misses
		printh("misses: " .. misses)
		if misses >= maxlives then
			printh("gameover")
			if current_level >= 3 then
				won = true
				rabbit_state = 2
			else
				gameover = true
			end
			tgameover = time()
			music(-1)
			sfx(62)
		end
	end




	-- scratch!

	if anybtn and gameover == false then
		tscratch = 0
		tcatanim = 0

		nextbeat = #arr_basket_beats_results + 1

		-- check beats

		--but first , check if should ignore the scratch
		local shouldcount = true
		printh("-------")
		printh(tickl)

		if (music_state == mstate.call and ( tickl > 2 and tickl < 13))
		then shouldcount = false end
		printh(shouldcount)

		if nextbeat <= #arr_basket_beats_show and shouldcount then

			b = arr_basket_beats_show[nextbeat]

			---s / (s/tick) = tick
			-- the 'tick' we mean is length of a note i.e. 16 pico ticks at normal speed
			local offset_ticks = get_offset_ticks()

			local tickf_adj = tickf - offset_ticks --i.e. negative means you get to hit earlier

			tickfl = tickf_adj % 16

			-- basket beats are 1-indexes, tick is 0 indexed!!
			diff = b - 1 - tickfl


			b_adj = b
			if diff < tickfl and abs(diff) > 8 then
				b_adj = b + 16 --must be adj cause we are using b again below
				-- printh("dddd")
			end

			diff = b_adj - 1 - tickfl
			absdiff = abs(diff)

			printh("b " .. b)
			
			
			-- check whats the closest fruit to hit
			closestfruit = 1
			for i = 1, #bubblefruits do
				f1 = bubblefruits[i]
				f2 = bubblefruits[closestfruit]

				if abs(f1.beat - b) < abs(f2.beat - b) then
					closestfruit = i
				end
			end

			--^ this is imperfect cause it checks the starting syllables
			-- also b is not the current beat but the supposed beat of the next slice, why?
			-- quick hack to revert to prev if still alive
			-- testbug1 unrelated to this, tested
			if closestfruit > 1 and bubblefruits[closestfruit-1].lives > 0
			and abs(bubblefruits[closestfruit-1].beat - b) < 6 --max 5 beats from starting syllable to end
			then
			closestfruit -= 1
			end


			-- hit correctly

				if absdiff < hit_margin then  -- set in change_difficulty
					printh("hit! " .. diff)
					arr_basket_beats_results[nextbeat] = true -- i.e. adds array length!
					
					if #bubblefruits > 0 then
					bubblefruits[closestfruit].tglow = 0.1 end

					-- change rabbit to happy if it wasn't angry
					if rabbit_state == 0 then
						rabbit_state = 2
					end

					-- create slice
					-- error avoiding if scratch right when bubblefruits was reset
					-- (cause bubblefruits is reset without offset adjustment)
					if #bubblefruits > 0 then
						f = bubblefruits[closestfruit]
						f.tfreeze = 0.2
						f.lives = f.lives - 1
						addslice(closestfruit)
					end


					if #arr_basket_beats_results == #arr_basket_beats_show then
						perfect_round = true
						for i = 1, #arr_basket_beats_results do
							if arr_basket_beats_results[i] == false then
								perfect_round = false
							end
						end

						if perfect_round then
							perfect_rounds_count = perfect_rounds_count + 1
							-- sfx(33) disable cause no channels
							dset(0, max(perfect_rounds_count, dget(0)))
						end
					else
						perfect_round = false
					end


				-- small miss
				elseif absdiff < 7 then
					if (diff < 0 ) then str_last_margin = "late!"
					else str_last_margin = "early!" end
					printh("smallmiss.." .. diff)
					rabbit_state = 1
					arr_basket_beats_results[nextbeat] = false

				-- no beats close
				else
					printh("nothing.." .. diff)
				end
		end
	
	end



	if tscratch >= 0 then
		tscratch += dt * 20
		if tscratch > 3 then tscratch = -1 end
	end

	if tcatanim >= 0 then
		tcatanim += dt * 30
		if tcatanim > 3 then tcatanim = -1 end
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
	updateslices()
end

function _draw()

	-- clean screen

	-- if rabbit_state == 0 then
	-- 	cls(4)
	-- elseif rabbit_state == 1 then
	-- 	cls(8)
	-- elseif rabbit_state == 2 then
	-- 	cls(11)
	-- end

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


	bstat = stat(50) - get_offset_ticks()

	-- draw fruit texts
	if gameover == false and won == false and allwon == false then
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
	end

	--test case
	if (testwin) then
	round  = 4
	playing = true
	current_difficulty_id = 4
	current_difficulty = game_difficulties.very_hard_plus
 	won = true
	current_level = 5
	currentfruits = {fruits.apple,fruits.orange, fruits.chirimoya, fruits.grape}
	end

	if (testbug1) then
	current_level = testbug1_level
	end

	if gameover == true then
		print("game over!", 68,66, 7)
		print("press ??? to\n  restart", 66,80, 10)
		print("score: " .. perfect_rounds_count, 62, 101, 7)
	elseif won == true then
		print("nicely done!", 65,66, 7)
		print("press ??? to\n continue", 66,80, 10)
		print("score: " .. perfect_rounds_count, 62, 96, 7)
		if (current_difficulty_id > 3) then
		print("(" .. current_difficulty.name .. ")", 62, 102) end
	elseif allwon == true then
		print("you are\namazing!", 72,60, 7)
		print("press ??? to\n continue", 66,76, 10)
		color = perfect_rounds_count == 32 and 10 or 7
		print("score: " .. perfect_rounds_count, 62, 96, color)
		if (current_difficulty_id > 3) then
		print("(" .. current_difficulty.name .. ")", 62, 102) end
	elseif playing == false then
		if not difficulty_selection then
		print("chiki's chefs", 62,62, 7)
		print("press ??? to\n   start", 66,72, 10)
		print("offset:\n??????".. input_offset.. " ms??????(??????)",62,87, 7)
		hiscore = dget(0)
		if hiscore == 32 then
			color = time() % 1.0 < 0.5 and 10 or 9
		else
			color = 7
		end
		print("hi score: " .. hiscore, 62, 101, color)
		else
		print("press ??? to\n   start", 66,72, 10)
		print("difficulty:\n??????".. current_difficulty.name .. "??????",62,87, 7)
		end
	end
	

	-- draw result checkmark
	if (tick % 2 == 0 or tickl < 8) and won == false and gameover == false and allwon == false then
		if perfect_round then
			spr(12, 97, 92, 2, 2)
		elseif rabbit_state == 1 then
			spr(14, 97, 92, 2, 2)
		end
		-- printh("perfect round")
	end	

	-- draw score
	if playing == true and won == false and gameover == false and allwon == false then
		if round == 0 then
			print("follow the\n  rhythm!", 68, 67, 10)
			print("press ??? to\n   slice", 67, 90, 7)
		else
			if (music_state ~= mstate.response) then
			print("score: " .. perfect_rounds_count, 62, 101, 7)
			else
			 print(str_last_margin, 62, 101, 7)
			end
		end
		
	end

	-- scratch
	if tscratch >= 0 then
		sprnum = flr(tscratch)
		sprind = 154 + sprnum * 2
		xscratch = 13 + (closestfruit - 1) * bubbles_xoffset
		spr(sprind, xscratch, 58, 2, 3)
	end

	-- cat
	altrender(true)
	xcat = 3 
	ycat = 64
	if tcatanim >= 0 then
		sprnum = flr(tcatanim)
		sprind = 114 + sprnum * 3
		xcat = xcat + sprnum / 1.5
		spr(sprind, xcat, ycat, 3, 2)
	else
		sprcat = headbob and 120 or 112
		spr(sprcat, xcat, ycat, 2, 2)	
	end	
	altrender(false)

	-- cat chef hat
	cy = headbob and 1 or 0
	spr(69, xcat + 2, ycat - 3 + cy)

	-- frog
	altrender(true)
	openmouth = false
	if calltime then
		for i = 1, #bubblefruits do
			if tickl == bubblefruits[i].tick % 16 then
				openmouth = true
			end
		end
	end
	sprfrog = 146
	if openmouth then
		sprfrog = 148
	elseif headbob then
		sprfrog = 144
	end
	spr(sprfrog, 8 * 8, 3 * 8, 2, 2)
	altrender(false)

	-- frog chef hat
	xfroghat = openmouth and 7 or 6
	yfroghat = headbob and 1 or 0
	spr(69, xfrog + xfroghat, yfrog - 10 + yfroghat, 1,1, true)

	-- bowl back
	xbowl = 10
	ybowl = 128 - 2 * 8
	bowlcolor = 5
	if current_level == 2 then bowlcolor = 14 end
	if current_level == 3 then bowlcolor = 2 end
	if current_level >= 4 then bowlcolor = 1 end
	ovalfill(xbowl + 2, ybowl, xbowl + 6 * 8 - 2, ybowl + 4, bowlcolor)

	-- fruits
	drawfruits()

	-- slices
	drawslices()
	
	-- bowl front
	altrender(true)
	bowlcolor = 6
	if current_level == 2 then bowlcolor = 15 end
	if current_level == 3 then bowlcolor = 8 end
	if current_level >= 4 then bowlcolor = 12 end
	pal(12, bowlcolor)
	spr(80, xbowl, ybowl, 6, 2)
	pal(12, 12)
	altrender(false)

	-- rabbit
	if playing == true then
		trabbitappear = min(trabbitappear + 3/60, 1)
		altrender(true)
		xrabbit = 96
		yrabbit = 97 + lerpquad(32, 0, trabbitappear)
		if headbob then yrabbit = yrabbit + 1 end 
		if rabbit_state == 0 then spr(199, xrabbit, yrabbit, 4,4)
		elseif rabbit_state == 1 then spr(196, xrabbit + 8, yrabbit, 3,4)
		elseif rabbit_state == 2 then spr(192, xrabbit, yrabbit, 4,4)
		end
	end
	altrender(false)


	-- bubble
	-- t = (sin(time()) + 1) * 5
	-- r = t
	-- drawbubble(25, 25, r)


	-- lives
	circfill(7,7, 6, 0)
	circfill(7,7, 5, 8)
	print(lives, 6,5, 7)


	-- debug

if (testbug1) then
	printdebug() end
	-- drawresultsquares()


	
end

function drawbubble(x, y, r)
	
	circ(x, y, r, 12) -- inner circle
	circ(x, y, r + 1, 7) -- outer circle

	-- specular highlight
	sx = x - r * 0.5
	sy = y - r * 0.5
	rectfill(sx, sy, sx + 1, sy + 1, 7)
end

function drawresultsquares()
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
	-- print("side prebar "..music_side_prebar)	
	-- print("side  "..music_side_show)	
	print("round "..round)
	print("tick " .. tick)
	print("tickf ".. tickf)
	print("sylaudio ".. sylaudio)
	print("level: "..current_level)
	print("level: "..current_level_show)


end

function addslice(fruitindex)
	f = bubblefruits[fruitindex]
	s = {
		x = f.x - 4 + rnd(4),
		y = f.y,
		sprite = f.data.slicesprite,
		w = f.data.slicesize.x, 
		h = f.data.slicesize.y,
		ymax = 110 + rnd(7)
	}
	add(slices, s)
	--printh("spr " .. f.data.slicesprite)
	--printh("adding new slice -> " .. f.data.name .. " at " .. f.x .. ", " .. f.y)
end

function updateslices()
	for i = 1, #slices do
		s = slices[i]
		s.y = min(s.y + 2, s.ymax)
	end
end

function drawslices()
	for i = 1, #slices do
		s = slices[i]
		spr(s.sprite, s.x - 4, s.y - 4, s.w, s.h)
		--printh("drawing -> "  .. s.sprite .. " at " .. s.x .. ", " .. s.y)
	end
end

function bringfruit(fruit)
	currfruits[#currfruits + 1] = {
		x = 120,
		y = 32,
		data = fruit
	}
end

-- beat refers to starting beat of first syllable
function addbubblefruit(fruit, position, beat)
	printh("adding " .. fruit.name)

	add(bubblefruits, {
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
		tfreeze = 0,
		tglow = 0,
		lives = #fruit.notes
	})
end



function updatefruits()

	--for different difficulties, adjusting the hardcoded numbers that were for default speed
	fallmultiplier = default_speed/current_speed
	

	for i = 1, #bubblefruits do

		f = bubblefruits[i]

		-- initial animation
		if f.pstart < 1 then
			f.pstart = f.pstart + 3/60
			f.x = lerpoutbacksoft(xfrog, f.x0, f.pstart)
			f.y = lerp(yfrog, f.y0, f.pstart)
		end


		-- falling animation
		if(tick - get_offset_ticks() >= f.sptick) then
			if f.tfreeze > 0 then
				f.tfreeze = f.tfreeze - dt
			end

			if f.tfreeze <= 0 then
				f.toffset = f.toffset + dt
			end
			f.y = f.y0 + f.toffset * f.toffset * (90 * fallmultiplier) + f.toffset * (25 * fallmultiplier)
		end

		-- glow animation when hit
		if f.tglow > 0 then
			f.tglow = f.tglow - dt
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
		if f.lives > 0 then

			
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

			-- print(f.lives, x, y, 7)

			-- bubble
			maxside = max(data.size.x, data.size.y)
			tilesize = maxside == 1 and 2 or 3


			if f.pstart < 1 then
				rbubble = lerpoutback(1, maxside * 6, f.pstart)
				drawbubble(f.x, f.y, rbubble)
			elseif f.toffset < 0.15 then
				bubblespr = maxside == 1 and 37 or 39

				-- explosion anims
				if f.toffset > 0.11 then 
					bubblespr = 92
					tilesize = 4
				elseif f.toffset > 0.06 then
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
		end
		-- debug
		-- print(f.beat, f.x, f.y, 7)
	end	
end

function textfruit(ff, row, rs)

	arr = ff.syllables

	bbcenterx = 88
	bbtopy = 63 + row * 8

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
			nohyphen = false
			if (i == 2 and ff == fruits.acaiberries) then
				nohyphen = true end

			if (not nohyphen) then
			syllable = syllable .. "-"
			end
		end	

		-- determine syllable color
		textcolor = 7
		result = rs[i]
		if result == 1 then -- miss
			textcolor = 8
		elseif result == 2 then -- hit
			textcolor = calltime and 10 or 11
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

ticks_in_beat = 4
ticks_in_pattern = 16

-- rhythms of a-side and b-side
startbeats_a = {0,4,8,12}
startbeats_b = {0,6,12}





function update_conductor()
	--54 is music pattern: 0 is intro, odd numbers are calls and even are responses
	-- 0 [12] [34] [56] [78] || [9 10] [11 12] ..

	-- make a stat 54 adj thats input offset adjusted
	--[[if (stat50_adj() > 0 and stat50_adj() < 6 and flag54 == true) then
		flag54 = false 
		stat54_adj = stat(54)
	end
	if (stat50_adj() > 6) then
	flag54 = true
	end--]]
	-- end of stat54 adj, unused cause turns out the visual offset looks best at 0 already

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
	responsetime = music_state == mstate.response

	tickl = stat(50) //tick but looping. use first channel as reference pos (cause it doesnt loop)
	beatnumber = tickl\4

	--update the 'on new bar' equivalents from the prebar variables for showing
	--adjust for gameplay offset, so doesnt eat into the response pattern phase
	-- minus so it happens later
	-- flag_refreshed_newbar is start of call phase only
	if(tickl - get_offset_ticks()  >= 0 and tickl < 3 and flag_refreshed_newbar == true) then
		flag_refreshed_newbar = false
		arr_basket_beats_show = {}
		str_last_margin = ""

		for i = 1, #arr_basket_beats do
			arr_basket_beats_show[i] = arr_basket_beats[i]
		end

		arr_basket_show = {}
		for i = 1, #arr_basket do
			arr_basket_show[i] = arr_basket[i]
		end


		if (allwon_prebar) then
			tgameover = time()
			allwon = true
			music (-1)
			rabbit_state = 2
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
		
		--melody notes go in next bars pattern
		-- put bunny's melody
		local _ss = stat(54)
		--but after 16 is 1 again, so imagine that its 0 when calculating the pattern in the next bar
		-- 17+ : 17 should be treated as 1 again
		if (_ss > 15) then
			if _ss > 31 then 
				_ss -= 16 --wraparound 2x, cause next bars aim (_ss+3) is 3!
			 end				
			_ss-=16
		end

		put_basketbeats_in_pattern(5,_ss+3,true)

		--sound fx for response is always in 42, using sfx in 2
		put_basketbeats_in_pattern(3,42,true)
		--put_basket_start_beats_in_pattern(5,42,true) --accent start of syllables / didnt work out

		--printh("reseting rabbit_state")
		rabbit_state = 0
		perfect_round = false
	end

	-- if in a second half of a response pattern or intro, generate new beat and put in call pattern
	if (tickl > ticks_in_pattern/2 and flag_refreshed_response == true and
	(music_state == mstate.intro or  music_state == mstate.response)) then
		flag_refreshed_newbar = true
		round+=1
		--check if we're in for a new level
		level = (round-1)\8+1 --round 1-8 is level 1, 9-16 is level 2,  etc
		-- level = (round-1)\2+1 --uncomment this for fast levels
		current_level = level
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

			if level > #fruitlevels then -- there's no more levels, you won!
				allwon_prebar = true --makes allwon true on next bar 
			else
				printh("new level!")
				is_new_level = true
				slices = {}
				prev_level = level
				newfruit = add_new_fruit(level)

				--add 'rest' in for level 3
				if (level == 3) then add(currentfruits,fruits.rest)
			end
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
		
		--put frogs melody
		local _ss = stat(54)
		--but after 16 is 1 again, so imagine that its 0 when calculating the pattern in the next bar
		-- 17+ : 17 should be treated as 1 again
		if (_ss > 15) then
			if _ss > 31 then 
				_ss -= 16 --wraparound 2x, cause next bars aim (_ss+3) is 3!
			 end				
			_ss-=16
		end

		put_basketbeats_in_pattern(5,_ss+3,true)

		--layer with sound
		--sound fx for call is always in 41, using sfx in 1
		put_basketbeats_in_pattern(0,41,true)


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

	while reroll == true  and testbug1 == false do
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


	if (music_side_prebar == mside.b and testbug1) then
		currentfruits = {fruits.orange,fruits.grape,fruits.chirimoya,fruits.watermelon,fruits.pineapple}
		arr_basket = {1,2,2} --only happens when first is *not* chirimoya?
	end

	if (music_side_prebar == mside.a and testbug1) then
		arr_basket = {3,3,3,3} --only happens when first is chirimoya?
	end

	if (allwon_prebar) then 
		add(currentfruits,fruits.cherry)
		local c = #currentfruits
		arr_basket = {c,c,c,c} 
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
	arr_basket_start_beats = {} -- beats of the first syllable

	if (testbug1) then
	arr_basket = {1}
	currentfruits = {fruits.grape}
	end

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
			if (j == 1) -- code
			then
			add(arr_basket_start_beats,bbeat)
			end
		end
	end

	-- for i=1,#arr_basket_beats do
	-- print (arr_basket_beats[i])
	-- end
end

function put_basket_start_beats_in_pattern(vol,pattern_num)
	--dont mute notes. this is for accenting extra
	--turn on in pattern
	for i=1,#arr_basket_start_beats do
		-- x,x,bit1,bit2,bit3
		--set_vol(pattern_num, arr_basket_start_beats[i], false,false,true)
		set_vol(pattern_num, arr_basket_start_beats[i], false,true,true)
	end
end

function put_basketbeats_in_pattern(vol,pattern_num,loud)
	--mute all notes
	for i=1,16 do
		-- x,x,bit1,bit2,bit3
		set_vol(pattern_num, i, false,false,false)
	end

	--turn on in pattern
	for i=1,#arr_basket_beats do
		-- x,x,bit1,bit2,bit3
		set_vol(pattern_num, arr_basket_beats[i], loud,loud,true)
	end
end


--difficulty change
function set_all_speeds(spd)
for i=3,42,1 do
 set_speed(i,spd)
 end

for i=30,39,1 do
 set_speed(i,spd*2)
 end
end
-->8
--eruonna's funcs:
function set_vol(sfx,time,bit1,bit2,bit3)
	local addr = 0x3200 + 68*sfx + 2*(time-1)
	poke2(addr, %addr & 0b1111000111111111) -- set everything to 0
	if bit1 then poke2(addr, %addr | 0b0000001000000000) end
	if bit2 then poke2(addr, %addr | 0b0000010000000000) end
	if bit3 then poke2(addr, %addr | 0b0000100000000000) end
end

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
		slicesize = {x = 1, y = 1},
		sprite = 1,
		slicesprite = 1,
		bottom = 0,
		notes = {1},
		maincolor = 15
	},
	grape = {
		name = "grape",
		syllables = {"grape"},
		size = {x = 1, y = 1},
		slicesize = {x = 1, y = 1},
		sprite = 6,
		slicesprite = 22,
		bottom = 0,
		notes = {1},
		maincolor = 13
	},
	apple = {
		name = "apple",
		syllables = {"ap", "ple"},
		size = {x = 1, y = 1},
		slicesize = {x = 1, y = 1},
		sprite = 1,
		slicesprite = 27,
		bottom = 0,
		notes = {1,3},
		maincolor = 8
	},
	orange = {
		name = "orange",
		syllables = {"o", "range"},
		size = {x = 1, y = 1},
		slicesize = {x = 1, y = 1},
		sprite = 59,
		slicesprite = 74,
		bottom = 0,
		notes = {1,2},
		maincolor = 9
	},
	banana = {
		name = "banana",
		syllables = {"ba", "na", "na"},
		size = {x = 2, y = 1},
		slicesize = {x = 2, y = 1},
		sprite = 16,
		slicesprite = 64,
		bottom = 0,
		notes = {0,1,3},
		maincolor = 10
	},
	papaya = {
		name = "papaya",
		syllables = {"pa", "pa", "ya"},
		size = {x = 2, y = 1},
		slicesize = {x = 2, y = 1},
		sprite = 7,
		slicesprite = 25,
		bottom = 0,
		notes = {0,1,3},
		maincolor = 7
	},
	coconut = {
		name = "coconut",
		syllables = {"co", "co", "nut"},
		size = {x = 2, y = 2},
		slicesize = {x = 2, y = 1},
		sprite = 237,
		slicesprite = 221,
		bottom = 0,
		notes = {0,2,3},
		maincolor = 7
	},
	watermelon = {
		name = "watermelon",
		syllables = {"wa", "ter", "me", "lon"},
		size = {x = 2, y = 2},
		slicesize = {x = 2, y = 1},
		sprite = 4,
		slicesprite = 42,
		bottom = 2,
		notes = {1,2,3,4},
		maincolor = 3
	},
	chirimoya = {
		name = "chirimoya",
		syllables = {"chi", "ri", "mo", "ya"},
		size = {x = 1, y = 1},
		slicesize = {x = 1, y = 1},
		sprite = 23,
		slicesprite = 24, 
		bottom = 0,
		notes = {1,2,3,4},
		maincolor = 3
	},
	pineapple = {
		name = "pineapple",
		syllables = {"pine", "ap", "ple"},
		size = {x = 1, y = 2},
		slicesize = {x = 1, y = 1},
		sprite = 235,
		slicesprite = 252,
		bottom = 0,
		notes = {1,3,4},
		maincolor = 3
	},
	acaiberries = {
		name = "acai berries",
		syllables = {"a", "cai", "ber","ries"},
		size = {x = 2, y = 2},
		slicesize = {x = 1, y = 1},
		sprite = 87,
		slicesprite = 105,
		bottom = 0,
		notes = {0,1,3,4},
		maincolor = 3
	},
	rest = {
		name = "rest",
		syllables = {".."},
		size = {x = 1, y = 1},
		slicesize = {x = 1, y = 1},
		sprite = 47, --todo
		slicesprite = 47, --todo
		bottom = 0,
		notes = {},
		maincolor = 0
	},
	cherry = {
		name = "cherry",
		syllables = {"cherry"},
		size = {x = 1, y = 1},
		slicesize = {x = 1, y = 1},
		sprite = 86,
		slicesprite = 22,
		bottom = 0,
		notes = {1},
		maincolor = 13
	}
}


fruitlevels = --repeated is to alter probabilities
{
	{fruits.orange,fruits.apple},
	{fruits.papaya,fruits.banana},
	{fruits.pineapple, fruits.coconut},
	{fruits.watermelon,fruits.chirimoya, fruits.acaiberries}
}

ybubble0 = 20
yhitcenter = 72
xfrog = 66
yfrog = 32
dt = 1/60
maxlives = 5



__gfx__
00000000000030009999999999999999000000000000000000000000000aaaaaaaa00000000aaaaaaaa000000000030000000000000000000000000000000000
0000000000033000999999999999999900000333333000000005000000a7aaaaaaa9000000a99999999a00000000330000000000000000000000000000000000
00000000088388009999999999999999000bbb3bb3b330000005500009aaaaaaaaaa99000a9999999999aa0008ff3ff000000000000000000000000000000000
0000000089888880999999999999999900b33333333bb3000005050099aaaaaaaaaaa922a990a010100999008ff666ff00000000000000000000000000000000
000000008988888000099900000000000b33333333333bb000500500b9aaa9aaaaa99920b9aa010101aa99a08ff2626f00000000000770000007700000770000
00000000888888800099999000099900b3bbbbbb3b3bb33b07dd0500bb999aaa99999900b99090109999aa008ff4646f00000000007770000007770007777000
00000000888888800999999900999990bb33333333333bbb06dd00500b999999999900000b99999999aa00008fffffff00000000077700000007777077770000
00000000088888000999999909999999bbbb3b33333333330555000000bbbb9bb900000000bbbbaaaa00000008ff6ff000000000777000000000077777000000
0000000000000000099999990999999933333333333bb3bb00000000000000000000000000000000000000000000000000077000770000000000007770000000
00000000000000000099999009999999b33333333333333b00000000033333300066660000000000000000000000000000077707700000000000077777000000
00500000000000d000099900009999900bbb33333333bbb000000000335333330066160000000000000000000000000000007777700000000000077007700000
005a000000000ad000000000000999000033bb3b33bb33000000000035333353061666600099a000000000000000000000000777000000000000770000770000
0099aaaaaaaaa990000000000000000000033333333330000000000033353333366661630a9990101010a9000000000000000777000000000000700000070000
00999aaaaaaa9990000000000000000000000bb33330000007dd000033333533361666630ba99901010a99000000000000000000000000000000700000000000
00099999999999000000000000000000000000000000000006dd000003353330566666630bba999999999a00fffffff000000000000000000000000000000000
000099999999900000000000000000000000000000000000055500000033330003355330000bbaaaaa9aa0008fffff8000000000000000000000000000000000
22222222222222220999999999999999999999900000000000000000000000000000000000000000000000000888880007000000000000000000007000000000
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
000000000000000099333333333333333333339900077777000000000007c00000000000000c7000000000000005000000000777777777777770000000000000
0000000000000000993333333333333333333399007776770000000000007c000000000000c700000000000000affa0000000077777777777700000000000000
00770000000007709933333333333333333333990777776700000000000007c0000000000c700000000000000a99f9a000000777777777777770000000000000
00f77777777777f099333333333333333333339977767760000000000000007cc000000cc700000079977999a9f97f9a00007770777777770777000000000000
006f777777777f609933333333333333333333997777676700000000000000077cccccc770000000a9799979f997799f00007700007777000077000000000000
0006fffffffff60099333333333333333333339976777676000000000000000007777770000000000799999af99f9f9f00070000070770700000700000000000
0000666666666000999999999999999999999999776667600000000000000000000000000000000000aaaaa00ff999a000700000700070070000070000000000
000000000000000009999999999999999999999077707600000000000000000000000000000000000000000000affa0007000000000000000000007000000000
22222222222222222222222222222222222222222222222200000000000000000000000000000000000050000000500000000000000000000000000000000000
22222222222222222222222222222222222222222222222200000000000333000000000000000000099affa00affa99000700000000000070000000000000700
2222222222222222222222222222222222222222222222220000500000303330003330000000000099af99faaf99fa9900070000077770070000000000007000
2277cccc22222222222222222222222222222222ccccccc2000500000000033303333300000000009f99f97ff79f99f900007000700007070000000000070000
2277cccccccccc2222222222222222222cccccccccccccc200010000000001d223333330000000009f99779ff97799f900000700700707077000700000700000
2277ccccccccccccccccccccccccccccccccccccccccccc2008ef000000001111d200000000000009a9f9f9ff9f9f9a900000077700077077007000077000000
2277ccccccccccccccccccccccccccccccccccccccccccc200288000000d1dd2222120000000000099af99faaf99fa9900000077700007777077000777000000
22277ccccccccccccccccccccccccccccccccccccccccc2200228000000212221111200000000000099aafa00afaa99000000007777777000770077770000000
44477ccccccccccccccccccccccccccccccccccccccccc4400000000000112221211100000000000000000000000000000000000777000000000777700000000
44447cccccccccccccccccccccccccccccccccccccccc44400000000000021111212000000000000000000000000000000000000070000000000777700000000
444477ccccccccccccccccccccccccccccccccccccccc44400000000000022211112000000000000000000000000000000000000700000000007000770007000
4444477ccccccccccccccccccccccccccccccccccccc4444000000000000111221110000000d2200000000000000000000000007000000000007007070070000
44444477ccccccccccccccccccccccccccccccccccc4444400000000000000111100000000022200000000000000000000000777000000000007000070000000
444444477ccccccccccccccccccccccccccccccccc44444400000000000000111000000000011100000000000000000000000070000000000007000070000000
444444444ccccccccccccccccccccccccccccccc4444444400000000000000000000000000000000000000000000000000007777000000000000777700077000
4444444444444cccccccccccccccccccccccc4444444444400000000000000000000000000000000000000000000000000777770700000000000000000077770
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222220000000000070770700000000000000000070000
22222f222f2222222222222222222222222222222222222222222222222222222222222222222222222222220000000000070000700000000000000000700000
22222ff22ff2222222222f222f2222222222222222222f222f2222222222222222222f222f222222222222220000000000070077700000000000000007000000
22222fffffff222222222ff22ff222222222222222222ff22ff222222222222222222ff22ff22222222222220000000000007777000000000000000000700000
2222fffffffff22222222ff7ffff72222222222222222ff7ffff72222222222222222fffffff2222222222220000000000000000000000000000000007000000
2222ffff0ff0ff222222fff77ff77222222222222222fff77ff77222222222222222fffffffff222222222220000000000000000000000000000000007000000
2222ffff0ff0ff222222fffffff5ff22fff222222222fffffff5ff2222f222222222ffff0ff0ff22222222220000000000000000000000000000007070700000
22288fffff5fff222222fffff707ff25fff222222222fffff707ff22f2f222222222ffff0ff0ff22222222220000000000000000700000000000077700000000
22ff88fff5f5ff2222f88fff0000ff5fff22222222f88fff0000ff22f2f2222222f88fffff5fff22222222220000000000000007770000000000007770000000
2ffff88ffffff8222fff88ff0000ff5ff22222222fff88ff0000ff2f2f2222222fff88fff5f5ff22222222220000000000000077700007077770000777000000
ffffff8888888522fffff88ffffff85222222222fffff88ffffff82f2f222222fffff88ffffff822222222220000000000000077000070077707000077000000
ffffffffaa855ff2fffffff88888852222222222fffffff8888885f2f2222222fffffff888888522222222220000000000000700000000077000000000700000
ffff5ffff22ffff2ffff5fffaa82222222222222ffff5fffaa855ffff2222222ffff5fffaa855ff2222222220000000000007000000000007000000000070000
ffff5ffff222fff2ffff5ffff222222222222222ffff5ffff222ffff22222222ffff5ffff22ffff2222222220000000000070000000000007000000000007000
fff555fff222ff22fff555fff222222222222222fff555fff222ffff22222222fff555fff22ffff2222222220000000000700000000000000000000000000700
2ff552ffff2222222ff552ffff222222222222222ff552ffff222ff2222222222ff552ffff22ff22222222220000000000000000000000000000000000000000
22222222222222222222222222222222222222222222222200000000000000000000000000000000000000000000000000000000000000000000000000000000
22222222222222222222222222222222222222222222222200000000000000000000000000000000000000000000000000000000000000000000000000000000
22222222222222222222222222222222222222222222222200000000000000000000000000000000000000000000000000000000000000000000000000000000
2222222222222222222bb2bbb22222222222bb2bbb2222220000000000000000000000000000000000000c000000000000000000000000000000000000000000
222bb2bbb2222222222bbbbbb22222222222bbbbbb22222200000000000000000000000000000000cc0000c00000000000000000000000000000000000000000
222bbbbbbb22222222b0bb0bbb222222222b0bb0bbb222220000000000000000000000000000000000cc00cc0000000000000000000000000000000000000000
22b0bb0bbbb222222bb0bb0bbbb9922222bb0bb0bbbb999200000000000000000000000000000000000cc00cc00c000000000000700000000000000000000000
2bb0bb0bbbb992222bbbbbbb3bba992222bbbbbbbbbb9992000000000000000000000000000000000000cc0ccc00c00000000000070000000000000000000000
2bbbbbbb3bba99222b333333bbbaa92222bb00bbbbbba922000000000000000000000000000000000000cccccc00cc0000000070077000000000000000000000
2b333333bbbaa9222bbbbbbbbbbaa92222bb00bbbbbbaa220000000000000000000000000000000000000cccccc0ccc000000007007707000000000000000000
22bbbbbbbbaaaab222bbbbbbbbaaaab2222bbbbbbbbaaaab0000000000000000000000000000000000000ccccccc0cc000000007707770700000000000070000
222bbbbbbaaaaab2222bbbbbbaaaaab22222bbbbbbaaaaab00000000000000000000000000000000000000cccccc0cc000000007777770700000000000007000
2222aaaaaa3aabb22222aaaaaa3aabb222222aaaaaa3aabb00000000000000000000000000000000000000cccccc0cc000000007777777770000000000007000
2222aaaaaa3abbb22222aaaaaa3abbb222222aaaaaa3abbb00000000000000000000000000000000000000cccccccccc00000000777777770000000000077070
2222bb3bbbb3bbb22222bb3bbbb3bbb222222bb3bbbb3bbb000000000000000000000000000000000000000ccccccccc00000000777777770000000000077070
22222bb3bbb3bb2222222bb3bbb3bb22222222bb3bbb3bb2000000000000000000000000000000000000000ccccccccc00000000777777770000000000770770
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ccccccccc00000000777777770000000000777770
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ccccccccc00000000777777700000000007777770
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cccccccc000000007777777700000000077777700
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000ccccc0ccc000000007777777000000000770770700
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000cc0cc0c00000000077077070000007777007707000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000cc0cc0c000000007700770700000000077770070000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000c00c0000000000000077000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
22222222222222222222222222777222222222222222222222777222222222222222222222222222227772220000000000000000000000000000000000000000
22222222222222227772222222777222222222227772222222777222222222222222222277722222227772220000000000000000000000000000000000000000
22222222222222277777222227777722222222277777222227777722222222222222222777772222277777220000000000000000000000000000000000000000
22222222222222277777222227777722222222277777222227777722222222222222222777772222277777220000000000000000000000000000000000000000
22222222222222277777222227777722222222277777222227777722222222222222222777772222277777220000000000000000000000000000000000000000
22222222222222277777722227777722222222277777722227777722222222222222222777777222277777220000000000000000000000000000000000000000
22222222222222277777722227777722222222277777722227777722222222222222222777777222277777220000000000000000000000000000000000000000
22222222222222227777722222777722262222227777722222777722222222222222222277777222227777220000000000000000000000000000000000000000
22222222222222227777772222777722262222227777772222777722222222222222222277777722227777220000000000000000000767777777000000000000
22222262222222222777772222777222262222222777772222777222222222622222222227777722227772220000000000000000005776666667750000000000
22222262222222222277772227777222262222222277772227777222222222622222222222777722277772220000000000000000005577666677550000000000
22222262222222222227777727772222262222222227777727772222222222622222222222277777277722220000000000000000005577777775550000000000
22222262222222222225577755772222262222222227777777772222222222622222222222277777777722220000000000000000002555777755550000000000
22222226222222222757777777577222262222222757777757777222222222262222222227755777557772220000000000000000000555555555500000000000
22222226222222227777777777777722262222227775777577777722222222262222222277577777775777220000000000000000000255555555500000000000
22222226222222277777777777777722226222277777575777777722222222262222222777777777777777220000000000000000000022225552000000000000
22222226222222277777777777777722226222277755577555777722222222262222222777555775557777220000000000000000000000000000000000000000
22222222622222777755577555777772226252777770777707777775222222226222227777707777077777720330330000000000000000000000000000000000
22222222622222777777777777777772226225577770777707777752222222226222227777707777077777723033303000000000000000000000000000000000
22222222622255555577eee777555555226222755577eee77755557722222222622255555577eee7775555550033300000000000000055555555000000000000
222222226222277777577e77757777772262277777577e7775777777222222226222277777577e77757777770093390000000000000555550555500000000000
22222222262227555577777777555557226227755577777777555577222222222622275555777777775555570999999000000000000555555550500000000000
22222222262255777757757757777775226227577777757777777755222222222622557777777577777777750999999000000000005555555505550000000000
22222222262222777775575577777772276755777777575777777772222222222622227777775757777777729499999900000000005555555555550000000000
22222222267722277777777777777722277772277777000777777722222222222677222777777777777777224999999900000000005555555555550000000000
22222222277772227777777777777222277772227777000777777222222222222777722277777777777772229999999900000000005555555555550000000000
22222222277772222777777777772222227777222777000777772222222222222777722227777777777722224949999900000000002555555555550000000000
22222222227777222227777777777222222777722227777777777222222222222277772222277777777772229499499900000000000555555555500000000000
2222222222277772227777777777722222277777227777777777722222222222222777722277777777777222494994990aaaa4a0000255555555500000000000
2222222222277777777777777777772222227777777777777777772222222222222777777777777777777722949499944a0aaaa9000022225552000000000000
22222222222277777777777777777772222227777777777777777772222222222222777777777777777777724949494994aaa0a4000000000000000000000000
22222222222222777777777777777772222222777777777777777772222222222222227777777777777777720494949049494949000000000000000000000000
__label__
44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444434444444344
44444000004444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444334444443344
444408888804444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444448ff3ff448ff3ff4
44408888888044444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444448ff666ff8ff666ff
44088888888804444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444448ff2626f8ff2626f
40888877788880444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444448ff4646f8ff4646f
40888878888880444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444448fffffff8fffffff
408888777888804444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444448ff6ff448ff6ff4
40888888788880444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444544444444434444454444
40888877788880444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444499599944444334449959994
4408888888880444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444499f9999948ff3ff499f99999
444088888880444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444449f999f998ff666ff9f999f99
44440888880444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444999999998ff2626f99999999
44444000004444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444999999998ff4646f99999999
44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444999999998fffffff99999999
444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444999999448ff6ff449999994
44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444344444444444444444444444444
44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444443344433333344445444444454444
44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444448ff3ff4335333334445544444455444
4444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444448ff666ff353333534445454444454544
4444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444448ff2626f333533334454454444544544
4444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444448ff4646f3333353347dd454447dd4544
4444444444444444444444444444444444444444444444444444444444444444444444447777744444444444444444448fffffff4335333446dd445446dd4454
44444444444444444444444444444444444444444444444444444444444444444444444477677744444444444444444448ff6ff4443333444555444445554444
44444444444444444444444444444444444444444444444444444444444444444444444476777774444444444444444444444444444444444444444444444444
44444444444444444444444444444444444444444444444444444444444444444444444446776777444444444445444443333334444444444444444444444333
4444444444444444444444444444444444444444444444444444444444444444444444447676777744444444444554443353333344544444444444d4444bbb3b
4444444444444444444444444444444444444444444444444444444444444444444bb4bb67677767444444444445454435333353445a444444444ad444b33333
4444444444444444444444444444444444444444444444444444444444444444444bbbbbb67666774444444444544544333533334499aaaaaaaaa9944b333333
444444444444444444444444444444444444444444444444444444444444444444b0bb0bbb6747774444444447dd45443333353344999aaaaaaa9994b3bbbbbb
44444444444444444444444444444444444444444444444444444444444444444bb0bb0bbbb994444444444446dd4454433533344449999999999944bb333333
44444444444444444444444444444444444444444444444444444444444444444bbbbbbb3bba99444444444445554444443333444444999999999444bbbb3b33
44444444444444444444444444444444444444444444444444444444444444444b333333bbbaa9444444444444444444444aaaaaaaa444444445444433333333
44444444444444444444444444444444444444444444444444444444444444444bbbbbbbbbbaa944444444444333333444a7aaaaaaa9444449959994b3333333
444444444444444444444444444444444444444444444444444444444444444444bbbbbbbbaaaab4444444443353333349aaaaaaaaaa994499f999994bbb3333
4444444444444444444444444444444444444444444444444444444444444444444bbbbbbaaaaab4444444443533335399aaaaaaaaaaa9229f999f994433bb3b
44444444444444444444444444444444444444444444444444444444444444444444aaaaaa3aabb44444444433353333b9aaa9aaaaa999249999999944433333
44444444444444444444444444444444444444444444444444444444444444444444aaaaaa3abbb44444444433333533bb999aaa999999449999999944444bb3
44444444444444444444444444444444444444444444444444444444444444444444bb3bbbb3bbb444444444433533344b999999999944449999999944444444
444444444444444444444444444444444444444444444444444444444444444444444bb3bbb3bb44444444444433334444bbbb9bb94444444999999444444444
44444444444444444444444444444444444444444444444444444444444444449999999999999999999999999999999999999999999999999999999999999999
44444444444444444444444444444444444444444444444444444444444444449999999999999999999999999999999999999999999999999999999999999999
44444444444444444444444444444444444444444444444444444444444444449999999999999999999999999999999999999999999999999999999999999999
44444444444444444444444444444444444444444444444444444444444444449999999999999999999999999999999999999999999999999999999999999999
44444444444444444444444444444444444444444444444444444444444444444449994444444444444999444444444444499944444444444449994444444444
44444444444444444444444444444444444444444444444444444444444444444499999444499944449999944449994444999994444999444499999444499944
44444444444444444444444444444444444444444444444444444444444444444999999944999994499999994499999449999999449999944999999944999994
44444444444444444444444444444444444444444444444444444444444444444999999949999999499999994999999949999999499999994999999949999999
44444444444444444444444444444444444444444444444444444444444444444999999949999999499999994999999949999999499999994999999949999999
44444444444444444444444444444444444444444444444444444444444444444499999449999999449999944999999944999994499999994499999449999999
44444444444444444444444444444444444444444444444444444444444444444449994444999994444999444499999444499944449999944449994444999994
44444444444444444444444444444444444444444444444444444444444444444444444444499944444444444449994444444444444999444444444444499944
44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
44444444444444444444444444444444444444444444444444444444499999999999999999999999999999999999999999999999999999999999999444444444
44444444444444444444444444444444444444444444444444444444999999999999999999999999999999999999999999999999999999999999999944444444
44444444444444444444444444444444444444444444444444444444993333333333333333333333333333333333333333333333333333333333339944444444
44444444444444444444444444444444444444444444444444444444993333333333333333333333333333333333333333333333333333333333339944444444
44444444444444444444444444444444444444444444444444444444993333333333333333333333333333333333333333333333333333333333339944444444
44444444777774444444444444444444444444444444444444444444993333333333333333333333333333333333333333333333333333333333339944444444
44444447776774444444444444444444444444444444444444444444993333377373737773737377733733377333333773737377737773377333339944444444
44444477777674444444444444444444444444444444444444444444993333733373733733737337337333733333337333737373337333733333339944444444
44444777677644444444444444444444444444444444444444444444993333733377733733773337333333777333337333777377337733777333339944444444
44444777767674444444444444444444444444444444444444444444993333733373733733737337333333337333337333737373337333337333339944444444
4444476777676f444444444444444444444444444444444444444444993333377373737773737377733333773333333773737377737333773333339944444444
444447766676fff44444444444444444444444444444444444444444993333333333333333333333333333333333333333333333333333333333339944444444
44444777f76fffff4444444444444444444444444444444444444444993333333333333333333333333333333333333333333333333333333333339944444444
4444444ffff0ff0ff444444444444444444444444444444444444444993333333333333333333333333333333333333333333333333333333333339944444444
4444444ffff0ff0ff444444444444444444444444444444444444444993333333333333333333333333333333333333333333333333333333333339944444444
44444488fffff5fff444444444444444444444444444444444444444993333333333333333333333333333333333333333333333333333333333339944444444
44444ff88fff5f5ff4444444444444444444444444444444444444449933333333aaa3aaa3aaa33aa33aa333333aaaaa333333aaa33aa3333333339944444444
4444ffff88ffffff84444444444444444444444444444444444444449933333333a3a3a3a3a333a333a3333333aa3a3aa333333a33a3a3333333339944444444
444ffffff888888854444444444444444444444444444444444444449933333333aaa3aa33aa33aaa3aaa33333aaa3aaa333333a33a3a3333333339944444444
444ffffffffaa855ff444444444444444444444444444444444444449933333333a333a3a3a33333a333a33333aa3a3aa333333a33a3a3333333339944444444
444ffff5ffff44ffff444444444444444444444444444444444444449933333333a333a3a3aaa3aa33aa3333333aaaaa3333333a33aa33333333339944444444
444ffff5ffff444fff44444444444444444444444444444444444444993333333333333333333333333333333333333333333333333333333333339944444444
444fff555fff444ff44444444444444444444444444444444444444499333333333333333333333aa3aaa3aaa3aaa3aaa3333333333333333333339944444444
4444ff554ffff44444444444444444444444444444444444444444449933333333333333333333a3333a33a3a3a3a33a33333333333333333333339944444444
999999999999999944444444444444444444444444444444444444449933333333333333333333aaa33a33aaa3aa333a33333333333333333333339944444444
99999999999999994444444444444444444444444444444444444444993333333333333333333333a33a33a3a3a3a33a33333333333333333333339944444444
999999999999999944444444444444444444444444444444444444449933333333333333333333aa333a33a3a3a3a33a33333333333333333333339944444444
99999999999999994444444444444444444444444444444444444444993333333333333333333333333333333333333333333333333333333333339944444444
44499944444444444444444444444444444444444444444444444444993333333333333333333333333333333333333333333333333333333333339944444444
44999994444999444444444444444444444444444444444444444444993333333333333333333333333333333333333333333333333333333333339944444444
49999999449999944444444444444444444444444444444444444444993333333333333333333333333333333333333333333333333333333333339944444444
49999999499999994444444444444444444444444444444444444444993333377377737773377377737773333333333333333333333333333333339944444444
49999999499999994444444444444444444444444444444444444444993333737373337333733373333733373333333333333333333333333333339944444444
44999994499999994444444444444444444444444444444444444444993333737377337733777377333733333333333333333333333333333333339944444444
44499944449999944444444444444444444444444444444444444444993333737373337333337373333733373333333333333333333333333333339944444444
44444444444999444444444444444444444444444444444444444444993333773373337333773377733733333333333333333333333333333333339944444444
44444444444444444444444444444444444444444444444444444444993333333333333333333333333333333333333333333333333333333333339944444444
44444444444444444444444444444444444444444444444444444444993333377777333333777377733333777337733333377777333333333333339944444444
44444444444444444444444444444444444444444444444444444444993333777337733333737373733333777373333333773377733333333333339944444444
44444444444444444444444444444444444444444444444444444444993333773337733333777373733333737377733333773337733333333333339944444444
44444444444444444444444444444444444444444444444444444444993333777337733333337373733333737333733333773377733333333333339944444444
44444444444444444444444444444444444444444444444444444444993333377777333333337377733333737377333333377777333333333333339944444444
44444444444444444444444444444444444444444444444444444444993333333333333333333333333333333333333333333333333333333333339944444444
44444444444444444444444444444444444444444444444444444444993333333333333333333333333333333333333333333333333333333333339944444444
44444444444444444444444444444444444444444444444444444444993333333333333333333333333333333333333333333333333333333333339944444444
44444444444444444444444444444444444444444444444444444444993333737377733333377337733773777377733333333377337773333333339944444444
44444444444444444444444444444444444444444444444444444444993333737337333333733373337373737373333733333337333373333333339944444444
44444444444444444444444444444444444444444444444444444444993333777337333333777373337373773377333333333337333373333333339944444444
44444444444444444444444444444444444444444444444444444444993333737337333333337373337373737373333733333337333373333333339944444444
44444444444444444444444444444444444444444444444444444444993333737377733333773337737733737377733333333377733373333333339944444444
44444444444444444444444444444444444444444444444444444444993333333333333333333333333333333333333333333333333333333333339944444444
44444444444444444444444444444444444444444444444444444444993333333333333333333333333333333333333333333333333333333333339944444444
44444444444444444444444444444444444444444444444444444444993333333333333333333333333333333333333333333333333333333333339944444444
44444444444444444444444444444444444444444444444444444444993333333333333333333333666666666666666633333333333333333333339944444444
44444444444444444444444444444444444444444444444444444444999999999999999999999999666666666666666699999999999999999999999944444444
44444444444444444444444444444444444444444444444444444444499999999999999999999999666666666666666699999999999999999999999444444444
44444444444444444444555555555555555555555555555554444444444444444444444444999944444444999944444444999944444444444444444444444444
44444444444445555555555555555555555555555555555555555555444444444444444444999944444444999944444444999944444444444444444444444444
44444444444455555555555555555555555555555555555555555555544444444444444449999444444444999944444444499994444444444444444444444444
44444444444477666655555555555555555555555555555555666666644444444444444449999444444444999944444444499994444444444444444444444444
44444444444477666666666655555555555555555556666666666666644444444444444449999444444444999944444444499994444444444444444444444444
44444444444477666666666666666666666666666666666666666666644444444444444499994444444444999944444444449999444444444444444444444444
44444444444477666666666666666666666666666666666666666666644444444444444499994444444444999944444444449999444444444444444444444444
44444444444447766666666666666666666666666666666666666666444444444444444499994444444444999944444444449999444444444444444444444444
44444444444447766666666666666666666666666666666666666666444444444444444999944444444444999944444444444999944444444444444444444444
44444444444444766666666666666666666666666666666666666664444444444444444999944444444444999944444444444999944444444444444444444444
44444444444444776666666666666666666666666666666666666664444444444444449999444444444444999944444444444499994444444444444444444444
44444444444444477666666666666666666666666666666666666644444444444444449999444444444444999944444444444499994444444444444444444444
44444444444444447766666666666666666666666666666666666444444444444444449999444444444444999944444444444499994444444444444444444444
44444444444444444776666666666666666666666666666666664444444444444444499994444444444444999944444444444449999444444444444444444444
44444444444444444446666666666666666666666666666666444444444444444444499994444444444444999944444444444449999444444444444444444444
44444444444444444444444666666666666666666666666444444444444444444444999944444444444444999944444444444444999944444444444444444444

__map__
00000000000000000000000000000b0b0b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000003b0b3b0b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000b1706060b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000006171011040b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000001707083b140b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000002030203020302030b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000012131213121312130b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000002223232323232324000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000003233333333333334000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000003233333333333334000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
020300000000003233333333333334000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
121300000000003233333333333334000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000003233333333333334000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000004243434343434344000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100000e6510e0502e0502905024050200501d0501a0501605014050110500f0500d0500c0500b0500a05009050080500705007050090500a0500c050013000230002300033000330003300033000230001300
01010000159501c930159501f930001002195020950229501e950229502295021950209501b950199501295000100001000010000100001000010000100001000010000100001000010000000000000000000000
0101000027a5028a5029a701fa6008a0000a0036a0036a0031a002ea002aa0023a002ca002ca0000a0000a0000a0000a0000a0001a0001a0002a0000100001000010000100001000010000100001000010000100
011000001f1551f1551f1551f1551c1551c1551c1551c1551a1551a1551a1551a1551c1551a1551f1551f15500000000000000000000000000000000000000000000000000000000000000000000000000000000
011000001f5551f5551f5551f5551c5551c5551c5551c5551a5551a5551a5551a5551c5551a5551f5551f55500500005000050000500005000050000500005000050000500005000050000500005000050000500
011000001f1551f1551f1551f1551d1551d1551d1551d1551a1551a1551a1551a1551d1551a1551f1551f15500000000000000000000000000000000000000000000000000000000000000000000000000000000
011000001f1551f1551f1551f1551d1551d1551d1551d1551a1551a1551a1551a1551d1551a1551f1551f15500000000000000000000000000000000000000000000000000000000000000000000000000000000
011000001f1551f1551f1551f1551c1551c1551c1551c1551a1551a1551a1551a1551c1551a1551f1551f15500000000000000000000000000000000000000000000000000000000000000000000000000000000
011000001f1551f1551f1551f1551c1551c1551c1551c1551a1551a1551a1551a1551c1551a1551f1551f15500000000000000000000000000000000000000000000000000000000000000000000000000000000
011000001f1551f1551f1551f1551d1551d1551d1551d1551a1551a1551a1551a1551d1551a1551f1551f15500000000000000000000000000000000000000000000000000000000000000000000000000000000
011000001f1551f1551f1551f1551d1551d1551d1551d1551a1551a1551a1551a1551d1551a1551f1551f15500000000000000000000000000000000000000000000000000000000000000000000000000000000
01100000215551f1551f5551f1551c5551f555215551f555215551f1551f5551f1551c1551a1551a5551c15500100000000000000000000000000000000000000000000000000000000000000000000000000000
01100000215551f1551f5451f1451c5551f555215551f555215551f1551f5551f1551c1551a1551a5551c15500000000000000000000000000000000000000000000000000000000000000000000000000000000
011000001d5451c1451d5551c1551d5551f5551d5551c5551d5551c1551d5551c1551d1551f1551d5551c15500000000000000000000000000000000000000000000000000000000000000000000000000000000
011000001c5551a1551c5551a1551c5551a5551c5551a5551f5551c1551c5551a1551a1551c1551a5551c1551a000010000100001000010000100001000010000100001000010000100001000010000100001000
01100000215551f1551f5551f1551c5551f555215551f555215551f1551f5551f1551c1551a1551a5551c15500100000000000000000000000000000000000000000000000000000000000000000000000000000
01100000215551f1551f5451f1451c5551f555215551f555215551f1551f5551f1551c1551a1551a5551c15500000000000000000000000000000000000000000000000000000000000000000000000000000000
011000001d5451c1451d5551c1551d5551f5551d5551c5551d5551c1551d5551c1551d1551f1551d5551c15500000000000000000000000000000000000000000000000000000000000000000000000000000000
011000001c5551a1551c5551a1551c5551a5551c5551a5551f5551c1551c5551a1551a1551c1551a5551c1551a000010000100001000010000100001000010000100001000010000100001000010000100001000
91100000241753c105301750c1053c1750c1052417530105301750c1052417530105301750c1053c1750c105241750c105301750c1053c1750c105241750c105301750c105241750c105301750c1053c1750c105
0110100000873186353761537615008733761537615246150087324615376151863500873246152b6153761518600186001860018600000001860018600000000000000000000000000000000000000000000000
01101000186351863537615376152461500200186350c2001863537605376151863524615246152b6153761518622186151861518613000001861318613000000000000000000000000000000000000000000000
0110100000853186351f6001f6152460018625008430c200246353760524600186253760018622186151861518613000001861318613000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0110100000873186353761537615008733761537615246150087324615376151863500873246152b6153761518622186151861518613000001861318613000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1920080013155101500c15513155101500c15513155101551315511150111551315511155131051315511155101550c1500c155101551115513105101550c155101550e1500e155101550e15513105131550e155
1920080013155111500c15513155111500c14013155111551315511150111551315511155131051315511155101550c1500c155101551115513105101550c155101550e1500e155101550e15513105131550e155
0120080009155101501315510155151560c146151360c1261315511150111551315511155131051315511155101550c1500c155101551115513105101550c155101550e1500e155101550e15513105131550e155
01200800071550e150131550e155171560e146171360e1261315511150111551315511155131051315511155101550c1500c155101551115513105101550c155101550e1500e155101550e15513105131550e155
0120080005155101500c155111550c156111460c136111261315511150111551315511155131051315511155101550c1500c155101551115513105101550c155101550e1500e155101550e15513105131550e155
01200800071550e1551015513155171560e146171360e1260f15511150111551315511155131051315511155101550c1500c155101551115513105101550c155101550e1500e155101550e15513105131550e155
2920080007155041500015507155041500015507155041551315511150111551315511155131051315511155101550c1500c155101551115513105101550c155101550e1500e155101550e15513105131550e155
2920080007155051500015507155051500014007155051551315511150111551315511155131051315511155101550c1500c155101551115513105101550c155101550e1500e155101550e15513105131550e155
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000001895318953189531895318953189531895318953189531895318953189531895318953189531895318953189531895318953189531895318953189531895318953189531895318953189531895318953
0110000018a5318a5318a5318a5318a5318a5318a5318a5318a5318a5318a5318a5318a5318a5318a5318a5318a5318a5318a5318a5318a5318a5318a5318a5318a5318a5318a5318a5318a5318a5318a5318a53
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0004000037050310502b0502705023050200500000000000000000000000000000000000000000000000000000000000000000000050000000000000000000000000000000000000000000000000000000000000
000400002c0502f050340503b0503d05000000000000000000000000000000000000000000000000000000000000000000000000b050000000000000000000000000000000000000000000000000000000000000
__music__
01 15434040
01 141f0329
00 141f042a
00 14200529
00 1420062a
00 141f0729
00 141f082a
00 14200929
00 14200a2a
00 16210b29
00 16220c2a
00 16230d29
00 16240e2a
00 16210f29
00 1622102a
00 16231129
00 1624122a
01 14250329
00 1425042a
00 14260529
00 1426062a
00 14250729
00 1425082a
00 14260929
00 14260a2a
00 16210b29
00 16220c2a
00 16230d29
00 16240e2a
00 16210f29
00 1622102a
00 16231129
02 1624122a

