/*
 *  @Name:     color
 *  
 *  @Author:   Brendan Punsky
 *  @Email:    bpunsky@gmail.com
 *  @Creation: 18-01-2018 19:53:01 UTC-5
 *
 *  @Last By:   Mikkel Hjortshoej
 *  @Last Time: 15-06-2018 16:46:49 UTC+1
 *  
 *  @Description:
 *  
 */

package main;

import imgui "shared:odin-imgui"


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

rgba_css :: proc(r, g, b : int, a : f32) -> imgui.Vec4 {
    return imgui.Vec4{
        f32(r) / 255,
        f32(g) / 255,
        f32(b) / 255,
        a
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

darkred        := hex(0x8B0000);

///// Flatuicolors.com

emerald        := hex(0x2ecc71);
alizarin       := hex(0xe74c3c);

//// Material Design Colors

red50          := hex(0xffebee);
red100         := hex(0xffcdd2);
red200         := hex(0xef9a9a);
red300         := hex(0xe57373);
red400         := hex(0xef5350);
red500         := hex(0xf44336);
red600         := hex(0xe53935);
red700         := hex(0xd32f2f);
red800         := hex(0xc62828);
red900         := hex(0xb71c1c);
redA100        := hex(0xff8a80);
redA200        := hex(0xff5252);
redA400        := hex(0xff1744);
redA700        := hex(0xd50000);

pink50         := hex(0xfce4ec);
pink100        := hex(0xf8bbd0);
pink200        := hex(0xf48fb1);
pink300        := hex(0xf06292);
pink400        := hex(0xec407a);
pink500        := hex(0xe91e63);
pink600        := hex(0xd81b60);
pink700        := hex(0xc2185b);
pink800        := hex(0xad1457);
pink900        := hex(0x880e4f);
pinkA100       := hex(0xff80ab);
pinkA200       := hex(0xff4081);
pinkA400       := hex(0xf50057);
pinkA700       := hex(0xc51162);

purple50       := hex(0xf3e5f5);
purple100      := hex(0xe1bee7);
purple200      := hex(0xce93d8);
purple300      := hex(0xba68c8);
purple400      := hex(0xab47bc);
purple500      := hex(0x9c27b0);
purple600      := hex(0x8e24aa);
purple700      := hex(0x7b1fa2);
purple800      := hex(0x6a1b9a);
purple900      := hex(0x4a148c);
purpleA100     := hex(0xea80fc);
purpleA200     := hex(0xe040fb);
purpleA400     := hex(0xd500f9);
purpleA700     := hex(0xaa00ff);

deep_purple50   := hex(0xede7f6);
deep_purple100  := hex(0xd1c4e9);
deep_purple200  := hex(0xb39ddb);
deep_purple300  := hex(0x9575cd);
deep_purple400  := hex(0x7e57c2);
deep_purple500  := hex(0x673ab7);
deep_purple600  := hex(0x5e35b1);
deep_purple700  := hex(0x512da8);
deep_purple800  := hex(0x4527a0);
deep_purple900  := hex(0x311b92);
deep_purpleA100 := hex(0xb388ff);
deep_purpleA200 := hex(0x7c4dff);
deep_purpleA400 := hex(0x651fff);
deep_purpleA700 := hex(0x6200ea);

indigo50       := hex(0xe8eaf6);
indigo100      := hex(0xc5cae9);
indigo200      := hex(0x9fa8da);
indigo300      := hex(0x7986cb);
indigo400      := hex(0x5c6bc0);
indigo500      := hex(0x3f51b5);
indigo600      := hex(0x3949ab);
indigo700      := hex(0x303f9f);
indigo800      := hex(0x283593);
indigo900      := hex(0x1a237e);
indigoA100     := hex(0x8c9eff);
indigoA200     := hex(0x536dfe);
indigoA400     := hex(0x3d5afe);
indigoA700     := hex(0x304ffe);

blue50         := hex(0xe3f2fd);
blue100        := hex(0xbbdefb);
blue200        := hex(0x90caf9);
blue300        := hex(0x64b5f6);
blue400        := hex(0x42a5f5);
blue500        := hex(0x2196f3);
blue600        := hex(0x1e88e5);
blue700        := hex(0x1976d2);
blue800        := hex(0x1565c0);
blue900        := hex(0x0d47a1);
blueA100       := hex(0x82b1ff);
blueA200       := hex(0x448aff);
blueA400       := hex(0x2979ff);
blueA700       := hex(0x2962ff);

light_blue50    := hex(0xe1f5fe);
light_blue100   := hex(0xb3e5fc);
light_blue200   := hex(0x81d4fa);
light_blue300   := hex(0x4fc3f7);
light_blue400   := hex(0x29b6f6);
light_blue500   := hex(0x03a9f4);
light_blue600   := hex(0x039be5);
light_blue700   := hex(0x0288d1);
light_blue800   := hex(0x0277bd);
light_blue900   := hex(0x01579b);
light_blueA100  := hex(0x80d8ff);
light_blueA200  := hex(0x40c4ff);
light_blueA400  := hex(0x00b0ff);
light_blueA700  := hex(0x0091ea);

cyan50         := hex(0xe0f7fa);
cyan100        := hex(0xb2ebf2);
cyan200        := hex(0x80deea);
cyan300        := hex(0x4dd0e1);
cyan400        := hex(0x26c6da);
cyan500        := hex(0x00bcd4);
cyan600        := hex(0x00acc1);
cyan700        := hex(0x0097a7);
cyan800        := hex(0x00838f);
cyan900        := hex(0x006064);
cyanA100       := hex(0x84ffff);
cyanA200       := hex(0x18ffff);
cyanA400       := hex(0x00e5ff);
cyanA700       := hex(0x00b8d4);

teal50         := hex(0xe0f2f1);
teal100        := hex(0xb2dfdb);
teal200        := hex(0x80cbc4);
teal300        := hex(0x4db6ac);
teal400        := hex(0x26a69a);
teal500        := hex(0x009688);
teal600        := hex(0x00897b);
teal700        := hex(0x00796b);
teal800        := hex(0x00695c);
teal900        := hex(0x004d40);
tealA100       := hex(0xa7ffeb);
tealA200       := hex(0x64ffda);
tealA400       := hex(0x1de9b6);
tealA700       := hex(0x00bfa5);

green50        := hex(0xe8f5e9);
green100       := hex(0xc8e6c9);
green200       := hex(0xa5d6a7);
green300       := hex(0x81c784);
green400       := hex(0x66bb6a);
green500       := hex(0x4caf50);
green600       := hex(0x43a047);
green700       := hex(0x388e3c);
green800       := hex(0x2e7d32);
green900       := hex(0x1b5e20);
greenA100      := hex(0xb9f6ca);
greenA200      := hex(0x69f0ae);
greenA400      := hex(0x00e676);
greenA700      := hex(0x00c853);

light_green50   := hex(0xf1f8e9);
light_green100  := hex(0xdcedc8);
light_green200  := hex(0xc5e1a5);
light_green300  := hex(0xaed581);
light_green400  := hex(0x9ccc65);
light_green500  := hex(0x8bc34a);
light_green600  := hex(0x7cb342);
light_green700  := hex(0x689f38);
light_green800  := hex(0x558b2f);
light_green900  := hex(0x33691e);
light_greenA100 := hex(0xccff90);
light_greenA200 := hex(0xb2ff59);
light_greenA400 := hex(0x76ff03);
light_greenA700 := hex(0x64dd17);

lime50         := hex(0xf9fbe7);
lime100        := hex(0xf0f4c3);
lime200        := hex(0xe6ee9c);
lime300        := hex(0xdce775);
lime400        := hex(0xd4e157);
lime500        := hex(0xcddc39);
lime600        := hex(0xc0ca33);
lime700        := hex(0xafb42b);
lime800        := hex(0x9e9d24);
lime900        := hex(0x827717);
limeA100       := hex(0xf4ff81);
limeA200       := hex(0xeeff41);
limeA400       := hex(0xc6ff00);
limeA700       := hex(0xaeea00);

yellow50       := hex(0xfffde7);
yellow100      := hex(0xfff9c4);
yellow200      := hex(0xfff59d);
yellow300      := hex(0xfff176);
yellow400      := hex(0xffee58);
yellow500      := hex(0xffeb3b);
yellow600      := hex(0xfdd835);
yellow700      := hex(0xfbc02d);
yellow800      := hex(0xf9a825);
yellow900      := hex(0xf57f17);
yellowA100     := hex(0xffff8d);
yellowA200     := hex(0xffff00);
yellowA400     := hex(0xffea00);
yellowA700     := hex(0xffd600);

amber50        := hex(0xfff8e1);
amber100       := hex(0xffecb3);
amber200       := hex(0xffe082);
amber300       := hex(0xffd54f);
amber400       := hex(0xffca28);
amber500       := hex(0xffc107);
amber600       := hex(0xffb300);
amber700       := hex(0xffa000);
amber800       := hex(0xff8f00);
amber900       := hex(0xff6f00);
amberA100      := hex(0xffe57f);
amberA200      := hex(0xffd740);
amberA400      := hex(0xffc400);
amberA700      := hex(0xffab00);

orange50       := hex(0xfff3e0);
orange100      := hex(0xffe0b2);
orange200      := hex(0xffcc80);
orange300      := hex(0xffb74d);
orange400      := hex(0xffa726);
orange500      := hex(0xff9800);
orange600      := hex(0xfb8c00);
orange700      := hex(0xf57c00);
orange800      := hex(0xef6c00);
orange900      := hex(0xe65100);
orangeA100     := hex(0xffd180);
orangeA200     := hex(0xffab40);
orangeA400     := hex(0xff9100);
orangeA700     := hex(0xff6d00);

deep_orange50   := hex(0xfbe9e7);
deep_orange100  := hex(0xffccbc);
deep_orange200  := hex(0xffab91);
deep_orange300  := hex(0xff8a65);
deep_orange400  := hex(0xff7043);
deep_orange500  := hex(0xff5722);
deep_orange600  := hex(0xf4511e);
deep_orange700  := hex(0xe64a19);
deep_orange800  := hex(0xd84315);
deep_orange900  := hex(0xbf360c);
deep_orangeA100 := hex(0xff9e80);
deep_orangeA200 := hex(0xff6e40);
deep_orangeA400 := hex(0xff3d00);
deep_orangeA700 := hex(0xdd2c00);

brown50        := hex(0xefebe9);
brown100       := hex(0xd7ccc8);
brown200       := hex(0xbcaaa4);
brown300       := hex(0xa1887f);
brown400       := hex(0x8d6e63);
brown500       := hex(0x795548);
brown600       := hex(0x6d4c41);
brown700       := hex(0x5d4037);
brown800       := hex(0x4e342e);
brown900       := hex(0x3e2723);

blue_grey50     := hex(0xeceff1);
blue_grey100    := hex(0xcfd8dc);
blue_grey200    := hex(0xb0bec5);
blue_grey300    := hex(0x90a4ae);
blue_grey400    := hex(0x78909c);
blue_grey500    := hex(0x607d8b);
blue_grey600    := hex(0x546e7a);
blue_grey700    := hex(0x455a64);
blue_grey800    := hex(0x37474f);
blue_grey900    := hex(0x263238);

grey50         := hex(0xfafafa);
grey100        := hex(0xf5f5f5);
grey200        := hex(0xeeeeee);
grey300        := hex(0xe0e0e0);
grey400        := hex(0xbdbdbd);
grey500        := hex(0x9e9e9e);
grey600        := hex(0x757575);
grey700        := hex(0x616161);
grey800        := hex(0x424242);
grey900        := hex(0x212121);