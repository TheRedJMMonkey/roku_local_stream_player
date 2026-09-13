sub Init()
    m.video = m.top.findNode("video")
    m.video.observeField("state", "onVideoStateChange")

    m.status = m.top.findNode("statusLabel")

    m.retryTimer = m.top.findNode("retryTimer")
    m.retryTimer.observeField("fire", "onRetryTimer")

    m.modal = m.top.findNode("modal")

    m.reg = CreateObject("roRegistrySection", "LocalStreamPlayer")

    m.currentScreen = ""
    m.pendingPreset = invalid
    m.pendingIndex = invalid

    LoadPresets()

    m.top.backgroundColor = "0x000000FF"
    m.top.setFocus(true)

    if m.presets.count() = 1
        p = m.presets[0]
        PlayStream(p.url, p.format)
    else
        ShowMainDialog()
    end if
end sub

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

function GetDefaultPresets() as object
    return [
        {
            name: "CGPC Local Stream (HLS)"
            url: "http://10.0.0.60:8888/stream/index.m3u8"
            format: "hls"
        }
    ]
end function

sub ShowModal(title as string, message as string, buttons as object, screenName as string)
    m.currentScreen = screenName
    m.modal.title = title
    m.modal.message = message
    m.modal.buttons = buttons
    m.modal.selectedIndex = 0
    m.modal.visible = true
    m.modal.setFocus(true)
end sub

sub CloseModal()
    m.modal.visible = false
end sub

sub ShowMainDialog()
    btns = []
    for each p in m.presets
        btns.push(p.name)
    end for
    btns.push("Manage Presets...")
    btns.push("Play Custom URL...")
    btns.push("Exit")

    ShowModal("Select a Stream", "Choose a preset, or manage/enter URLs below.", btns, "main")
end sub

sub ShowManageDialog()
    btns = []
    for each p in m.presets
        btns.push(p.name)
    end for
    btns.push("Add New Preset")
    btns.push("Reset to Defaults")
    btns.push("Back")

    ShowModal("Manage Presets", "Select a preset to play/edit/delete, or add a new one.", btns, "manage")
end sub

sub ShowPresetActionDialog(index as integer)
    m.actionIndex = index
    p = m.presets[index]

    ShowModal(p.name, p.url, ["Play", "Edit", "Delete", "Back"], "presetAction")
end sub

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
    kb.keyboard.text = m.pendingPreset.name
    kb.observeField("buttonSelected", "onKeyboardButton")

    m.nameKeyboard = kb
    m.currentScreen = "nameKeyboard"
    m.top.dialog = kb
end sub

sub ShowUrlKeyboard()
    kb = CreateObject("roSGNode", "KeyboardDialog")
    kb.title = "Stream URL"
    kb.buttons = ["Next", "Cancel"]
    kb.keyboard.text = m.pendingPreset.url
    kb.observeField("buttonSelected", "onKeyboardButton")

    m.urlKeyboard = kb
    m.currentScreen = "urlKeyboard"
    m.top.dialog = kb
end sub

sub ShowFormatDialog()
    ShowModal("Stream Format", "What kind of stream is this?", ["MP4", "HLS", "DASH", "MPEG-TS", "Cancel"], "formatDialog")
end sub

sub ShowCustomUrlKeyboard()
    kb = CreateObject("roSGNode", "KeyboardDialog")
    kb.title = "Enter Stream URL"
    kb.buttons = ["Play", "Cancel"]

    lastUrl = m.reg.Read("lastCustomUrl")
    if lastUrl <> invalid and lastUrl <> "" then kb.keyboard.text = lastUrl

    kb.observeField("buttonSelected", "onKeyboardButton")

    m.customKeyboard = kb
    m.currentScreen = "customUrlKeyboard"
    m.top.dialog = kb
end sub

sub HandleModalSelection()
    idx = m.modal.selectedIndex
    screen = m.currentScreen

    CloseModal()

    if screen = "main"
        HandleMainSelection(idx)
    else if screen = "manage"
        HandleManageSelection(idx)
    else if screen = "presetAction"
        HandlePresetAction(idx)
    else if screen = "formatDialog"
        HandleFormatSelection(idx)
    else if screen = "resetConfirm"
        HandleResetConfirm(idx)
    end if
end sub

sub HandleMainSelection(idx as integer)
    numPresets = m.presets.count()

    if idx < numPresets
        p = m.presets[idx]
        PlayStream(p.url, p.format)
    else if idx = numPresets
        ShowManageDialog()
    else if idx = numPresets + 1
        ShowCustomUrlKeyboard()
    else
        ExitClean()
    end if
end sub

sub HandleManageSelection(idx as integer)
    numPresets = m.presets.count()

    if idx < numPresets
        ShowPresetActionDialog(idx)
    else if idx = numPresets
        StartAddPreset()
    else if idx = numPresets + 1
        ShowResetConfirmDialog()
    else
        ShowMainDialog()
    end if
end sub

sub ShowResetConfirmDialog()
    ShowModal("Reset to Defaults", "This replaces all saved presets with the defaults.", ["Reset", "Cancel"], "resetConfirm")
end sub

sub HandleResetConfirm(idx as integer)
    if idx = 0
        m.presets = GetDefaultPresets()
        SavePresets()
    end if
    ShowManageDialog()
end sub

sub HandlePresetAction(idx as integer)
    p = m.presets[m.actionIndex]

    if idx = 0
        PlayStream(p.url, p.format)
    else if idx = 1
        StartEditPreset(m.actionIndex)
    else if idx = 2
        m.presets.Delete(m.actionIndex)
        SavePresets()
        ShowManageDialog()
    else
        ShowManageDialog()
    end if
end sub

sub HandleFormatSelection(idx as integer)
    formats = ["mp4", "hls", "dash", "ts"]

    if idx < formats.count()
        m.pendingPreset.format = formats[idx]
        SavePendingPreset()
        ShowManageDialog()
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
end sub

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
        ShowStatus("Stream not available - retrying in 5s (press Back for menu)")
        m.retryTimer.control = "start"
    end if
end sub

sub onRetryTimer()
    if m.currentUrl <> invalid
        PlayStream(m.currentUrl, m.currentFormat)
    end if
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false

    ' Custom modal
    if m.modal.visible
        if key = "OK"
            HandleModalSelection()
            return true
        else if key = "back"
            m.modal.selectedIndex = m.modal.buttons.count() - 1
            HandleModalSelection()
            return true
        end if
        return false
    end if

    ' Video navigation
    if m.video.visible
        if key = "back" or key = "options"
            m.retryTimer.control = "stop"
            m.video.control = "stop"
            m.video.visible = false
            HideStatus()
            ShowMainDialog()
            return true
        end if
    end if

    return false
end function

sub onKeyboardButton(event as object)
    idx = event.getData()
    dlg = event.getRoSGNode()
    if dlg = invalid then return

    btns = dlg.buttons
    if btns = invalid then return
    if idx < 0 or idx >= btns.count() then return

    btn = btns[idx]

    if btn = "Cancel"
        m.top.dialog = invalid

        if m.currentScreen = "nameKeyboard" or m.currentScreen = "urlKeyboard"
            ShowManageDialog()
        else if m.currentScreen = "customUrlKeyboard"
            ShowMainDialog()
        end if

    else if btn = "Next"
        if m.currentScreen = "nameKeyboard"
            m.pendingPreset.name = dlg.keyboard.text
            m.top.dialog = invalid
            ShowUrlKeyboard()
        else if m.currentScreen = "urlKeyboard"
            m.pendingPreset.url = dlg.keyboard.text
            m.top.dialog = invalid
            ShowFormatDialog()
        end if

    else if btn = "Play"
        url = dlg.keyboard.text
        m.reg.Write("lastCustomUrl", url)
        m.reg.Flush()
        m.top.dialog = invalid
        PlayStream(url, "hls")
    end if
end sub

sub ExitClean()
    m.modal.visible = false
    m.video.visible = false
    m.status.visible = false

    m.top.backgroundColor = "0x000000FF"

    children = m.top.getChildren(-1, 0)
    for each c in children
        c.visible = false
    end for

    m.top.exitApp = true
end sub
