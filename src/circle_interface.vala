/*
 * circle_interface.vala
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
 * Regroupement de classes permettant la création d'une structure
 * de type capture à partir d'un fichier au format PCAP standard.
 */

using Gee;
using Gtk;
using Cairo;
using NetFrames;

// Angle en degré = 180 * (angle en radian) / pi
// Angle en radian = pi * (angle en degré) / 180

/*
 * Ce fichier contient les classes permettant la création de l'affichage
 * en forme de cercle des hôtes à partir d'une structure capture.
 */


const int CIRCLE_MARGE_HORIZONTAL = 50;
const int CIRCLE_MARGE_VERTICAL = 50;

public enum DispText {
 SIZE,
 LATENCY
}

public enum DispLine {
	SINGLE,
	IN_OUT
}

/*
 * Il m'a semblé intéressant de décorréler la gestion du graphique
 * de la partie qui manipule les données.
 */

public class CircleConnection : TypedLine {
	public HostGraph hg1;  public HostGraph hg2;
	public Connection connection;

	public DispText text_type = DispText.SIZE;
	public DispLine line_type = DispLine.SINGLE;

	public bool show_size = true;

	public CircleConnection(int x1, int y1, int x2, int y2) {
		base.from_coordinates(x1, y1, x2, y2);

		start_style(ArrowHead.ArrowStyle.ARROW_SOLID);
		end_style(ArrowHead.ArrowStyle.ARROW_SOLID);
	}

	public CircleConnection.from_hostgraph(HostGraph hg1, HostGraph hg2) {
		Line l = new Line.from_coordinates(hg1.center_x, hg1.center_y, hg2.center_x, hg2.center_y);

		Point p1 = intersect_line_circle(l, hg1);
		Point p2 = intersect_line_circle(l, hg2);

		double p1x; double p1y; double p2x; double p2y;

		if ((p1 != null) && (p2 != null)) {
			p1x = p1.x; p1y = p1.y; 
			p2x = p2.x; p2y = p2.y;
		} else {
			p1x = hg1.center_x; p1y = hg1.center_y;
			p2x = hg2.center_x; p2y = hg2.center_y;
		}

		base.from_coordinates(p1x, p1y, p2x, p2y);

		this.hg1 = hg1; this.hg2 = hg2;

		start_style(ArrowHead.ArrowStyle.ARROW_SOLID);
		end_style(ArrowHead.ArrowStyle.ARROW_SOLID);
	}

    public new void draw(Context ctx) {
    	if (line_type == DispLine.IN_OUT) {
	    	TypedLine l1 = new TypedLine.from_coordinates(start.x, start.y, middle.x, middle.y);
	    	TypedLine l2 = new TypedLine.from_coordinates(end.x, end.y, middle.x, middle.y);

	    	l1.start_style (ArrowHead.ArrowStyle.ARROW_SOLID);
	    	// l1.end_style (ArrowHead.ArrowStyle.ARROW_SOLID);

	    	l2.start_style (ArrowHead.ArrowStyle.ARROW_SOLID);
	    	// l2.end_style (ArrowHead.ArrowStyle.ARROW_SOLID);

	    	l1.draw(ctx);
	    	l2.draw(ctx);

	    	if (text_type == DispText.SIZE) {
		    	show_vignette(ctx, l1.middle, readble_bytes_count(connection.size_from_host_a));
		    	show_vignette(ctx, l2.middle, readble_bytes_count(connection.size_from_host_b));
		    }
		    return;
		}

    	TypedLine l1 = new TypedLine.from_coordinates(start.x, start.y, end.x, end.y);
    	l1.start_style (ArrowHead.ArrowStyle.ARROW_SOLID);
    	l1.end_style (ArrowHead.ArrowStyle.ARROW_SOLID);

    	l1.draw(ctx);

    	if (text_type == DispText.SIZE) {
	    	show_vignette(ctx, l1.middle, readble_bytes_count(connection.total_size));
	    } else {
			show_vignette(ctx, l1.middle, NetFrames.latency_to_string(connection.latency));
		}

    }


}

public class NPC.CircleInterface : DrawingArea {
	Gtk.Menu popup = null;
	public unowned HostsGraph hosts_graph = null;
	public ArrayList<CircleConnection> connections = new ArrayList<CircleConnection>();

	public DispText text_type = DispText.SIZE;
	public DispLine line_type = DispLine.SINGLE;

	public bool host_move = false;
	public new NPC.Interface parent;

	public Rect get_circle_rect() {
		return new Rect.Region(
		               CIRCLE_MARGE_HORIZONTAL,
		               CIRCLE_MARGE_VERTICAL,
		               get_allocated_width() - CIRCLE_MARGE_HORIZONTAL * 2,
		               get_allocated_height() - CIRCLE_MARGE_VERTICAL * 2
		               );
	}

	public Rect get_area_rect() {
		return new Rect.Region(
		               0, 0,
		               get_allocated_width(),
		               get_allocated_height()
		               );
	}

	public CircleInterface(NPC.Interface parent) {
		set_size_request (200, 200);
		visible = true;
		can_focus = true;
		hexpand = true;
		vexpand = true;

		// initialisation du popup
		popup = NPC.MainWindow.builder.get_object("popup_circle") as Gtk.Menu;
		Gtk.MenuItem item = null;

		item = NPC.MainWindow.builder.get_object("popup_line_single") as Gtk.MenuItem;
		item.activate.connect(on_line_single);

		item = NPC.MainWindow.builder.get_object("popup_line_in_out") as Gtk.MenuItem;
		item.activate.connect(on_line_in_out);

		item = NPC.MainWindow.builder.get_object("popup_text_size") as Gtk.MenuItem;
		item.activate.connect(on_text_size);
		item = NPC.MainWindow.builder.get_object("popup_text_latency") as Gtk.MenuItem;
		item.activate.connect(on_text_latency);

		item = NPC.MainWindow.builder.get_object("popup_latency") as Gtk.MenuItem;
		item.activate.connect(on_latency);

		add_events(Gdk.EventMask.BUTTON_PRESS_MASK);
		add_events(Gdk.EventMask.BUTTON_RELEASE_MASK);
		add_events(Gdk.EventMask.POINTER_MOTION_MASK);
		add_events(Gdk.EventMask.KEY_RELEASE_MASK);

		draw.connect (on_draw);
		button_press_event.connect(on_drawingarea_button_press_event);
		button_release_event.connect(on_drawingarea_button_release_event);
		motion_notify_event.connect(on_drawingarea_mouse_move);
		key_release_event.connect(on_key_press);

		this.parent = parent;
		hosts_graph = parent.hosts_graph;
	}

	public void on_line_single() {
		line_type = DispLine.SINGLE;
		redraw();
	}

	public void on_line_in_out() {
		line_type = DispLine.IN_OUT;
		redraw();
	}

	public void on_text_size() {
		text_type = DispText.SIZE;
		redraw();
	}
	public void on_text_latency() {
		text_type = DispText.LATENCY;
		line_type = DispLine.SINGLE;
		redraw();
	}

	public void on_latency() {
		if (parent.conn_clicked == null) return;

		Gtk.Dialog d = NPC.MainWindow.builder.get_object("dlg_latency") as Gtk.Dialog;
		Gtk.Entry e = NPC.MainWindow.builder.get_object("entry_latency") as Gtk.Entry;
		e.set_text(NetFrames.latency_to_string(parent.conn_clicked.connection.latency));

		Gtk.Label l = NPC.MainWindow.builder.get_object("label_suggested") as Gtk.Label;
		l.set_text(NetFrames.latency_to_string(parent.conn_clicked.connection.suggested_latency));

		d.response.connect(test);

		d.run();
	}

	int32 parse_microseconds(string str_to_parse) {
		string str = str_to_parse.replace(" ", "");
		double parsed = 0;

		if (str.has_suffix("ms")) {
			str = str.replace("ms", "");
			parsed = double.parse(str);
			return (int32) (parsed * 1000);
		} 

		if (str.has_suffix("µs")) {
			str = str.replace("µs", "");
		}

		parsed = double.parse(str);
		return (int32) parsed;
	}

	public void test (Gtk.Dialog source, int response_id)  {
		if (! source.visible) return;
		Gtk.Entry e = NPC.MainWindow.builder.get_object("entry_latency") as Gtk.Entry; 

		switch (response_id) {
		case 1:
			parent.conn_clicked.connection.latency = parse_microseconds(e.get_text());
			source.visible = false;
			break;
		case 0:
		default:
			stdout.printf ("close\n");
			source.visible = false;
			break;
		}
	}

	public void on_renamed_host(string old_name, string new_name) {
		HostGraph hg = hosts_graph.search_by_name(old_name);

		if (hg != null)
			hg.name = new_name;

		redraw();
	}

	public bool on_key_press (Gdk.EventKey event) {
		if (has_focus) {
			if ((event.keyval == 65535) && (parent.clicked != null)) {
				parent.on_hosts_delete();
				redraw();
				return false;
			}

		}

		return true;
	}

	public bool on_drawingarea_button_release_event(Widget w, Gdk.EventButton event) {
		if (parent.clicked == null) {
			if  ((event.type == Gdk.EventType.BUTTON_RELEASE) && (event.button == 3) &&  (parent.capture != null))
				popup.popup(null, null, null, event.button, event.time);

			return true;
		}

		if (!host_move) return true;

		host_move = false;
		return true;
	}

	public bool on_drawingarea_mouse_move(Gdk.EventMotion event) {
		if ((parent.clicked == null) || (!host_move)) return true;

		calul_clicked_host_position((int)event.x, (int)event.y);

		redraw();

		return true;
	}

	public bool on_drawingarea_button_press_event(Widget w, Gdk.EventButton event) {
		Value val;

		if (host_move) return true;

		grab_focus();

		foreach (HostGraph hg in hosts_graph) {
			if (hg.is_clicked((int)event.x, (int)event.y)) {
				host_move = true;

				if (hg == parent.clicked) // already clicked
					return true;


				parent.clicked = hg;
				parent.conn_clicked = null;
				parent.deletion_progress = true;

				TreeIter iter;
				parent.ls_hosts.get_iter_first(out iter);

				do {
					parent.ls_hosts.get_value (iter, 0, out val);

					if ((string) val == hg.host_addr.to_string()) {
						Gtk.TreePath path = new Gtk.TreePath ();
						path.append_index (hg.num);
						parent.tsel_hosts.select_path (path);
					}
				} while  (parent.ls_hosts.iter_next(ref iter));

				parent.deletion_progress = false;

				parent.sig_clicked_host(hg);

				redraw();
				return true;
			}
		}

		foreach (CircleConnection cg in connections) {
			if (cg.distance_from((int) event.x, (int) event.y) < 5) {
				parent.conn_clicked = cg;
				parent.clicked = null;
				parent.sig_clicked_connection(parent.conn_clicked.connection);
				redraw();
				return true;
			}
		}
		parent.conn_clicked = null;
		parent.clicked = null;
		return true;
	}

	public void redraw() {
		queue_draw_area (0, 0,
		                 get_allocated_width(), get_allocated_height());
	}

	public void calul_clicked_host_position(int x, int y) {
		int dx; int dy;

		Rect ellipse = get_circle_rect();

		dx = (ellipse.center_x - x);
		dy = (ellipse.center_y - y);

		double rapport = (double) ellipse.height / (double) ellipse.width;
		parent.clicked.angle = Math.atan2((double) (dy / rapport), dx);
		calcul_sing_host_position(parent.clicked);
	}

	// on a l'angle d'un hote graphie et on calcule ses coordonnees
	// par rapport a la taille de l'aire a tracer.
	public void calcul_sing_host_position(HostGraph hg) {
		Rect ellipse = get_circle_rect();

		int eWidth;
		int eHeight;
		int lx;
		int ly;

		eWidth = ellipse.right - ellipse.left;
		eHeight = ellipse.bottom - ellipse.top;

		lx = (int) Math.round((eWidth / 2) * Math.cos(hg.angle));
		ly = (int) Math.round((eHeight / 2) * Math.sin(hg.angle));

		hg.put(
		        ellipse.left + (int)((eWidth / 2) - lx) - HOST_RADIUS,
		        ellipse.top + (int)((eHeight / 2) - ly)- HOST_RADIUS);

	}

	// ici on calcule l'angle par rapport à la position de l'hote
	// sera utilisé dans le cas où l'on a sélectionné un hote.
	public void calcul_sing_host_angle(HostGraph hg) {
		Rect ellipse = get_circle_rect();

		double rapport;
		int dx;
		int dy;

		rapport = (double)(ellipse.height / ellipse.width);

		dx = hg.left - ellipse.left - (int) (ellipse.width / 2);
		dy = (int) Math.round((hg.top - ellipse.top - ellipse.height / 2) / rapport);
		hg.angle = Math.atan2(dx, -dy) + (Math.PI / 2);
	}

	public void draw_circle(Context context) {
		context.save();
		double xc;
		double yc;
		double rapport;

		Rect ellipse = get_circle_rect();

		int width = ellipse.width;
		int height = ellipse.height;


		int max = int.max(width, height);

		double radius = (double) max / 2;

		context.set_source_rgba (0, 0, 0, 1);

		if (max == width) {
			rapport = (double) height / (double) max;
			xc = ellipse.center_x;
			yc = ellipse.center_y / rapport;
			context.scale(1, rapport);
			context.arc(xc, yc, radius, 0, 2 * Math.PI);
		} else {
			rapport = (double) width / (double) max;
			xc =ellipse.center_x / rapport;
			yc = ellipse.center_y;
			context.scale(rapport, 1);
			context.arc(xc, yc, radius, 0, 2 * Math.PI);
		}

		context.stroke();
		context.restore();
	}

	public void calcul_all_hosts_positions() {
		foreach(HostGraph hg in hosts_graph)
			calcul_sing_host_position(hg);
	}

	public void draw_host_on_circle(Context context) {
		Rect ellipse = get_circle_rect();

		context.save();

		foreach(HostGraph hg in hosts_graph) {
			if (hg.hide) continue;


			if ((parent.clicked != null) && (hg.num == parent.clicked.num))
				context.set_source_rgba (1, 0, 0, 1);
			else
				context.set_source_rgba (0, 0, 0, 1);

			hg.draw_host(context);

			if ((parent.capture.capture_from != null) && (parent.capture.capture_from.equal(hg.host_addr))) {

				context.save();
				context.set_source_rgba (0, 1, 0, 1);
				context.arc(hg.center_x, hg.center_y, HOST_RADIUS -2, 0, 2 * Math.PI);
				context.stroke();
				context.restore();

			}

			hg.draw_text(context, ellipse);

		}
		context.restore();
	}

	public void draw_connections(Context context) {
		context.save();

		context.set_source_rgba (0, 0, 0, 1);
		context.set_line_width (2);

		connections.clear();
		foreach (Connection c in parent.capture.connections) {
			HostGraph hg1 = hosts_graph.search_by_ip(c.host_a);
			HostGraph hg2 = hosts_graph.search_by_ip(c.host_b);

			if (hg1.hide || hg2.hide) continue;


			CircleConnection gc = new CircleConnection.from_hostgraph(hg1, hg2);
			gc.line_type = line_type;
			gc.text_type = text_type;
			// gc.show_size = show_size; gc.show_single_line = show_single_line;
			gc.connection = c;
			connections.add(gc);

			if ((parent.conn_clicked != null) && (parent.conn_clicked.hg1 == hg1) && (parent.conn_clicked.hg2 == hg2))
				context.set_source_rgba (1, 0, 0, 1);
			else
				context.set_source_rgba (0, 0, 0, 1);

			gc.draw(context);
		}

		context.stroke();
		context.restore();

	}

	public bool on_draw(Widget da, Context context) {

		context.set_source_rgba (1, 1, 1, 1);
		context.rectangle (0, 0, get_allocated_width(), get_allocated_height());
		context.fill ();

		draw_circle(context);

		if (parent.capture == null) return true;

		calcul_all_hosts_positions();
		draw_connections(context);
		draw_host_on_circle(context);

		return true;
	}
}

