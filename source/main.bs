sub Main()
    screen = CreateObject("roSGScreen")
    m.port = CreateObject("roMessagePort")
    screen.setMessagePort(m.port)
    scene = screen.CreateScene("MainScene")
    screen.show()

    while true
        msg = wait(30, m.port)
        msgType = type(msg)
        if msgType = "roSGScreenEvent"
            if msg.isScreenClosed() then return
        end if

        if scene.exitApp = true
            ' Fade to black before exiting
            scene.backgroundColor = "0x000000FF"

            ' Optionally hide all children so last frame is pure black
            children = scene.getChildren(-1, 0)
            for each c in children
                c.visible = false
            end for

            return
        end if
    end while
end sub
