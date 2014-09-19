/*
 * NPC_interface.vala
 * 
 * Copyright 2013 Cyriac REMY <cyriac.remy@no-log.org>
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

public class ConnectsInfos {
	Connection _connection = null;
	Session _session = null;

	
	public Connection connection { 
		get { 
			return _connection; 
		} 
	}

	public Session session { 
		get { 
			return _session; 
		} 
	}

	public bool is_connection { 
		get { 
			return ((_connection != null) && (_session == null)); 
		} 
	}

	public bool is_session { 
		get { 
			return _session != null; 
		} 
	}
	
	public ConnectsInfos(Capture capture, string line) {
		string ip_src;
		string ip_dst;
		int16 port_src;
		int16 port_dst;
		
		MatchInfo info;
		var r1 = new Regex ("(?P<ip_src>\\d+\\.\\d+\\.\\d+\\.\\d+) <--> (?P<ip_dst>\\d+\\.\\d+\\.\\d+\\.\\d+)");
		var r2 = new Regex ("(?P<ip_src>\\d+\\.\\d+\\.\\d+\\.\\d+) <--> (?P<ip_dst>\\d+\\.\\d+\\.\\d+\\.\\d+) \\(frames: \\d+\\) S:(?P<port_src>\\d+) D:(?P<port_dst>\\d+) .*");

		if (r1.match(line, 0, out info)) {
			ip_src = info.fetch_named("ip_src");
			ip_dst = info.fetch_named("ip_dst");
			_connection = capture.connections.search_connection(new Connection(new InetAddress.from_string(ip_src), new InetAddress.from_string(ip_dst)));
		}

		if (r2.match(line, 0, out info)) {
			ip_src = info.fetch_named("ip_src");
			ip_dst = info.fetch_named("ip_dst");
			port_src = (int16) int.parse(info.fetch_named("port_src"));
			port_dst = (int16) int.parse(info.fetch_named("port_dst"));

			_connection = capture.connections.search_connection(new Connection(new InetAddress.from_string(ip_src), new InetAddress.from_string(ip_dst)));
			/*
			if (_connection != null) 
				_session = _connection.sessions.search_from_addr(new SocketInfos(new InetAddress.from_string(ip_src), port_src), 
							new SocketInfos(new InetAddress.from_string(ip_dst), port_dst));
			*/
			if (_connection != null) {
				_session = _connection.sessions.search_session(
						new Session.from_addr(
								new InetAddress.from_string(ip_src), port_src, 
								new InetAddress.from_string(ip_dst), port_dst
								)
						);

				if (_session == null)
				_session = _connection.sessions.search_session(
						new Session.from_addr(
								new InetAddress.from_string(ip_src), port_dst, 
								new InetAddress.from_string(ip_dst), port_src
								)
						);
			}

		}
	}
}

public class NPC.Interface : Object {
	public Gtk.Builder builder { 
		get { 
			return NPC.MainWindow.builder; 
		} 
	}

	public signal void sig_clicked_host(HostGraph hg);
	public signal void sig_clicked_connection(Connection conn);
	public signal void sig_host_renamed(string name, string newname);
	public signal void sig_host_deleted(InetAddress address);

    public HostsGraph hosts_graph = new HostsGraph();
    public Sessions sessions_hide = new Sessions();

    public NPC.CircleInterface circle_interface = null;
    public NPC.NavigatorInterface navigator_interface = null;

	public bool deletion_progress = false;
   	public HostGraph clicked = null;
   	public CircleConnection conn_clicked = null;

	public ListStore ls_hosts = null;
	public ListStore ls_frames = null;
	public ListStore ls_hosts_ref = null;

	public TreeStore ts_connects = null;

	public Capture capture = null;

	public TreeView tv_hosts = null;
	public TreeSelection tsel_hosts = null;
	ulong tsel_hosts_handler;

	TreeView tv_connects = null;
	TreeSelection tsel_connects = null;

	public TreeView tv_frames = null;
	public FrameModel frame_model = new FrameModel ();
	TreeSelection tsel_frames = null;
	Notebook notebook = null;
	Gtk.Menu popup_hosts = null;
	Gtk.Menu popup_connects = null;

	// public HostGraph ref_host = null;
	
    public Interface() {
		hosts_graph = new HostsGraph();
        circle_interface = new NPC.CircleInterface(this);
		navigator_interface = new NavigatorInterface(this);

		ls_hosts_ref = NPC.MainWindow.builder.get_object("store_hosts_ref") as ListStore;
		       
		/* Hosts initialization */
		tv_hosts =  NPC.MainWindow.builder.get_object("HostsList") as TreeView;
		ls_hosts = NPC.MainWindow.builder.get_object("store_hosts") as ListStore;
		
		tsel_hosts = tv_hosts.get_selection();
		tsel_hosts_handler = tsel_hosts.changed.connect(on_hosts_changed);
		
		tv_hosts.add_events(Gdk.EventMask.BUTTON_RELEASE_MASK);
		tv_hosts.button_release_event.connect(on_hosts_button_press_event);
		//tsel_hosts.set_mode(SelectionMode.MULTIPLE);

		/* Connections initilization (second onglet) */
		tv_connects =  NPC.MainWindow.builder.get_object("tv_connects") as TreeView;		
		ts_connects = NPC.MainWindow.builder.get_object("store_connects") as TreeStore;
		tsel_connects = tv_connects.get_selection();
		tsel_connects.changed.connect(on_connects_changed);

		tv_connects.add_events(Gdk.EventMask.KEY_RELEASE_MASK);
		tv_connects.key_release_event.connect(on_key_press_connects);
		tv_connects.add_events(Gdk.EventMask.BUTTON_RELEASE_MASK);
		tv_connects.button_release_event.connect(on_connects_button_press_event);

		/* Frames initialization */
		tv_frames =  NPC.MainWindow.builder.get_object("tv_frames") as TreeView;
		tsel_frames = tv_frames.get_selection();
		tsel_frames.changed.connect(on_frames_changed);
		ls_frames =  NPC.MainWindow.builder.get_object("store_frames") as ListStore;

		Box b = NPC.MainWindow.builder.get_object("box2") as Box;
		b.add(circle_interface);

		CellRendererText renderer =  NPC.MainWindow.builder.get_object("crt_address") as  CellRendererText;
		renderer.edited.connect(on_host_edited);

		sig_host_renamed.connect(circle_interface.on_renamed_host);
		sig_clicked_host.connect(refresh_frames_list_from_host);
		sig_clicked_connection.connect(refresh_frames_list_from_connection);
		
		popup_hosts = NPC.MainWindow.builder.get_object("popup_hosts") as Gtk.Menu;

		((Gtk.MenuItem) builder.get_object("popup_hosts_delete")).activate.connect(on_hosts_delete);
		((Gtk.MenuItem) builder.get_object("popup_hosts_icon")).activate.connect(on_hosts_change_icon);
		((Gtk.MenuItem) builder.get_object("popup_reference")).activate.connect(on_hosts_reference);
		((Gtk.MenuItem) builder.get_object("popup_host_hide")).activate.connect(on_hosts_hide_unhide);


		popup_connects = NPC.MainWindow.builder.get_object("popup_connects") as Gtk.Menu;

		((Gtk.MenuItem) builder.get_object("popup_connects_delete")).activate.connect(on_connects_delete);
		((Gtk.MenuItem) builder.get_object("popup_connects_hide")).activate.connect(on_connects_hide_unhide);

        notebook = NPC.MainWindow.builder.get_object("notebook1") as Notebook;
		notebook.switch_page.connect(switch_page);
        
		//sig_host_renamed.connect(on_renamed_host);
    }
        
    public void clear() {
    	deletion_progress = true;
   		clicked = null;
   		conn_clicked = null;
		// ref_host = null;

    	ls_hosts.clear(); // <-----------------
		tv_frames.set_model(null);		
		frame_model.clear();
		tv_frames.set_model(frame_model);

		// ts_connects.clear();
    	hosts_graph.clear();
    	deletion_progress = false;
    }

	public void switch_page (Widget page, uint page_num) {
		if ((page_num == 2) && (notebook.page != 2))
			navigator_interface.recalcul_all();
	}
/*
 *                FRAME MODEL CODE SOURCE
*/
    public void refresh_frames_list_from_frames(Frames frames) {
		tv_frames.set_model(null);		
		frame_model.clear();
		foreach (NetFrames.Frame f in frames)
			frame_model.add(new FrameNode.from_frame(f, capture.get_first_frame_captured()));
			
		tv_frames.set_model(frame_model);
	}

    public void add_frame_to_frames_list(NetFrames.Frame f) {
		frame_model.add(new FrameNode.from_frame(f, capture.get_first_frame_captured()));
	}

    public void refresh_frames_list_from_session(Session s) {
		tv_frames.set_model(null);
		frame_model.clear();

		foreach (NetFrames.Frame f in s.frames)
			frame_model.add(new FrameNode.from_frame(f, capture.get_first_frame_captured()));
		
		tv_frames.set_model(frame_model);
	}
	
    public void refresh_frames_list_from_host(HostGraph hg) {
		tv_frames.set_model(null);
		frame_model.clear();

		foreach (NetFrames.Frame f in capture.frames)
			if (f.has_host(hg.host_addr))
			frame_model.add(new FrameNode.from_frame(f, capture.get_first_frame_captured()));
				
		tv_frames.set_model(frame_model);
	}

    public void refresh_frames_list_from_connection(Connection conn) {
		tv_frames.set_model(null);
		frame_model.clear();
	
		foreach (NetFrames.Frame f in capture.frames)
			if (f.has_host(conn.host_a) && f.has_host(conn.host_b))
				frame_model.add(new FrameNode.from_frame(f, capture.get_first_frame_captured()));
				
		tv_frames.set_model(frame_model);
	}

/*
 *                FRAME LISTSORE CODE SOURCE
*/

/*
	void set_store_frame(NetFrames.Frame f, TreeIter iter) {
			DateTime dt =  new DateTime.from_timeval_utc (f.pcap_frame.rec.ts) ;
			string dateformat = dt.format("%T.");
			dateformat = dateformat + dt.get_microsecond().to_string();

			ls_frames.set(iter,
				0 , f.num,
				1, f.src.to_string(),
				2, f.dst.to_string(),
				3, f.len,
				4, dateformat,
				5, 
					#if (TSHARK_DECODE_ENABLED)
					f.dissect
					#else
					""
					#endif
				);
	}
    public void refresh_frames_list_from_frames(Frames frames) {
    	ls_frames.clear();
		TreeIter root;
		foreach (NetFrames.Frame f in frames) {
			ls_frames.append (out root);
			set_store_frame(f, root);
		}
	}

    public void add_frame_to_frames_list(NetFrames.Frame f) {
			TreeIter root;    	
			ls_frames.append (out root);
			set_store_frame(f, root);
	}

    public void refresh_frames_list_from_session(Session s) {
    	ls_frames.clear();
		TreeIter root;
		foreach (NetFrames.Frame f in s.frames) {
			ls_frames.append (out root);
			set_store_frame(f, root);
		}
	}
	
    public void refresh_frames_list_from_host(HostGraph hg) {
    	ls_frames.clear();
		TreeIter root;

		foreach (NetFrames.Frame f in capture.frames) {
			if (f.has_host(hg.host_addr)) {
				ls_frames.append (out root);
				set_store_frame(f, root);
			}
		}
	}

    public void refresh_frames_list_from_connection(Connection conn) {
    	ls_frames.clear();
		TreeIter root;
	
		foreach (NetFrames.Frame f in capture.frames)
			if (f.has_host(conn.host_a) && f.has_host(conn.host_b)) {
				ls_frames.append (out root);
				set_store_frame(f, root);
			}
	}
*/
    public void on_host_edited (string p_path, string new_name) {
		TreePath path = new TreePath.from_string(p_path);
		TreeIter iter;

		ls_hosts.get_iter (out iter, path);

		Value old_name;
		ls_hosts.get_value (iter, 0, out old_name);
		sig_host_renamed((string) old_name, new_name);
		ls_hosts.set(iter, 0, new_name, -1);
		refresh_connects();
	}

	public void refresh_connects() {
		ts_connects.clear();
		Gtk.TreeIter root;
		Gtk.TreeIter iter_sessions;

		NetFrames.Frame f = capture.frames.get_at(0);
		GLib.TimeVal start_time_capture = f.time;

		foreach (Connection c in capture.connections) {
			ts_connects.append (out root, null);

			HostGraph host_a = circle_interface.hosts_graph.search_by_ip(c.host_a);
			HostGraph host_b = circle_interface.hosts_graph.search_by_ip(c.host_b);
			string tmp = "";

			if (host_a.is_renamed) 
				tmp = host_a.name + " (" + host_a.host_addr.to_string() + ")";
			else
				tmp = host_a.host_addr.to_string();

			if (host_b.is_renamed) 
				tmp = tmp + " <--> " + host_b.name + " (" + host_b.host_addr.to_string() + ") (frames: " + c.total_frames().to_string() + ")";
			else
				tmp = tmp + " <--> " + host_b.host_addr.to_string() + " (frames: " + c.total_frames().to_string() + ")";

			ts_connects.set(root, 0, tmp, -1);

			foreach (Session s in c.sessions) {
				ts_connects.append(out iter_sessions, root);

				tmp = "";
				if (sessions_hide.search_session(s) != null) 
					tmp = "-- ";

				DateTime session_start =  new DateTime.from_timeval_utc (s.frames[0].time);
				DateTime session_end =  new DateTime.from_timeval_utc (s.frames[s.frames.size- 1].time);
/*
				string dateformat = dt.format("%T.");
				dateformat = dateformat + dt.get_microsecond().to_string();
*/
		int64 diff_start = session_start.difference(new DateTime.from_timeval_utc (start_time_capture));
		int64 diff_stop = session_end.difference(new DateTime.from_timeval_utc (start_time_capture));
		int64 session_duration = session_end.difference(session_start);

		tmp = "S:" + s.host_a.port.to_string() +" D:" + s.host_b.port.to_string() + " (frames: " + s.frames.size.to_string() + ")";

				ts_connects.set(iter_sessions, 
//					0, tmp + s.to_string(), 
					0, tmp,
					1, s.total_size,
					2, s.size_from_host_a,
					3, s.size_from_host_b,
					4, convert_duree((double) diff_start, 4),
					5, convert_duree((double) diff_stop, 4),
					6, convert_duree((double) session_duration, 2),
					-1);
			}
		}
	}

	public void refresh_hosts() {
		deletion_progress = true;

		ls_hosts.clear();

		deletion_progress = false;

		TreeIter root;
		int num = 0;
		foreach (HostGraph hg in circle_interface.hosts_graph) {
			hg.num = num++;
			ls_hosts.append (out root);
			ls_hosts.set (root,0, hg.name);
		}

		/* 
		 * J'ai hésité entre recréer la liste ou la mettre à jour...
		 */
		 /*
		TreeModel model;
		TreeIter iter;

		tsel_hosts.get_selected (out model, out iter);
		ls_hosts.remove(iter);
		*/

	}

	public void delete_host(InetAddress host) {
		deletion_progress = true;
// 		capture.sig_delete_host(host);
		capture.delete_host(host);
		
		int i = 0;
		HostGraph hg = null;

		while (i < hosts_graph.size) {
			hg = hosts_graph[i];
			if (! capture.hosts.contains(hg.host_addr)) {
				hosts_graph.remove(hg);
			} else {
				i++;
			}
		}

		deletion_progress = false;

		refresh_connects();
 		refresh_hosts();
		circle_interface.redraw();
	}
	
	public void on_connects_changed() {
		TreeModel model;
		TreeIter iter;
		Value val;

		if (deletion_progress) return;
		
		if (! tsel_connects.get_selected (out model, out iter)) return;

		ts_connects.get_value(iter, 0, out val);

		string line = (string) val;
		ConnectsInfos conn = new ConnectsInfos(capture, line);

		if (conn.is_session) {
				refresh_frames_list_from_session(conn.session);
		}
		
		if (conn.is_connection) {
			refresh_frames_list_from_connection(conn.connection);			
		}
	}


	public void on_frames_changed()   {
		// unimplemented
	}

	public void on_hosts_changed()   {
		TreeModel model;
		TreeIter iter;
		Value val;

		if (deletion_progress) return;

		tsel_hosts.get_selected (out model, out iter);
		ls_hosts.get_value (iter, 0, out val);

		clicked = circle_interface.hosts_graph.search_by_name((string) val);

		circle_interface.redraw();
	}

	public  bool on_key_press_connects (Gdk.EventKey event) {
		if ((! tv_connects.has_focus) || (event.keyval != 65535)) return false;
		
		TreeIter iter;
		TreeModel model;
		TreePath path;
		Value val;
		
		tsel_connects.get_selected (out model, out iter);
		ts_connects.get_value (iter, 0, out val);
		path = ts_connects.get_path(iter);

		ConnectsInfos conn = new ConnectsInfos(capture, (string) val);
		
		if (conn.is_session) {

			deletion_progress = true;
			
			capture.delete_session(conn.session);
			refresh_connects();
			refresh_hosts();
			// tsel_connects.select_path(new TreePath.from_string ("1:1:1"));
			tv_connects.expand_to_path (path) ;
			deletion_progress = false;
			
			return true;
		}
		if (conn.is_connection) {
			stdout.printf ("connection\n");
			return true;
		}
		return false;
        //return (base.key_press_event != null) ? base.key_press_event(event) : false;
	}
/*
	public void delete_clicked_host() {
		deletion_progress = true;
		// capture.delete_host(clicked.host_addr);
		capture.sig_delete_host(clicked.host_addr);
		circle_interface.hosts_graph.remove(clicked);
		refresh_hosts();
		navigator_interface.init_from_capture(capture);
		
		clicked = null;
		deletion_progress = false;
	}
	*/

	public void on_connects_delete() {
		TreeIter iter, iter_parent;
		TreeModel model;
		Value val;
		
		tsel_connects.get_selected (out model, out iter);
		if (! ts_connects.iter_parent(out iter_parent, iter)) 
			return;

		ts_connects.get_value (iter, 0, out val);
		string ports_infos = (string) val;
		ts_connects.get_value (iter_parent, 0, out val);

		ConnectsInfos conn = new ConnectsInfos(capture, (string) val + " " + ports_infos);

		deletion_progress = true;
		
		capture.delete_session(conn.session);
		ts_connects.remove(ref iter);
		refresh_hosts();

		// tsel_connects.select_path(new TreePath.from_string ("1:1:1"));
		// tv_connects.expand_to_path (path) ;
		deletion_progress = false;
	}

	public void on_connects_hide_unhide() {
		TreeIter iter, iter_parent;
		TreeModel model;
		Value val;
		
		tsel_connects.get_selected (out model, out iter);
		if (! ts_connects.iter_parent(out iter_parent, iter)) 
			return;

		ts_connects.get_value (iter, 0, out val);
		string ports_infos = (string) val;
		if (ports_infos.has_prefix ("-- ")) ports_infos = ports_infos.substring(3);

		ts_connects.get_value (iter_parent, 0, out val);

		ConnectsInfos conn = new ConnectsInfos(capture, (string) val + " " + ports_infos);

		Connection c = capture.connections.search_connection(conn.connection);
		Session s = c.sessions.search_session(conn.session);

		if (sessions_hide.search_session(s) == null) {
			sessions_hide.add(s);
			ts_connects.set(iter, 0, "-- " + ports_infos, -1);
		}
		else {
			sessions_hide.remove(s);
			ts_connects.set(iter, 0, ports_infos, -1);
		}
	}		

	public void on_hosts_delete() {
		if (clicked == null) return;
		
		delete_host(clicked.host_addr);
		clicked = null;
		
		/*
		delete_clicked_host();
		circle_interface.redraw();		
		*/
	}

	public void on_hosts_hide_unhide() {
		if (clicked == null) return;
		
		clicked.hide = ! clicked.hide;
		navigator_interface.init_from_capture(capture);		
		circle_interface.redraw();
	}
	
	public bool is_host_reference(InetAddress addr) {
		Gtk.TreeIter iter;

    	bool valid = ls_hosts_ref.get_iter_first(out iter);
 		Value host_addr;

    	while (valid) {
       		ls_hosts_ref.get_value (iter, 0, out host_addr);
			
			if ((string) host_addr == addr.to_string())
				return true;

       		valid = ls_hosts_ref.iter_next(ref iter);
    	}

    	return false;
	}

	public void add_host_as_reference(HostGraph hg) {
		if (is_host_reference(hg.host_addr))
			return;

		Gtk.TreeIter iter;

		ls_hosts_ref.append (out iter);
		ls_hosts_ref.set (iter, 0, hg.host_addr.to_string());		
	}

	public void on_hosts_reference() {
		if (clicked == null) return;

		add_host_as_reference(clicked);
		// ref_host = clicked;
	}
	
	public void on_hosts_change_icon() {
		FileChooserDialog fcd =  new FileChooserDialog("Choisir une incone", null,  Gtk.FileChooserAction.OPEN,
			"_Annuler",
			Gtk.ResponseType.CANCEL,
			"_Ouvrir",
			Gtk.ResponseType.ACCEPT);
		
		FileFilter filter = new Gtk.FileFilter ();
		filter.set_filter_name ("PNG");
		filter.add_pattern ("*.png");
		fcd.add_filter (filter);
		
		filter = new Gtk.FileFilter ();
		filter.set_filter_name ("all files");
		filter.add_pattern ("*.*");
		fcd.add_filter (filter);		

        fcd.set_current_folder(".");
		
		if (fcd.run() == Gtk.ResponseType.ACCEPT) {
			try {			
				clicked.icon = new Gdk.Pixbuf.from_file_at_scale (fcd.get_filename(), HOST_DIAMETER, HOST_DIAMETER, true);			
			} catch (GLib.Error e) {
				stdout.printf("Error: %s\n", e.message);
			}			
		}
		fcd.destroy();
	}
	
	public bool on_hosts_button_press_event(Widget w, Gdk.EventButton event) {		
        if ((event.type == Gdk.EventType.BUTTON_RELEASE) && (event.button == 3)) {			
            popup_hosts.popup(null, null, null , event.button, event.time);
            return true;
		}
		
		
		return false;
	}

	public bool on_connects_button_press_event(Widget w, Gdk.EventButton event) {		
        if ((event.type == Gdk.EventType.BUTTON_RELEASE) && (event.button == 3)) {			
            popup_connects.popup(null, null, null , event.button, event.time);
            return true;
		}
		
		
		return false;
	}

	public void init_from_capture(Capture capture) {
		this.capture = capture;

        double espace_angle = (2 * Math.PI) / capture.hosts.size;
        double angle = 0;
		int i = 0;

		TreeIter root;

		foreach (InetAddress ip in capture.hosts) {
            HostGraph hg = new HostGraph.Null();
            
			ls_hosts.append (out root);
			ls_hosts.set (root,0, ip.to_string());

			hg.host_addr = ip;            
            hg.angle = angle;
            hg.num = i; i++;
            hosts_graph.add(hg);
            
            angle = angle + espace_angle;
		}

//		ref_host = hosts_graph.search_by_ip(capture.connections.get_host_by_max_peers(capture.hosts));

		refresh_connects();
		circle_interface.redraw();

		navigator_interface.init_from_capture(capture);
	}
}
