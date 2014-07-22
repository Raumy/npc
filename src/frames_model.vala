/*
 * frames_model.vala
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
using NetFrames;

public class FrameNode : Object {
	public uint32 num_trame { get; set; }
	public string source { get; set; }
	public string destination { get; set; }
	public uint32 taille { get; set; }
	public string temps { get; set; }
	public string decodage { get; set; }


	public FrameNode.from_frame(NetFrames.Frame f, NetFrames.Frame start_capture) {
		DateTime dt =  new DateTime.from_timeval_utc (f.pcap_frame.rec.ts);
		DateTime from =  new DateTime.from_timeval_utc (start_capture.pcap_frame.rec.ts);

		int64 diff = dt.difference(from);
/*
		string dateformat = dt.format("%T.");
		dateformat = dateformat + dt.get_microsecond().to_string();
*/

		string format = "%4.6f".printf ((double) ((double) diff / 1000000));


		this.num_trame = f.num;
		this.source = f.src.to_string() + ":" + f.src_port.to_string();
		this.destination = f.dst.to_string() + ":" + f.dst_port.to_string();
		this.taille = f.len;
		this.temps = format;
		this.decodage = f.dissect;
	}

	public FrameNode (uint32 num_trame, string source, string destination, uint32 taille, string temps, string decodage) {
		this.num_trame = num_trame;
		this.source = source;
		this.destination = destination;
		this.taille = taille;
		this.temps = temps;
		this.decodage = decodage;

	}
}

public class FrameModel : Object, TreeModel {
	protected GenericArray<FrameNode> data;
	protected int stamp = 0;

	public FrameModel (owned GenericArray<FrameNode>? data = null) {
		if (data == null) {
			this.data = new GenericArray<FrameNode> ();
		} else {
			this.data = (owned) data;
		}
	}

	public void clear() {
		data = null;
		data = new GenericArray<FrameNode> ();
		/*
		   for (int index = 0; index < data.length; index++) {
		        data[index] = null;
		   }
		 */
		stamp++;
	}

	public Type get_column_type (int index) {
		switch (index) {
		case 0 :
		case 3:
			return typeof (ulong);
		case 1:
		case 2:
		case 5:
			return typeof (string);
		case 4:
			return typeof (string);

		default:
			return Type.INVALID;
		}
	}

	public void get_value (Gtk.TreeIter iter, int column, out Value val) {
		assert (iter.stamp == stamp);

		FrameNode node = data.get ((int) iter.user_data);
		switch (column) {
		case 0:
			val = Value (typeof (ulong));
			val.set_ulong ((ulong) node.num_trame);
			break;

		case 1:
			val = Value (typeof (string));
			val.set_string (node.source);
			break;

		case 2:
			val = Value (typeof (string));
			val.set_string (node.destination);
			break;

		case 3:
			val = Value (typeof (ulong));
			val.set_ulong ((ulong) node.taille);
			break;
		case 4:
			val = Value (typeof (string));
			val.set_string (node.temps);
			break;

		case 5:
			val = Value (typeof (string));
			val.set_string (node.decodage);
			break;

		default:
			val = Value (Type.INVALID);
			break;
		}
	}
	public int get_n_columns () {
		return 61;
	}

	public void add (FrameNode n) {
		data.add (n);
		stamp++;
	}


	public Gtk.TreeModelFlags get_flags () {
		return 0;
	}


	public bool get_iter (out Gtk.TreeIter iter, Gtk.TreePath path) {
		if (path.get_depth () != 1 || data.length == 0) {
			return invalid_iter (out iter);
		}

		iter = Gtk.TreeIter ();
		iter.user_data = path.get_indices ()[0].to_pointer ();
		iter.stamp = this.stamp;
		return true;
	}


	public Gtk.TreePath ? get_path (Gtk.TreeIter iter) {
		assert (iter.stamp == stamp);

		Gtk.TreePath path = new Gtk.TreePath ();
		path.append_index ((int) iter.user_data);
		return path;
	}

	public int iter_n_children (Gtk.TreeIter ? iter) {
		assert (iter == null || iter.stamp == stamp);
		return (iter == null) ? data.length : 0;
	}

	public bool iter_next (ref Gtk.TreeIter iter) {
		assert (iter.stamp == stamp);

		int pos = ((int) iter.user_data) + 1;
		if (pos >= data.length) {
			return false;
		}
		iter.user_data = pos.to_pointer ();
		return true;
	}

	public bool iter_previous (ref Gtk.TreeIter iter) {
		assert (iter.stamp == stamp);

		int pos = (int) iter.user_data;
		if (pos >= 0) {
			return false;
		}

		iter.user_data = (--pos).to_pointer ();
		return true;
	}

	public bool iter_nth_child (out Gtk.TreeIter iter, Gtk.TreeIter ? parent, int n) {
		assert (parent == null || parent.stamp == stamp);

		if (parent == null && n < data.length) {
			iter = Gtk.TreeIter ();
			iter.stamp = stamp;
			iter.user_data = n.to_pointer ();
			return true;
		}

		// Only used for trees
		return invalid_iter (out iter);
	}

	public bool iter_children (out Gtk.TreeIter iter, Gtk.TreeIter ? parent) {
		assert (parent == null || parent.stamp == stamp);
		// Only used for trees
		return invalid_iter (out iter);
	}

	public bool iter_has_child (Gtk.TreeIter iter) {
		assert (iter.stamp == stamp);
		// Only used for trees
		return false;
	}

	public bool iter_parent (out Gtk.TreeIter iter, Gtk.TreeIter child) {
		assert (child.stamp == stamp);
		// Only used for trees
		return invalid_iter (out iter);
	}

	private bool invalid_iter (out Gtk.TreeIter iter) {
		iter = Gtk.TreeIter ();
		iter.stamp = -1;
		return false;
	}

}
/*
   public class Application : Gtk.Window {
                FrameModel model = new FrameModel ();

        public Application () {
                // Prepare Gtk.Window:
                this.title = "My Gtk.TreeModel";
                this.window_position = Gtk.WindowPosition.CENTER;
                this.destroy.connect (Gtk.main_quit);
                this.set_default_size (350, 70);

                Gtk.Grid grid = new Gtk.Grid();
                this.add (grid);

                Gtk.Button button = new Gtk.Button.with_label ("Click me (0)");
                grid.attach(button, 0, 0, 1, 1);

                button.clicked.connect (() => {
                        // Emitted when the button has been activated:
                        //button.label = "Click me (%d)".printf (++this.click_counter);
                        stdout.printf ("test\n");

                        for (int i = 0; i < 10000; i++) {
                                model.add (new FrameNode(1, "hallo" , "hello", 10, 1000, "decode"));
                        }

                });

                // Model:

                for (int i = 0; i < 10000; i++) {
                                model.add (new FrameNode(1, "hallo" , "hello", 10, 1000, "decode"));
                }

                // View:

                Gtk.TreeView view = new Gtk.TreeView.with_model (model);
                view.expand = true;
        ScrolledWindow scroll = new ScrolledWindow(null, null);
        scroll.add(view);
                grid.attach(scroll, 0, 1, 1, 1);

                view.insert_column_with_attributes (-1, "num", new Gtk.CellRendererText (), "text", 0);
                view.insert_column_with_attributes (-1, "source", new Gtk.CellRendererText (), "text", 1);
                view.insert_column_with_attributes (-1, "destination", new Gtk.CellRendererText (), "text", 2);
                view.insert_column_with_attributes (-1, "taille", new Gtk.CellRendererSpin (), "text", 3);
                view.insert_column_with_attributes (-1, "temps", new Gtk.CellRendererSpin (), "text", 3);
                view.insert_column_with_attributes (-1, "decode", new Gtk.CellRendererSpin (), "text", 3);
        }

        public static int main (string[] args) {
                Gtk.init (ref args);

                Application app = new Application ();
                app.show_all ();
                Gtk.main ();
                return 0;
        }
   }
 */
