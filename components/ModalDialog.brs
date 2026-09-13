sub init()
    m.panel = m.top.findNode("panel")
    m.titleLabel = m.top.findNode("titleLabel")
    m.messageLabel = m.top.findNode("messageLabel")
    m.buttonGroup = m.top.findNode("buttonGroup")

    m.top.observeField("title", "update")
    m.top.observeField("message", "update")
    m.top.observeField("buttons", "update")
    m.top.observeField("selectedIndex", "update")
    m.top.observeField("visible", "update")
end sub

sub clearButtons()
    children = m.buttonGroup.getChildren(-1, 0)
    for each c in children
        m.buttonGroup.removeChild(c)
    end for
end sub

sub update()
    m.titleLabel.text = m.top.title
    m.messageLabel.text = m.top.message

    clearButtons()

    btns = m.top.buttons
    btnCount = 0
    if btns <> invalid then btnCount = btns.count()

    ' --- Padding variables ---
    paddingPanel = 40
    paddingTitle = 0
    paddingMessage = 24
    paddingButton = 16

    ' --- Text heights ---
    titleTextHeight = 40
    messageLineHeight = 30
    buttonTextHeight = 30

    ' --- Compute message text height ---
    msgLines = 1
    if m.top.message <> invalid then
        msgLines = m.top.message.split(chr(10)).count()
    end if
    messageTextHeight = msgLines * messageLineHeight

    ' --- Element heights ---
    titleHeight = paddingTitle * 2 + titleTextHeight
    messageHeight = paddingMessage * 2 + messageTextHeight
    buttonHeight = paddingButton * 2 + buttonTextHeight

    ' --- Button stack height ---
    buttonSpacing = 16
    totalButtonHeight = 0
    if btnCount > 0
        totalButtonHeight = btnCount * buttonHeight + (btnCount - 1) * buttonSpacing
    end if

    ' --- Panel size ---
    contentWidth = 820
    panelWidth = paddingPanel * 2 + contentWidth
    panelHeight = paddingPanel * 2 + titleHeight + messageHeight + totalButtonHeight

    panelX = (1920 - panelWidth) / 2
    panelY = (1080 - panelHeight) / 2

    ' --- VS Code Dark 2026 colors ---
    panelColor = "0x1E1E1EFF"
    titleColor = "0xD4D4D4FF"
    messageColor = "0xB0B0B0FF"
    buttonColor = "0x2D2D2DFF"
    buttonHighlightColor = "0x313233FF"
    buttonTextColor = "0xCCCCCCFF"
    highlightBorderColor = "0x387995FF"

    ' PANEL
    m.panel.width = panelWidth
    m.panel.height = panelHeight
    m.panel.translation = [panelX, panelY]
    m.panel.color = panelColor

    ' TITLE
    titleY = panelY + paddingPanel
    m.titleLabel.width = contentWidth
    m.titleLabel.height = titleHeight
    m.titleLabel.translation = [panelX + paddingPanel, titleY]
    m.titleLabel.color = titleColor

    ' MESSAGE
    messageY = titleY + titleHeight
    m.messageLabel.width = contentWidth
    m.messageLabel.height = messageHeight
    m.messageLabel.translation = [panelX + paddingPanel, messageY]
    m.messageLabel.color = messageColor

    ' BUTTONS
    y = messageY + messageHeight
    for i = 0 to btnCount - 1
        ' Background
        bg = CreateObject("roSGNode", "Rectangle")
        bg.width = contentWidth
        bg.height = buttonHeight
        bg.translation = [panelX + paddingPanel, y]

        if i = m.top.selectedIndex then
            bg.color = buttonHighlightColor
        else
            bg.color = buttonColor
        end if

        m.buttonGroup.appendChild(bg)

        ' FULL BORDER (4 sides)
        if i = m.top.selectedIndex then
            borderThickness = 2

            ' Top
            topBorder = CreateObject("roSGNode", "Rectangle")
            topBorder.width = contentWidth
            topBorder.height = borderThickness
            topBorder.translation = [panelX + paddingPanel, y]
            topBorder.color = highlightBorderColor
            m.buttonGroup.appendChild(topBorder)

            ' Bottom
            bottomBorder = CreateObject("roSGNode", "Rectangle")
            bottomBorder.width = contentWidth
            bottomBorder.height = borderThickness
            bottomBorder.translation = [panelX + paddingPanel, y + buttonHeight - borderThickness]
            bottomBorder.color = highlightBorderColor
            m.buttonGroup.appendChild(bottomBorder)

            ' Left
            leftBorder = CreateObject("roSGNode", "Rectangle")
            leftBorder.width = borderThickness
            leftBorder.height = buttonHeight
            leftBorder.translation = [panelX + paddingPanel, y]
            leftBorder.color = highlightBorderColor
            m.buttonGroup.appendChild(leftBorder)

            ' Right
            rightBorder = CreateObject("roSGNode", "Rectangle")
            rightBorder.width = borderThickness
            rightBorder.height = buttonHeight
            rightBorder.translation = [panelX + paddingPanel + contentWidth - borderThickness, y]
            rightBorder.color = highlightBorderColor
            m.buttonGroup.appendChild(rightBorder)
        end if

        ' Label
        btn = CreateObject("roSGNode", "Label")
        btn.text = btns[i]
        btn.width = contentWidth
        btn.height = buttonHeight
        btn.translation = [panelX + paddingPanel, y]
        btn.horizAlign = "center"
        btn.vertAlign = "center"
        btn.font = "font:MediumSystemFont"
        btn.color = buttonTextColor
        m.buttonGroup.appendChild(btn)

        y += buttonHeight + buttonSpacing
    end for
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false

    btnCount = m.top.buttons.count()
    if btnCount = 0 then return false

    idx = m.top.selectedIndex

    if key = "up"
        if idx > 0 then idx -= 1
        m.top.selectedIndex = idx
        return true

    else if key = "down"
        if idx < btnCount - 1 then idx += 1
        m.top.selectedIndex = idx
        return true

    else if key = "OK" or key = "back"
        return false
    end if

    return false
end function
