#if (! WITH_UI)
const string npc_ui="""<?xml version="1.0" encoding="UTF-8"?>
<interface>
  <!-- interface-requires gtk+ 3.0 -->
  <object class="GtkAdjustment" id="adj_scale">
    <property name="upper">100</property>
    <property name="step_increment">1</property>
    <property name="page_increment">10</property>
  </object>
  <object class="GtkAdjustment" id="adj_scroll">
    <property name="upper">100</property>
    <property name="step_increment">1</property>
    <property name="page_increment">10</property>
  </object>
  <object class="GtkDialog" id="dlg_latency">
    <property name="can_focus">False</property>
    <property name="border_width">5</property>
    <property name="type_hint">dialog</property>
    <child internal-child="vbox">
      <object class="GtkBox" id="dialog-vbox1">
        <property name="can_focus">False</property>
        <property name="orientation">vertical</property>
        <property name="spacing">2</property>
        <child internal-child="action_area">
          <object class="GtkButtonBox" id="dialog-action_area1">
            <property name="can_focus">False</property>
            <property name="layout_style">end</property>
            <child>
              <object class="GtkButton" id="button1">
                <property name="label">gtk-cancel</property>
                <property name="visible">True</property>
                <property name="can_focus">True</property>
                <property name="receives_default">True</property>
                <property name="use_stock">True</property>
              </object>
              <packing>
                <property name="expand">False</property>
                <property name="fill">True</property>
                <property name="position">0</property>
              </packing>
            </child>
            <child>
              <object class="GtkButton" id="button2">
                <property name="label">gtk-ok</property>
                <property name="visible">True</property>
                <property name="can_focus">True</property>
                <property name="receives_default">True</property>
                <property name="use_stock">True</property>
              </object>
              <packing>
                <property name="expand">False</property>
                <property name="fill">True</property>
                <property name="position">1</property>
              </packing>
            </child>
          </object>
          <packing>
            <property name="expand">False</property>
            <property name="fill">True</property>
            <property name="pack_type">end</property>
            <property name="position">0</property>
          </packing>
        </child>
        <child>
          <object class="GtkFixed" id="fixed1">
            <property name="height_request">60</property>
            <property name="visible">True</property>
            <property name="can_focus">False</property>
            <child>
              <object class="GtkEntry" id="entry_latency">
                <property name="width_request">100</property>
                <property name="height_request">25</property>
                <property name="visible">True</property>
                <property name="can_focus">True</property>
                <property name="invisible_char">●</property>
              </object>
              <packing>
                <property name="x">101</property>
                <property name="y">15</property>
              </packing>
            </child>
            <child>
              <object class="GtkLabel" id="lb_latency">
                <property name="width_request">100</property>
                <property name="height_request">25</property>
                <property name="visible">True</property>
                <property name="can_focus">False</property>
                <property name="label" translatable="yes">Latency</property>
              </object>
              <packing>
                <property name="y">15</property>
              </packing>
            </child>
            <child>
              <object class="GtkLabel" id="label4">
                <property name="width_request">100</property>
                <property name="height_request">20</property>
                <property name="visible">True</property>
                <property name="can_focus">False</property>
                <property name="label" translatable="yes">LAN ~2ms WAN ~15ms</property>
              </object>
              <packing>
                <property name="x">26</property>
                <property name="y">49</property>
              </packing>
            </child>
          </object>
          <packing>
            <property name="expand">False</property>
            <property name="fill">True</property>
            <property name="position">1</property>
          </packing>
        </child>
      </object>
    </child>
    <action-widgets>
      <action-widget response="0">button1</action-widget>
      <action-widget response="1">button2</action-widget>
    </action-widgets>
  </object>
  <object class="GtkWindow" id="main_window">
    <property name="can_focus">False</property>
    <property name="title" translatable="yes">Network Packet Cleaner - Board</property>
    <child>
      <object class="GtkBox" id="box1">
        <property name="visible">True</property>
        <property name="can_focus">False</property>
        <property name="orientation">vertical</property>
        <child>
          <object class="GtkBox" id="box3">
            <property name="visible">True</property>
            <property name="can_focus">False</property>
            <child>
              <object class="GtkMenuBar" id="menubar">
                <property name="visible">True</property>
                <property name="can_focus">False</property>
                <child>
                  <object class="GtkMenuItem" id="menuitem_file">
                    <property name="visible">True</property>
                    <property name="can_focus">False</property>
                    <property name="label" translatable="yes">_File</property>
                    <property name="use_underline">True</property>
                    <child type="submenu">
                      <object class="GtkMenu" id="menu_file">
                        <property name="visible">True</property>
                        <property name="can_focus">False</property>
                        <child>
                          <object class="GtkMenuItem" id="menuitem_open">
                            <property name="visible">True</property>
                            <property name="can_focus">False</property>
                            <property name="tooltip_text" translatable="yes">Ouvre un fichier NPC</property>
                            <property name="label" translatable="yes">_open</property>
                            <property name="use_underline">True</property>
                          </object>
                        </child>
                        <child>
                          <object class="GtkMenuItem" id="menuitem_save">
                            <property name="visible">True</property>
                            <property name="can_focus">False</property>
                            <property name="tooltip_text" translatable="yes">Enregistrer un fichier NPC</property>
                            <property name="label" translatable="yes">_save</property>
                            <property name="use_underline">True</property>
                          </object>
                        </child>
                        <child>
                          <object class="GtkSeparatorMenuItem" id="menuitem_separator1">
                            <property name="visible">True</property>
                            <property name="can_focus">False</property>
                          </object>
                        </child>
                        <child>
                          <object class="GtkMenuItem" id="menuitem_import">
                            <property name="visible">True</property>
                            <property name="can_focus">False</property>
                            <property name="tooltip_markup" translatable="yes">Importer un fichier PCAP</property>
                            <property name="label" translatable="yes">_import</property>
                            <property name="use_underline">True</property>
                          </object>
                        </child>
                        <child>
                          <object class="GtkMenuItem" id="menuitem_export">
                            <property name="visible">True</property>
                            <property name="can_focus">False</property>
                            <property name="tooltip_markup" translatable="yes">Exporter les données dans un fichier PCAP</property>
                            <property name="label" translatable="yes">_export</property>
                            <property name="use_underline">True</property>
                          </object>
                        </child>
                        <child>
                          <object class="GtkSeparatorMenuItem" id="menuitem_separator2">
                            <property name="visible">True</property>
                            <property name="can_focus">False</property>
                          </object>
                        </child>
                        <child>
                          <object class="GtkImageMenuItem" id="menuitem_quit">
                            <property name="label">gtk-quit</property>
                            <property name="visible">True</property>
                            <property name="can_focus">False</property>
                            <property name="use_underline">True</property>
                            <property name="use_stock">True</property>
                          </object>
                        </child>
                      </object>
                    </child>
                  </object>
                </child>
                <child>
                  <object class="GtkMenuItem" id="menuitem2">
                    <property name="visible">True</property>
                    <property name="can_focus">False</property>
                    <property name="no_show_all">True</property>
                    <property name="label" translatable="yes">Show</property>
                    <property name="use_underline">True</property>
                    <child type="submenu">
                      <object class="GtkMenu" id="menu4">
                        <property name="visible">True</property>
                        <property name="can_focus">False</property>
                        <child>
                          <object class="GtkCheckMenuItem" id="chk_show_hosts_ref">
                            <property name="visible">True</property>
                            <property name="can_focus">False</property>
                            <property name="label" translatable="yes">Show hosts reference</property>
                            <property name="use_underline">True</property>
                          </object>
                        </child>
                      </object>
                    </child>
                  </object>
                </child>
                <child>
                  <object class="GtkMenuItem" id="menuitem4">
                    <property name="visible">True</property>
                    <property name="can_focus">False</property>
                    <property name="label" translatable="yes">_Help</property>
                    <property name="use_underline">True</property>
                    <child type="submenu">
                      <object class="GtkMenu" id="menu3">
                        <property name="visible">True</property>
                        <property name="can_focus">False</property>
                        <child>
                          <object class="GtkImageMenuItem" id="imagemenuitem10">
                            <property name="label">gtk-about</property>
                            <property name="visible">True</property>
                            <property name="can_focus">False</property>
                            <property name="use_underline">True</property>
                            <property name="use_stock">True</property>
                          </object>
                        </child>
                      </object>
                    </child>
                  </object>
                </child>
              </object>
              <packing>
                <property name="expand">False</property>
                <property name="fill">True</property>
                <property name="position">0</property>
              </packing>
            </child>
          </object>
          <packing>
            <property name="expand">False</property>
            <property name="fill">True</property>
            <property name="position">0</property>
          </packing>
        </child>
        <child>
          <object class="GtkNotebook" id="notebook1">
            <property name="height_request">349</property>
            <property name="visible">True</property>
            <property name="can_focus">True</property>
            <child>
              <object class="GtkBox" id="box2">
                <property name="visible">True</property>
                <property name="can_focus">False</property>
                <child>
                  <object class="GtkTreeView" id="HostsList">
                    <property name="width_request">120</property>
                    <property name="visible">True</property>
                    <property name="can_focus">True</property>
                    <property name="model">store_hosts</property>
                    <property name="headers_clickable">False</property>
                    <property name="search_column">0</property>
                    <child internal-child="selection">
                      <object class="GtkTreeSelection" id="treeview-selection4">
                        <property name="mode">browse</property>
                      </object>
                    </child>
                    <child>
                      <object class="GtkTreeViewColumn" id="col_ip_address">
                        <property name="title" translatable="yes">_IP Address</property>
                        <child>
                          <object class="GtkCellRendererText" id="crt_address">
                            <property name="editable">True</property>
                          </object>
                          <attributes>
                            <attribute name="text">0</attribute>
                          </attributes>
                        </child>
                      </object>
                    </child>
                  </object>
                  <packing>
                    <property name="expand">False</property>
                    <property name="fill">True</property>
                    <property name="position">0</property>
                  </packing>
                </child>
                <child>
                  <placeholder/>
                </child>
              </object>
            </child>
            <child type="tab">
              <object class="GtkLabel" id="label1">
                <property name="visible">True</property>
                <property name="can_focus">False</property>
                <property name="label" translatable="yes">Circle</property>
              </object>
              <packing>
                <property name="tab_fill">False</property>
              </packing>
            </child>
            <child>
              <object class="GtkScrolledWindow" id="scrolledwindow2">
                <property name="visible">True</property>
                <property name="can_focus">True</property>
                <property name="shadow_type">in</property>
                <child>
                  <object class="GtkTreeView" id="tv_connects">
                    <property name="visible">True</property>
                    <property name="can_focus">True</property>
                    <property name="model">store_connects</property>
                    <property name="headers_clickable">False</property>
                    <property name="search_column">0</property>
                    <child internal-child="selection">
                      <object class="GtkTreeSelection" id="treeview-selection2"/>
                    </child>
                    <child>
                      <object class="GtkTreeViewColumn" id="ts_ses_con">
                        <property name="title" translatable="yes">_Connections/Sessions</property>
                        <child>
                          <object class="GtkCellRendererText" id="cellrenderertext8"/>
                          <attributes>
                            <attribute name="text">0</attribute>
                          </attributes>
                        </child>
                      </object>
                    </child>
                    <child>
                      <object class="GtkTreeViewColumn" id="treeviewcolumn7">
                        <property name="title" translatable="yes">Length</property>
                        <child>
                          <object class="GtkCellRendererText" id="cellrenderertext7">
                            <property name="placeholder_text">Length</property>
                          </object>
                          <attributes>
                            <attribute name="text">1</attribute>
                          </attributes>
                        </child>
                      </object>
                    </child>
                    <child>
                      <object class="GtkTreeViewColumn" id="treeviewcolumn8">
                        <property name="title" translatable="yes">Bytes -&gt;</property>
                        <child>
                          <object class="GtkCellRendererText" id="cellrenderertext9"/>
                          <attributes>
                            <attribute name="text">2</attribute>
                          </attributes>
                        </child>
                      </object>
                    </child>
                    <child>
                      <object class="GtkTreeViewColumn" id="treeviewcolumn9">
                        <property name="title" translatable="yes">&lt;- Bytes</property>
                        <child>
                          <object class="GtkCellRendererText" id="cellrenderertext10"/>
                          <attributes>
                            <attribute name="text">3</attribute>
                          </attributes>
                        </child>
                      </object>
                    </child>
                    <child>
                      <object class="GtkTreeViewColumn" id="treeviewcolumn10">
                        <property name="title" translatable="yes">Start time</property>
                        <child>
                          <object class="GtkCellRendererText" id="cellrenderertext11"/>
                          <attributes>
                            <attribute name="text">4</attribute>
                          </attributes>
                        </child>
                      </object>
                    </child>
                    <child>
                      <object class="GtkTreeViewColumn" id="treeviewcolumn11">
                        <property name="title" translatable="yes">End time</property>
                        <child>
                          <object class="GtkCellRendererText" id="cellrenderertext12"/>
                          <attributes>
                            <attribute name="text">5</attribute>
                          </attributes>
                        </child>
                      </object>
                    </child>
                    <child>
                      <object class="GtkTreeViewColumn" id="treeviewcolumn12">
                        <property name="title" translatable="yes">Duration</property>
                        <child>
                          <object class="GtkCellRendererText" id="cellrenderertext13"/>
                          <attributes>
                            <attribute name="text">6</attribute>
                          </attributes>
                        </child>
                      </object>
                    </child>
                  </object>
                </child>
              </object>
              <packing>
                <property name="position">1</property>
              </packing>
            </child>
            <child type="tab">
              <object class="GtkLabel" id="label2">
                <property name="visible">True</property>
                <property name="can_focus">False</property>
                <property name="label" translatable="yes">Treeview</property>
              </object>
              <packing>
                <property name="position">1</property>
                <property name="tab_fill">False</property>
              </packing>
            </child>
            <child>
              <object class="GtkBox" id="box4">
                <property name="visible">True</property>
                <property name="can_focus">False</property>
                <property name="orientation">vertical</property>
                <child>
                  <object class="GtkDrawingArea" id="da_navigator">
                    <property name="height_request">48</property>
                    <property name="visible">True</property>
                    <property name="can_focus">False</property>
                    <property name="valign">end</property>
                    <property name="hexpand">True</property>
                  </object>
                  <packing>
                    <property name="expand">False</property>
                    <property name="fill">False</property>
                    <property name="position">0</property>
                  </packing>
                </child>
                <child>
                  <object class="GtkScrollbar" id="scrollbar1">
                    <property name="visible">True</property>
                    <property name="can_focus">False</property>
                    <property name="adjustment">adj_scroll</property>
                  </object>
                  <packing>
                    <property name="expand">False</property>
                    <property name="fill">True</property>
                    <property name="position">1</property>
                  </packing>
                </child>
                <child>
                  <object class="GtkBox" id="box5">
                    <property name="visible">True</property>
                    <property name="can_focus">False</property>
                    <child>
                      <object class="GtkScale" id="scale1">
                        <property name="visible">True</property>
                        <property name="can_focus">True</property>
                        <property name="hexpand">True</property>
                        <property name="adjustment">adj_scale</property>
                        <property name="restrict_to_fill_level">False</property>
                        <property name="fill_level">0</property>
                        <property name="round_digits">1</property>
                        <property name="draw_value">False</property>
                      </object>
                      <packing>
                        <property name="expand">False</property>
                        <property name="fill">True</property>
                        <property name="position">0</property>
                      </packing>
                    </child>
                    <child>
                      <object class="GtkLabel" id="lb_interval">
                        <property name="width_request">50</property>
                        <property name="visible">True</property>
                        <property name="can_focus">False</property>
                      </object>
                      <packing>
                        <property name="expand">False</property>
                        <property name="fill">True</property>
                        <property name="position">1</property>
                      </packing>
                    </child>
                  </object>
                  <packing>
                    <property name="expand">False</property>
                    <property name="fill">True</property>
                    <property name="position">2</property>
                  </packing>
                </child>
              </object>
              <packing>
                <property name="position">2</property>
              </packing>
            </child>
            <child type="tab">
              <object class="GtkLabel" id="label3">
                <property name="visible">True</property>
                <property name="can_focus">False</property>
                <property name="label" translatable="yes">Navigator</property>
              </object>
              <packing>
                <property name="position">2</property>
                <property name="tab_fill">False</property>
              </packing>
            </child>
            <child>
              <placeholder/>
            </child>
            <child type="tab">
              <placeholder/>
            </child>
          </object>
          <packing>
            <property name="expand">False</property>
            <property name="fill">True</property>
            <property name="position">1</property>
          </packing>
        </child>
        <child>
          <object class="GtkScrolledWindow" id="scrolledwindow1">
            <property name="visible">True</property>
            <property name="can_focus">True</property>
            <property name="shadow_type">in</property>
            <child>
              <object class="GtkTreeView" id="tv_frames">
                <property name="visible">True</property>
                <property name="can_focus">True</property>
                <property name="model">store_frames</property>
                <property name="headers_clickable">False</property>
                <property name="enable_search">False</property>
                <property name="search_column">0</property>
                <property name="enable_grid_lines">horizontal</property>
                <child internal-child="selection">
                  <object class="GtkTreeSelection" id="treeview-selection"/>
                </child>
                <child>
                  <object class="GtkTreeViewColumn" id="treeviewcolumn1">
                    <property name="resizable">True</property>
                    <property name="title" translatable="yes">_Frame</property>
                    <child>
                      <object class="GtkCellRendererText" id="cellrenderertext1"/>
                      <attributes>
                        <attribute name="text">0</attribute>
                      </attributes>
                    </child>
                  </object>
                </child>
                <child>
                  <object class="GtkTreeViewColumn" id="treeviewcolumn2">
                    <property name="resizable">True</property>
                    <property name="title" translatable="yes">_Source</property>
                    <child>
                      <object class="GtkCellRendererText" id="cellrenderertext2"/>
                      <attributes>
                        <attribute name="text">1</attribute>
                      </attributes>
                    </child>
                  </object>
                </child>
                <child>
                  <object class="GtkTreeViewColumn" id="treeviewcolumn3">
                    <property name="resizable">True</property>
                    <property name="title" translatable="yes">_Destination</property>
                    <child>
                      <object class="GtkCellRendererText" id="cellrenderertext3"/>
                      <attributes>
                        <attribute name="text">2</attribute>
                      </attributes>
                    </child>
                  </object>
                </child>
                <child>
                  <object class="GtkTreeViewColumn" id="treeviewcolumn4">
                    <property name="resizable">True</property>
                    <property name="title" translatable="yes">_Length</property>
                    <child>
                      <object class="GtkCellRendererText" id="cellrenderertext4"/>
                      <attributes>
                        <attribute name="text">3</attribute>
                      </attributes>
                    </child>
                  </object>
                </child>
                <child>
                  <object class="GtkTreeViewColumn" id="treeviewcolumn5">
                    <property name="resizable">True</property>
                    <property name="title" translatable="yes">_Time</property>
                    <child>
                      <object class="GtkCellRendererText" id="cellrenderertext5"/>
                      <attributes>
                        <attribute name="text">4</attribute>
                      </attributes>
                    </child>
                  </object>
                </child>
                <child>
                  <object class="GtkTreeViewColumn" id="treeviewcolumn6">
                    <property name="resizable">True</property>
                    <property name="title" translatable="yes">_Decode</property>
                    <child>
                      <object class="GtkCellRendererText" id="cellrenderertext6"/>
                      <attributes>
                        <attribute name="text">5</attribute>
                      </attributes>
                    </child>
                  </object>
                </child>
              </object>
            </child>
          </object>
          <packing>
            <property name="expand">False</property>
            <property name="fill">True</property>
            <property name="position">2</property>
          </packing>
        </child>
      </object>
    </child>
  </object>
  <object class="GtkMenu" id="popup_circle">
    <property name="visible">True</property>
    <property name="can_focus">False</property>
    <child>
      <object class="GtkMenuItem" id="popup_line_type">
        <property name="visible">True</property>
        <property name="can_focus">False</property>
        <property name="label" translatable="yes">Lines type</property>
        <property name="use_underline">True</property>
        <child type="submenu">
          <object class="GtkMenu" id="menu1">
            <property name="visible">True</property>
            <property name="can_focus">False</property>
            <child>
              <object class="GtkMenuItem" id="popup_line_single">
                <property name="visible">True</property>
                <property name="can_focus">False</property>
                <property name="label" translatable="yes">Single</property>
                <property name="use_underline">True</property>
              </object>
            </child>
            <child>
              <object class="GtkMenuItem" id="popup_line_in_out">
                <property name="visible">True</property>
                <property name="can_focus">False</property>
                <property name="label" translatable="yes">In &amp; Out</property>
                <property name="use_underline">True</property>
              </object>
            </child>
          </object>
        </child>
      </object>
    </child>
    <child>
      <object class="GtkMenuItem" id="popup_line_show">
        <property name="visible">True</property>
        <property name="can_focus">False</property>
        <property name="label" translatable="yes">Text</property>
        <property name="use_underline">True</property>
        <child type="submenu">
          <object class="GtkMenu" id="menu2">
            <property name="visible">True</property>
            <property name="can_focus">False</property>
            <child>
              <object class="GtkMenuItem" id="popup_text_size">
                <property name="visible">True</property>
                <property name="can_focus">False</property>
                <property name="label" translatable="yes">Size</property>
                <property name="use_underline">True</property>
              </object>
            </child>
            <child>
              <object class="GtkMenuItem" id="popup_text_latency">
                <property name="visible">True</property>
                <property name="can_focus">False</property>
                <property name="label" translatable="yes">Latency</property>
                <property name="use_underline">True</property>
              </object>
            </child>
          </object>
        </child>
      </object>
    </child>
    <child>
      <object class="GtkSeparatorMenuItem" id="menuitem1">
        <property name="visible">True</property>
        <property name="can_focus">False</property>
      </object>
    </child>
    <child>
      <object class="GtkMenuItem" id="popup_latency">
        <property name="visible">True</property>
        <property name="can_focus">False</property>
        <property name="label" translatable="yes">Latency</property>
        <property name="use_underline">True</property>
      </object>
    </child>
  </object>
  <object class="GtkMenu" id="popup_connects">
    <property name="visible">True</property>
    <property name="can_focus">False</property>
    <child>
      <object class="GtkMenuItem" id="popup_connects_delete">
        <property name="visible">True</property>
        <property name="can_focus">False</property>
        <property name="label" translatable="yes">Delete</property>
        <property name="use_underline">True</property>
      </object>
    </child>
    <child>
      <object class="GtkMenuItem" id="popup_connects_hide">
        <property name="visible">True</property>
        <property name="can_focus">False</property>
        <property name="label" translatable="yes">Show / Hide</property>
        <property name="use_underline">True</property>
      </object>
    </child>
  </object>
  <object class="GtkMenu" id="popup_hosts">
    <property name="visible">True</property>
    <property name="can_focus">False</property>
    <child>
      <object class="GtkMenuItem" id="popup_hosts_delete">
        <property name="visible">True</property>
        <property name="can_focus">False</property>
        <property name="label" translatable="yes">_Delete</property>
        <property name="use_underline">True</property>
      </object>
    </child>
    <child>
      <object class="GtkMenuItem" id="popup_hosts_icon">
        <property name="visible">True</property>
        <property name="can_focus">False</property>
        <property name="label" translatable="yes">_Change Icon</property>
        <property name="use_underline">True</property>
      </object>
    </child>
    <child>
      <object class="GtkMenuItem" id="popup_reference">
        <property name="visible">True</property>
        <property name="can_focus">False</property>
        <property name="label" translatable="yes">_Choose host as reference</property>
        <property name="use_underline">True</property>
      </object>
    </child>
    <child>
      <object class="GtkMenuItem" id="popup_host_hide">
        <property name="visible">True</property>
        <property name="can_focus">False</property>
        <property name="label" translatable="yes">_Show / hide</property>
        <property name="use_underline">True</property>
      </object>
    </child>
  </object>
  <object class="GtkTreeStore" id="store_connects">
    <columns>
      <!-- column-name Connexions -->
      <column type="gchararray"/>
      <!-- column-name lenght -->
      <column type="guint"/>
      <!-- column-name Bytes -->
      <column type="guint"/>
      <!-- column-name <- -->
      <column type="guint"/>
      <!-- column-name Start -->
      <column type="gchararray"/>
      <!-- column-name End -->
      <column type="gchararray"/>
      <!-- column-name Duration -->
      <column type="gchararray"/>
    </columns>
  </object>
  <object class="GtkListStore" id="store_frames">
    <columns>
      <!-- column-name num_trame -->
      <column type="guint"/>
      <!-- column-name source -->
      <column type="gchararray"/>
      <!-- column-name destination -->
      <column type="gchararray"/>
      <!-- column-name taille -->
      <column type="guint"/>
      <!-- column-name temps -->
      <column type="gchararray"/>
      <!-- column-name decodage -->
      <column type="gchararray"/>
    </columns>
  </object>
  <object class="GtkListStore" id="store_hosts">
    <columns>
      <!-- column-name ip_address -->
      <column type="gchararray"/>
      <!-- column-name selected -->
      <column type="gboolean"/>
    </columns>
  </object>
  <object class="GtkListStore" id="store_hosts_ref">
    <columns>
      <!-- column-name adresse -->
      <column type="gchararray"/>
    </columns>
  </object>
  <object class="GtkWindow" id="win_hosts_ref">
    <property name="can_focus">False</property>
    <property name="resizable">False</property>
    <child>
      <object class="GtkFixed" id="fixed2">
        <property name="visible">True</property>
        <property name="can_focus">False</property>
        <child>
          <object class="GtkTreeView" id="treeview1">
            <property name="width_request">160</property>
            <property name="height_request">229</property>
            <property name="visible">True</property>
            <property name="can_focus">True</property>
            <property name="model">store_hosts_ref</property>
            <child internal-child="selection">
              <object class="GtkTreeSelection" id="treeview-selection5"/>
            </child>
            <child>
              <object class="GtkTreeViewColumn" id="treeviewcolumn13">
                <property name="title" translatable="yes">IP Address</property>
                <child>
                  <object class="GtkCellRendererText" id="cellrenderertext14"/>
                  <attributes>
                    <attribute name="text">0</attribute>
                  </attributes>
                </child>
              </object>
            </child>
          </object>
          <packing>
            <property name="x">10</property>
            <property name="y">10</property>
          </packing>
        </child>
        <child>
          <object class="GtkButton" id="btn_del_ref">
            <property name="label" translatable="yes">Remove</property>
            <property name="width_request">100</property>
            <property name="height_request">32</property>
            <property name="visible">True</property>
            <property name="can_focus">True</property>
            <property name="receives_default">True</property>
          </object>
          <packing>
            <property name="x">186</property>
            <property name="y">14</property>
          </packing>
        </child>
        <child>
          <object class="GtkButton" id="btn_close_ref">
            <property name="label" translatable="yes">Close</property>
            <property name="width_request">100</property>
            <property name="height_request">32</property>
            <property name="visible">True</property>
            <property name="can_focus">True</property>
            <property name="receives_default">True</property>
          </object>
          <packing>
            <property name="x">186</property>
            <property name="y">205</property>
          </packing>
        </child>
      </object>
    </child>
  </object>
</interface>
""";
#endif
