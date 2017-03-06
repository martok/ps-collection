add-type -AssemblyName microsoft.VisualBasic
add-type -AssemblyName System.Windows.Forms

$Def_PID = 5420


[Microsoft.VisualBasic.Interaction]::AppActivate($Def_PID)
[System.Windows.Forms.SendKeys]::SendWait(“{HOME}”)
start-sleep -Seconds 2

$i = 0
do {
 [System.Windows.Forms.SendKeys]::SendWait(“^{i}”)
 start-sleep -Seconds 2
 $fn = "IMG{0}.png" -f $i.ToString("D4")
 [System.Windows.Forms.SendKeys]::SendWait($fn)
 [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")

 start-sleep -Seconds 2
 [System.Windows.Forms.SendKeys]::SendWait("{DOWN}")
 start-sleep -Seconds 2
 $i ++
} while (1)