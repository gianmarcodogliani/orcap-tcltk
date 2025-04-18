namespace eval orbench { } 
#
#
#
proc orbench::load_orDb_Dll_Tcl64 {} {
    set cdsRoot [exec cds_root cds_root]
    load [file normalize [file join $cdsRoot/tools/bin/ orDb_Dll_Tcl64]] DboTclWriteBasic
    return
}
proc orbench::create_session {} {
    set dboSession [DboTclHelper_sCreateSession] 
    return $dboSession
}
proc orbench::open_design_in_session {dboSession designPath} {
    set dboState [DboState]
    set csDesignPath [DboTclHelper_sMakeCString $designPath] 
    set dboDesign [$dboSession GetDesignAndSchematics $csDesignPath $dboState]
    return $dboDesign
}
proc orbench::close_session {dboSession dboDesign} {
    DboSession_MarkAllLibForSave $dboSession $dboDesign
    DboSession_SaveDesign $dboSession $dboDesign
    DboSession_RemoveDesign $dboSession $dboDesign
    DboTclHelper_sDeleteSession $dboSession
    return
}
#
#
#
proc orbench::get_name {dbObject} {
    set csName [DboTclHelper_sMakeCString]
    $dbObject GetName $csName
    set name [DboTclHelper_sGetConstCharPtr $csName]
    return $name
}
proc orbench::get_value {dbObject {type ""}} {
    set csValue [DboTclHelper_sMakeCString]
    if {$type == "display"} {   ;# display property
        $dbObject GetValueString $csValue
    } else {   ;# user property
        $dbObject GetStringValue $csValue
    }
    set value [DboTclHelper_sGetConstCharPtr $csValue]
    return $value
}
proc orbench::scan_dprops {dbObject} {   ;# display properties
    set dboState [DboState]
    set propIter [$dbObject NewDisplayPropsIter $dboState] 
    set dboProp [$propIter NextProp $dboState] 
    while {$dboProp != "NULL"} {  
        set name [orbench::get_name $dboProp]
        set value [orbench::get_value $dboProp display]   ;# display
        # process $name and $value
        set dboProp [$propIter NextProp $dboState] 
    } 
    delete_DboDisplayPropsIter $propIter
    return
}
proc orbench::scan_uprops {dbObject} {   ;# user properties
    set dboState [DboState]
    set propIter [$dbObject NewUserPropsIter $dboState] 
    set dboProp [$propIter NextUserProp $dboState] 
    while {$dboProp != "NULL"} {  
        set name [orbench::get_name $dboProp] 
        set value [orbench::get_value $dboProp ""]   ;# user
        # process $name and $value
        set dboProp [$propIter NextUserProp $dboState] 
    } 
    delete_DboUserPropsIter $propIter
    return
}
proc orbench::scan_eprops {dbObject} {   ;# effective propreties
    set dboState [DboState]
    set propIter [$dbObject NewEffectivePropsIter $dboState]  
    set pName [DboTclHelper_sMakeCString] 
    set pValue [DboTclHelper_sMakeCString] 
    set pType [DboTclHelper_sMakeDboValueType] 
    set pEdit [DboTclHelper_sMakeInt] 
    set dboState [$propIter NextEffectiveProp $pName $pValue $pType $pEdit] 
    while {[$dboState OK] == 1} { 
        set name [DboTclHelper_sGetConstCharPtr $pName]
        set value [DboTclHelper_sGetConstCharPtr $pValue]
        # process $name and $value 
        set dboState [$propIter NextEffectiveProp $pName $pValue $pType $pEdit] 
    } 
    delete_DboEffectivePropsIter $propIter
    return
}
proc orbench::get_schematic {{dboDesign ""} schematic} {
    set dboState [DboState]
    if {$dboDesign == ""} {
        set dboDesign [GetActivePMDesign]
    }
    set csSchematic [DboTclHelper_sMakeCString $schematic] 
    set dboSchematic [$dboDesign GetSchematic $csSchematic $dboState]
    return $dboSchematic
}
proc orbench::scan_schematics {{dboDesign ""}} {
    set dboState [DboState]
    if {$dboDesign == ""} {
        set dboDesign [GetActivePMDesign]
    } 
    set schematicIter [$dboDesign NewViewsIter $dboState $::IterDefs_SCHEMATICS]
    set dboView [$schematicIter NextView $dboState]
    while {$dboView != "NULL"} {
        set dboSchematic [DboViewToDboSchematic $dboView]
        # process $dboSchematic
        set dboView [$schematicIter NextView $dboState]
    }
    delete_DboLibViewsIter $schematicIter
    return
}
proc orbench::get_page {dboSchematic page} {
    set dboState [DboState]
    set csPage [DboTclHelper_sMakeCString $page] 
    set dboPage [$dboSchematic GetPage $csPage $dboState]
    return $dboPage
}
proc orbench::scan_pages {dboSchematic} {
    set dboState [DboState]
    set pageIter [$dboSchematic NewPagesIter $dboState]
    set dboPage [$pageIter NextPage $dboState]
    while {$dboPage != "NULL"} {
        # process $dboPage
        set dboPage [$pageIter NextPage $dboState]
    }
    delete_DboSchematicPagesIter $pageIter
}
proc orbench::scan_parts {dboPage schematicType} {
    set dboState [DboState]
    set partIter [$dboPage NewPartInstsIter $dboState]
    set dboPartInst [$partIter NextPartInst $dboState]
    while {$dboPartInst != "NULL"} {
        if {$schematicType == "flat"} {
            set dboPlacedInst [DboPartInstToDboPlacedInst $dboPartInst]
            if {$dboPlacedInst != "NULL"} {
                # process $dboPlacedInst
            }
        } elseif {$schematicType == "hier"} {
            set dboDrawnInst [DboPartInstToDboDrawnInst $dboPartInst]
            if {$dboDrawnInst != "NULL"} {
                # process $dboDrawnInst
            }
        }
    set dboPartInst [$partIter NextPartInst $dboState]
    }
    delete_DboPagePartInstsIter $partIter
    return
}
proc orbench::scan_wires {dboPage} {
    set dboState [DboState]
    set wireIter [$dboPage NewWiresIter $dboState] 
    set dboWire [$wireIter NextWire $dboState] 
    while {$dboWire != "NULL"} { 
        set objType [$dboWire GetObjectType] 
        if {$objType == $::DboBaseObject_WIRE_SCALAR} { 
            # process scalar $dboWire
        } elseif {$objType == $::DboBaseObject_WIRE_BUS} { 
            # process bus $dboWire 
        } 
        set dboWire [$wireIter NextWire $dboState] 
    } 
    delete_DboPageWiresIter $wireIter
    return
}
proc orbench::scan_globals {dboPage} {
    set dboState [DboState]
    set globalIter [$dboPage NewGlobalsIter $dboState]  
    set dboGlobal [$globalIter NextGlobal $dboState] 
    while {$dboGlobal != "NULL"} { 
        # process $dboGlobal
        set dboGlobal [$globalIter NextGlobal $dboState] 
    } 
    delete_DboPageGlobalsIter $globalIter
    return
}
proc orbench::scan_offpages {dboPage} {
    set dboState [DboState]
    set offpageIter [$dboPage NewOffPageConnectorsIter $dboState $::IterDefs_ALL] 
    set dbOffpage [$offpageIter NextOffPageConnector $dboState] 
    while {$dbOffpage !="NULL"} { 
        # process $dbOffpage
        set dbOffpage [$offpageIter NextOffPageConnector $dboState] 
    } 
    delete_DboPageOffPageConnectorsIter $offpageIter
    return
}
