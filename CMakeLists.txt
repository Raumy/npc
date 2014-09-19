#
# Network Packet Filter
#
# Copyright 2013-2014 Cyriac REMY <cyriac.remy@no-log.org>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
# MA 02110-1301, USA.
#
# Classe de point d'entrée d'éxécution du programme.
# La fenêtre principale est décomposée en deux onglets :
#      une présentation de fichier lu sous forme de cercle
#      une présentation sous forme de "treeview"
#
#
# cmake -G"MSYS Makefiles" for Windows

project(npc)
cmake_minimum_required(VERSION 2.8)

list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake)
set(CMAKE_C_FLAGS -w)

set(PKGS glib-2.0 json-glib-1.0 gtk+-3.0 gee-0.8  gio-2.0 libarchive)

set(UI_TYPE "WITH_UI")
set(GETTEXT_PACKAGE "npc")
set(VERSION 2.2)
file(REMOVE vala.Stamp)

add_definitions(-DWITH_UI)
add_definitions(-DGETTEXT_PACKAGE=\"${GETTEXT_PACKAGE}\")

find_package(PkgConfig)

include_directories(${CMAKE_CURRENT_SOURCE_DIR}/lib)
link_directories(${CMAKE_CURRENT_SOURCE_DIR}/lib)


pkg_check_modules(DEPS REQUIRED ${PKGS})
add_definitions(${DEPS_CFLAGS})
link_libraries(${DEPS_LIBRARIES})
link_directories(${DEPS_LIBRARY_DIRS})

set(PKGS ${PKGS} libpcap)

IF(${WIN32})
	MESSAGE ("WINDOWS Plateform")
	link_libraries(wpcap)
	set(LIBNET libnetframes.dll)
ENDIF()

IF(${UNIX})
	MESSAGE ("UNIX Plateform")
	link_libraries(pcap)
	set(LIBNET libnetframes.so)
ENDIF()

find_package(Vala REQUIRED)
include (TargetDistclean)

include(ValaVersion)
include(ValaPrecompile)

vala_precompile(VALA_C
		src/main.vala
		src/hosts_graph.vala
		src/circle_interface.vala
		src/utils.vala
		src/npc_interface.vala
		src/navigator_interface.vala
		src/graph_utils.vala
		src/frames_model.vala
		src/colors_scheme.vala
		src/npc_ui.vala
		src/json_config_file.vala
		src/npc_config_file.vala
	CUSTOM_VAPIS
		${CMAKE_CURRENT_SOURCE_DIR}/lib/libnetframes.vapi
	PACKAGES
		${PKGS}
	OPTIONS
		--disable-warnings		
		-X -w
		-D ${UI_TYPE}
		--target-glib=2.32
		-X lib/libnetframes.dll
)


add_executable(npc ${VALA_C})

target_link_libraries(
	npc 
	m
)	

target_link_libraries(
        npc
        libnetframes.dll
)
  #ADD_CUSTOM_TARGET (distclean @echo cleaning for source distribution)
  SET(DISTCLEANED
   cmake.depends
   cmake.check_depends
   CMakeCache.txt
   cmake.check_cache
   core core.*
   gmon.out
)
  
  ADD_CUSTOM_COMMAND(
    DEPENDS clean
    COMMENT "distribution clean"
    COMMAND rm
    ARGS    -Rf CMakeTmp ${DISTCLEANED}
    TARGET  distclean
  )


  ADD_CUSTOM_COMMAND(
    DEPENDS clean
    COMMENT "cmake clean"
    COMMAND rm
    ARGS    -Rf CMakeTmp ${DISTCLEANED} CMakeFiles
    TARGET  distclean
  )

add_custom_command(TARGET npc
     POST_BUILD
     COMMAND rm src/*.c
)
