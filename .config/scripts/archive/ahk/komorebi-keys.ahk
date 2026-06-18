#Requires AutoHotkey v2.0
#SingleInstance Force

; Full replacement for whkd — all lalt+ and lwin+ komorebi bindings.
; Non-tilde hotkeys suppress keys from reaching applications, so no app
; can eat an lalt+key combination before this script handles it.

; ─────────────────────────────────────────────────────────────────────────────
;  Helpers
; ─────────────────────────────────────────────────────────────────────────────

KWM(cmd) {
    Run("komorebic " . cmd, , "Hide")
}

PSFile(script, args := "") {
    cmd := 'powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "' . script . '"'
    if (args != "")
        cmd .= " " . args
    Run(cmd, , "Hide")
}

UP   := EnvGet("USERPROFILE")
LAPP := EnvGet("LOCALAPPDATA")
FOL  := UP . "\.config\scripts\powershell\whkd\focus-or-launch.ps1"

; ─────────────────────────────────────────────────────────────────────────────
;  Focus                                                    lalt + h/j/k/l
; ─────────────────────────────────────────────────────────────────────────────

<!h::KWM("focus left")
<!j::KWM("focus down")
<!k::KWM("focus up")
<!l::KWM("focus right")

; ─────────────────────────────────────────────────────────────────────────────
;  Focus Cycling                               lalt+shift+[  /  lalt+shift+]
; ─────────────────────────────────────────────────────────────────────────────

<!+[::KWM("cycle-focus previous")
<!+]::KWM("cycle-focus next")

; ─────────────────────────────────────────────────────────────────────────────
;  Move                                               lalt + shift + h/j/k/l
; ─────────────────────────────────────────────────────────────────────────────

<!+h::KWM("move left")
<!+j::KWM("move down")
<!+k::KWM("move up")
<!+l::KWM("move right")
<!+Enter::KWM("promote")

; ─────────────────────────────────────────────────────────────────────────────
;  Stacking
; ─────────────────────────────────────────────────────────────────────────────

<!Left::KWM("stack left")
<!Down::KWM("stack down")
<!Up::KWM("stack up")
<!Right::KWM("stack right")
<!vkBA::KWM("unstack")              ; lalt+;   (oem_1 = VK_OEM_1)
<![::KWM("cycle-stack previous")    ; lalt+[   (oem_4)
<!]::KWM("cycle-stack next")        ; lalt+]   (oem_6)

; ─────────────────────────────────────────────────────────────────────────────
;  Resizing
; ─────────────────────────────────────────────────────────────────────────────

<!vkBB::KWM("resize-axis horizontal increase")    ; lalt+=   (oem_plus)
<!vkBD::KWM("resize-axis horizontal decrease")    ; lalt+-   (oem_minus)
<!+vkBB::KWM("resize-axis vertical increase")     ; lalt+shift+=
<!+vkBD::KWM("resize-axis vertical decrease")     ; lalt+shift+-

; ─────────────────────────────────────────────────────────────────────────────
;  Layout
; ─────────────────────────────────────────────────────────────────────────────

<!x::KWM("flip-layout horizontal")
<!y::KWM("flip-layout vertical")

; ─────────────────────────────────────────────────────────────────────────────
;  Window State
; ─────────────────────────────────────────────────────────────────────────────

<!t::KWM("toggle-float")
<!f::KWM("toggle-monocle")
<!q::KWM("close")
<!m::KWM("minimize")

; ─────────────────────────────────────────────────────────────────────────────
;  Manager
; ─────────────────────────────────────────────────────────────────────────────

<!+r::KWM("retile")
<!p::KWM("toggle-pause")
<!i::KWM("toggle-shortcuts")
<!b::PSFile(UP . "\.config\scripts\powershell\komorebi\toggle-bar.ps1")

; ─────────────────────────────────────────────────────────────────────────────
;  Workspaces                                               lalt + 1-9
; ─────────────────────────────────────────────────────────────────────────────

<!1::KWM("focus-workspace 0")
<!2::KWM("focus-workspace 1")
<!3::KWM("focus-workspace 2")
<!4::KWM("focus-workspace 3")
<!5::KWM("focus-workspace 4")
<!6::KWM("focus-workspace 5")
<!7::KWM("focus-workspace 6")
<!8::KWM("focus-workspace 7")
<!9::KWM("focus-workspace 8")

<!+1::KWM("move-to-workspace 0")
<!+2::KWM("move-to-workspace 1")
<!+3::KWM("move-to-workspace 2")
<!+4::KWM("move-to-workspace 3")
<!+5::KWM("move-to-workspace 4")
<!+6::KWM("move-to-workspace 5")
<!+7::KWM("move-to-workspace 6")
<!+8::KWM("move-to-workspace 7")
<!+9::KWM("move-to-workspace 8")

; ─────────────────────────────────────────────────────────────────────────────
;  Cycle Workspaces
; ─────────────────────────────────────────────────────────────────────────────

<!vkBC::KWM("cycle-workspace previous")     ; lalt+,   (oem_comma)
<!vkBE::KWM("cycle-workspace next")         ; lalt+.   (oem_period)
^<!h::KWM("cycle-workspace previous")       ; lalt+ctrl+h
^<!l::KWM("cycle-workspace next")           ; lalt+ctrl+l

<!+vkBC::KWM("cycle-move-to-workspace previous")    ; lalt+shift+,
<!+vkBE::KWM("cycle-move-to-workspace next")        ; lalt+shift+.
^<!+h::KWM("cycle-move-to-workspace previous")      ; lalt+shift+ctrl+h
^<!+l::KWM("cycle-move-to-workspace next")          ; lalt+shift+ctrl+l

; ─────────────────────────────────────────────────────────────────────────────
;  App Launchers                                            lwin + ...
; ─────────────────────────────────────────────────────────────────────────────

<#Enter::PSFile(FOL, '-ProcessName emacs -LaunchPath "C:\Program Files\Emacs\emacs-30.2\bin\emacsclient.exe" -Arguments "-c -n"')
<#n::PSFile(UP . "\.config\scripts\powershell\whkd\emacs-daily-review.ps1")
<#f::PSFile(FOL, '-ProcessName firefox -LaunchPath "C:\Program Files\Mozilla Firefox\firefox.exe"')
<#v::PSFile(FOL, '-ProcessName Code -LaunchPath "' . LAPP . '\Programs\Microsoft VS Code\Code.exe"')
<#o::PSFile(FOL, '-ProcessName olk -LaunchPath "' . LAPP . '\Microsoft\WindowsApps\olk.exe"')
<#d::PSFile(FOL, '-ProcessName Discord -LaunchPath "' . LAPP . '\Discord\Update.exe" -Arguments "--processStart Discord.exe"')
<#p::PSFile(FOL, '-ProcessName PhoneExperienceHost -LaunchPath "explorer.exe" -Arguments "shell:AppsFolder\Microsoft.YourPhone_8wekyb3d8bbwe!App"')
<#+n::PSFile(FOL, '-ProcessName Obsidian -LaunchPath "' . LAPP . '\Programs\Obsidian\Obsidian.exe"')
<#+vkBF::PSFile(FOL, '-ProcessName Windsurf -LaunchPath "' . LAPP . '\Programs\Windsurf\Windsurf.exe"')
