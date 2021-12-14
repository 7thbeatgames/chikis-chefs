luapico-8 cartridge // http://www.pico-8.com
version 34
__lua__


-- consts
lost = 0
win = 1
perfect = 2

-- vars
endingtype = 0 

function _init()
	params = stat(6)

	if params == "perfect" then
		endingtype = perfect
	else 
		endingtype = win
	end

	endingtype = perfect
end

function _update60()

end

function _draw()

	drawperfect()	
end

function drawperfect()

	cls(4)
	tick = stat(50)
	-- printh(tick)
	headbob = time() * 1.5 % 1 < 0.25

	--print("file 1")
	--str = stat(6)
	--print("param -> " .. str)

	-- floor
	rectfill(0,64,128, 128, 2)
	fillp(0b0101101001011010.1)
	rectfill(0,64,128, 128, 1)
	fillp()

	-- cake base
	wbase = 7 * 8 + 2
	hbase = 2 * 8
	xbase = 61 - wbase / 2
	ybase = 77 - hbase / 2
	ovalfill(xbase, ybase, xbase + wbase, ybase + hbase, 1)

	-- cake
	spr(136, 30, 45, 8, 6)

	-- fruits in case of perfect
	if endingtype == perfect then
		spr(96, 64, 50, 1, 1)
		spr(97, 54, 50, 1, 1)
		spr(98, 58, 45, 1, 1)
		spr(99, 49, 45, 1, 1)
		spr(100, 74, 48, 1, 1)
		spr(112, 64, 48, 1, 1)
		spr(113, 44, 53, 1, 1)
		spr(114, 42, 48, 1, 1)
		spr(115, 58, 48, 1, 1)
	end

	-- candles
	xcandles = {60, 70, 50, 45, 58}
	ycandles = {40, 45, 43, 43, 44}

	for i = 1, #xcandles do
		xcandle = xcandles[i]
		ycandle = ycandles[i]
		spr(64 + time() * 4 % 4, xcandle,ycandle,1,2)
	end



	-- text
	print("happy birthday david!\n thanks for playing", 21, 25, 7)

	yoffset = 10

	-- cat
	altrender(true)
	sprcat = headbob and 230 or 228
	spr(sprcat, 15, 60 + yoffset, 2, 2)
	altrender(false)

	-- frog
	altrender(true)
	sprrabbit = headbob and 224 or 226
	spr(sprrabbit, 10, 85 + yoffset, 2, 2)
	altrender(false)

	-- rabbit
	altrender(true)
	sprfrog = headbob and 192 or 194
	spr(sprfrog, 30, 75 + yoffset, 2, 2, true)
	altrender(false)

	-- chiki
	altrender(true)
	sprchiki = headbob and 160 or 162
	spr(sprchiki, 85, 75 + yoffset, 2, 2, true)
	altrender(false)

end


function altrender(set)
	palt(2, set)
	palt(0, not set)
end


__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000022222222222222222d2222200000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000022222222222222222222222222222222222220000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000222222d2222222d22222222d22222222dd2222222220000000000
000000000000000000000000000000000000000000000000000000000000000000000000002222d2222222222222222222222222222222222222222000000000
00000000000000000000000000000000000000000000000000000000000000000000000000422222222222222222222222222222222222d22222224000000000
00000000000000000000000000000000000000000000000000000000000000000000000000444422222222222222222222222222222222222224444000000000
00000000000000000000000000000000000000000000000000000000000000000000000000444444444444222222222222222222222244444444444000000000
00000000000000000000000000000000000000000000000000000000000000000000000000744444444444444444444444444444444444444444444000000000
00000000000000000000000000000000000000000000000000000000000000000000000000774477444444444444444444444444444444444444447000000000
00000000000000000000000000000000000000000000000000000000000000000000000000f77777444444444474444444444444444444444444447000000000
0000000000000000000000000000000000000000000000000000000000000000000000000077777774444444777774444477444444477444477447f000000000
00000000000000000000000000000000000000000000000000000000000000000000000000774777774444477777774477777444447777447777777000000000
00000000000000000000000000000000000000000000000000000000000000000000000000777777777444777777777777777444477777777747774000000000
000000000000000000000000000000000000000000000000000000000000000000000000006777f77777777777777777777f7744777f77777777776000000000
00000000000000000000000000000000000000000000000000000000000000000000000000766677777777777777774777777777777777777776667000000000
0000000000000000000900000000000000000000000000000000000000000000000000000074776f66666777777477777777777777776666666777f000000000
0000090000090000009900000009000000000000000000000000000000000000000000000047777777777666666666666666666666667777777777f000000000
0009900000990000009a0000009a9000000000000000000000000000000000000000000000777777777777f77777777777777777747777777777777000000000
000a900000a90000009a000000aa9000000000000000000000000000000000000000000000f77777777777477777777777777777777777777747777000000000
000e0000000e0000000e0000000e0000000000000000000000000000000000000000000000777777477f77777777777777777f77777777777777777000000000
0006000000060000000600000006000000000000000000000000000000000000000000000067777777777777777f777747777777777777777777776000000000
000e0000000e0000000e0000000e0000000000000000000000000000000000000000000000766677777777777777777777747777777774777776667000000000
00060000000600000006000000060000000000000000000000000000000000000000000011777766666667777777777777777777777766666667777100000000
000e0000000e0000000e0000000e0000000000000000000000000000000000000000011111777777777776666666666666666666666677777777777111100000
0006000000060000000600000006000000000000000000000000000000000000000111111117777f777777777777777777777777777774777777771111111000
000e0000000e0000000e0000000e0000000000000000000000000000000000000001111111111177777477777747777747777777777777777771111111111000
000000000000000000000000000000000000000000000000000000000000000000000111111111111111177777f777777477ff77777711111111111111100000
00000000000000000000000000000000000000000000000000000000000000000000000011111111111111111111111111111111111111111111111100000000
00000000000000000000000000000000000000000000000000000000000000000000000000001111111111111111111111111111111111111111000000000000
00aff000000000000000800000000000000000000000000000000000000000000000000000000000000011111111111111111111111100000000000000000000
0f999f00000000000008800000666000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
09f99700770000000881800000661000fffffff00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
097779007777000018881000061660008fffff800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0a9ff900f77777008818800006666000088888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00aa9f000f777f008888800006160000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000fff0000888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000a99000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00aaa4a000777000a01099900000dd00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0a0aaaa007667700910999a00000dd00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0499a0a00767670009999a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000007770000aaa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
22222222222222222222222222222222222222222222222222222222222222220000000000000000000000000000000000000000000000000000000000000000
22222222222222222222227777722222222222222222222222222277777222220000000000000000000006000006000007000060000000000000000000000000
22222277777222222222277777772222222222777772222222222777777722220000000000000000600067600077600077600676000600060000000000000000
22222777777722222222777777777222222227777777222222227777777772220000000000060006766777766777766677760677760600676000000000000000
22227777777772222227777707707222222277777777722222277777077072220000000000676006777677767666667777776777776760677606000000000000
22277777077072222222777707707222222777770770722222227777077072220000000000677667776766677777776677667667777776777767600000000000
22227777077072222222777777aaaa2222227777077072222222777777aaaa22000000000767777666777777777d777777777776676666667767767000000000
2222777777aaaa2222227777775aaa222222777777aaaa2222227777775aaa22000000007676666777d777777d777777777777777777777d6667767000000000
22227777775aaa22227767777775aa2222227777775aaa22227767777775aa22000000006766667777777777777777777777d7777777dd777766667700000000
227767777775aa2227777667777d2222227767777775aa2227777667777d2222000000067767667d7777777777777d7777777777777777777776666600000000
27777667777d22222277777666d6222227777667777d22222277777666d622220000000677767677777777777777d77777777777777777d77777667600000000
2277777666d6222222277777777722222277777666d6222222277777777722220000000776677666777777777777777777777777777777777767667700000000
2227777777772222222222aa777222222227777777772222222224777772222200000007677777676777777d7777777777777777777777777676677700000000
22222a777772222222222aa2422222222222447777722222222244aa22222222000000067777667767677777777777d7777777d7777777676776777600000000
2222aa2242222222222222aa222222222222244aa222222222224aa2222222220000000767767777767677767777767777767d7776d776767777676700000000
2222aaa4aa22222222222224422222222222222aaa22222222222aaa222222220000000776767776677677676777676777676777676767767776667700000000
22222222222228282222222222222828222222222222222222222222222222220000000777776767777766776766776d66776766777677776677677700000000
22222222222228882222222777772888222222222222222222222222222222220000000777777767776777777677777677777677777677677777777700000000
22222227777722822222227777777282222222222222222222222222222222220000000777777776677677776777766777766777776766777777777700000000
22222277777772222222277777777722222222222222222222222222222222220000000277777777777766677667777677677667777777777777777200000000
22222777777777222222777770777022222222222222222222222222222222220000000427777777777777777777777776777777777777777777772400000000
22227777707770222222277707070722222222222222222222222222222222220000000442227777777777777777777777777777777777777772224400000000
222227770707072222222777777aaaa2222222222222222222222222222222220000000444442227777777777777777777777777777777772224444400000000
22222777777aaaa2222227777775aaa2222222222222222222222222222222220000000444444442222222777777777777777777722222224444444400000000
277727777775aaa22222267777775aa2222222222222222222222222222222220000000444444444444444222222222222222222244444444444444400000000
2777767777775aa2222777667777d622222222222222222222222222222222220000000f44444444444444444444444444444444444444444444444f00000000
227777667777d62222777777666d6662222222222222222222222222222222220000000ff444444444444444444444444444444444444444444444ff00000000
22277777666d622227777777777772622222222222222222222222222222222200000004ffff444444444444444444444444444444444444444ffff400000000
2222777777777222277277777777722222222222222222222222222222222222000000044ffffff444444444444444444444444444444444ffffff4400000000
222222a777772222222222a777772222222222222222222222222222222222220000000444ffffffffffff4444444444444444444ffffffffffff44400000000
22222aa22442222222222aa2244222222222222222222222222222222222222200000004444444ffffffffffffffffffffffffffffffffff4444444400000000
22222aaa2aaa222222222aaa2aaa2222222222222222222222222222222222220000000444444444444444fffffffffffffffffff44444444444444400000000
22222222222222222222222222222222222222222222222222222222222222220000000044444444444444444444444444444444444444444444444000000000
22222222222222222222222222222222222222222222222222222222222222220000000004444444444444444444444444444444444444444444440000000000
22222222222222222222222222222222222222222222222222222222222222220000000000004444444444444444444444444444444444444440000000000000
2222222222222222222bb2bbb2222222222222222222222222222222222222220000000000000004444444444444444444444444444444440000000000000000
222bb2bbb2222222222bbbbbb2222222222222222222222222222222222222220000000000000000000000444444444444444444400000000000000000000000
222bbbbbbb22222222b0bb0bbb222222222222222222222222222222222222220000000000000000000000000000000000000000000000000000000000000000
22b0bb0bbbb222222bb0bb0bbbb99222222222222222222222222222222222220000000000000000000000000000000000000000000000000000000000000000
2bb0bb0bbbb992222bbbbbbb3bba9922222222222222222222222222222222220000000000000000000000000000000000000000000000000000000000000000
2bbbbbbb3bba99222b333333bbbaa922222222222222222222222222222222220000000000000000000000000000000000000000000000000000000000000000
2b333333bbbaa9222bbbbbbbbbbaa922222222222222222222222222222222220000000000000000000000000000000000000000000000000000000000000000
22bbbbbbbbaaaab222bbbbbbbbaaaab2222222222222222222222222222222220000000000000000000000000000000000000000000000000000000000000000
222bbbbbbaaaaab2222bbbbbbaaaaab2222222222222222222222222222222220000000000000000000000000000000000000000000000000000000000000000
2222aaaaaa3aabb22222aaaaaa3aabb2222222222222222222222222222222220000000000000000000000000000000000000000000000000000000000000000
2222aaaaaa3abbb22222aaaaaa3abbb2222222222222222222222222222222220000000000000000000000000000000000000000000000000000000000000000
2222bb3bbbb3bbb22222bb3bbbb3bbb2222222222222222222222222222222220000000000000000000000000000000000000000000000000000000000000000
22222bb3bbb3bb2222222bb3bbb3bb22222222222222222222222222222222220000000000000000000000000000000000000000000000000000000000000000
22222222222222222222222772772222222222222222222222222222222222220000000000000000000000000000000000000000000000000000000000000000
22222227727722222222222772772222222222f222f2222222222222222222220000000000000000000000000000000000000000000000000000000000000000
22222227727722222222222772772222222222ff22ff2222222222f222f222220000000000000000000000000000000000000000000000000000000000000000
22222227727722222222222777777222222222fffffff222222222ff22ff22220000000000000000000000000000000000000000000000000000000000000000
2222222777777222222222777777772222222fffffffff22222222fffffff2220000000000000000000000000000000000000000000000000000000000000000
2222227777777722222222777077077222222ffff0ff0ff222222fffffffff220000000000000000000000000000000000000000000000000000000000000000
2222227770770772222222777077077222222ffff0ff0ff222222ffff0ff0ff20000000000000000000000000000000000000000000000000000000000000000
22222277707707722222227777774472222288fffff5fff222222ffff0ff0ff20000000000000000000000000000000000000000000000000000000000000000
22222277777744722222277777677772222ff88fff5f5ff2222f88fffff5fff20000000000000000000000000000000000000000000000000000000000000000
2662777777677772266277777776772222ffff88ffffff8222fff88fff5f5ff20000000000000000000000000000000000000000000000000000000000000000
666777777776772266677777777772222ffffff8888888522fffff88ffffff820000000000000000000000000000000000000000000000000000000000000000
667777777777722266777777777722222ffffffffaa855ff2fffffff888888520000000000000000000000000000000000000000000000000000000000000000
267777777766622226777777776662222ffff5ffff22ffff2ffff5fffaa855ff0000000000000000000000000000000000000000000000000000000000000000
227777777776662222777777777666222ffff5ffff222fff2ffff5ffff22ffff0000000000000000000000000000000000000000000000000000000000000000
222777667777666222277766777766622fff555fff222ff22fff555fff22ffff0000000000000000000000000000000000000000000000000000000000000000
2227776667776662222777666777666222ff552ffff2222222ff552ffff22ff20000000000000000000000000000000000000000000000000000000000000000
__sfx__
0001000010050120501405015050160501705017050180501205019050150501b0501c050180501e0501f0501c050210502205024050260502705029050240502a0502c0502d0502e0502f050310503205036050
__music__
00 00424344

