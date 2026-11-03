# Preview launcher follow-up

After stage29 push1636318 the user reported no visible preview from the supplied
start_game.ps1 command. Their launch-20261102T0959544780870Z record selected combat,
1920x1080 windowed on larger left3840x2160 DISPLAY1. Logs contain normal Godot/
D3D12 startup with no engine diagnostics; no Godot process remained when inspected.
This alone does not establish why the process ended or prove physical visibility.

The launcher incorrectly used Start-Process -WindowStyle Hidden for an interactive
game. Changed it to Normal, and added a bounded two-second startup-exit check with
recorded state/exit code and explicit log path on failure. Background GPU fixtures
retain their independent minimized/no_focus policy. Direct console-wrapper launch
is recommended to the user so output and process lifetime remain in their terminal.

Validation: PowerShell AST parse PASS; -Scene combat -ConfigureOnly PASS confirms
current DISPLAY1 mapping and owned profile; direct combat scene headless30-frame
startup exits0 without diagnostics. git diff --check PASS. No physical desktop
launch/input was performed, so actual window visibility remains to be confirmed.
No gameplay code or packaged EXE/PCK changed. This local follow-up is not included
in the already pushed1636318 checkpoint.
