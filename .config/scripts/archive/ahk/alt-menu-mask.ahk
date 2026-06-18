#Requires AutoHotkey v2.0
#SingleInstance Force

; Port of Taran's Alt_menu_acceleration_DISABLER to AHK v2.
; Pairs each Alt keydown with an unassigned scan code so Windows never
; enters menu mode, which causes whkd hotkeys to be eaten on first press.
; Reference: https://github.com/TaranVH/2nd-keyboard

~LAlt::
{
    SendInput("{Blind}{sc0E9}")
    KeyWait("LAlt")
    SendInput("{Blind}{sc0EA}")
}

~RAlt::
{
    SendInput("{Blind}{sc0E9}")
    KeyWait("RAlt")
    SendInput("{Blind}{sc0EA}")
}
