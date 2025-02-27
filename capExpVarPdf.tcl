package provide capExpVarPdf_package 1.0

namespace eval expVarPdf { }

proc expVarPdf::enable_journaling {} {
    # if Journaling == 0, set it to 1
    if {![GetOptionBool Journaling]} {SetOptionBool Journaling TRUE}
    return
}
proc expVarPdf::look_4_gs {} {
    set found false   ;# found flag
    # Look for ghostscript in system env variables
    foreach var [split $::env(PATH) ";"] {
        set var [string map {\\ /} $var]   ;# Normalize path to bin folder
        if {[regexp {(C:/Program Files/gs/)(.*)(/bin)} $var fullMatch j0 ver j1]} {
            # A ghostscript version has been found 
            set found true
        }
    }
    if {$found == "false"} {
        # Ghostscript has not been found in system env variables
        set answer [tk_messageBox -title "Error" -message "Ghostscript not found in PATH system environment variable" \
                        -detail "Configure system PATH and reboot" -icon error -type ok]
        switch -- $answer {
            ok { return 1 }
        }
    }
    return 0
}
proc expVarPdf::get_bom_variants {} {
    set dboPath [GetActivePMDesign]   ;# _DboDesign
    set cisDesign [CPartMgmt_GetCisDesign $dboPath]   ;# _CISDesign
    set bomVarContainer [$cisDesign GetBOMVariantContainer]   ;# _CNewBOm
    set bomVarCount [$bomVarContainer GetBomCount]   ;# int
    if {$bomVarCount > 0} {
        # There is at least one BOM Variant
        set csBomVarName [DboTclHelper_sMakeCString]   ;# _CString
        for {set i 0} {$i < $bomVarCount} {incr i} {
		    $bomVarContainer GetBomName $i $csBomVarName
		    set bomVarName [DboTclHelper_sGetConstCharPtr $csBomVarName]   ;# char*
		    set bomVarList [lappend bomVarList $bomVarName] 
	    }
        return $bomVarList
    } else {
        return ""
    }
}
proc expVarPdf::sanity_check {str} {
    set illegal_chars "\ | ! £ $ % & ? ^ * @ + < > , ~ #"
    set mapping [list]
    foreach char $illegal_chars {
        lappend mapping $char _
    }
    set sanitized [string map $mapping $str]
    return $sanitized
}
proc expVarPdf::get_design_name {} {
    set dboPath [GetActivePMDesign]   ;# _DboDesign
    set csPath [DboTclHelper_sMakeCString]   ;# _CString
    $dboPath GetName $csPath 
    set path [DboTclHelper_sGetConstCharPtr $csPath]   ;# char*
    set dsnName [lindex [split [lindex [split $path "\\"] end] "."] 0]
    return [string map {" " _} [sanity_check $dsnName]]
}
proc expVarPdf::export_pdf {varName} {
    package require OrHandlerPDFExport
    # Possibility to manage OrCADPS_XX.X?
    ::OrHandlerPDFExport::printPDF {{"outputDirectory":"./",\
                                    "outputPdfFile":"sample.pdf",\
                                    "postscriptFilePath":"OrCADPS_24.1",\
                                    "PStoPdfConverter":"Ghostscript 64 bit / equivalent",\
                                    "PdfExcludeProp":"Line Style!!Line Width!!Color!!Location X-Coordinate!!Location Y-Coordinate",\
                                    "PStoPdfCommand":"{gswin64} -sDEVICE=pdfwrite -sOutputFile=$::capPdfUtil::mPdfFilePath -dBATCH -dNOPAUSE $::capPdfUtil::mPSFilePath",\
                                    "commandIndex":2,"printingMode":"0","orientation":"1",\
                                    "createPdfPropertiesFile":"0",\
                                    "createNetAndPartBookmarks":"1",\
                                    "PaperSizeIndex":0}}
    # Rename sample.pdf
    if {$varName == "<Core Design>"} {
        set filePrefix [get_design_name]
        set fileExt "_coredsn.pdf"
        set fileName "$filePrefix$fileExt"   ;# dsnName_coredsn.pdf
    } else {
        set filePrefix [get_design_name]
        set fileExt "_[string map {" " _} [sanity_check $varName]].pdf"
        set fileName "$filePrefix$fileExt"   ;# dsnName_bomVar.pdf
    }
    file rename -force "sample.pdf" $fileName   ;# -force to allow overwriting
    return
}
proc expVarPdf::switch_var_view {varName} {
    set xmlFileName "var_view_mode.xml"
    set fp [open $xmlFileName w+]
	set bomVarList [get_bom_variants]
    # Header
	puts $fp {<?xml version="1.0" encoding="UTF-8" standalone="yes" ?>}
    # <DialogControls>
	puts $fp "<DialogControls>"
        # <Control Type>
		puts $fp {<Control Type="LIST_BOX" Enable="TRUE" Visible="TRUE" Id="1265">}
		puts $fp "<Value><!\[CDATA\[$varName\]\]></Value>"   ;# To Be Printed
		puts $fp "<Value><!\[CDATA\[<Core Design>\]\]></Value>"
        foreach bomVarName $bomVarList {
		    puts $fp "<Value><!\[CDATA\[$bomVarName\]\]></Value>"
		}
        # <\Control>
        puts $fp "</Control>"
        # <Control Type>
        puts $fp {<Control Type="PUSH_BUTTON" Enable="TRUE" Visible="TRUE" Id="1">}
		puts $fp "<Value><!\[CDATA\[OK\]\]></Value>"
		puts $fp "</Control>"
		puts $fp {<Control Type="PUSH_BUTTON" Enable="TRUE" Visible="TRUE" Id="2">}
		puts $fp "<Value><!\[CDATA\[Cancel\]\]></Value>"
		puts $fp "</Control>"
		puts $fp {<Control Type="PUSH_BUTTON" Enable="TRUE" Visible="TRUE" Id="57670">}
		puts $fp "<Value><!\[CDATA\[Help\]\]></Value>"
        # <\Control>
        puts $fp "</Control>"
    # </DialogControls>
    puts $fp "</DialogControls>"
	close $fp
    Menu "View::Variant View Mode" | DialogBox  "OK" "./$xmlFileName"   ;# Switch Variant View
    file delete "./$xmlFileName"   ;# Delete tmp File
    return [expVarPdf::export_pdf $varName]   ;# Export pdf and record pdf as printed
}
proc expVarPdf::restore_core_design_view {} {
    set xmlFileName "var_view_mode.xml"
    set fp [open $xmlFileName w+]
	set bomVarList [get_bom_variants]
    # Header
	puts $fp {<?xml version="1.0" encoding="UTF-8" standalone="yes" ?>}
    # <DialogControls>
	puts $fp "<DialogControls>"
        # <Control Type>
		puts $fp {<Control Type="LIST_BOX" Enable="TRUE" Visible="TRUE" Id="1265">}
		puts $fp "<Value><!\[CDATA\[<Core Design>\]\]></Value>"
		puts $fp "<Value><!\[CDATA\[<Core Design>\]\]></Value>"
        foreach bomVarName $bomVarList {
		    puts $fp "<Value><!\[CDATA\[$bomVarName\]\]></Value>"
		}
        # <\Control>
        puts $fp "</Control>"
        # <Control Type>
        puts $fp {<Control Type="PUSH_BUTTON" Enable="TRUE" Visible="TRUE" Id="1">}
		puts $fp "<Value><!\[CDATA\[OK\]\]></Value>"
		puts $fp "</Control>"
		puts $fp {<Control Type="PUSH_BUTTON" Enable="TRUE" Visible="TRUE" Id="2">}
		puts $fp "<Value><!\[CDATA\[Cancel\]\]></Value>"
		puts $fp "</Control>"
		puts $fp {<Control Type="PUSH_BUTTON" Enable="TRUE" Visible="TRUE" Id="57670">}
		puts $fp "<Value><!\[CDATA\[Help\]\]></Value>"
        # <\Control>
        puts $fp "</Control>"
    # </DialogControls>
    puts $fp "</DialogControls>"
	close $fp
    Menu "View::Variant View Mode" | DialogBox  "OK" "./$xmlFileName"   ;# Switch Variant View
    file delete "./$xmlFileName"   ;# Delete tmp File
    return
}
#
# Main Procedure
#
proc expVarPdf::export {{var all}} {
    expVarPdf::enable_journaling   ;# Make sure Journaling is enabled before using Menu command
    ;# Make sure ghostscript is set in sys env variables
    if {![expVarPdf::look_4_gs]} {   
        set bomVarList [expVarPdf::get_bom_variants]
        ;# Insert <Core Design> in bomVarList at pos 0 (first), empty list case is managed
        set bomVarList [linsert $bomVarList 0 "<Core Design>"]
        if {$var == "all"} {
            foreach bomVar $bomVarList {
                expVarPdf::switch_var_view $bomVar
            }
        } elseif {[lsearch $bomVarList $var] >= 0} {
            expVarPdf::switch_var_view $var
        } else {
            puts "\[    1\]RuntimeError variant $var not found"
            return
        }
        expVarPdf::restore_core_design_view
        set answer [tk_messageBox -title "Info" -message "PDF Export completed successfully" -icon info -type ok]
        switch -- $answer {
            ok { return }
        }
    }
}