/*
 * colors_scheme.vala
 * 
 * Copyright 2013-2014 Cyriac REMY <raum@no-log.org>
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
 * MA 02110-1301, USA.
 * 
 */

using Gee;
using Gtk;
using Cairo;

public class sColorBytes {
	public uint32 inf;
	public uint32 sup;
	public Gdk.RGBA color;
	public string str_color = "";
	
	public sColorBytes(uint32 i, uint32 s, string str) {
		inf = i;
		sup = s;
		str_color = str;
		
		color = ColorScheme.get_color(str);	
	}
	
	public string range_to_string() {
		if (inf == sup) 
			return "%lu byte". printf (inf);
			
		if (sup == -1) 
			return "> %lu bytes". printf (inf);
			
			
		return "%lu - %lu bytes". printf (inf, sup);
	}
	
	public string to_string() {
		return "[%lu - %lu ] => %s". printf (inf, sup, str_color);
	}
	
	public bool in_range(uint32 len) {
		if ((sup == -1) && (len >= inf)) return true;
		
		return (len >= inf) && (len <= sup);
	}
}

public  class ColorScheme {
	public static HashMap<string,Gdk.RGBA?> colors_table = null;
	public static ArrayList<sColorBytes> ColorPerBytes = null;
	
	public static void set_red(Context cr) {
		Gdk.cairo_set_source_rgba (cr, colors_table["red"]);
	}
	public static void set_black(Context cr) {
		Gdk.cairo_set_source_rgba (cr, colors_table["black"]);
	}

	public static void set_white(Context cr) {
		Gdk.cairo_set_source_rgba (cr, colors_table["white"]);
	}

	public static void set_color(Context ctx, string str_color) {
		if (str_color.has_prefix("#")) {
			Gdk.RGBA color = Gdk.RGBA();
			color.parse(str_color);
			Gdk.cairo_set_source_rgba (ctx, color);
		} else
			Gdk.cairo_set_source_rgba (ctx, colors_table[str_color.down()]);
	}
	
	public static Gdk.RGBA get_color(string str_color) {
		return colors_table[str_color.down()];
	}
	
	public static void init() {
		colors_table = new HashMap<string,Gdk.RGBA?>();
		
		string[] table = str_colors_table.split("\r\n");
		foreach (string s in table) {
			if (s == "") continue;
			
			string[] infos = s.split(";");
			Gdk.RGBA color = Gdk.RGBA();
			color.parse(infos[1]);
			colors_table[infos[0].down()] = color;
		}
		
		ColorPerBytes = new ArrayList<sColorBytes>();
		ColorPerBytes.add(new sColorBytes(0, 0, "size_red"));
		ColorPerBytes.add(new sColorBytes(1, 99, "size_orange"));
		ColorPerBytes.add(new sColorBytes(100, 499, "size_yellow"));
		ColorPerBytes.add(new sColorBytes(500, 999, "size_green"));
		ColorPerBytes.add(new sColorBytes(1000, 1459, "size_blue"));
		ColorPerBytes.add(new sColorBytes(1459, -1, "size_dark_blue"));
		
	}
	
	public static void set_color_by_lenght(Context ctx, uint32 len) {
		
		foreach (sColorBytes c in ColorPerBytes)
			if (c.in_range(len)) { Gdk.cairo_set_source_rgba (ctx, c.color); return; }
	}
}

const string str_colors_table = """Black;#000000
White;#ffffff
Dark_Blue;#000080
Dark_Green;#008000
Dark_Turquoise;#008080
Dark_Red;#800000
Dark_Magenta;#800080
Dark_Brown;#808000
Dark_Gray;#808080
gray;#c0c0c0
blue;#0000ff
green;#00ff00
cyan;#00ffff
red;#ff0000
magenta;#ff00ff
Yellow;#ffff00
Gray_80%;#333333
Gray_70%;#4c4c4c
Gray_60%;#666666
Gray_40%;#999999
Gray_30%;#b3b3b3
Gray_20%;#cccccc
Gray_10%;#e6e6e6
Blue_gray;#e6e6ff
Red_1;#ff3366
Red_2;#dc2300
Red_3;#b84700
Red_4;#ff3333
Red_5;#eb613d
Red_6;#b84747
Red_7;#b80047
Red_8;#99284c
Magenta_1;#94006b
Magenta_2;#94476b
Magenta_3;#944794
Magenta_4;#9966cc
Magenta_5;#6b4794
Magenta_6;#6b2394
Magenta_7;#6b0094
Magenta_8;#5e11a6
Blue_1;#280099
Blue_2;#4700b8
Blue_3;#2300dc
Blue_4;#2323dc
Blue_5;#0047ff
Blue_6;#0099ff
Blue_7;#00b8ff
Blue_8;#99ccff
Blue_9;#cfe7f5
Turquoise_1;#00dcff
Turquoise_2;#00cccc
Turquoise_3;#23b8dc
Turquoise_4;#47b8b8
Turquoise_5;#33a3a3
Turquoise_6;#198a8a
Turquoise_7;#006b6b
Turquoise_8;#004a4a
Green_1;#355e00
Green_2;#5c8526
Green_3;#7da647
Green_4;#94bd5e
Green_5;#00ae00
Green_6;#33cc66
Green_7;#3deb3d
Green_8;#23ff23
Yellow_1;#e6ff00
Yellow_2;#ffff99
Yellow_3;#ffff66
Yellow_4;#e6e64c
Yellow_5;#cccc00
Yellow_6;#b3b300
Yellow_7;#808019
Yellow_8;#666600
Brown_1;#4c1900
Brown_2;#663300
Brown_3;#804c19
Brown_4;#996633
Orange_1;#cc6633
Orange_2;#ff6633
Orange_3;#ff9966
Orange_4;#ffcc99
Violet;#9999ff
Bordeaux;#993366
Pale_yellow;#ffffcc
Pale_green;#ccffff
Dark_violet;#660066
Salmon;#ff8080
Sea_blue;#0066cc
Chart_1;#004586
Chart_2;#ff420e
Chart_3;#ffd320
Chart_4;#579d1c
Chart_5;#7e0021
Chart_6;#83caff
Chart_7;#314004
Chart_8;#aecf00
Chart_9;#4b1f6f
Chart_10;#ff950e
Chart_11;#c5000b
Chart_12;#0084d1
size_red;#ef0000
size_orange;#f78010
size_yellow;#efef00
size_green;#20B020
size_blue;#2090FF
size_dark_blue;#0000BD""";
