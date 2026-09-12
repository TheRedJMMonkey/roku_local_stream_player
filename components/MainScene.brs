' ============================================================
' Default presets used the first time the app runs, and
' whenever "Reset to Defaults" is used in the preset editor.
' ============================================================
function GetDefaultPresets() as object
    return [
        {
            name: "FFmpeg Local Stream (MPEG-TS)"
            url: "http://192.168.18.206:8080/stream.ts"
            format: "ts"
        }
    ]
end function

sub Init()
    m.video = m.top.findNode("video")
    m.video.observeField("state", "onVideoStateChange")

    m.status = m.top.findNode("statusLabel")

    m.retryTimer = m.top.findNode("retryTimer")
    m.retryTimer.observeField("fire", "onRetryTimer")

    m.reg = CreateObject("roRegistrySection", "LocalStreamPlayer")

    LoadPresets()

    m.top.backgroundColor = "0x000000FF"
    m.top.setFocus(true)

    ' Skip the menu entirely when there's exactly one preset configured.
    ' Back/Options still bring up the full menu at any time.
    if m.presets.count() = 1
        p = m.presets[0]
        PlayStream(p.url, p.format)
    else
        ShowMainDialog()
    end if
end sub

' ============================== Persistence ==============================

sub LoadPresets()
    stored = m.reg.Read("presets")
    if stored <> invalid and stored <> ""
        parsed = ParseJson(stored)
        if parsed <> invalid and type(parsed) = "roArray"
            m.presets = parsed
            return
        end if
    end if
    m.presets = GetDefaultPresets()
    SavePresets()
end sub

sub SavePresets()
    m.reg.Write("presets", FormatJson(m.presets))
    m.reg.Flush()
end sub

' ============================== Main dialog ==============================

sub ShowMainDialog()
    dialog = CreateObject("roSGNode", "Dialog")
    dialog.title = "Select a Stream"
    dialog.message = "Choose a preset, or manage/enter URLs below."

    buttons = []
    for each p in m.presets
        buttons.push(p.name)
    end for
    buttons.push("Manage Presets...")
    buttons.push("Play Custom URL...")
    buttons.push("Exit")
    dialog.buttons = buttons

    dialog.observeField("buttonSelected", "onMainDialogSelected")
    m.mainDialog = dialog
    m.top.dialog = dialog
end sub

sub onMainDialogSelected(event as object)
    index = event.getData()
    numPresets = m.presets.count()
    m.mainDialog.close = true

    if index < numPresets
        p = m.presets[index]
        PlayStream(p.url, p.format)
    else if index = numPresets
        ShowManageDialog()
    else if index = numPresets + 1
        ShowCustomUrlKeyboard()
    else
        m.top.close = true
    end if
end sub

' ============================== Manage presets ==============================

sub ShowManageDialog()
    dialog = CreateObject("roSGNode", "Dialog")
    dialog.title = "Manage Presets"
    dialog.message = "Select a preset to play/edit/delete, or add a new one."

    buttons = []
    for each p in m.presets
        buttons.push(p.name)
    end for
    buttons.push("Add New Preset")
    buttons.push("Reset to Defaults")
    buttons.push("Back")
    dialog.buttons = buttons

    dialog.observeField("buttonSelected", "onManageDialogSelected")
    m.manageDialog = dialog
    m.top.dialog = dialog
end sub

sub onManageDialogSelected(event as object)
    index = event.getData()
    numPresets = m.presets.count()
    m.manageDialog.close = true

    if index < numPresets
        ShowPresetActionDialog(index)
    else if index = numPresets
        StartAddPreset()
    else if index = numPresets + 1
        ShowResetConfirmDialog()
    else
        ShowMainDialog()
    end if
end sub

sub ShowResetConfirmDialog()
    dialog = CreateObject("roSGNode", "Dialog")
    dialog.title = "Reset to Defaults"
    dialog.message = "This replaces all saved presets with the defaults. This cannot be undone."
    dialog.buttons = ["Reset", "Cancel"]
    dialog.observeField("buttonSelected", "onResetConfirmSelected")
    m.resetDialog = dialog
    m.top.dialog = dialog
end sub

sub onResetConfirmSelected(event as object)
    index = event.getData()
    m.resetDialog.close = true
    if index = 0
        m.presets = GetDefaultPresets()
        SavePresets()
    end if
    ShowManageDialog()
end sub

sub ShowPresetActionDialog(index as integer)
    m.actionIndex = index
    p = m.presets[index]

    dialog = CreateObject("roSGNode", "Dialog")
    dialog.title = p.name
    dialog.message = p.url
    dialog.buttons = ["Play", "Edit", "Delete", "Back"]

    dialog.observeField("buttonSelected", "onPresetActionSelected")
    m.actionDialog = dialog
    m.top.dialog = dialog
end sub

sub onPresetActionSelected(event as object)
    index = event.getData()
    m.actionDialog.close = true
    p = m.presets[m.actionIndex]

    if index = 0 ' Play
        PlayStream(p.url, p.format)
    else if index = 1 ' Edit
        StartEditPreset(m.actionIndex)
    else if index = 2 ' Delete
        m.presets.Delete(m.actionIndex)
        SavePresets()
        ShowManageDialog()
    else ' Back
        ShowManageDialog()
    end if
end sub

' ============================== Add / edit preset flow ==============================
' Both flows collect Name -> URL -> Format, then save.
' m.pendingIndex = invalid means "add new"; otherwise it's the index being edited.

sub StartAddPreset()
    m.pendingIndex = invalid
    m.pendingPreset = { name: "", url: "", format: "mp4" }
    ShowNameKeyboard()
end sub

sub StartEditPreset(index as integer)
    m.pendingIndex = index
    orig = m.presets[index]
    m.pendingPreset = { name: orig.name, url: orig.url, format: orig.format }
    ShowNameKeyboard()
end sub

sub ShowNameKeyboard()
    kb = CreateObject("roSGNode", "KeyboardDialog")
    kb.title = "Preset Name"
    kb.buttons = ["Next", "Cancel"]
    if m.pendingPreset.name <> "" then kb.keyboard.text = m.pendingPreset.name
    kb.observeField("buttonSelected", "onNameEntered")
    m.nameKeyboard = kb
    m.top.dialog = kb
end sub

sub onNameEntered(event as object)
    index = event.getData()
    m.nameKeyboard.close = true
    if index = 0 and m.nameKeyboard.keyboard.text <> ""
        m.pendingPreset.name = m.nameKeyboard.keyboard.text
        ShowUrlKeyboard()
    else
        ShowManageDialog()
    end if
end sub

sub ShowUrlKeyboard()
    kb = CreateObject("roSGNode", "KeyboardDialog")
    kb.title = "Stream URL"
    kb.buttons = ["Next", "Cancel"]
    if m.pendingPreset.url <> "" then kb.keyboard.text = m.pendingPreset.url
    kb.observeField("buttonSelected", "onUrlEntered")
    m.urlKeyboard = kb
    m.top.dialog = kb
end sub

sub onUrlEntered(event as object)
    index = event.getData()
    m.urlKeyboard.close = true
    if index = 0 and m.urlKeyboard.keyboard.text <> ""
        m.pendingPreset.url = m.urlKeyboard.keyboard.text
        ShowFormatDialog()
    else
        ShowManageDialog()
    end if
end sub

sub ShowFormatDialog()
    dialog = CreateObject("roSGNode", "Dialog")
    dialog.title = "Stream Format"
    dialog.message = "What kind of stream is this?"
    dialog.buttons = ["MP4 (progressive / fMP4)", "HLS (.m3u8)", "DASH (.mpd)", "MPEG-TS", "Cancel"]
    dialog.observeField("buttonSelected", "onFormatSelected")
    m.formatDialog = dialog
    m.top.dialog = dialog
end sub

sub onFormatSelected(event as object)
    index = event.getData()
    m.formatDialog.close = true

    formats = ["mp4", "hls", "dash", "ts"]
    if index < formats.count()
        m.pendingPreset.format = formats[index]
        SavePendingPreset()
    else
        ShowManageDialog()
    end if
end sub

sub SavePendingPreset()
    if m.pendingIndex = invalid
        m.presets.push(m.pendingPreset)
    else
        m.presets[m.pendingIndex] = m.pendingPreset
    end if
    SavePresets()
    ShowManageDialog()
end sub

' ============================== One-off custom URL ==============================

sub ShowCustomUrlKeyboard()
    kb = CreateObject("roSGNode", "KeyboardDialog")
    kb.title = "Enter Stream URL"
    kb.buttons = ["Play", "Cancel"]

    lastUrl = m.reg.Read("lastCustomUrl")
    if lastUrl <> invalid and lastUrl <> "" then kb.keyboard.text = lastUrl

    kb.observeField("buttonSelected", "onCustomUrlEntered")
    m.customKeyboard = kb
    m.top.dialog = kb
end sub

sub onCustomUrlEntered(event as object)
    index = event.getData()
    m.customKeyboard.close = true

    if index = 0
        url = m.customKeyboard.keyboard.text
        if url <> ""
            m.reg.Write("lastCustomUrl", url)
            m.reg.Flush()
            PlayStream(url, GuessFormat(url))
        else
            ShowMainDialog()
        end if
    else
        ShowMainDialog()
    end if
end sub

' Best-effort format guess from the URL extension, used only
' for one-off custom URLs (saved presets always store an explicit format).
function GuessFormat(url as string) as string
    lcUrl = LCase(url)
    if Instr(1, lcUrl, ".m3u8") > 0 then return "hls"
    if Instr(1, lcUrl, ".mpd") > 0 then return "dash"
    if Instr(1, lcUrl, ".ts") > 0 then return "ts"
    return "mp4"
end function

' ============================== Playback ==============================

sub PlayStream(url as string, format as string)
    m.retryTimer.control = "stop"
    m.currentUrl = url
    m.currentFormat = format

    content = CreateObject("roSGNode", "ContentNode")
    content.url = url
    content.streamFormat = format
    content.live = true

    m.video.content = content
    m.video.visible = true
    m.video.control = "play"
    m.video.setFocus(true)

    ShowStatus("Connecting to stream...")
end sub

sub ShowStatus(text as string)
    m.status.text = text
    m.status.visible = true
end sub

sub HideStatus()
    m.status.visible = false
end sub

sub onVideoStateChange(event as object)
    state = event.getData()

    if state = "playing"
        HideStatus()
    else if state = "buffering"
        ShowStatus("Connecting to stream...")
    else if state = "error" or state = "finished"
        ' Stream isn't there (FFmpeg not running, YouTube not live, etc.)
        ' Keep the video node up so the picture returns as soon as the
        ' source comes back, but tell the user what's going on instead
        ' of leaving a silent black screen, and retry automatically.
        ShowStatus("Stream not available - retrying in 5s (press Back for menu)")
        m.retryTimer.control = "start"
    end if
end sub

sub onRetryTimer()
    if m.currentUrl <> invalid
        PlayStream(m.currentUrl, m.currentFormat)
    end if
end sub

' ============================== Remote control ==============================

function onKeyEvent(key as string, press as boolean) as boolean
    handled = false
    if press and m.video.visible
        if key = "back" or key = "options"
            m.retryTimer.control = "stop"
            m.video.control = "stop"
            m.video.visible = false
            HideStatus()
            ShowMainDialog()
            handled = true
        end if
    end if
    return handled
end function
