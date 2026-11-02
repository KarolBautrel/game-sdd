# Read display modes in physical pixels. WinForms alone can return DPI-virtualized sizes.
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Windows.Forms
if (-not ('SddQaDisplayModes' -as [type])) {
    Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public static class SddQaDisplayModes {
    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    public struct Mode {
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)] public string device;
        public ushort specVersion, driverVersion, size, driverExtra;
        public uint fields;
        public int x, y;
        public uint orientation, fixedOutput;
        public short color, duplex, yResolution, ttOption, collate;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)] public string form;
        public ushort logPixels;
        public uint bitsPerPixel, width, height, flags, frequency, icmMethod,
            icmIntent, mediaType, ditherType, reserved1, reserved2,
            panningWidth, panningHeight;
    }
    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    private static extern bool EnumDisplaySettings(string device, int mode, ref Mode settings);
    public static Mode Read(string name) {
        var mode = new Mode();
        mode.size = (ushort)Marshal.SizeOf(typeof(Mode));
        if (!EnumDisplaySettings(name, -1, ref mode))
            throw new Exception("Current display mode unavailable: " + name);
        return mode;
    }
}
'@
}
foreach ($screen in [System.Windows.Forms.Screen]::AllScreens) {
    $mode = [SddQaDisplayModes]::Read($screen.DeviceName)
    $scaleX = [double]$mode.width / $screen.Bounds.Width
    $scaleY = [double]$mode.height / $screen.Bounds.Height
    [pscustomobject]@{
        DeviceName = $screen.DeviceName
        Primary = $screen.Primary
        X = $mode.x
        Y = $mode.y
        Width = [int]$mode.width
        Height = [int]$mode.height
        RefreshHz = [int]$mode.frequency
        VirtualizedWidth = $screen.Bounds.Width
        VirtualizedHeight = $screen.Bounds.Height
        WorkingX = $mode.x + [int][Math]::Round(($screen.WorkingArea.X - $screen.Bounds.X) * $scaleX)
        WorkingY = $mode.y + [int][Math]::Round(($screen.WorkingArea.Y - $screen.Bounds.Y) * $scaleY)
        WorkingWidth = [int][Math]::Round($screen.WorkingArea.Width * $scaleX)
        WorkingHeight = [int][Math]::Round($screen.WorkingArea.Height * $scaleY)
    }
}
