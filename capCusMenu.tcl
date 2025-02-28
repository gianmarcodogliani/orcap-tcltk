# ---------------------------------------------------------------------------------------
# capCusMenu.tcl
# Author: Gianmarco Dogliani
# GitHub: https://github.com/gianmarcodogliani/orcap-tcltk
# Created: 2025-02-28
# Updated: 2025-02-28
# Description: This script sets up a custom pull-down menù within Capture's menù bar
# Usage: Copy the script to the capAutoLoad directory and launch Capture.
# License: MIT License
# ---------------------------------------------------------------------------------------

proc registerMenu {args} {
	catch {
        InsertXMLMenu  [list [list "menuptr1"] "" "" [list "popup" "Menu Label 1"  "" "" "" "" ""] ""]
            InsertXMLMenu  [list [list "menuptr1" "submenuptr1"] "" "" [list "popup" "SubMenu Label 1"  "" "" "" "" ""] ""]
                InsertXMLMenu  [list [list "menuptr1" "submenuptr1" "submenuact11"] "" "" [list "action" "&SubMenu Action 11"  "0" "submenuact11" "submenuupd11" "" "" "" "SubMenu Action 11"] ""]
                InsertXMLMenu  [list [list "menuptr1" "submenuptr1" "submenuact12"] "" "" [list "action" "&SubMenu Action 12"  "0" "submenuact12" "submenuupd12" "" "" "" "SubMenu Action 12"] ""]
                InsertXMLMenu  [list [list "menuptr1" "submenuptr1" "sepptr1"] "1" "submenuact12" [list "separator"] ""]
                # ----------
                InsertXMLMenu  [list [list "menuptr1" "submenuptr1" "submenuact13"] "" "" [list "action" "&SubMenu Action 13"  "0" "submenuact13" "submenuupd13" "" "" "" "SubMenu Action 13"] ""]
            InsertXMLMenu  [list [list "menuptr1" "submenuptr2"] "" "" [list "popup" "SubMenu Label 2"  "" "" "" "" ""] ""]
                InsertXMLMenu  [list [list "menuptr1" "submenuptr2" "submenuact21"] "" "" [list "action" "&SubMenu Action 21"  "0" "submenuact21" "submenuupd21" "" "" "" "SubMenu Action 21"] ""]
            InsertXMLMenu  [list [list "menuptr1" "sepptr2"]  "1" "menuptr1" [list "separator"] ""]
            # ----------
            InsertXMLMenu  [list [list "menuptr1" "submenuptr3"] "" "" [list "action" "&SubMenu Action 3"  "0" "submenuact3" "submenuupd3" "" "" "" "SubMenu Action 3"] ""]
            InsertXMLMenu  [list [list "menuptr1" "sepptr3"]  "1" "menuptr1" [list "separator"] ""]
            # ----------
            InsertXMLMenu  [list [list "menuptr1" "submenuptr4"] "" "" [list "action" "&SubMenu Action 4"  "0" "submenuact4" "submenuupd4" "" "" "" "SubMenu Action 4"] ""]  
               
        RegisterAction "submenuact11" "capTrue" "" "submenuproc11" ""
		RegisterAction "submenuupd11" "capTrue" "" "capTrue" ""
        RegisterAction "submenuact12" "capTrue" "" "submenuproc12" ""
		RegisterAction "submenuupd12" "capTrue" "" "capTrue" ""
        RegisterAction "submenuact13" "capTrue" "" "submenuproc13" ""
        RegisterAction "submenuupd13" "capTrue" "" "capTrue" ""
        RegisterAction "submenuact21" "capTrue" "" "submenuproc21" ""
        RegisterAction "submenuupd21" "capTrue" "" "capTrue" ""
        RegisterAction "submenuact3"  "capTrue" "" "submenuproc3" ""
        RegisterAction "submenuupd3"  "capTrue" "" "capTrue" ""
        RegisterAction "submenuact4"  "capTrue" "" "submenuproc4" ""
        RegisterAction "submenuupd4"  "capTrue" "" "capTrue" ""
	}
}

proc submenuproc11 {args} { puts "Got in submenuproc11!" }
proc submenuproc12 {args} { puts "Got in submenuproc12!" }
proc submenuproc13 {args} { puts "Got in submenuproc13!" }
proc submenuproc21 {args} { puts "Got in submenuproc21!" }
proc submenuproc3 {args} { puts "Got in submenuproc3!" }
proc submenuproc4 {args} { puts "Got in submenuproc4!" }

registerMenu   ;# Invoke main procedure