/*
 *  @Name:     color
 *  
 *  @Author:   Brendan Punsky
 *  @Email:    bpunsky@gmail.com
 *  @Creation: 18-01-2018 19:53:01 UTC-5
 *
 *  @Last By:   Brendan Punsky
 *  @Last Time: 18-01-2018 21:08:23 UTC-5
 *  
 *  @Description:
 *  
 */

import imgui "shared:libbrew/brew_imgui.odin"


_unit : f32 : 1.0/255;

alpha :: proc(color : imgui.Vec4, a : f32) -> imgui.Vec4 {
    color.w = a;
    return color;
}

hex :: proc(h : u32) -> imgui.Vec4 {
    return imgui.Vec4 {
        f32( (h <<  8) >> 24) * _unit,
        f32( (h << 16) >> 24) * _unit,
        f32( (h << 24) >> 24) * _unit,
        1.0,
    };
}


white          := hex(0xFFFFFF);
black          := hex(0x000000);
   
red            := hex(0xFF0000);
green          := hex(0x00FF00);
blue           := hex(0x0000FF);

yellow         := hex(0xFFFF00);
cyan           := hex(0x00FFFF);
fuschia        := hex(0xFF00FF);

orange         := hex(0xFFA500);
pink           := hex(0xFFC0CB);
purple         := hex(0x800080);
   
tan            := hex(0xD2B48C);
wheat          := hex(0xF5DEB3);
salmon         := hex(0xFA8072);
silver         := hex(0xC0C0C0);
skyblue        := hex(0x87CEEB);
powderblue     := hex(0xB0E0E6);
paleturquoise  := hex(0xAFEEEE);
navy           := hex(0x000080);
midnightblue   := hex(0x191970);
ivory          := hex(0xFFFFF0);
indigo         := hex(0x4B0082);
hotpink        := hex(0xFF69B4);
firebrick      := hex(0xB22222);
seagreen       := hex(0x2E8B57);
cornflowerblue := hex(0x6495ED);
crimson        := hex(0xDC143C);

dimgray        := hex(0x696969);
dimgrey        := hex(0x696969);
darkgray       := hex(0xA9A9A9);
darkgrey       := hex(0xA9A9A9);
lightgray      := hex(0xD3D3D3);
lightgrey      := hex(0xD3D3D3);
gray           := hex(0x808080);
grey           := hex(0x808080);
slategray      := hex(0x708090);
slategrey      := hex(0x708090);

