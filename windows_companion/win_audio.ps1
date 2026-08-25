param(
    [string]$Action,
    [float]$Value = 0
)

$code = @"
using System;
using System.Runtime.InteropServices;

[Guid("5CDF2C82-841E-4546-9722-0CF74078229A"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
interface IAudioEndpointVolume {
    int f(); int g(); int h(); int i();
    int SetMasterVolumeLevelScalar(float fLevel, System.Guid pguidEventContext);
    int j();
    int GetMasterVolumeLevelScalar(out float pfLevel);
    int SetMute([MarshalAs(UnmanagedType.Bool)] bool bMute, System.Guid pguidEventContext);
    int GetMute(out bool pbMute);
}

[Guid("D666063F-1587-4E43-81F1-B948E807363F"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
interface IMMDevice {
    int Activate(ref System.Guid id, int clsCtx, int opt, out IAudioEndpointVolume epv);
}

[Guid("A95664D2-9614-4F35-A746-DE8DB63617E6"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
interface IMMDeviceEnumerator {
    int GetDefaultAudioEndpoint(int dataFlow, int role, out IMMDevice endpoint);
}

[ComImport, Guid("BCDE0395-E52F-467C-8E3D-C4579291692E")]
class MMDeviceEnumeratorComObject {}

public class WinAudio {
    private static IAudioEndpointVolume GetEndpoint() {
        var enumerator = new MMDeviceEnumeratorComObject() as IMMDeviceEnumerator;
        IMMDevice dev;
        enumerator.GetDefaultAudioEndpoint(0, 1, out dev);
        var guid = typeof(IAudioEndpointVolume).GUID;
        IAudioEndpointVolume epv;
        dev.Activate(ref guid, 23, 0, out epv);
        return epv;
    }

    public static void SetVolume(float val) {
        var epv = GetEndpoint();
        epv.SetMasterVolumeLevelScalar(Math.Max(0.0f, Math.Min(1.0f, val / 100.0f)), System.Guid.Empty);
    }

    public static float GetVolume() {
        var epv = GetEndpoint();
        float v;
        epv.GetMasterVolumeLevelScalar(out v);
        return (float)Math.Round(v * 100.0f);
    }

    public static void SetMute(bool mute) {
        var epv = GetEndpoint();
        epv.SetMute(mute, System.Guid.Empty);
    }

    public static bool GetMute() {
        var epv = GetEndpoint();
        bool m;
        epv.GetMute(out m);
        return m;
    }
}
"@

if (-not ([System.Management.Automation.PSTypeName]'WinAudio').Type) {
    Add-Type -TypeDefinition $code
}

switch ($Action.ToLower()) {
    "getvolume" {
        $v = [WinAudio]::GetVolume()
        Write-Output $v
    }
    "setvolume" {
        [WinAudio]::SetVolume($Value)
        Write-Output "OK"
    }
    "getmute" {
        $m = [WinAudio]::GetMute()
        Write-Output $m
    }
    "setmute" {
        $muteBool = ($Value -gt 0)
        [WinAudio]::SetMute($muteBool)
        Write-Output "OK"
    }
    "wifion" {
        Get-NetAdapter -Name *Wi-Fi*,*Wireless*,*WLAN* -ErrorAction SilentlyContinue | Enable-NetAdapter -Confirm:$false -ErrorAction SilentlyContinue
        Write-Output "OK"
    }
    "wifioff" {
        Get-NetAdapter -Name *Wi-Fi*,*Wireless*,*WLAN* -ErrorAction SilentlyContinue | Disable-NetAdapter -Confirm:$false -ErrorAction SilentlyContinue
        Write-Output "OK"
    }
    "bluetoothon" {
        try {
            [Windows.Devices.Radios.Radio,Windows.System.Devices,ContentType=WindowsRuntime] | Out-Null
            $radios = [Windows.Devices.Radios.Radio]::GetRadiosAsync().GetAwaiter().GetResult()
            $bt = $radios | Where-Object { $_.Kind -eq 'Bluetooth' }
            if ($bt) { $bt.SetStateAsync('On').GetAwaiter().GetResult() | Out-Null }
        } catch {
            Get-PnpDevice -Class Bluetooth -ErrorAction SilentlyContinue | Enable-PnpDevice -Confirm:$false -ErrorAction SilentlyContinue
        }
        Write-Output "OK"
    }
    "bluetoothoff" {
        try {
            [Windows.Devices.Radios.Radio,Windows.System.Devices,ContentType=WindowsRuntime] | Out-Null
            $radios = [Windows.Devices.Radios.Radio]::GetRadiosAsync().GetAwaiter().GetResult()
            $bt = $radios | Where-Object { $_.Kind -eq 'Bluetooth' }
            if ($bt) { $bt.SetStateAsync('Off').GetAwaiter().GetResult() | Out-Null }
        } catch {
            Get-PnpDevice -Class Bluetooth -ErrorAction SilentlyContinue | Disable-PnpDevice -Confirm:$false -ErrorAction SilentlyContinue
        }
        Write-Output "OK"
    }
    "displayoff" {
        (Add-Type -MemberDefinition '[DllImport("user32.dll")] public static extern int SendMessage(int hWnd, int hMsg, int wParam, int lParam);' -Name "Win32Display" -Namespace Win32 -PassThru)::SendMessage(0xffff, 0x0112, 0xF170, 2) | Out-Null
        Write-Output "OK"
    }
    "displayon" {
        (Add-Type -MemberDefinition '[DllImport("user32.dll")] public static extern void mouse_event(int dwFlags, int dx, int dy, int dwData, int dwExtraInfo);' -Name "Win32Mouse" -Namespace Win32 -PassThru)::mouse_event(1, 1, 1, 0, 0)
        Write-Output "OK"
    }
}
