/*
 * io_board.vala
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

using Json;
using Archive;
using NetFrames;

public class NPC.IOBoard {
	public void write_board(string filename, ref NPC.Interface main_interface) {
		Json.Builder build_json = new Json.Builder ();

		build_json.begin_object ();

		build_json.set_member_name("hosts");
		build_json.begin_array();

		foreach (HostGraph hg in main_interface.hosts_graph) {
			var b = build_json.begin_object ();
			b.set_member_name("name");
			b.add_string_value (hg.name);
			b.set_member_name("ip_address");
			b.add_string_value(hg.host_addr.to_string());
			b.set_member_name("hide");
			b.add_boolean_value(hg.hide);
			b.end_object();
		}

		build_json.end_array();
		build_json.end_object ();

		Json.Generator generator = new Json.Generator ();
		generator.set_pretty (true);
		Json.Node root = build_json.get_root ();
		generator.set_root (root);

		string str = generator.to_data (null);


		main_interface.capture.save_pcap("pcap_file.pcap");

		// create a writable archive
		var archive = new Archive.Write();
		// var buffer = new char[ARCHIVE_BUFFER];

		// set archive format
		archive.set_format_pax_restricted();
		archive.set_compression_none();

		// open file
		if (archive.open_filename(filename) == Archive.Result.FAILED) {
			return;
		}

		// set up the entry
		var entry = new Archive.Entry();
		entry.set_pathname("config.txt");
		entry.set_size(str.length);
		entry.set_filetype(0100000);
		entry.set_perm(0644);

		// write the file
		archive.write_header(entry);
		archive.write_data(str.data, str.length);


		try {
			File file = File.new_for_path ("pcap_file.pcap");

			FileInfo info = file.query_info ("*", FileQueryInfoFlags.NONE);
			DataInputStream dis = new DataInputStream (file.read ());

			int64 size = info.get_size();
			var buffer = new uint8[size];
			size_t bytes_read;
			dis.read_all(buffer, out bytes_read);
			dis.close();

			// set up the entry
			entry = new Archive.Entry();
			entry.set_pathname("pcap_file.pcap");
			entry.set_size(size);
			entry.set_filetype(0100000);
			entry.set_perm(0644);

			// write the file
			archive.write_header(entry);
			archive.write_data(buffer, bytes_read);

			file.delete();

		} catch (GLib.Error e) {
			stdout.printf("Error: %s\n", e.message);
		}

		// close the archive
		archive.close();

	}


	void process (Json.Node node, ref NPC.Interface main_interface) {
		unowned Json.Object obj = node.get_object ();

		foreach (unowned string name_object in obj.get_members ()) {
			switch (name_object) {
			case "hosts":
				unowned Json.Array array = obj.get_member (name_object).get_array ();

				foreach (unowned Json.Node item in array.get_elements ()) {
					string name = "";
					InetAddress address = null;
					bool hide = false;

					foreach (unowned string item_name in item.get_object().get_members ()) {
						switch (item_name) {
						case "name":
							name = item.get_object().get_string_member(item_name);
							break;
						case "ip_address":
							address = new InetAddress.from_string(item.get_object().get_string_member(item_name));
							break;
						case "hide":
							hide = item.get_object().get_boolean_member(item_name);
							break;
						default: break;
						}
					}

					HostGraph hg = main_interface.hosts_graph.search_by_ip(address);
					hg.name = name;
					hg.hide = hide;
					main_interface.refresh_hosts();
					main_interface.refresh_connects();
				}

				break;
			case "pcap_filename":
				stdout.printf ("%s\n", obj.get_string_member (name_object));
				break;
			case "latency":
				stdout.printf ("%" + int64.FORMAT + "\n", obj.get_int_member (name_object));
				break;
			default:
				break;
			}
		}
	}

	void read_json(string str, ref NPC.Interface main_interface) {
		Json.Parser parser = new Json.Parser ();
		try {
			parser.load_from_data (str);

			// Get the root node:
			Json.Node node = parser.get_root ();

			// Process (print) the file:
			process (node, ref main_interface);
		} catch (Error e) {
			stdout.printf ("Unable to parse the string: %s\n", e.message);
		}
	}

	public Capture load_board(string filename, out Capture capture, ref NPC.Interface main_interface) {
		Archive.Read read = new Archive.Read();

		weak Archive.Entry entry;

		File file = File.new_for_path ("pcap_file.pcap");

	    if (file.query_exists ()) {
	        file.delete();
	    }


		// read.support_filter_all();
		read.support_format_all();
		string config = "";

		Archive.Result r = read.open_filename(filename, 4096);

		while ((r = read.next_header(out entry)) == Archive.Result.OK) {
			switch (entry.pathname()) {
			case "config.txt":
				char[] buf = new char[entry.size()];
				read.read_data(buf, (size_t) entry.size());

				int i;
				for (i = (int) entry.size(); buf[i] != '}'; i--) {

					// stdout.printf ("%c\n", buf[i]);
				}

				buf[i + 1] = '\x0';

				config = (string) buf;
				break;
			case "pcap_file.pcap":
				size_t bytes_read;
				uint8 buf[4096];
				try {
					// file = File.new_for_path ("pcap_file.pcap");
					IOStream ios = file.create_readwrite (FileCreateFlags.PRIVATE);
					OutputStream os = ios.output_stream;
					size_t written;

					while ((bytes_read =  read.read_data(buf, 4096)) != 0) {
						if (bytes_read != 4096) {
							uint8[] tmp_char = new uint8[bytes_read];
							for (int i = 0; i < bytes_read; i++)
								tmp_char[i] = buf[i];
							os.write_all(tmp_char, out written);
						} else
							os.write_all(buf, out written);
					}

					ios.close();
					capture = new Capture("pcap_file.pcap");
					main_interface.init_from_capture(capture);
					file.delete();
				} catch (GLib.Error e) {
					stdout.printf("Error: %s\n", e.message);
				}				
				break;

			default: break;
			}
			read.read_data_skip();
		}

		read_json(config, ref main_interface);
		return main_interface.capture;
	}


}