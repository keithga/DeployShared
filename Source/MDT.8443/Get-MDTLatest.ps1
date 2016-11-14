
$MDTRoot = "x:\program files\microsoft deployment toolkit"

robocopy "$MDTRoot\SCCM" "$PSScriptRoot\SCCM" 
robocopy "$MDTRoot\Templates" "$PSScriptRoot\Templates"
robocopy /e "$MDTRoot\Templates\distribution\scripts" "$PSScriptRoot\scripts" /xf *.gif *.png *.bmp *.jpg *.ico
.\SCCM