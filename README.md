Network PAcket Cleaner (npc)
===

Network Packet Cleaner helps you to easily clean a "pcap" file by manipulating graphically hosts, connections, sessions.

Feel free to contribute if you are interested.

![sample](https://a.fsdn.com/con/app/proj/netpackclean/screenshots/capt2.png/182/137)
![sample](https://a.fsdn.com/con/app/proj/netpackclean/screenshots/new_feature.jpg/182/137)
![sample](https://a.fsdn.com/con/app/proj/netpackclean/screenshots/shark_nav1.jpg/182/137)

**sorry dont have time for more explanations**

How to compile
===

*For Linux / Ubuntu*

    # add-apt-repository ppa:vala-team/ppa
    # aptitude  update
    # aptitude  install tshark
    # aptitude  install vala-0.22 libgee-0.8-2 libgee-0.8-dev
    # cd /usr/share
    # mv vala/vapi/gee-0.8* vala-0.22/vapi
    # mv vala vala.old
    # ln -s vala-0.22 vala
    # aptitude install libpcap-dev libjson-glib-1.0-0 libjson-glib-dev libgtk-3-dev libarchive-dev tshark 

Overwrite vapis files in /usr/share/vala/vapi with files in vapis directory.


    $ cd npc
    $ make linux
    $ ls -l npc

Download [libpcap from tcpdump site](http://www.tcpdump.org/#latest-release)

    ./configure --prefix=/usr
    make
    make install

How to run
===

*How to run executable under Windows (MingW32)*

    $ export LANGUAGE="fr_FR"
    $ export LANGUAGE="en_EN"
    $ export PATH=$PATH;/c/Program\ Files/Wireshark/
    $ npc.exe

Test a pre compiled version
===

You can download and try from sourceforge :

[Network Packet Cleaner](https://sourceforge.net/projects/netpackclean/)