sub Main()
    screen = CreateObject("roSGScreen")
    m.port = CreateObject("roMessagePort")
    screen.setMessagePort(m.port)
    scene = screen.CreateScene("MainScene")
    screen.show()

    while true
        ' Short timeout (not the usual 0/infinite) so this loop also
        ' wakes up on its own to check the exitApp field directly,
        ' rather than relying solely on a field-change notification
        ' being delivered across threads.
        msg = wait(30, m.port)
        msgType = type(msg)
        if msgType = "roSGScreenEvent"
            if msg.isScreenClosed() then return
        end if

        if scene.exitApp = true
            return
        end if
    end while
end sub
