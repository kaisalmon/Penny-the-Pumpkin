[PENNY THE PUMPKIN](https://www.lexaloffle.com/bbs/?tid=52122)

## Controls
**Left/Right** arrows: Move Penny left or right
**Up/Down** arrows: Stretch Penny up or down
**X/O/Z** buttons: Make Penny jump. **HOLD** jump for a bigger leap! 
**Menu/Space**: Access the menu, featuring a soft-lock ejector just in case!



## Description
**Penny the Pumpkin** takes you on a delightful platforming journey with light puzzles to solve. Guide Penny, our lovable gourd, as she collects 12 precious coins! Your progress is saved every time she grabs a coin or enters a new area.

Once you've collected all 12 coins, put your skills to the test by unlocking the thrilling speedrun mode! Note that saving is disabled in this mode, so it's all about your skill and reflexes. Can you beat the programmer's current record of 2:51.5? 🏆



## Technical Notes

This game uses [P9 Compression](https://www.lexaloffle.com/bbs/?tid=34058) to have four banks of 16x128 tiles that can be  switched between during gameplay. 

Each level is then defined as an array of "blocks", where each block is a rectangle of the tilemap somewhere in the level. This allows me to have seven different areas, some of which are quite large, as well as easily having overlapping elements. Blocks can also have properties such as an update method ran each frame, if they should have collision disabled, if they should be drawn in front of the player, if they should be drawn just as a cheap rect fill, if they should be repeated etc. This gives me a lot of power in level design.


The physics is relatively simple, with the character animations being based on a very simple [spring math](https://en.wikipedia.org/wiki/Hooke%27s_law):
```
spring_dy = (spring_y - spring_y_target) * SPRING_CONSTANT 
spring_dy *= (1-DAMPING_CONSTANT)
spring_y += spring_dy
```

Each level uses a different screen pallete, which often use the [secret palette](https://pico-8.fandom.com/wiki/Palette#128..143:_Undocumented_extra_colors). Additionally for the title screen, a (trick)[https://www.lexaloffle.com/bbs/?tid=38565] documented by @bonevolt is used to switch to a different pallete for the area of the screen behind the logo! I had to do some extra bit of bit math to have it drawn to an arbitrary place on the screen without clobbering memory!
```
 y= 10 -- The vertical position in PIXELS
 h= 3 -- The height in rows of EIGHT pixels
 poke(0x5f5f,0x10) -- enable the effect
 pal(NEW_PAL,2) -- Set the pallete for the section
 pal_memset(0x5f70,0,16) -- clear the settings from previous update
 local rem=flr(y)%8 -- calculate the remainder, since the dual-pallete mode works rows of 8 at a pixels at a time
 pal_memset(0x5f70+(y)/8-1,255<<rem,1) -- Set the flags above where main body made of full 8-high rows can be set
 pal_memset(0x5f70+(y)/8,255,h) --Set the flags for the main body of h 8-pixel-high rows
 pal_memset(0x5f70+(y)/8+h,~(255<<rem),1) -- Set the flags below where main body made of full 8-high rows can be set
```
```
function pal_memset(addr, val, len)
 local min_mem = 0x5f70
 local max_mem = 0x5f70 + 18

    if addr >= min_mem and (addr + len - 1) <= max_mem then
        memset(addr, val, len)
    end
end

