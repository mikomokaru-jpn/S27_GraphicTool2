/*------------------------------------------------------------------------------
CGRect+Util.swift
 
 
Property
 SelectedLine
 SelectedCorner
 
Instance Method
 func isInside(_:tolerance:)
 func onTheLine(_:tolerance:)
 func onTheCorner(_:tolerance:)
 ------------------------------------------------------------------------------*/
import Foundation
extension CGRect {
    //選択された線
    enum SelectedLine {
        case None
        case Left
        case Top
        case Right
        case Bottom
    }
    //選択された角
    enum SelectedCorner {
        case None
        case LeftBottom
        case LeftTop
        case RightTop
        case RightBottom
    }
    //--------------------------------------------------------------------------
    //点が矩形領域内にあるか？
    //--------------------------------------------------------------------------
    func isInside(_ point: CGPoint, tolerance:CGFloat = 5) -> Bool {
        //x方向の定規
        var xFrom = self.origin.x
        var xTo = self.origin.x + self.width
        if self.width < 0{
            xTo = xFrom
            xFrom = self.origin.x + self.width
        }
        //y方向の定規
        var yFrom = self.origin.y
        var yTo = self.origin.y + self.height
        if self.height < 0{
            yTo = yFrom
            yFrom = self.origin.y + self.height
        }
        if (xFrom - tolerance <= point.x && point.x <= xTo + tolerance) &&
            (yFrom - tolerance <= point.y && point.y <= yTo + tolerance){
            return true
        }
        return false
    }
    //--------------------------------------------------------------------------
    //点が枠線上にあるか？
    //--------------------------------------------------------------------------
    func onTheLine(_ point: CGPoint, tolerance:CGFloat = 5) -> SelectedLine{
        let topLeft = CGPoint.init(x: self.origin.x,
                                   y: self.origin.y + self.size.height)
        let topRight = CGPoint.init(x: self.origin.x + self.size.width,
                                    y: self.origin.y + self.size.height)
        let bottomRight = CGPoint.init(x: self.origin.x + self.size.width,
                                   y: self.origin.y)

        let leftLine = (self.origin, topLeft)
        let topLine = (topLeft, topRight)
        let rightLine = (topRight, bottomRight)
        let bottomLine = (bottomRight, self.origin)
        //左側の線
        if (leftLine.0.x - tolerance <= point.x && point.x <= leftLine.0.x + tolerance) &&
           (leftLine.0.y <= point.y && point.y <= leftLine.1.y) {
            print("leftLine")
            return SelectedLine.Left
        }
        //上側の線
        if (topLine.0.x <= point.x && point.x <= topLine.1.x) &&
            (topLine.0.y - tolerance <= point.y && point.y <= topLine.0.y + tolerance) {
            print("topLine")
            return SelectedLine.Top
        }
        //右側の線
        if (rightLine.0.x - tolerance <= point.x && point.x <= rightLine.0.x + tolerance) &&
            (rightLine.0.y >= point.y && point.y >= rightLine.1.y) {
            print("rightLine")
            return SelectedLine.Right
        }
        //下側の線
        if (bottomLine.0.x >= point.x && point.x >= bottomLine.1.x) &&
            (bottomLine.0.y - tolerance <= point.y && point.y <= bottomLine.0.y + tolerance) {
            print("bottomLine")
            return SelectedLine.Bottom
        }
        return SelectedLine.None
    }
    //--------------------------------------------------------------------------
    //点が四隅上にあるか？
    //--------------------------------------------------------------------------
    func onTheCorner(_ point: CGPoint, tolerance:CGFloat = 5) -> SelectedCorner{
        
        let leftTop = CGPoint.init(x: self.origin.x,
                                   y: self.origin.y + self.size.height)
        let rightTop = CGPoint.init(x: self.origin.x + self.size.width,
                                    y: self.origin.y + self.size.height)
        let  rightBottom = CGPoint.init(x: self.origin.x + self.size.width,
                                       y: self.origin.y)
        
        if (self.origin.x - tolerance <= point.x && point.x <= self.origin.x + tolerance) &&
            (self.origin.y - tolerance <= point.y && point.y <= self.origin.y + tolerance){
            return .LeftBottom
        }
        if (leftTop.x - tolerance <= point.x && point.x <= leftTop.x + tolerance) &&
            (leftTop.y - tolerance <= point.y && point.y <= leftTop.y + tolerance){
            return .LeftTop
        }
        if (rightTop.x - tolerance <= point.x && point.x <= rightTop.x + tolerance) &&
            (rightTop.y - tolerance <= point.y && point.y <= rightTop.y + tolerance){
            return .RightTop
        }
        if (rightBottom.x - tolerance <= point.x && point.x <= rightBottom.x + tolerance) &&
            (rightBottom.y - tolerance <= point.y && point.y <= rightBottom.y + tolerance){
            return .RightBottom
        }
        return .None
    }
}
