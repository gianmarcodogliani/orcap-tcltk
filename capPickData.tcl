# -------------------------------------------------------------------------------------
# capPickData.tcl
# Author: Gianmarco Dogliani
# GitHub: https://github.com/gianmarcodogliani/orcap-tcltk
# Created: 2025-02-28
# Updated: 2025-02-28
# Description: This script runs batch Extracta to backannotate mirror data from
#              PCB Editor to OrCAD X Capture.
# Usage: Source the script at the Capture command window and type pickData::pickMirror
# License: MIT License
# -------------------------------------------------------------------------------------

namespace eval pickData { }

proc pickData::look_4_algro {} {
    set pVer "SPB_[lindex [split [GetProductVersion] " "] 0]"
    set found 0   ;# found flag
    # Look for allegro in system env variables
    foreach var [split $::env(PATH) ";"] {
        set var [string map {\\ /} $var]   ;# Normalize path to bin folder
        if {[regexp {(C:/Cadence/)(.*)(/tools/bin)} $var fullMatch j0 ver j1]} {
            if {$ver == $pVer} {
                # An allegro version has been found 
                incr found
            }
        }
    }
    if {$found < 2} {
        # allegro has not been found in system env variables
        set answer [tk_messageBox -title "Error" -message "Allegro not found in PATH system environment variable" \
                        -detail "Configure system PATH and reboot" -icon error -type ok]
        switch -- $answer {
            ok { return 1 }
        }
    } else {  
        return 0
    }
}
proc pickData::write_cmd {} {
    set pVer "SPB_[lindex [split [GetProductVersion] " "] 0]"
    set text "COMPONENT REFDES REFDES_SORT SYM_MIRROR END" 
    set cmd "C:/Cadence/$pVer/share/pcb/text/views/temp.txt"
    set fp [open $cmd w]
    foreach line $text {
        puts $fp $line
    }
    close $fp
    return $cmd
}
proc pickData::get_design_name {} {
    set dboPath [GetActivePMDesign]   ;# _DboDesign
    set csPath [DboTclHelper_sMakeCString]   ;# _CString
    $dboPath GetName $csPath 
    set path [DboTclHelper_sGetConstCharPtr $csPath]   ;# char*
    set dsnName [lindex [split [lindex [split $path "\\"] end] "."] 0]
    return $dsnName
}
proc pickData::parse {report} {
    set line 0
    set fp [open $report r]
    while {[gets $fp data] >= 0} {
        # Skip first two lines
        if {$line > 1} {
            set refdes [lindex [split $data "!"] 1]
            set mirror [lindex [split $data "!"] end-1]
            if {$mirror == ""} {
                # Component is unplaced
                set mirror NA
            }
            set mirrorData [lappend mirrorData "$refdes $mirror"]
        }
        incr line
    }
    close $fp
    return $mirrorData
}
proc pickData::add_property {dboPlacedInst name value} {
    set csPropName [DboTclHelper_sMakeCString $name]
    set csPropValue [DboTclHelper_sMakeCString $value]
    $dboPlacedInst SetEffectivePropStringValue $csPropName $csPropValue
    return
}
proc pickData::add_mirror_data {data} {
    set nullObject NULL
    set status [DboState]
    set dboPath [GetActivePMDesign]
    set schematicIter [$dboPath NewViewsIter $status $::IterDefs_SCHEMATICS]
    set dboView [$schematicIter NextView $status]   ;# first schematic 'view'
    # iterate on schematics
    while {$dboView != $nullObject} {
        set dboSchematic [DboViewToDboSchematic $dboView]   ;# cast to _DboSchematic
        set pageIter [$dboSchematic NewPagesIter $status]                    
        set dboPage [$pageIter NextPage $status]   ;# first page (_DboPage)
        # iterate on pages
        while {$dboPage != $nullObject} {
            set partInstIter [$dboPage NewPartInstsIter $status]
            set dboPartInst [$partInstIter NextPartInst $status]   ;# first part inst (_DboPartInst)
            # iterate on part instances
            while {$dboPartInst != $nullObject} {
                set dboPlacedInst [DboPartInstToDboPlacedInst $dboPartInst]   ;# _DboPlacedInst
                if {$dboPlacedInst != $nullObject} {
                    set csRef [DboTclHelper_sMakeCString]
                    $dboPlacedInst GetReference $csRef
                    set ref [DboTclHelper_sGetConstCharPtr $csRef]
                    foreach item $data {
                        if {$ref == [lindex $item 0]} {
                            pickData::add_property $dboPlacedInst Pick_Mirror [lindex $item 1]
                        }
                    }
                }
                set dboPartInst [$partInstIter NextPartInst $status]   ;# next part inst
            }
            delete_DboPagePartInstsIter $partInstIter     
            set dboPage [$pageIter NextPage $status]   ;# next page
        }
        delete_DboSchematicPagesIter $pageIter
        set dboView [$schematicIter NextView  $status]   ;# next schematic 'view'
    }
    delete_DboLibViewsIter $schematicIter
    return
}
#
# Main Procedure
#
proc pickData::pickMirror {} {
    ;# Make sure allegro is set in sys env variables
    if {![pickData::look_4_algro]} {
        set types { {{Allegro Board Files}   {.brd}} }   ;# Force user to choose .brd files only
        set board [tk_getOpenFile -filetypes $types]
        if {$board != ""} {
            set cmd [pickData::write_cmd]
            set rep "[string map [subst {[get_design_name].opj out}] [GetActiveOpjName]].txt"
            exec cmd.exe /e /r "extracta -q $board $cmd $rep"
            set mirrorData [pickData::parse $rep]
            pickData::add_mirror_data $mirrorData
            # Cleanup
            file delete $cmd
            file delete extract.log
            file delete -force signoise.run
            file delete $rep
            set answer [tk_messageBox -title "Info" -message "Pick Data completed successfully" -icon info -type ok]
            switch -- $answer {
                ok { return }
            }
        } else {
            # User may have pressed Cancel
        }
        return
    }
}