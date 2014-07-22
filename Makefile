#  Makefile
#  
#  Copyright 2013 Cyriac REMY <cyriac.remy@no-log.org>
#  
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#  
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#  
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
#  MA 02110-1301, USA.
#
 
# Program name : npc stands for "Network Packer Cleaner"
PROGRAM = npc
GETTEXT_PACKAGE = npc
VERSION = 2.1

GEE_WIN_VERSION=0.8
GEE_LINUX_VERSION=0.8
PCAP_WIN_LIB=wpcap
PCAP_LINUX_LIB=pcap

C_DEFINES := _VERSION='"$(VERSION)"' GETTEXT_PACKAGE='"$(GETTEXT_PACKAGE)"'	
DEFINE_CFLAGS := $(foreach def,$(C_DEFINES),-X -D$(def))

VALA_DEFINES := WITHOUT_UI
DEFINE_VALAFLAGS := $(foreach def,$(VALA_DEFINES),-D $(def))

DEFINE_FLAGS := $(DEFINE_CFLAGS) $(DEFINE_VALAFLAGS)

# packages used 
PKGS_WIN = --pkg json-glib-1.0 --pkg gtk+-3.0 --pkg gee-$(GEE_WIN_VERSION) --pkg gio-2.0 --pkg libpcap --pkg libarchive
PKGS_LINUX = --pkg json-glib-1.0 --pkg gtk+-3.0 --pkg gee-$(GEE_LINUX_VERSION) --pkg gio-2.0 --pkg libpcap --pkg libarchive
	
# source files
SRC = lib/libnetframes.vapi \
	src/main.vala \
	src/hosts_graph.vala \
	src/circle_interface.vala \
	src/utils.vala \
	src/npc_interface.vala \
	src/navigator_interface.vala \
	src/graph_utils.vala \
	src/frames_model.vala \
	src/colors_scheme.vala \
	src/npc_ui.vala \
	src/io_board.vala

# vala compiler
VALAC = valac
 
# compiler options for a standard build
# preprocessor variables :
#    WINDOWS : compilation on MingW32/Windows
#    LINUX : compilation on Linux distribution
#    TSHARK_DECODE_ENABLED : compile with tshark spawn support
#VALACOPTS = -D WINDOWS -X -w --disable-warnings -X -I/opt/include -X -lwpcap

VALA_WIN_COPTS =  -X lib/libnetframes.dll -X -Ilib -X -w -X -I/opt/include -X -l$(PCAP_WIN_LIB) --target-glib=2.32
#VALA_WIN_COPTS =  -X lib/libnetframes.dll -X -Ilib -g -X -w --disable-warnings -X -I/opt/include -X -l$(PCAP_WIN_LIB) --target-glib=2.32
VALA_LINUX_COPTS = -X -lX11 -X -lm -X lib/libnetframes.so -X -Ilib -g -X -w --disable-warnings -X -I/opt/include -X -l$(PCAP_LINUX_LIB) --target-glib=2.32

# the 'all' target build a debug build

windows:
	@$(VALAC) $(VALA_WIN_COPTS) $(DEFINE_FLAGS) $(SRC) -o $(PROGRAM) $(PKGS_WIN)

linux:
	@$(VALAC) $(VALA_LINUX_COPTS) $(DEFINE_FLAGS) $(SRC) -o $(PROGRAM) $(PKGS_LINUX)


#	tar czvf npc-win32.v$(VERSION).tar.gz npc-win INSTALL Changelog  > /dev/null