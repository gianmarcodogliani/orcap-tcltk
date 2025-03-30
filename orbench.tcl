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
#
#
#
proc orbench::get_schematic {dboDesign schematic} {
    set dboState [DboState]
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