/*
 * navigator_interface.vala
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


// TODO: il faut ajouter deux fonctionnalites :
// schema réseau avec latence par connection
// Au lieu de faire un "host reference", faire une liste de reference. Si deux hotes sont références alors ne pas utiliser la latence.

// 1 millisecond = 1000 microseconds
// 1 second = 1000 milliseconds
// latency = 20ms = 20 000 µs


//		Context context = Gdk.cairo_create(da.get_window());


struct MouseInfos {
	double time;
	double position;
}

public class NavigatorLine : TypedLine {
	public Frames frames = new Frames();
	public bool selected = false;
	public bool changed = true;
	public uint32 len = 0;

	public NavigatorLine(Point s, Point e) {
		base(s, e);
	}
	public NavigatorLine.from_line(Line l) {
		base(l.start, l.end);
	}

	public NavigatorLine.from_coordinates(int x1, int y1, int x2, int y2) {
		base.from_coordinates(x1, y1, x2, y2);
	}

	public void add_frame(NetFrames.Frame f) {
		frames.add(f);
		len += f.len;
	}
}

public class NavigatorLines : HashMap<uint,NavigatorLine> {
	public NavigatorLine add_line(NetFrames.Frame ? f, Line l) {
		// false => on n'a pas à redessiner, true => on doit dessiner ce nouveau trait
		uint hash = l.hash();
		NavigatorLine nl = null;

		if (this[hash] != null) {
			this[hash].add_frame(f);
		} else {
			nl = new NavigatorLine(l.start, l.end);
			nl.start_style(ArrowHead.ArrowStyle.ARROW_SOLID);
			nl.add_frame(f);
			set(hash, nl);
		}
		return (NavigatorLine) nl;
	}
}

public class Rubberband {
	public int x1 = -1;
	public int y1 = -1;
	public int x2 = -1;
	public int y2 = -1;
	public Gdk.RGBA color;

	public void reset() {
		x1 = -1; y1 = -1; x2 = -1; y2 = -1;
	}
}

public class DrawingNavigator : DrawingArea {
	public Gtk.Builder builder { 
		get { 
			return NPC.MainWindow.builder; 
		} 
	}

	const int MARGE_HORIZONTAL = 70;
	const int MARGE_VERTICAL = 50;

	int navigator_width {
		get {
			return get_allocated_width() - 2 * MARGE_HORIZONTAL;
		}
	}

	int navigator_height {
		get {
			return get_allocated_height() - 2 * MARGE_VERTICAL;
		}
	}

	unowned NPC.NavigatorInterface parent = null;
	public unowned HostsGraph hosts_graph = null;
	public HostGraph clicked = null;

	Rubberband rubberband = new Rubberband();
	bool doing_rubberband = false;

	Gtk.Menu popup = null;

	MouseInfos mouse_infos;
	public NavigatorLines nav_lines = new NavigatorLines();

	Rect region_invalidation = new Rect.Null();

	public Frames frames_selected = new Frames();

	bool zoom_selection = false;

	public DrawingNavigator(NPC.NavigatorInterface parent) {
		this.parent = parent;
		this.hosts_graph = parent.hosts_graph;
		expand = true;
		mouse_infos.time = -1;

		// initialisation du popup
		popup = NPC.MainWindow.builder.get_object("popup_hosts") as Gtk.Menu;

		((Gtk.MenuItem) builder.get_object("popup_hosts_delete")).activate.connect(on_hosts_delete);
		((Gtk.MenuItem) builder.get_object("popup_hosts_icon")).activate.connect(on_hosts_change_icon);
		((Gtk.MenuItem) builder.get_object("popup_reference")).activate.connect(on_hosts_reference);
		((Gtk.MenuItem) builder.get_object("popup_host_hide")).activate.connect(on_hosts_hide_unhide);

		// initialisation des signaux
		add_events(Gdk.EventMask.BUTTON_PRESS_MASK);
		add_events(Gdk.EventMask.BUTTON_RELEASE_MASK);
		add_events(Gdk.EventMask.POINTER_MOTION_MASK);

		draw.connect(on_draw);
		motion_notify_event.connect(on_mouse_move);
		button_press_event.connect(on_button_press_event);
		button_release_event.connect(on_button_release_event);

	}

	public void on_hosts_delete() {
		parent.parent.on_hosts_delete();
		calcul_hosts_position();
		build_nav_lines();
		redraw();
	}

	public void on_hosts_change_icon() {
		parent.parent.on_hosts_change_icon();
		redraw();
	}

	public void on_hosts_reference() {
		parent.parent.add_host_as_reference(parent.parent.clicked);
		build_nav_lines();
		redraw();
	}

	public void on_hosts_hide_unhide() {
		if (clicked == null) return;

		clicked.hide = !clicked.hide;
		calcul_hosts_position();
		build_nav_lines();
		redraw();
	}

	public void calcul_hosts_position() {
		if (parent.parent.capture == null) return;

		int gap = (int) (navigator_height / (hosts_graph.unhide_size() - 1));
		int start_y = MARGE_VERTICAL;

		foreach (HostGraph hg in hosts_graph) {
			if (hg.hide) continue;

			hg.put(20, start_y  - HOST_RADIUS);

			start_y += gap;
		}
	}

	int calcul_abscisse(int64 microtime) {
		return (int) ( (microtime - parent.ajust_scroll.value)* navigator_width / parent.interval);
	}

	// calcule l'abscisse  donnée par le temps de la trame
	public int get_abscisse_from_time(NetFrames.Frame f) {
		// temps entre la première trame affichée et la trame en paramètre
		// diff est en µs
		DateTime dt =  new DateTime.from_timeval_utc (f.pcap_frame.rec.ts);

		return calcul_abscisse(dt.difference(parent.from));
	}

	public int delay(int latency) {
		return (int) (latency * get_allocated_width() / parent.interval); // intervalle de 1s, soit 1000ms
	}

	public void build_nav_lines() {
		if (parent.parent.capture == null) return;

		// HostGraph ref_host = parent.parent.ref_host;

		HostGraph hg1 = null;
		HostGraph hg2 = null;

		Line line = null;
		nav_lines.clear();
		
		foreach (Connection c in parent.capture.connections) {
			foreach (Session s in c.sessions) {
				if (parent.sessions_hide.search_session(s) != null) continue;
				
				 foreach (NetFrames.Frame f in s.frames) {
				//int index = 0;
				//for (index = 0; index < s.frames.size; index++) {
				//	NetFrames.Frame f = s.frames[index];
					NetFrames.Frame reference = null;
					int abs = 0;

					hg1 = hosts_graph.search_by_ip(f.src);
					hg2 = hosts_graph.search_by_ip(f.dst);

					if (hg1.hide || hg2.hide) continue;

					if ((s.flow_informations != null) && (s.flow_informations.has_reference_frame(f, out reference)))
						abs = get_abscisse_from_time(reference) + MARGE_HORIZONTAL;
					else
						abs = get_abscisse_from_time(f) + MARGE_HORIZONTAL;


					if (abs > get_allocated_width() - MARGE_HORIZONTAL) continue;
//					if (abs < MARGE_VERTICAL + HOST_DIAMETER) continue;


					// la trame en cours peut avoir :
					// un hote référence en adresse source, donc il faut ajouter la latence
					// un hote référence en adresse destination, donc il faut soustraire la latence
					// ni l'un ni l'autre, et bien on ajoute la latence par défaut

					if (parent.parent.is_host_reference(hg1.host_addr)) {
						line = new Line.from_coordinates(abs, hg1.center_y, get_abscisse_from_time(f) + MARGE_HORIZONTAL + delay(c.latency), hg2.center_y);					
//						stdout.printf ("Frame %s is source and reference\n", hg1.host_addr.to_string());
					} 
					else if (parent.parent.is_host_reference(hg2.host_addr)) {
//						line = new Line.from_coordinates(get_abscisse_from_time(f) + MARGE_VERTICAL - delay(c.latency), hg1.center_y, abs , hg2.center_y);					
						line = new Line.from_coordinates(abs - delay(c.latency), hg1.center_y, get_abscisse_from_time(f) + MARGE_HORIZONTAL , hg2.center_y);					
//						stdout.printf ("Frame %s is destination and reference\n", hg2.host_addr.to_string());

					} else
						line = new Line.from_coordinates(abs, hg1.center_y, get_abscisse_from_time(f) + MARGE_HORIZONTAL + delay(c.latency), hg2.center_y);
/*
					if (reference != null) {
						stdout.printf ("%d has ref %d\n", (int) f.num, (int) reference.num );
					}
*/
/*
	// Pour le moment la corrélation de trames ne fonctionne pas....
					if (parent.parent.is_host_reference(hg1.host_addr) && parent.parent.is_host_reference(hg2.host_addr)) {
						stdout.printf ("double ref\n");

						if (s.get_next_from_frame(f, out next)) {
							stdout.printf ("%d / %d\n", (int) f.num, (int) next.num);
							f.display(); next.display();
							if (f.pcap_frame.tcp_hdr.th_seq == next.pcap_frame.tcp_hdr.th_ack) {
								int abs2 = get_abscisse_from_time(next) + MARGE_VERTICAL;
								line = new Line.from_coordinates(abs, hg1.center_y, abs2, hg2.center_y);
								double latency = next.time.tv_usec - f.time.tv_usec;
								stdout.printf ("%f\n", latency / 1000);
							} 
						}
					}
*/
/*
					if (line == null)
						line = new Line.from_coordinates(abs, hg1.center_y, get_abscisse_from_time(f) + MARGE_VERTICAL + delay(c.latency), hg2.center_y);
*/
					nav_lines.add_line(f, line);
					line = null;					
					// index++;
				}
			}
		}
		stdout.printf ("\n\n");
	}

	public void draw_nav_lines(Context context, bool force = false) {

		// http://references.valadoc.org/#!api=cairo/Cairo.Context.set_antialias

		foreach (uint key in nav_lines.keys) {
			NavigatorLine l = nav_lines[key];

			if (!l.changed && !force) continue;

			l.changed = false;

			if (l.selected)
				ColorScheme.set_color(context, "Gray_60%");
			else
				ColorScheme.set_color_by_lenght(context, l.len);

			l.draw(context);
		}
	}

	public void draw_microtime(Context context) {
		if (mouse_infos.time == -1) return;

		context.rectangle(0, 0,  get_allocated_width(), 25);
		context.clip();
		ColorScheme.set_color(context, "Pale_green");
		context.rectangle (0, 0, get_allocated_width(), 25);
		context.fill ();

		ColorScheme.set_black(context);
		Cairo.TextExtents extents;
		context.select_font_face ("Arial", Cairo.FontSlant.NORMAL, Cairo.FontWeight.NORMAL);
		context.set_font_size (10);

		string time_text = convert_duree(mouse_infos.time, 4);
		context.text_extents (time_text, out extents);
		context.move_to (mouse_infos.position, 20);
		context.show_text (time_text);

		string s = "de %s a %s".printf (convert_duree(time_from_abscisse(50), 4),
		                                convert_duree(time_from_abscisse(get_allocated_width() - 50), 4));
		context.move_to (20, 10);
		context.show_text (s);

	}

	public bool on_draw(Widget da, Context context) {
		Gdk.Rectangle rubber_rect = Gdk.Rectangle();
/*
		uint keyval;
		Gdk.ModifierType modifiers;

		Gdk.Device.get_key (0, out  keyval, out  modifiers) ;
*/

		//stdout.printf("shift state %d\n", test);

		if (parent.parent.capture == null) return true;

		if (doing_rubberband) {
			rubber_rect.x = (int) Math.fmin(rubberband.x1, rubberband.x2);
			rubber_rect.y = (int) Math.fmin (rubberband.y1, rubberband.y2);
			rubber_rect.width = (int) Math.fabs (rubberband.x1 - rubberband.x2);
			rubber_rect.height = (int) Math.fabs (rubberband.y1 - rubberband.y2);

			if (!region_invalidation.is_null) {
				context.rectangle(region_invalidation.left - 5, region_invalidation.top - 5,
				                  region_invalidation.width + 5, region_invalidation.height + 5);
				context.clip();
				region_invalidation.set(rubber_rect.x - 10, rubber_rect.y - 10,
				                        rubber_rect.width + 20, rubber_rect.height + 20);
			}

			if (NPC.MainWindow.shift_pressed || zoom_selection)
				ColorScheme.set_color(context, "blue");
			else
				ColorScheme.set_color(context, "black");

			context.rectangle (rubber_rect.x, rubber_rect.y, rubber_rect.width, rubber_rect.height);
			context.stroke ();
		}

		foreach (HostGraph hg in hosts_graph) {
			if (hg.hide) continue;

			ColorScheme.set_black(context);

			context.move_to (0, hg.center_y);
			context.line_to (get_allocated_width(), hg.center_y);
			context.stroke();

			if (clicked == hg)
				ColorScheme.set_red(context);

			hg.draw_host(context);
			hg.draw_text(context);
		}

		draw_nav_lines(context, true);
		return true;
	}

	public bool on_button_release_event(Widget w, Gdk.EventButton event) {
		if (!zoom_selection && ((event.type == Gdk.EventType.BUTTON_RELEASE) && (event.button == 3))) {
			if (clicked != null)
				popup.popup(null, null, null, event.button, event.time);

			return true;
		}

		if (doing_rubberband) {
			int left = (int) Math.fmin(rubberband.x1, rubberband.x2);
			int width = (int) Math.fabs (rubberband.x1 - rubberband.x2);

			stop_rubberbanding();

			if (( width > 20) && (NPC.MainWindow.shift_pressed || zoom_selection)) {
				double factor = (double) get_allocated_width() / (double) width;
				double time = time_from_abscisse(left);

				parent.ajust_scale.value = parent.ajust_scale.value / factor;
				parent.ajust_scroll.value = time;
				zoom_selection = false;
				redraw();
			}
			parent.parent.refresh_frames_list_from_frames(frames_selected);
		}

		return false;
	}

	void unselect_frames() {
		foreach (uint key in nav_lines.keys) {
			NavigatorLine l = nav_lines[key];

			if (l.selected) {
				l.selected = false;

				l.changed = true;
			}
		}
	}

	void start_rubberbanding (int x, int y) {
		rubberband.x1 = x;
		rubberband.x2 = x;
		rubberband.y1 = y;
		rubberband.y2 = y;

		if (NPC.MainWindow.shift_pressed || zoom_selection)
			rubberband.color = ColorScheme.get_color("blue");
		else
			rubberband.color = ColorScheme.get_color("black");

		doing_rubberband = true;
	}

	void stop_rubberbanding () {
		if (!doing_rubberband) return;

		doing_rubberband = false;

		region_invalidation.reset();
		rubberband.reset();

		redraw();
	}

	bool update_rubberband_selection () {
		bool changed = false;
		int changements = 0;

		int x, y;
		int width;
		int height;

		/* determine the new rubberband area */
		x = (int) Math.fmin (rubberband.x1, rubberband.x2);
		y = (int) Math.fmin (rubberband.y1, rubberband.y2);
		width = (int) Math.fabs (rubberband.x1 - rubberband.x2);
		height = (int) Math.fabs (rubberband.y1 - rubberband.y2);

		Rect region = new Rect.Region (x, y, width, height);

		foreach (uint key in nav_lines.keys) {
			NavigatorLine l = nav_lines[key];

			if (line_in_rectangle(l, region) || line_intersect_rectangle(l, region)) {
				foreach (NetFrames.Frame f in l.frames) {
					if (!frames_selected.contains(f))
						frames_selected.add(f);

				}

				l.selected = true;
				l.changed = true;
				changements++;
				queue_draw_item (l);
			} else {
				if (l.selected) {
					l.selected = false;
					foreach (NetFrames.Frame f in l.frames)
						frames_selected.remove(f);

					l.changed = true;
					changements++;
					queue_draw_item (l);
				}
			}
		}

		if ((changements >0) && (changements < 15))
			parent.parent.refresh_frames_list_from_frames(frames_selected);

		region_invalidation = rectangle_overlap(
		        region_invalidation,
		        new Rect.Region(x, y, width, height)
		        );
		get_window().invalidate_rect(region_invalidation.GdkRectangle(), false);

		return changed;
	}

	void queue_draw_item (NavigatorLine l) {
		region_invalidation = rectangle_overlap(
		        region_invalidation,
		        new Rect.Coordinates((int) l.start.x,(int) l.start.y,
		                             (int) l.end.x, (int) l.end.y)
		        );
	}


	HostGraph get_item_at_coords (int x, int y) {
		foreach (HostGraph hg in hosts_graph)
			if (hg.is_clicked(x, y))
				return hg;

		return (HostGraph) null;
	}

	public bool on_button_press_event(Widget w, Gdk.EventButton event) {
		unselect_frames();

		if ((clicked = get_item_at_coords((int) event.x, (int) event.y)) != null) {
			parent.parent.clicked = clicked;
			return true;
		}

		if ((event.x < MARGE_HORIZONTAL) || (event.x > get_allocated_width() - MARGE_HORIZONTAL)) return true;

		if (event.button == 3)
			zoom_selection = true;

		start_rubberbanding((int) event.x, (int) event.y);
		frames_selected.clear();
		redraw();

		return true;
	}

	public bool on_mouse_move(Gdk.EventMotion event) {
//		if ((event.x < MARGE_HORIZONTAL) || (event.x > get_allocated_width() - MARGE_HORIZONTAL)) return false;

		mouse_infos.time = time_from_abscisse(event.x);
		mouse_infos.position = event.x;

		draw_microtime(Gdk.cairo_create(get_window()));

		if (!doing_rubberband) {
			return true;
		}

		rubberband.x2 = (int) event.x;
		rubberband.y2 = (int) event.y;

		update_rubberband_selection();
		return true;
	}

	public void redraw() {
		queue_draw_area (0, 0,
		                 get_allocated_width(),
		                 get_allocated_height());
	}

	public double time_from_abscisse(double x) {
		int wtx = get_allocated_width() - 2 * MARGE_HORIZONTAL;

		return ((x - MARGE_HORIZONTAL) * parent.interval) / wtx + parent.ajust_scroll.value;
	}

}

public class NPC.NavigatorInterface {
	public NPC.Interface parent;
	public DrawingNavigator da = null;

	public Capture capture { get { return parent.capture; } }
	public HostsGraph hosts_graph = null;
	public NavigatorLines nav_lines { get { return da.nav_lines; } }
	public Sessions sessions_hide { get { return parent.sessions_hide; } }
	// public ListStore ls_hosts_ref { get { return parent.ls_hosts_ref; } }


	public Adjustment ajust_scale = null;
	public Adjustment ajust_scroll = null;

	public Scrollbar scroll = null;

	Label lb_interval = null;
	public int interval = 0;
//	public int latency = 10000; // 10 ms = 10 000 µs
//	public int latency = 1000; // 10 ms = 10 000 µs  LAN LATENCY

	public DateTime from =  null;
	public DateTime to =  null;

	public NavigatorInterface(NPC.Interface parent) {
		this.parent = parent;
		hosts_graph = parent.hosts_graph;

		da = new DrawingNavigator(this);
		Box box = NPC.MainWindow.builder.get_object("box4") as Box;
		box.add(da);
		box.reorder_child (da, 0);

		DrawingArea infos_len = NPC.MainWindow.builder.get_object("da_navigator") as DrawingArea;
		infos_len.draw.connect(on_draw_infos_length);
		infos_len.override_background_color(StateFlags.NORMAL, ColorScheme.get_color("Gray_10%"));


		ajust_scale =NPC.MainWindow.builder.get_object("adj_scale") as Adjustment;
		ajust_scale.value_changed.connect(resize_navigator);

		ajust_scroll = NPC.MainWindow.builder.get_object("adj_scroll") as Adjustment;
		ajust_scroll.value_changed.connect(scroll_navigator);

		scroll = NPC.MainWindow.builder.get_object("scrollbar1") as Scrollbar;

		da.configure_event.connect(navigator_configure_event);
		da.override_background_color(StateFlags.NORMAL, ColorScheme.get_color("Gray_10%"));

		lb_interval = NPC.MainWindow.builder.get_object("lb_interval") as Label;
	}


	public bool on_draw_infos_length(Widget da, Context context) {
		context.select_font_face ("Arial", Cairo.FontSlant.NORMAL, Cairo.FontWeight.NORMAL);
		context.set_font_size (10);

		int x = 50;
		foreach (sColorBytes c in ColorScheme.ColorPerBytes) {
			Gdk.cairo_set_source_rgba (context, c.color);
			context.move_to(x,5);
			context.line_to(x,30);
			context.stroke();

			context.move_to (x + 10, 20);
			context.show_text (c.range_to_string());

			x+= 110;
		}
		return false;
	}

	public bool navigator_configure_event (Gdk.EventConfigure event) {
		if (event.type == Gdk.EventType.CONFIGURE) {
			da.calcul_hosts_position();
			da.build_nav_lines();
			da.redraw();
		}
		return false;
	}


	public void scroll_navigator() {
		da.build_nav_lines();
		da.redraw();
	}

	public void resize_navigator() {
		TimeSpan diff = to.difference(from);
		 if (ajust_scale.value < 0.01) ajust_scale.value = 0.01;

		// interval correspond au temps "affichable" sur le navigateur
		// par exemple sur une capture de 5s, on n'affiche que 1s
		interval = (int) (ajust_scale.value * diff / 100);

		ajust_scroll.lower = -1000;

		ajust_scroll.upper = (int) diff - interval;

		// Label l = parent.builder.get_object("lb_interval") as Label;
		lb_interval.set_label(convert_duree(interval));

		da.build_nav_lines();
		
		da.redraw();

	}

	public void init_from_capture(Capture capture) {
		// pour déter(int) Math.fminer le début et la fin de l'intervalle, il faut récupérer les première et
		// dernière trames d'hôtes visible.... Avec la méthode ci-dessus, si les hôtes sont cachés
		// on n'a pas la "bonne taille de fenêtre".

		from = null;
		to = null;

		HostGraph hg1 = null;
		HostGraph hg2 = null;

		if (hosts_graph == null) stdout.printf ("NULL\n");

		foreach (NetFrames.Frame f in capture.frames) {
			if ((hg1 == null) || (!f.src.equal(hg1.host_addr))) hg1 = hosts_graph.search_by_ip(f.src);
			if ((hg2 == null) || (!f.dst.equal(hg2.host_addr))) hg2 = hosts_graph.search_by_ip(f.dst);

			if (hg1.hide || hg2.hide) continue;

			if (from == null)
				from = new DateTime.from_timeval_utc (f.pcap_frame.rec.ts);

			to  = new DateTime.from_timeval_utc (f.pcap_frame.rec.ts);
		}


		ajust_scale.upper = 100;
		ajust_scale.value = 100;
		resize_navigator();

		da.nav_lines.clear();

		recalcul_all();
	}

	public void recalcul_all() {
		da.calcul_hosts_position();
		da.build_nav_lines();
		da.redraw();
	}
}

