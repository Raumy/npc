/*
 * utils.vala
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
 * Regroupement de fonctions utiles.
 *
 */
// using NetFrames;


string bool_to_string(bool x) {
	return "%s".printf(x ? "true" : "false");
}
/*
double minus(double a) {
	return 0 - a;
}

double sqr(double a) {
	return a * a;
}

long timevaldiff(GLib.TimeVal starttime, GLib.TimeVal finishtime) {
	long msec;
	msec=(finishtime.tv_sec-starttime.tv_sec)*1000;
	msec+=(finishtime.tv_usec-starttime.tv_usec)/1000;
	return msec;
}

*/
string convert_duree(double duree, int precision = 2) {
	string format = "%4." + precision.to_string() + "f s";
	if (duree > 100000) // > 1s
		return format.printf (duree / 1000000);

	format = "%4." + precision.to_string() + "f ms";
	if (duree > 10000) // > 1s
		return format.printf (duree / 1000);

	format = "%4." + precision.to_string() + "f µs";
	return format.printf (duree);

}

string readble_bytes_count(int64 bytes, bool si = true) {
    int unit = si ? 1000 : 1024;

    if (bytes < unit) return bytes.to_string() + " B";

    int exp = (int) (Math.log(bytes) / Math.log(unit));

//    string pre = (si ? "kMGTPE" : "KMGTPE").charAt(exp-1) + (si ? "" : "i");
    string pre = (si ? "kMGTPE" : "KMGTPE").@get(exp-1).to_string() + (si ? "" : "i");


//    return String.format("%.1f %sB", bytes / Math.pow(unit, exp), pre);
    return "%.1f %sB".printf (bytes / Math.pow(unit, exp), pre);
}