Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class DisplayControl {
    [DllImport("user32.dll")]
    public static extern IntPtr SendMessage(IntPtr hWnd, uint Msg, IntPtr wParam, IntPtr lParam);
    public static void TurnOff() {
        SendMessage((IntPtr)0xFFFF, 0x0112, (IntPtr)0xF170, (IntPtr)2);
    }
}
"@
[DisplayControl]::TurnOff()
Write-Output "TurnOff command sent"
