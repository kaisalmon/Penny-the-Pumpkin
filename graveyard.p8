pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
function _init()

end
function _draw()
	cls(0)
	spooky_pal = split("128,130,131,132,133,5,134,136,137,9,3,12,13,8,4")
	pal(spooky_pal,1)
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
1110111011000011111111110000000011153311444994f0004994442249944444499444444994ff111111100111111100000000000000004411111100000000
010101011049aa511110011100000000153333514444990b330499442244994444449944444499ff11111103b011111100000000000000001144114900000000
101010100499779011099411000000005333ab31444444033b3049942224299224422992244229af111111033011111100000000000000004994a11100000000
01010101049997901049790100000000333bba3144444420030444992222124412221244122212aa1111100530011111000000000000000014449a1100000000
0000000054999990154499010000000033b3bb3194444449402444491241124112411221124112f11110044449a001110000000000000000114a791100000000
000000005449994011544011000000005333bb339944444494444444121112111211121112111211110949949a9aa0110000000000000000444aea1100000000
00000000154444011115011100000000333b3b3349944444499444441111111111111111111111111094994999a9aa0100000000000000001111144100000000
000000001155001111111111000000005333b33344994444449944441111111111111111111111110949949999999aa000000000000000001491114900000000
0000000011111111111111110000000033333b331111111105ddd60110010010010010010010010009499499999a949011111111111111114411111100000000
00000000111111111111111100000000533333331110111105dd670104904904904904904904904909499499999a949011111111111111111199119400000000
00000000111041111111111100000000333333331107011110dd6011044044044044044044044044044994999949949011111111111111114444a11100000000
0000000011097411111141110000000015355351110601111056701110010010010010010010010004449499994994901111113311111111199a9a1100000000
0000000011549011111594110000000011549511105670111106011111111111111111111111111104449499994949901131133311311131114a7a1100000000
000000001115011111115111000000001154951110dd601111070111111111111111111111111111054449499494999013311331113111314449ea1100000000
000000001111111111111111000000001154951105dd670111101111111111111111111111111111105454444445990113313331113131311111199100000000
000000001111111111111111000000001549995105ddd60111111111111111111111111111111111110000000000001113313311313133331941114400000000
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
11111554449999999991111177777777eeeeeeee1111114991111111111111111111111111111111111111111999941111111114999491111111111111111111
111155444949494949491111cccccccceeeeeeee1111111449999111111111111111111111111111111111114994411199911114999491111111111111111111
111554449494949494949111eeeeeeeeeeeeeeee111111199999aa9111111111111111111111111111111111144111119a911111494911111111111111111111
111544444444444444449111eeeeeeeeeeeeeeee1111119999119999111111111111111111111111111111111111111999411111111111111111111111111111
115544444444444444444911eeeeeeeeeeeeeeee1111119991111999199911111991111111111111111111999999111999111991111111111111111111111111
154454545454545454544491eeeeeeeeeeeeeeee111111999111199999a911119a911199991111999111199999aa911999119a91999911199999911111111111
554545454545454545454449eeeeeeeeeeeeeeee11111199999999949999111199a919aa99111999a9119994114999199919991199a911999999a91111111111
555555555555555555555554eeeeeeeeeeeeeeee11111199994444419999111199991999499199499911999111199919999991119999199994499a9111111111
51111111111111111111111551111111111111151111119999111111499911119991199919999419991999911119991999999111999919999114999111111111
15511111111111111111155115511111111115511111119999111111199991199991999414999119991999911119941999199991999499994111999111111111
19a555111111111111555a9119a5551111555a911111114999111111149999999941999111499119991999999999911994114999999199991111999111111111
19991955555555555591999119991155551199911111111444111111114499944411499111141114991999944444411441111444444149911111994111111111
144419a9119aa9119a9144411444119aa91144411111111111111111111144411111144111111111441999911111111111111111111114411111441111111111
11111999119999119991111111111199991111111111111111111111111111111111111111111111111499911111111111111111111111111111111111111111
11111444114444114441111111111144441111111111111111111111111111111111111111111111111199411111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111144111111111111111111111111111111111111111111
111011111111011111111011111101111111111111111111111111111111111111111111111d6611000000001111999991111111000005119999999999999999
110c01111110c01111110c011110c01111111111111111111ee1ee111111111111d66611111d6611000000001111194949111111999940119494949494949494
10c7c001110c7c000110c7c0110c7c001194111111111111eeeeeee11ee1ee111d6666611d666666000000001111149494491111444450114949994949494999
0cec7cc000cec7ccc00cec7c00cec7cc9111199991111111eeeeeee11eeeee111d6666611d666666000000001144444444111111000001114495544444449955
ceccc77ccceccc777cceccc7cceccc7711aa1aa11a111111eeeeeee11eeeee111d666661111d6611000000001115444444445111441111114955554444995555
cccecccccccceccccccccecccccceccc11aa1aa11a1111111eeeee1111eee1111d666661111d6611000000001111445454511111454111119555555449555559
ceeeeccccceeeeccccceeeeccceeeecc119919911a11111111eee111111e11111d666661111d6611000000001115454541111111545451119555555495555555
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee9144144119111111111e1111111111111d666661111d6611000000001111155555551111555111119555555495555554
00000000544999111155499915449911111911111111111711111111111177177777111111111111111111111111111111111111111111119555555495555554
00000000444476911567444915474911115691111177717771777111111777677777711115115111115111511111111111111111111111119555555495555554
00000000467777695677777415474911156769111777767776777711111777777777677115115111115111511116111111111111111111119555555495555544
00000000444476411467444415474454157779111777777777777671176777777777777115115155515115511167611111111111111111119555555455555544
00000000555555111155555515777511144744111777777777777771777777777777776715555151515151511116111111111111111111114444444455555554
00000000111511111111511115676511154744547777777777777771777777777777777715115155515155511111111111111111111111114545454555555555
00000000111411111111411111465111154644117777777777777767167777777777777711111111111111111111111111111111111111115454545455555555
00000000111411111111411111151111155444111677777777777777177777777777777711111111111111111111111111111111111111115555555595555555
00000000000000000000000011994451111191111777777777777777777777777777777711111111111111110000000011111100111100111115151100000000
00000000000000000000000011947451111965111777777777777671776777777777677115551111111115510000000011111108011080111115551100000000
00000000000000000000000011947451119676511177677767777711117777777777711111511111111115510000000011111100011000111111511100000000
00000000000000000000000045447451119777511111777771777711117776767767711111515151555515510000000011111111111111111115551100000000
00000000000000000000000011577751114474411111777771111111111771771177177111515151515515110000000011111101010101111115151100000000
00000000000000000000000011567651454474511111177111111771111111111111177115515551511515110000000011111110101011111115551100000000
00000000000000000000000011156411114464511111111111111771111111111111111111111111111111110000000011111111111111111111511100000000
00000000000000000000000011115111114445511111111111171111111111111111711111111111111111110000000011111111111111111115551100000000
__gff__
0000010602818a060606000000000000000101020a0202020202000000000000000101000002020000000000000000000001010000818a0606060000000000000a050a0a0a0a060606000000000002020a0a0a0a0a0a0000000000000a0000020a0a0a0a0a0a0200000000000000000a0a0a0a010a0a0a0a0a0200000000000a
00000000020200000000000000000000000000000202020200000000000000000000000a0602020200000000000000000000000a8a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
2a2b000102007677787777780a0b107677787979795200500708094042002c2d373839104a4b4c4d10070809ecec7dd87ed97d001d0c1c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3a3b001112005051525151521a1b1050515266666652005017181960620000007071724a4b5b5b4c4d174f19fcfd00000000001d0d6a0e1c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3738397072000000005151521010106061624e4e4e547755171819a0a10000000000005a5b5b5b5b5d272829e1e2e3e40000000d6a6a6a0ec0c1c1c20000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
520000000060455151515151446162000060615206504551515151516f6f6f544141414142191807080809190000000070616151515151526a6a5657586a67686a6a6a6a6d6e6a6a6a6a6a6a76a300000000000000000000d87d00d9007ed9000000000000000000000000000000000000000000000000000000000000000000
5200d900000060515151517f52fe00000000fe060006504551517f6f6f6f6f6f6f6f6f6f54421817181819190000000000fe0060455151526a6a56de586c67686b6a6a6a67686a6a6a6a6a6a507f000079797979797979797677777777a377787979790000000000000000000000000000000000000000000000000000000000
5208090000000006507f515152fe00000000fe000000065045516f6f6f6f6f6f6f6f7f6f6f544142181819190000000000fe0000507f51526c7a56ee587c67687b6b6a6a67686a6a6a6a6a6a506f5154420808080966666660614551515151526666665051000000000000000000000000000000000000000000000000000000
52181900000000005045515206fe7e00007dfe00000000065045516f7f6f6f6f6f6f6f6f6f6f6f54421819190000000000fe000050516f527c00db575800676800006a6a67686a6a6a6a6a6a506f515152181818194e4e4e4e4e6045514461624e4e4e5051000000000000000000000000000000000000000000000000000000
547819000000000006065306003739373839380000000000065051516f6f6f6f6f6f6f6f6f7f6f6f54414219000000003738393750515152000056575800676800006a6a67686a6a6d6e6a6a506f51515442181819d97d0000000060616200fe0000005051000000000000000000000000000000000000000000000000000000
6f52197d0000000000000600000000000000000000000000005051516f6f6f6f6f6f6f6f6f6f6f7f6f6f5441420000000000000006060652004647474747474700006b6a67686a6a67686a6a506f5151515442180708080900797900000000fe0079795051000000000000000000000000000000000000000000000000000000
6f5208080900000000000000000000000000000000000000005051516f6f6f6f6f6f6f6f6f6f6f6f6f6f6f7f54414142000000000000005200db46474857575700007b6b67686a6a67686a6a507f51515151544217181819d84e4e00000000fe004e4e5051000000000000000000000000000000000000000000000000000000
6f5478181900000000000000000000000000000000000000005045516f6f6f6f6f6f6f6f6f6f6f6f6f6f7f6f6f6f6f544141414141414152005656df585749570000000067686a6a67686a6c506f515151515154421818070808097e007979373839405551000000000000000000000000000000000000000000000000000000
6f6f521819007d7e00000000000000000000000000000000000650516f6f7f7d00d87ed90000000000000017171818181819181818505152005656ef585657570000000067687a7a67687a7c506f5151515151515441421718180709004e66790000505151000000000000000000000000000000000000000000000000000000
7f6f52080808080808090000000000000000000000000000000050456f6f6f00d87e7dd900000000000000171718181818191818185051520808080808080808080800006768000067680000506f515151515151515151414218171900004e4e0000505151000000000000000000000000000000000000000000000000000000
6f6f5218181818181819007d00007e000000000000000000000006506f6f6fd900d87d0000000000000000000000000000000000000000521818181818181818181800006768000067680000506f5151515151515151515154414219000000000040555151000000000000000000000000000000000000000000000000000000
6f6f54781818181818197e07080808080900000000000000000000506f6f6f7ed97e00d800000000000000000000000000000000000000521818181818181818181808096768000067680000506f5151515151515151515151515442007979000050515151000000000000000000000000000000000000000000000000000000
6f6f6f521818181807080809181818181900000000000000003535506f6f6f00000000000000000000000000dd00000000000000000000520808080809181818181818196768000708080808506f51515151515151515151515151527d6666000050515151000000000000000000000000000000000000000000000000000000
6f6f6f521818181817181819181818070809000000000000354041556f6f6f0000000000000000000000000057dc000000000000000000521818181807080809181807080808080918181818506f515151515151515151515151515441424e000050515151000000000000000000000000000000000000000000000000000000
6f7f6f54a3781818171818191818181718190000000000354055516f6f6f6f1c0000000000000000000000005749dca0a1a20000000000521818181817181819181817181818181918181818507f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6f6f6f6f6f521818171818191818181718190000000035405551516f6f6f7f0e1cd900000000000000000000575758b0b1b20000000000547818181817181819181817070808080809181818506f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
09e50e3f6fde7fe72525fc39384e4eb82f2e1d73538ecc0a5b5b54678b6fe117a49567e0ffc87ee6e6ffe3fc5e3fff85c4fff93fc8492ea9a4e2736751c13a7e70f149d25916bbffd55ffa25ffd5f9bebff8fdfffe1f7bbdffd7ffac9ac3f2b8e277da775bff0ffe1fece13fff89fffc5e384a7e724d7d4ec87affe3e89fffc3
fbc46e87e7cffff1affff0fff9848e34f20e1c7ec7472770ff62fdcf6ffc17ffeef52d9fd45fdbf3ae79ee847e22f1ff8bff1ffbfb895bf6c16f87fe793fff8feb2bff7a3fff9122709e5fffe17ffe89cce2f6953b3f604b6bff53fff93f47feecde000000000000000000000000000000000000000000000000000000000000
fffff87fd3bfffefd1bbbc003b28a9332837a20322bfa73070bef13f31038404f87f130c2f8a948ba78cb093940b3536b733b4363d35a323a41c9bd21c3e3daf2b2ba4ac2cb4b8208e860e2e0687082525a626f99aef2a2dbcaaa1a0772d2eba38aa5fffe2cd533b71c4e7a4efce1dffe4bef1f7fff1b86fc2711d49f8ba9d7e
4bf9f3cffe9bc733f3dfa3f55dfb21c7efa57fe6e7bfc78924b0e6f7fc752fb27fe84fcf5fe7fafe9d7f7fe71fa7f5f9fee9cf2dcb9e3ff3f9ca71c670e2f1fc7fbb2733ffb74ffbff07fe1ffc5ff8f977f9d92ffe444ffcbff9bff538493993ff3a79fc7113ffbf3ffa3ff4ffeafea6bc9c5ee2fedfc7efffb7a59629df6ee2
ffe67febfc67feca7ef139349fd7fe29ffb6f73ff5ffeb6ffcfcc913c6ffd0f65fcff096c923ff77a0ffd0ffdfe59144f47c3213ff3dffe1ffc7ff9492126926fa1f8cffe7ffd24ffeb7f4efc926db1a593ff94ebffb7ff7fff0ffefffe663ff467ffa9ffeffc79dcfff8707ffdfffdfffc03fff83ff9697f06ffcd3fa7fe4bf
7d0fcf5fcffff85f99f9ffe57e9f8c3ff33f2e6faf61aed2d927eb3fff87fa7ff6bfffc4fffe2c79f87d24924feaf7fc45ffd5fa467fe820e787fff1bfff8ffffc8becea733fff93fffc93fff927fff247e653c750fc5ff9e6febfcfdbfab3fc7f3bf5bfbffe5438af311cf7fffcafff1fffcbea24ed2dfbf177f4927fff33ff
f9bfffcefffe7ffff4339db6dc713df669fca4d6efd93fffa3ba9fffd24a8483fffa753fa273fffd4ffd5ff83ff07fe92ffe0ffdbff8d9ffc9f927fe4e24fc5a25b248ffcca8d7ff27fe4fffeaaffe5ffc4ddbf2fcbf2fcbff9ffff5bf9693c984fffebf29f873d4fffec7b2ffff67fffae63f5fffed53fa133a82c9efe3bd13
3fff93fbffff256a67fff6f3fffb9ebd4e9d484fd5ecfffeeffff7a6ff5f7e3ddfcd7f70ee3ddfcd7f70e0f10e39bf8ff3674ffdbffa3ff4ffeafefdfc640824726a768179c2fffd1399c5ed2a767a74096d7fe999f47feefc803b3d3a04b6bff4ccfa3ff7fe4000000000000000000000000000000000000000000000000000
