param(
    [string]$Action,
    [string]$Value = ""
)

Add-Type -AssemblyName System.Runtime.WindowsRuntime -ErrorAction SilentlyContinue

$asTaskGeneric = [System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object {
    $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1'
} | Select-Object -First 1

function Get-RadiosList {
    [Windows.Devices.Radios.Radio,Windows.System.Devices,ContentType=WindowsRuntime] | Out-Null
    $op = [Windows.Devices.Radios.Radio]::GetRadiosAsync()
    $task = $asTaskGeneric.MakeGenericMethod([System.Collections.Generic.IReadOnlyList[Windows.Devices.Radios.Radio]]).Invoke($null, @($op))
    $task.Wait()
    return $task.Result
}

function Set-RadioState([string]$Kind, [string]$TargetState) {
    $radios = Get-RadiosList
    $radio = $radios | Where-Object { $_.Kind -eq $Kind }
    if ($radio) {
        $stateEnum = if ($TargetState.ToLower() -eq 'on') { [Windows.Devices.Radios.RadioState]::On } else { [Windows.Devices.Radios.RadioState]::Off }
        $op = $radio.SetStateAsync($stateEnum)
        $task = $asTaskGeneric.MakeGenericMethod([Windows.Devices.Radios.RadioAccessStatus]).Invoke($null, @($op))
        $task.Wait()
        return $task.Result
    }
    return "NotFound"
}

if (-not ([System.Management.Automation.PSTypeName]'WinDisplay').Type) {
    Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class WinDisplay {
    [DllImport("user32.dll")]
    public static extern IntPtr SendMessage(IntPtr hWnd, uint Msg, IntPtr wParam, IntPtr lParam);
    [DllImport("user32.dll")]
    public static extern void mouse_event(int dwFlags, int dx, int dy, int dwData, int dwExtraInfo);

    public static void TurnOff() {
        SendMessage((IntPtr)0xFFFF, 0x0112, (IntPtr)0xF170, (IntPtr)2);
    }
    public static void TurnOn() {
        mouse_event(1, 1, 1, 0, 0);
        mouse_event(1, -1, -1, 0, 0);
    }
}
"@
}

switch ($Action.ToLower()) {
    "status" {
        $radios = Get-RadiosList
        $wifi = ($radios | Where-Object { $_.Kind -eq 'WiFi' }).State -eq 'On'
        $bt = ($radios | Where-Object { $_.Kind -eq 'Bluetooth' }).State -eq 'On'
        Write-Output "{\"wifi\":$($wifi.ToString().ToLower()),\"bluetooth\":$($bt.ToString().ToLower())}"
    }
    "setwifi" {
        $res = Set-RadioState "WiFi" $Value
        Write-Output "OK:$res"
    }
    "setbluetooth" {
        $res = Set-RadioState "Bluetooth" $Value
        Write-Output "OK:$res"
    }
    "displayoff" {
        [WinDisplay]::TurnOff()
        Write-Output "OK"
    }
    "displayon" {
        [WinDisplay]::TurnOn()
        Write-Output "OK"
    }
}
