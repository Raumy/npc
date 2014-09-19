/*
 * main.vala
 *
 * Copyright 2013-2014 Cyriac REMY <cyriac.remy@no-log.org>
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
 * Classe de point d'entrée d'éxécution du programme.
 * La fenêtre principale est décomposée en deux onglets :
 *      une présentation de fichier lu sous forme de cercle
 *      une présentation sous forme de "treeview"
 *
 */

//              stdout.printf ("::: %s - %s :: %d ::: \n", GLib.Log.FILE, GLib.Log.METHOD, GLib.Log.LINE);

using Gee;
using Gtk;
using NetFrames;

extern const string GETTEXT_PACKAGE;

public class NPC.MainWindow {
	public Capture capture = null;

	public static Gtk.Builder builder = null;

	NPC.Interface main_interface = null;
	NPC.ConfigFile in_out_file = new NPC.ConfigFile();

	public Window window;
//	Window hosts_ref;


	ScrolledWindow scw_connects = null;
	public static bool shift_pressed = false;

	public MainWindow.from_file(string filename) {
		capture = new Capture(filename);

		init_main_application();
		main_interface.init_from_capture(capture);

		select_captured_host();
	}

	public MainWindow() {
		init_main_application();
	}

	public Gtk.Builder get_builder() {
		Gtk.Builder bld;

		bld = new Gtk.Builder();
		try {
			# if WITH_UI
			bld.add_from_file("../src/npc.ui");
			# else
				bld.add_from_string(npc_ui, npc_ui.length);
			# endif
		} catch (Error err) {
			stdout.printf("Error : %s\n", err.message);
		}
		return bld;
	}

	public void init_main_application() {
		builder = get_builder();

		builder.connect_signals(this);
		window = builder.get_object("main_window") as Window;
		window.destroy.connect(stop_main);
		window.set_default_size (800, 300);

		window.add_events(Gdk.EventMask.STRUCTURE_MASK);
		window.add_events(Gdk.EventMask.KEY_RELEASE_MASK);
		window.add_events(Gdk.EventMask.KEY_PRESS_MASK);

		window.key_release_event.connect(on_key_press_connects);
		window.key_press_event.connect(on_key_press_connects);

		window.configure_event.connect(Window_configure_event);
		scw_connects = builder.get_object("scrolledwindow1") as ScrolledWindow;

//		window.window_state_event.connect (window_state_event);

		// modal = builder.get_object("window_modal") as Window;
//		hosts_ref = builder.get_object("win_hosts_ref") as Window;

		main_interface = new NPC.Interface();
		init_menu(builder);
	}

	void init_menu(Gtk.Builder builder) {
		((Gtk.MenuItem) builder.get_object("menuitem_open")).activate.connect(open_board);
		((Gtk.MenuItem) builder.get_object("menuitem_save")).activate.connect(save_board);
		((Gtk.MenuItem) builder.get_object("menuitem_import")).activate.connect(import_capture);
		((Gtk.MenuItem) builder.get_object("menuitem_export")).activate.connect(export_capture);
		((Gtk.MenuItem) builder.get_object("menuitem_quit")).activate.connect(stop_main);
	}

	public void select_captured_host() {
		TreeModel model;
		TreeIter iter;
		Value val;

		Dialog choose_captured_host  = builder.get_object("dia_captured_host") as Dialog;
		if (choose_captured_host.run() == 1) {
			TreeView tv = builder.get_object("tv_captured_host") as TreeView;
			ListStore ls_hosts = builder.get_object("store_hosts") as ListStore;


			// get the IP Address selected

			tv.get_selection().get_selected (out model, out iter);
			ls_hosts.get_value (iter, 0, out val);

			// add this address to reference list
			ls_hosts = builder.get_object("store_hosts_ref") as ListStore;
			ls_hosts.append (out iter);
			ls_hosts.set (iter, 0, (string) val);

			// and finally set the captured host in capture object....
			main_interface.capture.set_captured_host(new InetAddress.from_string((string) val));
			
			choose_captured_host.hide();
		}
	}

	public void check_show_hosts_reference() {
		Gtk.CheckMenuItem ci = builder.get_object("chk_show_hosts_ref") as Gtk.CheckMenuItem;
		if (ci.active)
			// hosts_ref.show_all();
			((Window) builder.get_object("win_hosts_ref")).show_all();
		else
			// hosts_ref.set_visible (false);
			((Window) builder.get_object("win_hosts_ref")).set_visible(false);
	}

	public void stop_main() {
		if (capture != null) {
			capture.frames.clear();
			capture.hosts.clear();
			capture.connections.clear();
			capture = null;
		}

		Gtk.main_quit();
	}

	public void add_filters(FileChooserDialog fcd) {
		FileFilter filter = new Gtk.FileFilter ();
		filter.set_filter_name ("capture files");
		filter.add_pattern ("*.pcap");
		fcd.add_filter (filter);

		filter = new Gtk.FileFilter ();
		filter.set_filter_name ("all files");
		filter.add_pattern ("*.*");
		fcd.add_filter (filter);
	}

	public void add_npc_filters(FileChooserDialog fcd) {
		FileFilter filter = new Gtk.FileFilter ();
		filter.set_filter_name ("NPC Files");
		filter.add_pattern ("*.npc");
		fcd.add_filter (filter);

		filter = new Gtk.FileFilter ();
		filter.set_filter_name ("all files");
		filter.add_pattern ("*.*");
		fcd.add_filter (filter);
	}

	public void export_capture() {
		FileChooserDialog fcd =  new FileChooserDialog("Exporter une capture", window,  Gtk.FileChooserAction.SAVE,
		                                               "_Annuler",
		                                               Gtk.ResponseType.CANCEL,
		                                               "_Enregistrer",
		                                               Gtk.ResponseType.ACCEPT);

		add_filters(fcd);
		fcd.set_current_folder(".");

		if (fcd.run() == Gtk.ResponseType.ACCEPT) {
			stdout.printf ("%s / %s\n", fcd.get_uri(), fcd.get_filename());
			capture.save_pcap(fcd.get_filename());
		}
		fcd.destroy();
	}

	public void import_capture() {
		FileChooserDialog fcd =  new FileChooserDialog("Importer une capture", window,  Gtk.FileChooserAction.OPEN,
		                                               "_Annuler",
		                                               Gtk.ResponseType.CANCEL,
		                                               "_Ouvrir",
		                                               Gtk.ResponseType.ACCEPT);

		Gtk.MessageDialog msg = new Gtk.MessageDialog (window,
		                                               Gtk.DialogFlags.MODAL,
		                                               Gtk.MessageType.INFO,
		                                               Gtk.ButtonsType.NONE,
		                                               "Veuillez patienter..\nChargement en cours!");

		add_filters(fcd);

		fcd.set_current_folder(".");
		if (fcd.run() == Gtk.ResponseType.ACCEPT) {
			string filename = fcd.get_filename();
			fcd.destroy();

			if (capture != null) {
				capture.frames.clear();
				capture.hosts.clear();
				capture.connections.clear();
			}

			msg.show();
			capture = new Capture(filename);
			msg.destroy();
			main_interface.clear();
			main_interface.init_from_capture(capture);

			select_captured_host();
		} else {
			fcd.destroy();
			msg.destroy();
		}

	}


	void save_board() {
		FileChooserDialog fcd =  new FileChooserDialog("Enregistrer", window,  Gtk.FileChooserAction.SAVE,
		                                               "_Annuler",
		                                               Gtk.ResponseType.CANCEL,
		                                               "_Enregistrer",
		                                               Gtk.ResponseType.ACCEPT);

		add_npc_filters(fcd);

		fcd.set_current_folder(".");

		if (fcd.run() == Gtk.ResponseType.ACCEPT) {
			in_out_file.write_board(fcd.get_filename(), ref main_interface);
		}
		fcd.destroy();

	}

	public void open_board() {
		FileChooserDialog fcd =  new FileChooserDialog("Ouvrir une capture", window,  Gtk.FileChooserAction.OPEN,
		                                               "_Annuler",
		                                               Gtk.ResponseType.CANCEL,
		                                               "_Ouvrir",
		                                               Gtk.ResponseType.ACCEPT);

		Gtk.MessageDialog msg = new Gtk.MessageDialog (window, Gtk.DialogFlags.MODAL, Gtk.MessageType.INFO, Gtk.ButtonsType.NONE, "Veuillez patienter..\nChargement en cours!");

		add_npc_filters(fcd);

		fcd.set_current_folder(".");
		if (fcd.run() == Gtk.ResponseType.ACCEPT) {
			string filename = fcd.get_filename();
			fcd.destroy();

			if (capture != null) {
				capture.frames.clear();
				capture.hosts.clear();
				main_interface.hosts_graph.clear();
				capture.connections.clear();
			}
			msg.show();
			in_out_file.load_board(filename, out capture, ref main_interface);
			msg.destroy();
			select_captured_host();
		} else {
			fcd.destroy();
		}

	}


	public bool on_key_press_connects (Gdk.EventKey event) {
		if ((event.type == Gdk.EventType.KEY_PRESS) && (event.state == Gdk.ModifierType.SHIFT_MASK))
			shift_pressed = true;

		if ((event.type == Gdk.EventType.KEY_RELEASE) && (event.state != Gdk.ModifierType.SHIFT_MASK) && shift_pressed)
			shift_pressed = false;

		return false;
	}

	public bool Window_configure_event (Gdk.EventConfigure event) {
		if (event.type == Gdk.EventType.CONFIGURE) {
			int w, h;
			window.get_size(out w, out h);
			scw_connects.height_request = (int) (30 * h / 100);
			//circle.navigator.build_nav_lines();
		}

		return false;
	}

	public void show_all() {
		window.show_all();
	}

}

public static int main(string[] args) {
	Intl.setlocale(LocaleCategory.MESSAGES, "");
	Intl.textdomain(GETTEXT_PACKAGE);
	Intl.bind_textdomain_codeset(GETTEXT_PACKAGE, "utf-8");
	Intl.bindtextdomain(GETTEXT_PACKAGE, "./locale");

	ColorScheme.init();
	Gtk.init(ref args);

	NPC.MainWindow m = new NPC.MainWindow();
	m.show_all();

	Gtk.main();

	return 0;
}