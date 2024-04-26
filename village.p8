pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
function _init()

end
function _draw()
	cls(0)
day=split("1,2,3,4,5,6,7,8,9,10,11,12,13,-4,15")
sea_pal=split("14,2,3,4,5,6,7,8,9,10,11,12,13,-4,15")
	pal(sea_pal,1)
	palt(0,false)
	palt(1,true)
	poke(0x5f2e ,1)
	map()
end
__gfx__
000000001111000000001111111110000001111144499444005555605000000000000000000000051111111001111111111111115353333333333b3b00000000
0000000011503bbbbbb305111110099997700111444049440d6656010b33b33b3b33b33b3b33b33011111106d0111111b311b3b135313333331333b300000000
00700700153bbbbb76bbbb5111099aaa77a970114407049410d6501100030330000303300003033011111106601111113b3b3b3b533333333333333b00000000
00077000103bbbb6777bbb011099a449944777014406029910d67011222020042220200222202000111110056001111133333333333333333333333300000000
0007700003bbbbb7776bbb30109a997799797901905670291105011142224229944242299442444f111004449f90011133333133333333333333333300000000
0070070003bbbbbb67bbbbb004a9977997774a9090dd6024110601114424444499444444994444ff110f4ff4f9f9901133333333333333333333333300000000
0000000003bbbbbbbbb67bb004a9779977794a9005dd6702111011112444444449944444499444ff10f4ff4fff9fff0131333333333333333333333300000000
0000000003bbbbbbbbb76bb004a7799777994a9005ddd602111111112249444444994444449944ff104ff4f44ffff90133333333333333333333333300000000
1111111103bbbbbbbbbbbbb00977997779994a9044499444444994442229944444499444444994ff102f44fffff9f40111111111111111119911111100000000
11111111033bbbbbbbbbbbb00999977799a94a9044449944444499442224994444449944444499ff1102f4fffff94401b1111111111111351144119900000000
11111111033bbbbbbbbbbbb0049977799a994a90444449a4444449942224499444444994444449af110ff444ff4ff4f03b311111111113534449a11100000000
111111110333bbbbbbbbbb3010977799a999a901444444aa224444992224449944444499444444aa1024f4fff44ff420b3b1111111113535144a911100000000
1111111103333bbbbbbbb33010977999999a9901944444fa422444494224444994444449944444fa024ff4ffff4f4f013b3b311111115153114a791100000000
11111111053333333333335011094aaaaaa99011994444ff442444444424444499444444994444ff05444f4ff4f4ff2033b3b31111353533494aea1100000000
1111111110553333333355011110044444400111499444ff244444442444444449944444499444ff105454444445ff01313b3b31115353331111144100000000
1111111111000000000000111111100000011111449944ff224944442249444444994444449944ff11000000000000113333b3b1153533311441119400000000
1110111011000011111111111111111111111111444994f0004994442249944444499444444994ff111111100111111100000000000000004411111100000000
010101011049aa511110011111111111111111114444990b330499442244994444449944444499ff11111103b011111100000000000000001144114900000000
1010101004997790110994111111111111111911444444033b3049942224299224422992244229af111111033011111100000000000000004994a11100000000
010101010499979010497901111111111111941144444420030444992222124412221244122212aa1111100530011111000000000000000014449a1100000000
000000005499999015449901111111111119411194444449402444491241124112411221124112f11110044449a001110000000000000000114a791100000000
00000000544999401154401111111111119401119944444494444444121112111211121112111211110949949a9aa0110000000000000000444aea1100000000
000000001544440111150111111111111941011149944444499444441111111111111111111111111094994999a9aa0100000000000000001111144100000000
000000001155001111111111111111114411011144994444449944441111111111111111111111110949949999999aa000000000000000001491114900000000
00000000111111111111111111115514211011111111111105ddd60110010010010010010010010009499499999a949011111111111111114411111100000000
00000000111111111111111111115642111011111110111105dd670104904904904904904904904909499499999a949011111111111111111199119400000000
00000000111041111111111111116621111011111107011110dd6011044044044044044044044044044994999949949011111111111111114444a11100000000
0000000011097411111141111112440111011111110601111056701110010010010010010010010004449499994994901111113311111111199a9a1100000000
0000000011549011111594111111211000111111105670111106011111111111111111111111111104449499994949901131133311311131114a7a1100000000
000000001115011111115111111111111111111110dd601111070111111111111111111111111111054449499494999013311331113111314449ea1100000000
000000001111111111111111111111111111111105dd670111101111111111111111111111111111105454444445990113313331113131311111199100000000
000000001111111111111111111111111111111105ddd60111111111111111111111111111111111110000000000001113313311313133331941114400000000
50000000000000000000000550000005555555555555555550000000000000000000000599494999111111111111116666111111111111115555555544499444
07767776677767766777677007766670555555555555555507999999499999994999994094999994111111111111116666111111111111115445544544499444
0d65666556665665566657700d655670555655555555555509444444444444444444445049555559111111111166661661666611111111114444444444444444
0d65555555555555555555600d655560555555665665565540000000000000000000000949555554111111111666666666666661111111114554455499999999
0055655d555655655555577000555670555555665665555554444444444444444444494949555554111111116666666666666666111111115555555599999999
0d65555555555555556557700d655670555665555555555545454545454545454545449949555554111111116666666666666666111111115445544544444444
0d65565556555555555557700d6556705556655ddd56655554545454545454545454545959555554111111116666666666666666111111114444454444994444
0055555555555555d555556000555560555555600d56655555555555555555555555554955444445111111166666666666666666611111114544444444994444
00555555555555555555556000555560555665600d55555554599999999999999999999999999999111116616666666650000005166111111114111144499444
0d665d5555555555555556700d665670555665566556655555949494949494949494949994949494111166666666666604444440666611111111411144499444
0d66556555555555556556700d6656705555555555566555545949494949494949494949494949491116666666666666059f9940666661111114111144994444
0d66555555555555555555600d665560555556656655555555444444444444444444449944444444111666666666666604944f40666661111111411149944499
00555555555555555555667000556670556556656655555554544444444444444444494944999444166166666666666605944940666616611114111199444999
0d655655d5555555565d66700d65667055555555555565555545454545454545454544994955554466666666666666660499f940666666661111411194449944
0d65555555555555555566700d656670555555555555555554545454545454545454545995555554666666666666666605454540666666661114111144499444
005555555555d5555555556000555560555555555555555555555555555555555555554995555554666666666666666650000005666666661111411144994444
00555655555555655565667000556670500000000000000555555555545445444494494995555554333333333333333333333333333333333333433355555555
0d65555555555555555566700d656670077767766777677054455445545445444494494995555554333333333333333333333333333343333333333355555555
0d65555555655555555555600d65556000665665566656604444444454544544449449499555555433333333b3333333333333b3343435343434393955555555
005555655555565556d5567000555670005555555555556045544554545445444494494995555554333333333333333333333333535343434393434355555555
0d66555555555555555556700d6656700d6566555565557055555555545445444494494995555554333333333313333333333331343435343434393955555555
0d66566556656665566655600d6655600d656655555565705445544554544544449449499555555433333333133333333333b331545445444494494355555555
00000dd00dd0ddd00ddd0060000000600055555ddd55566044444444545445444494494995555554333333331133333b33333331345435444394434955555555
50000000000000000000000550000005005555600d55566045544554545445444494494995555554333333331131333333331311543445434493494955555555
50000000000000000000000511111111005555600d55557050000000000000000000000511111111333333331113333313313111111111111111111155555555
077677766777677667776600111111110d656656655555700db3bb3b333b33b33b333b30141514153b3333331111113333111111111111111111111165566665
0d6566655666566556665600111111110d656655556655700035335535535555553535504141414133333b311111111111111111111111111111111155566665
0d6555555555555555555500111111110d655555556656600d5555555555555555555560151415143313333311111111111111111111111111111331555dddd5
0d66555555555555555556705000000500555555555556600055655d555655655555567055555555113331331111111111111111131113111111133155555555
0d66566556656665566655600776667000566655665665700d655555555555555565567054455445111133111111111111111111131113113311333156655655
00000dd00dd0ddd50ddd00600d655670000ddd00dd0d0d700d65565556555555555556704444444411111111111111111111111111331131333133115dd55555
5000000000000000000000050d65556050000000000000050055555555555555d555556045544554111111111111111111111111313131331331331155555555
ffff8ff73dfbff7e9a0003228a2a031b308273aa021ac0c83048408b53b2b2ca334b637bb315cee3cefbf3ffb0fe6353cbbbcbd377e3d33bd67a92b9c9c93232
4af64a0aa27fa9eeeee005051d7085859db056bd17fcc5ab6e5ffde997e99c7f1e87cff7f2fc4fdf756ffd5af9fb8ee761e7f93cfa7eafeffe9fefbcf7fecf31
b8ff78ff715e7ef78fff2ff4cffacf2df75ee78694ff395fbbfff3f1af83cdff3ef8cff78f2ef4cfd71fffb9fff2eff5df42ff7cff78d96c9df1bcfbcff3affb
0fffbeff5cffb8ff4629ed763fcf7cefedfaeff2dffdbf3affa1f7fe19f71ff53fffa4fecffb9f971bdfbf37ff710579ff73ef731e1272ff30ff98ffacf5ef67
8fffccfd7ceff27eef39efff9e731eff3cfff0767c5ff6ef95f74ff34a0fe9f054c185c81732cdd971f8effbcfb442cff7b07699ffad77ffbdff2bf33ffff99f
27f70ef98ff77f3ff99ff3bf7df5eff3cfff8fff5fff7eff4d3e8878d514c4b8ff8e9465f7ceff5c8ff5bfef0969b5f2fff7dff1495e72ef36f18f6e07ff3cff
58d2ffdcff59cc87d1ffbfff9fff3fff7efffcfff9ff3215dc109dff79ff75effbcffaac2da0f71ef75e84ff3d30ff2437b33eff773fcfffdfffdc1ae0a4d0f3
f7ef3cffe4f37ffb9a3c2f01b8ccc1ff6effdfff9bffcf50a3179c70f4dff3bff36fe7e0c5f43cafffeff0ff0f98ff24a2bf7a9e224fcfa3cff7f16c1f93ff2d
f74ef6cff78fff0f427e88e8f3ff68fd9fc58b2ee48f4429fccffdaf4af72f391fcff30fecbcffa9e778ef4b2fe7489e7cf78ff32fff1e27ff6ca516f2ef87ff
ecf78e7afe4b0816ff2c07e4e1b9f9fdf76eff7cbc797a1ef55879fe5e7099ba98ffcfb1f0cf535c2efddfc911a3eb71f9cfc572356fd3b944efc1e1f0cf9e4c
fffcf4cff9b8ff8fc9f48077f3ffa85fdcf99ffeb9ff75eff8dfc1ef97e371ff96ac7ae473f3fecf7a1ef73ff7ff918f5cb4b476c0e7c5f36fef78ef86f25f5c
c2a4e0d2f73ef3b1f3fff8e39effbcf7ff32ff9ff3ffac8def168fe5bbee7aef2394cfefea46f2f0ff5e3f9ff57beffcff6ef7ff73ff9fcd154ecba42e3cff0c
00000000000000000000000000000000000000001111111999991111111111111111111111111111111111111111111111111111111111111111111111111111
000000000000000000000000000000000000000011111199999aa911111111111111111111111111111111111111111111111111111111111111111111111111
00000000000000000000000000000000000000001111199991199991111999911111111111111111111111111111111111111111119111111111111111111111
00000000000000000000000000000000000000001111199911119991199449a91111999999111119999991119911111199111119119111191111111111111111
1111111111155111111111110000000001001001111119991111999199911199911999449a9111999449a9199a911119a9111119119991919111111111111111
1111111111554911111111113bbbbbbb904904901111199999999941999111999199941199a9199941199a9499a1111999111199919191999111111111111111
11111111155494911111111133b3b3b3404404401111199994444419999999991199911149991999111499914999119999111119119191911111111111111111
1111111115444941111111115333b333035035031111199991111114999411111199911119991999111199911499919994111119911111199111111111111111
11111111554444491111111153333535131313531111199991111111999111111199911119991999111199911149999941111111111111111111111111111111
11111115545454544111111155353535111313131111199991111111499999999199411119941994111199411114999911111111111111111111111111111111
11111155454545454411111155553555111113111111199991111111144999944144111114411441111144111111999411111111113111111111111111111111
11111155555555555411111155555555111111111111149991111111111444411111111111111111111111111119999111111111494911111111111111111111
11111554449999999991111111111111eeeeeeee1111114991111111111111111111111111111111111111111999941111111114999491111111111111111111
11115544494949494949111111111111eeeeeeee1111111449999111111111111111111111111111111111114994411199911114999491111111111111111111
11155444949494949494911111111111eeeeeeee111111199999aa9111111111111111111111111111111111144111119a911111494911111111111111111111
11154444444444444444911111111111eeeeeeee1111119999119999111111111111111111111111111111111111111999411111111111111111111111111111
11554444444444444444491111111111eeeeeeee1111119991111999199911111991111111111111111111999999111999111991111111111111111111111111
15445454545454545454449111111111eeeeeeee111111999111199999a911119a911199991111999111199999aa911999119a91999911199999911111111111
55454545454545454545444911111111eeeeeeee11111199999999949999111199a919aa99111999a9119994114999199919991199a911999999a91111111111
55555555555555555555555411111111eeeeeeee11111199994444419999111199991999499199499911999111199919999991119999199994499a9111111111
51111111111111111111111551111111111111151111119999111111499911119991199919999419991999911119991999999111999919999114999111111111
15511111111111111111155115511111111115511111119999111111199991199991999414999119991999911119941999199991999499994111999111111111
19a555111111111111555a9119a5551111555a911111114999111111149999999941999111499119991999999999911994114999999199991111999111111111
19991955555555555591999119991155551199911111111444111111114499944411499111141114991999944444411441111444444149911111994111111111
144419a9119aa9119a9144411444119aa91144411111111111111111111144411111144111111111441999911111111111111111111114411111441111111111
11111999119999119991111111111199991111111111111111111111111111111111111111111111111499911111111111111111111111111111111111111111
11111444114444114441111111111144441111111111111111111111111111111111111111111111111199411111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111144111111111111111111111111111111111111111111
1110111111110111111110111111011111555555ddd51111111111111111111111111111111d6611000000001111999991111111000005119999999999999999
110c01111110c01111110c011110c01111555555ddd551111ee1ee111111111111d66611111d6611000000001111194949111111999940119494949494949494
10c7c001110c7c000110c7c0110c7c0015ddd5555ddd5111eeeeeee11ee1ee111d6666611d666666000000001111149494491111444450114949994949494999
0cec7cc000cec7ccc00cec7c00cec7cc155ddd555dddd511eeeeeee11eeeee111d6666611d666666000000001144444444111111000001114495544444449955
ceccc77ccceccc777cceccc7cceccc77555dddd55ddddd51eeeeeee11eeeee111d666661111d6611000000001115444444445111441111114955554444995555
cccccccccccccccccccccccccccccccc55dddddd55ddddd51eeeee1111eee1111d666661111d6611000000001111445454511111454111119555555449555559
cccccecccccceccccccecccccccceccc555555dd5555dddd11eee111111e11111d666661111d6611000000001115454541111111545451119555555495555555
ccceeeeccceeeeccceeeeccccceeeecc5555555555555555111e1111111111111d666661111d6611000000001111155555551111555111119555555495555554
00000000544999111155499915449911111911111111111711111111111177177777111111111111111111111111111111111111111111119555555495555554
00000000444476911567444915474911115691111177717771777111111777677777711115115111115111511111111111111111111111119555555495555554
00000000467777695677777415474911156769111777767776777711111777777777677115115111115111511116111111111111111111119555555495555544
00000000444476411467444415474454157779111777777777777671176777777777777115115155515115511167611111111111111111119555555455555544
00000000555555111155555515777511144744111777777777777771777777777777776715555151515151511116111111111111111111114444444455555554
00000000111511111111511115676511154744547777777777777771777777777777777715115155515155511111111111111111111111114545454555555555
00000000111411111111411111465111154644117777777777777767167777777777777711111111111111111111111111111111111111115454545455555555
00000000111411111111411111151111155444111677777777777777177777777777777711111111111111111111111111111111111111115555555595555555
11111111111111111111111111994451111191111777777777777777777777777777777711111111111111110000000011111100111100111115151100000000
11111111111111111111111111947451111965111777777777777671776777777777677115551111111115510000000011111108011080111115551100000000
11115551111111111111111111947451119676511177677767777711117777777777711111511111111115510000000011111100011000111111511100000000
11155d55111111111111111145447451119777511111777771777711117776767767711111515151555515510000000011111111111111111115551100000000
11155ddd111111115111111111577751114474411111777771111111111771771177177111515151515515110000000011111101010101111115151100000000
111555dd111115d1d511111111567651454474511111177111111771111111111111177115515551511515110000000011111110101011111115551100000000
1155555d5dd1555ddd51111111156411114464511111111111111771111111111111111111111111111111110000000011111111111111111111511100000000
1155555d55515555dd55111111115111114445511111111111171111111111111111711111111111111111110000000011111111111111111115551100000000
__gff__
0000010602818a060606000000000000000101020a0202020202000000000000000101000002020000000000000000000001010000818a0606060000000000000a0a0a0a0a0a060606000000000002020a0a0a0a0a0a0000000000000a0000020a0a0a0a0a0a0200000000000000000a0a0a0a010a0a0a0a0a0200000000000a
00000000020200000000000000000000000000000202020200000000000000000000000a060202020000000000000000000000008a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
2a2b0001020076a3787777780a0b107677787979795200500708094042002c2d373839104a4b4c4d10070809ecec7dd87ed97d001d0c1c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3a3b001112005051525151521a1b1050515266666652005017181960620000007071724a4b5b5b4c4d174f19fcfd00000000001d0d6a0e1c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3738397072000000005151521010106061624e4e4e547755171819a0a10000000000005a5b5b5b5b5d272829e1e2e3e40000000d6a6a6a0ec0c1c1c20000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005151515151515151515151521819197d007e00007d1717181818565957580017181818181900000017181818181818500000000000000000000000000000000000000000000050515151000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005151515151515151514461621819190708090046474747481818566957580017181818181900000017181818181818500000000000000000000000000000000000000000000050515151000000000000
000000000000e200000000000000000000000000000000000000000000000000000000000000000000000000000000005151514461614551515266171819191718190057494957580708080808080809181818181900000017181818181876557de2000000000000000000000000000000000000000050515151000000000000
77a377777777777778000046474748000000000000000000000000000000000000000000000000004647474800000076515144626666505151526617180708261819005649495758171815282816182509181818190000007677a3777777515177a3777777777800000000000000000000000000000050515151000000000000
515151515144616162c3c4565757580046474747474748000000000000000000000000000000000056575758c0c1c2507f44626666666061616266171817181818197956595757072615290000271618191818181979797950515151515151515151515151515200000000000000000000000000000050515151000000000000
5151515144620000000000564949580056494957494958000046474748000000464747474800000056495758004a4b50515266666666666666666617181718181819665669575717181900000007080808080808094e4e4e50515151515151515151446161616200000000000000000000000000000050515151000000000000
5151515152000000000000564949580056494957494958c3c4564949580000005649574958c0c1c2565757584a4b5b60515266666666667677777778181718181807080808080809152900000017181846474748194e4e4e50515151515151516161626666660000000000000000000708080808090060515151000000000000
51515151544200000000005659575800565757575757580000565757570000005657575758000000564957585a5b5b66616266666666665051515154781718181817181818181819190000000017181856595758194e4e4e5051515151515151666666666666000000000000000000175f18184f190000605151000000000000
5151515151520000000000566957580056575757575758000056494958c0c1c256495749580000005659575800000066666666666666765551515144621718181817181818181819190000000017181856695758194e4e4e507f51515151515166666666666600000000000000000027164f1815290000006051000000000000
515151514461720000000708080808095649575957495800005657575700000056575757580000005669575800e10066777777a37777555151514462181718180708080809181819197de2007e17180708080809194e4e4e50515151515151516666666666660000000000000000000027161529000000000050000000000000
51446161626666000000171818181819565757695757580000565957580000005657595758000000070808080808087651515151515151515151521718171818171818181918181919767777777818171818181976784e4e50515151515151514141414141414200000000000000000000272900000000000050000000000000
616266666666660000001707080808080808080808080808095669575800e100565769575800000017181818181818505151515151515151515152171817181817181818191818197655515151547777777777775554a37755515151515151515151515144520600000000000000000708080808080900000050000000000000
6666666666666600e10017171818181815282816181807080808080809a4390708080808090000001718181818181850515151515151515151446217181718767777777777777777555151515151515151515151515151517f515151515151515151514462060000000000000000001718185f185f1900000050000000000000
666666666640414142001717181818152900002716181718181818181900001718181818190000001718181818181850515151515151515144626617181718505151515151515151515151515151515151515151515151515151515151515151515151520000000000000000000000174f185f15282900000050000000000000
66666666405551515442080808091819000000001718171818184647474800171818181819000000171818181818185051515151515151446266661718177655515151515151515151515151515151515151515151515151515151515151515151515152d0d0d0d0d0d0d0d0d0d0d027161815290000d0d0d050000000000000
41414141555151515154414218191529000000002716171818185649495800171818181819000000171818181818185051515151515151526666661776775551515151515151515151515151515151515151515151515151515151515151515151515152b4b4b4b4b4b4b4b4b4b4b400272829000000b4b4b450000000000000
92fdc9c27275c17970eb9a9c766052dadaa33b5b7f08bd24ab3f07fe05fe3ff26e6ffe1fc5e3fff8fc4fffe14ff2124baa69389cd9d4704e9f9c3c52749645aefff3d7fe597ff57e6faffe3f7fff91deef7ff7ffef26b0fcae389df69dd6ffbfefe4e13fff93fffcae384a7e724d7d4ec87affede89fffc8fbc46e87e7cffff2
effff23ff9848e34f20e1c7ec7472770ff62fdcf6ffc17fff81bd4b67f517f6fceb9e7ba11f88bc7fe0ffc3fdfee256fdb05be1ff9e4fffe67acaffdee21c2797fff8ffffc489cce2f6953b3f604b6bff53fff9bf47febfc80000000000000000000000000000000000000000000000000000000000000000000000000000000
fffff87fd3bfffefd1bbbc003b28a9332837a20322bfa73070bef13f31038404f87f130c2f8a948ba78cb093940b3536b733b4363d35a323a41c9bd21c3e3daf2b2ba4ac2cb4b8208e860e2e0687082525a626f99aef2a2dbcaaa1a0772d2eba38aa5fffe2cd533b71c4e7a4efce1dffe4bef1f7fff1b86fc2711d49f8ba9d7e
4bf9f3cffe9bc733f3dfa3f55dfb21c7efa57fe6e7bfc78924b0e6f7fc752fb27fe84fcf5fe7fafe9d7f7fe71fa7f5f9fee9cf2dcb9e3ff3f9ca71c670e2f1fc7fbb2733ffb74ffbff07fe1ffc5ff8f977f9d92ffe444ffcbff9bff538493993ff3a79fc7113ffbf3ffa3ff4ffeafea6bc9c5ee2fedfc7efffb7a59629df6ee2
ffe67febfc67feca7ef139349fd7fe29ffb6f73ff5ffeb6ffcfcc913c6ffd0f65fcff092c92bff77a0ffd0ffdfe59144f47c3213ff3dffe1ffc7ff94b2492449be87e33ff9fff493ffadfd3bf249b6c6964ffe53affedffdfffc3ffbfff998ffd19ffea7ffbff1e773ffe1c1fff7fff7fff00fffe0ffe5a5fc1bff34fe9ff92f
df43f3d7f3fffe17e67e7ff95fa7e30ffccfcb97b6bd5bb4b649facfffe1fe9ffdaffff13fff8b1e7e1f492493fabdff12f49ffa7ff67e9fe039e1fffc6fffe3ffff22fb3a9ccfffe4ffff24fffe49fffc91f9a53c750fc5ff9e6febfcfdbfab3fc7f3bf5bfbffe59469e6239effff95ffe3fff97d449da5bf7e2eff2924fffe
67fff37fff9dfffcffffe8673b6db8e27becd3f949addfb27fff47753fffa4950907fff4ea7f44ebfffa9ffabff6ffe3ffc1ffa7ff0c7fe067ff27e49ff93893f16896c923ff32a35ffc9ff93fffaabff97ff1376fcbf2fcbf2ffe7fffd6fe5a4f2e13fffafca7e1cf53fffb1ecbfffd9fffeb98fd7fffb54fe84cea0b27bf8e
f44cfffe4feffffc95a99fffdbcfffee7af53a75213f57b3fffbbfffde9bfd7df8f77f35fdc0fb12b7ed82df0ffcf27fff33d657ff6710e13cbfffcbfffe044e6717b4a9d9fb025b5ffa9fffcdfa3ff87e407e40ff0fc87ec096d7fea7fff3fe8ffdbf9000000000000000000000000000000000000000000000000000000000
