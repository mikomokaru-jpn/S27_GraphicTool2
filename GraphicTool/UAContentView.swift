/*------------------------------------------------------------------------------
UAContentView.swift
マウスのドラッグでウィンドウを移動する
 
Property
 startPoint: NSPoint
 endPoint: NSPoint

Instance Mehod
 override func mouseDown(with:)
 override func mouseDragged(with:)
 override func mouseUp(with:)
------------------------------------------------------------------------------*/
import Cocoa
class UAContentView: NSView {
    
    var startPoint = NSMakePoint(0, 0)
    var endPoint = NSMakePoint(0, 0)
    //--------------------------------------------------------------------------
    //マウスダウン
    //--------------------------------------------------------------------------
    override func mouseDown(with event: NSEvent) {
        startPoint =  event.locationInWindow
    }
    //--------------------------------------------------------------------------
    //マウスドラッグ
    //--------------------------------------------------------------------------
    override func mouseDragged(with event: NSEvent) {
        if startPoint == NSZeroPoint{
            //ボタンの周縁部をクリックするとmouseUpだけ起動する場合があるので対応
            return
        }
        endPoint =  event.locationInWindow
        let xSpan = endPoint.x - startPoint.x
        let ySpan = endPoint.y - startPoint.y
        var newOrigin =  self.window!.frame.origin
        newOrigin.x += xSpan
        newOrigin.y += ySpan
        self.window!.setFrameOrigin(newOrigin)
    }
    //--------------------------------------------------------------------------
    //マウスアップ
    //--------------------------------------------------------------------------
    override func mouseUp(with event: NSEvent) {
        if startPoint == NSZeroPoint{
            //ボタンの周縁部をクリックするとmouseUpだけ起動する場合があるので対応
            return
        }
        endPoint =  event.locationInWindow
        let xSpan = endPoint.x - startPoint.x
        let ySpan = endPoint.y - startPoint.y
        var newOrigin =  self.window!.frame.origin
        newOrigin.x += xSpan
        newOrigin.y += ySpan
        startPoint = NSMakePoint(0, 0)
        self.window!.setFrameOrigin(newOrigin)
    }
}
