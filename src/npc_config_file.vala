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

public class NPC.ConfigFile {
	unowned NPC.Interface main_interface = null;

	 void write_hosts(JsonConfigFile ncr) {
		foreach (HostGraph hg in main_interface.hosts_graph) {
    		ncr.builder.begin_object ();
    		ncr.write_string("name", hg.name);
    		ncr.write_string("ip_address", hg.host_addr.to_string());
    		ncr.write_boolean("hide", hg.hide);
			ncr.builder.end_object();
		}
	}

	 void write_latencies(JsonConfigFile ncr) {
		foreach (Connection connection in main_interface.capture.connections) {
    		ncr.builder.begin_object ();
    		ncr.write_string("from", connection.host_a.to_string());
    		ncr.write_string("to", connection.host_b.to_string());
    		ncr.write_int("latency", connection.latency);
			ncr.builder.end_object();
		}
	}

	public void write_board(string filename, ref NPC.Interface main_interface) {
		JsonConfigFile build_json = new JsonConfigFile();
		build_json.start_builder();
		build_json.build_array("hosts", write_hosts);
		build_json.build_array("latencies", write_latencies);

		build_json.end_builder();
		string str = build_json.generate_string_data();

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

	void read_host(Json.Node n, JsonConfigFile ncr) {
		string name = ncr.read_string(n, "name");
		InetAddress address = ncr.read_inetaddress(n, "ip_address");
		bool hide = ncr.read_bool(n, "hide");

		HostGraph hg = main_interface.hosts_graph.search_by_ip(address);
		hg.name = name;
		hg.hide = hide;
		main_interface.refresh_hosts();
		main_interface.refresh_connects();
	 }

	 void read_latencies(Json.Node n, JsonConfigFile ncr) {
 		InetAddress from = ncr.read_inetaddress(n, "from");
 		InetAddress to = ncr.read_inetaddress(n, "to");
  		int64 latency = ncr.read_int(n, "latency");

		Connection c = main_interface.capture.connections.search_connection( new Connection (from, to) );

		if (c != null) {
			c.latency = (int32) latency;
		}

	 }

	void read_json(string str, ref NPC.Interface main_interface) {
		this.main_interface = main_interface;		
		JsonConfigFile ncr = new JsonConfigFile.from_string(str);

		ncr.read_array(null, "hosts", read_host);
		ncr.read_array(null, "latencies", read_latencies);
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