/*
 * hosts_graph.vala
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
 * Regroupement de classes permettant la création et la manipulation
 * d'une réprésention d'un hôte, il s'agit d'un objet positionnable
 *
 */

using Gee;
using Cairo;


const int HOST_RADIUS = 20;
const int HOST_DIAMETER = HOST_RADIUS * 2;

// En fait comme je recalcule systématiquement l'emplacement des hôtes
// graphique pour chaque interface, je n'ai besoin que d'une classe.
// Pour le cercle, il s'agit de coordonnées polaires.
// Pour le navigateur, elles sont cartésiennes.

public class HostGraph : Rect {
	public int num = 0;
	public bool hide = false;

	protected string _name = "";
	protected InetAddress _host_addr = null;

	public Gdk.Pixbuf icon = null;
	public double angle = 0;

	public InetAddress host_addr {
		get { return _host_addr; }
		set {
			_host_addr = value;
			if (_name == "")
				_name = _host_addr.to_string();
		}
	}

	public string name { get { return _name; } set { _name = value; } }

	public bool is_renamed { get { return _name != _host_addr.to_string(); } }

	public new int center_x { get { return left + HOST_RADIUS; } }
	public new int center_y { get { return top + HOST_RADIUS; } }

	public bool is_clicked(int x, int y) {
		return in_rect(x, y);
	}

	public void draw_host(Context context) {
		if (icon == null) {
			context.move_to(center_x, center_y);
			context.arc(center_x, center_y, HOST_RADIUS, 0, 2 * Math.PI);
			context.fill();
		} else {
			context.save();
			Gdk.cairo_set_source_pixbuf(context, icon, center_x - HOST_RADIUS, center_y - HOST_RADIUS);
			context.paint();
			context.restore();
		}
	}

	public void draw_text(Context context, Rect ? ellipse = null) {
		Cairo.TextExtents extents;
		context.select_font_face ("Arial", Cairo.FontSlant.NORMAL, Cairo.FontWeight.NORMAL);
		context.set_font_size (10);

		context.text_extents (name, out extents);

		if ((ellipse != null) && (center_y < ellipse.center_y))
			context.move_to (center_x - extents.width / 2, center_y - HOST_RADIUS - 5);
		else
			context.move_to (center_x - extents.width / 2, center_y + HOST_RADIUS + 10);

		context.show_text (name);
	}

	public HostGraph.Null() {
		base.Dimensions(HOST_DIAMETER, HOST_DIAMETER);
		// this.parent = parent;
	}

	public HostGraph.Circle(int x, int y, double angle) {
		base.Region(x, y, HOST_DIAMETER, HOST_DIAMETER);
		this.angle = angle;
	}

	public HostGraph.Navigator(int x, int y) {
		this.Region(x, y, HOST_DIAMETER, HOST_DIAMETER);
	}

	public new void display() {
		// stdout.printf("num:%d, x:%d, y:%d, w:%d, h:%d, angle:%f\n", num, left, top, width, height, angle);
	}

}


public class HostsGraph : ArrayList < HostGraph > {
	public int unhide_size() {
		int count = 0;
		foreach (HostGraph hg in this)
			if (!hg.hide) count++;

		return count;
	}

	public HostGraph search_by_ip(InetAddress ? ip) {
		if (ip == null) (HostGraph) null;

		foreach (HostGraph hg in this) {
			if (ip.equal(hg.host_addr))
				return hg;
		}
		return (HostGraph) null;
	}

	public HostGraph search_by_name(string name) {
		foreach (HostGraph hg in this) {
			if (hg.name == name)
				return hg;
		}
		return (HostGraph) null;
	}

	public void delete_host(InetAddress host) {
		int i = 0;
		HostGraph hg = null;

		while (i < size) {
			hg = this[i];

			if (hg.host_addr.equal(host)) {
				remove(hg);
			}
			else i++;

		}
	}

	public void clear_orphans_hostgraph() {
		int i = 0;
		HostGraph hg = null;

		while (i < size) {
			hg = this[i];

			if (hg.host_addr == null)
				remove(hg);
			else i++;

		}

	}
}
