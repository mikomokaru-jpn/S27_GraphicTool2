/*------------------------------------------------------------------------------
UAView.swift
 
Property
 fontSizeList: [CGFloat] (Global)
 textColorList: [NSClor] (Global)
 status: Int
 cgImage: CGImage?
 cgImageRect: CGRect
 tetxtBoxCtrl: TextBoxCtrl
 textViewList: [UATextView]
 selectedTextView :UATextView?
 preRect: CGRect
 rectShape: CAShapeLayer
 startPoint: CGPoint
 selectedLine: CGRect.SelectedLine
 selectedCorner: CGRect.SelectedCorner
 
Instance Method
 override func acceptsFirstMouse(for:)
 override func draw(_:)
 override func awakeFromNib()
 override func mouseDown(with:)
 override func mouseDragged(with:)
 override func mouseUp(with:)
 func displayImage(image:)
 func createImage()
 func writeText() <TextBoxCtrlDelegate>
 private func showTextBox(_)
 private func insideView(_)
 ------------------------------------------------------------------------------*/
import Cocoa
import QuartzCore
//フォントサイズ
let fontSizeList:[CGFloat] = [10, 12, 14, 16, 18, 20, 22, 24, 36, 48, 64, 72, 96]
//テキスト色
let textColorList = [NSColor.black,
                     NSColor.red,
                     NSColor.blue,
                     NSColor.green,
                     NSColor.orange,
                     NSColor.white]

class UAView: NSView, TextBoxCtrlDelegate {
    /*ステータス：ビュー上のマウス操作と対応する
        0: 未選択
        1: 新規入力待ち
        2: 既存選択中
        3: 縦または横方向に拡大・縮小中
        4: 対角方向に拡大・縮小中
    */
    @objc var status: Int = 0 {
        willSet {
            self.willChangeValue(forKey: "status")
        }
        didSet{
            self.didChangeValue(forKey: "status")
        }
    }
    var cgImage: CGImage? = nil             //イメージ
    var cgImageRect = CGRect.init()         //イメージのサイズと表示位置
    var tetxtBoxCtrl = TextBoxCtrl.init()   //テキスト入力サブウィンドウ
    var textViewList = [UATextView]()       //テキスト（配列）
    //選択中のテキストボックス
    var selectedTextView :UATextView? = nil {
        didSet{
            if let frame = selectedTextView?.frame{
                preRect = frame
            }
        }
    }
    var preRect: CGRect = CGRect.init()                 //拡大・縮小の開始時点の矩形
    var rectShape: CAShapeLayer = CAShapeLayer.init()   //テキスト入力領域の矩形
    var startPoint: CGPoint = CGPoint.init(x: 0, y: 0)  //テキスト入力領域の開始点
    var selectedLine: CGRect.SelectedLine = .None       //選択中の矩形の線
    var selectedCorner: CGRect.SelectedCorner = .None   //選択中の矩形の角

    //--------------------------------------------------------------------------
    // クリックに即反応する
    //--------------------------------------------------------------------------
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool{
        return true
    }
    //--------------------------------------------------------------------------
    // ビューの再描画
    //--------------------------------------------------------------------------
    override func draw(_ dirtyRect: NSRect) {
        if let context = NSGraphicsContext.current?.cgContext{
            if let image = self.cgImage{
                //イメージファイルの画像を表示
                context.draw(image, in: self.cgImageRect)
            }
        }
    }
    //--------------------------------------------------------------------------
    // オブジェクトロード時
    //--------------------------------------------------------------------------
    override func awakeFromNib() {
        self.wantsLayer = true
        self.layer?.borderWidth = 1
        //トラッキングエリアの設定：補足したいイベントを指定する
        let options:NSTrackingArea.Options = [
            .mouseMoved,
            .mouseEnteredAndExited,
            .activeAlways
        ]
        let trackingArea = NSTrackingArea.init(rect: self.bounds,
                                               options: options,
                                               owner: self,
                                               userInfo: nil)
        self.addTrackingArea(trackingArea)
        tetxtBoxCtrl.delagate = self
    }
    //--------------------------------------------------------------------------
    // マウスダウン
    //--------------------------------------------------------------------------
    override func mouseDown(with event: NSEvent) {
        startPoint = self.convert(event.locationInWindow, from: nil)
        switch status {
        case 0: //未選択
            for textView in textViewList{
                if textView.frame.isInside(startPoint){
                    //クリックした位置に入力テキストがある
                    textView.lineWidth = 2
                    textView.needsDisplay = true
                    selectedTextView = textView
                    status = 2 //既存選択中
                }
            }
        case 1: //新規入力待ち
            if (rectShape.path?.boundingBox.isInside(startPoint))!{
                self.showTextBox(startPoint)
            }else{
                //入力領域のクリア（範囲外のとき）
                rectShape.removeFromSuperlayer()
                //選択中のテキストがあれば未選択にする（範囲外のとき）
                if selectedTextView != nil{
                    selectedTextView!.lineWidth = 0
                    selectedTextView!.needsDisplay = true
                    selectedTextView = nil
                }
                tetxtBoxCtrl.window?.close()
                status = 0 //未選択
            }
        case 2: //既存選択中
            for textView in textViewList{
                if textView.frame.isInside(startPoint){
                    //クリックした位置に入力テキストがある
                    if event.clickCount == 2{
                        self.showTextBox(startPoint)
                        return
                    }
                }
            }
            selectedTextView?.lineWidth = 0
            selectedTextView?.needsDisplay = true
            selectedTextView = nil
            tetxtBoxCtrl.window?.close()
            status = 0 //未選択
            //移動・拡大・縮小
            for textView in textViewList{
                selectedCorner = textView.frame.onTheCorner(startPoint)
                if selectedCorner != .None{
                    textView.lineWidth = 2
                    textView.needsDisplay = true
                    selectedTextView = textView
                    status = 4 //縦and横変形開始
                    break
                }
                selectedLine = textView.frame.onTheLine(startPoint)
                if selectedLine != .None{
                    textView.lineWidth = 2
                    textView.needsDisplay = true
                    selectedTextView = textView
                    status = 3 //縦or横変形開始
                    break
                    
                }
                if textView.frame.isInside(startPoint){
                    textView.lineWidth = 2
                    textView.needsDisplay = true
                    selectedTextView = textView
                    status = 2 //既存選択中（移動）
                    break
                }
            }
        default:
            break
        }
    }
    //--------------------------------------------------------------------------
    // マウスドラッグ
    //--------------------------------------------------------------------------
    override func mouseDragged(with event: NSEvent) {
        let minimum: CGFloat = 10
        switch status {
        case 0: //未選択
            status = 1  //新規入力待ちへ
        case 1: //新規入力待ち
            let endPoint = self.convert(event.locationInWindow, from: nil)
            let width  = fabs(startPoint.x - endPoint.x)
            let height  = fabs(startPoint.y - endPoint.y)
            //矩形の原点を左下に合わせる
            var xPos: CGFloat = 0.0;
            var yPos: CGFloat = 0.0;
            var flg: Bool = false;
            if startPoint.x < endPoint.x && startPoint.y < endPoint.y{
                xPos = startPoint.x
                yPos = startPoint.y
                flg = true
            }
            if startPoint.x > endPoint.x && startPoint.y < endPoint.y{
                xPos = endPoint.x
                yPos = startPoint.y
                flg = true
            }
            if startPoint.x > endPoint.x && startPoint.y > endPoint.y{
                xPos = endPoint.x
                yPos = endPoint.y
                flg = true
            }
            if startPoint.x < endPoint.x && startPoint.y > endPoint.y{
                xPos = startPoint.x
                yPos = endPoint.y
                flg = true
            }
            if !flg{
                return
            }
            //新規入力領域の描画
            let rect = NSRect.init(origin: CGPoint.init(x: xPos, y: yPos),
                                   size: CGSize.init(width: width, height: height))
            rectShape.path = NSBezierPath.init(rect: rect).cgPath
            rectShape.fillColor = NSColor.clear.cgColor
            rectShape.strokeColor = NSColor.orange.cgColor
            rectShape.lineWidth = 1
            self.layer?.addSublayer(rectShape)
        case 2: //既存選択中
            var newPoint = preRect.origin
            let endPoint = self.convert(event.locationInWindow, from: nil)
            let diff = CGPoint.init(x: endPoint.x - startPoint.x, y: endPoint.y - startPoint.y)
            newPoint.x += diff.x
            newPoint.y += diff.y
            var newRect = selectedTextView!.frame
            newRect.origin = newPoint
            if self.insideView(newRect){
                //移動
                selectedTextView!.frame.origin = newPoint
                selectedTextView!.needsDisplay = true
            }
        case 3: //縦または横方向に拡大・縮小中
            var newPoint = preRect.origin
            var newSize = preRect.size
            let endPoint = self.convert(event.locationInWindow, from: nil)
            switch self.selectedLine{
            case .Left:
                let diff = CGPoint.init(x: endPoint.x - startPoint.x, y: 0)
                if newSize.width - diff.x <= minimum{
                    return
                }
                newPoint.x += diff.x
                newSize.width -= diff.x
            case .Top:
                let diff = CGPoint.init(x:0 , y: endPoint.y - startPoint.y)
                if newSize.height + diff.y <= minimum{
                    return
                }
                newSize.height += diff.y
            case .Right:
                let diff = CGPoint.init(x:endPoint.x - startPoint.x , y: 0)
                if newSize.width + diff.x <= minimum{
                    return
                }
                newSize.width += diff.x
            case .Bottom:
                let diff = CGPoint.init(x:0 , y: endPoint.y - startPoint.y)
                if newSize.height - diff.y <= minimum{
                    return
                }
                newPoint.y += diff.y
                newSize.height -= diff.y
            default:
                return
            }
            //拡大・縮小
            selectedTextView?.frame.origin = newPoint
            selectedTextView?.frame.size = newSize
            selectedTextView?.needsDisplay = true
        case 4: //対角方向に拡大・縮小中
            var newPoint = preRect.origin
            var newSize = preRect.size
            let endPoint = self.convert(event.locationInWindow, from: nil)
            let diff = CGPoint.init(x: endPoint.x - startPoint.x, y: endPoint.y - startPoint.y)
            switch self.selectedCorner{
            case .LeftBottom:
                if (newSize.width - diff.x <= minimum) || (newSize.height - diff.y <= minimum){
                    return
                }
                newPoint.x += diff.x
                newPoint.y += diff.y
                newSize.width -= diff.x
                newSize.height -= diff.y
            case .LeftTop:
                if (newSize.width - diff.x <= minimum) || (newSize.height + diff.y <= minimum){
                    return
                }
                newPoint.x += diff.x
                newSize.width -= diff.x
                newSize.height += diff.y
                
            case .RightTop:
                if (newSize.width + diff.x <= minimum) || (newSize.height + diff.y <= minimum){
                    return
                }
                newSize.width += diff.x
                newSize.height += diff.y
            case .RightBottom:
                if (newSize.width + diff.x <= minimum) || (newSize.height - diff.y <= minimum){
                    return
                }
                newPoint.y += diff.y
                newSize.width += diff.x
                newSize.height -= diff.y
            default:
                return
            }
            //拡大・縮小
            selectedTextView?.frame.origin = newPoint
            selectedTextView?.frame.size = newSize
            selectedTextView?.needsDisplay = true
        default:
            break
        }
    }
    //--------------------------------------------------------------------------
    // マウスアップ
    //--------------------------------------------------------------------------
    override func mouseUp(with event: NSEvent) {
        if status == 3  || status == 4{ //拡大・縮小の終了
            status = 2 //既存選択中
        }
    }
    //インスタンスメソッド
    //--------------------------------------------------------------------------
    // イメージの表示サイズの算定
    //--------------------------------------------------------------------------
    func displayImage(image: CGImage){
        self.cgImage = image
        let maxSize = CGSize.init(width: self.frame.width, height: self.frame.height)
        var origin = CGPoint.init(x: 0, y: 0)
        
        var newSize = CGSize.init(width: 0, height: 0)
        if ( CGFloat(image.height) / CGFloat(image.width) < maxSize.height / maxSize.height) {
            //横長・上下に余白
            newSize.width = maxSize.width
            newSize.height = floor(maxSize.width * CGFloat(image.height) / CGFloat(image.width))
            origin.y = floor((maxSize.height - newSize.height) / 2) //余白
        }else{
            //縦長。左右に余白
            newSize.width = floor(maxSize.height * CGFloat(image.width) / CGFloat(image.height))
            newSize.height = maxSize.height
            origin.x = floor((maxSize.width - newSize.width) / 2) //余白
        }
        self.cgImageRect = CGRect.init(x: origin.x, y: origin.y,
                                       width: newSize.width, height: newSize.height)
        self.needsDisplay = true
    }
    //--------------------------------------------------------------------------
    // イメージファイルの作成・出力
    //--------------------------------------------------------------------------
    func createImage() -> Data?{
        //出力用コンテキストの作成
        let imageColorSpace = CGColorSpace(name: CGColorSpace.sRGB)
        guard let newContext = CGContext.init(
            data: nil,
            width: Int(self.frame.width),
            height: Int(self.frame.height),
            bitsPerComponent: 8,
            bytesPerRow: Int(self.frame.width) * 4,
            space: imageColorSpace!,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else{
                return nil
        }
        //ビューイメージをコンテキストに描き出す
        self.layer!.borderWidth = 0
        self.layer!.render(in: newContext)
        self.layer!.borderWidth = 1
        //コンテキストからCGImageオブジェクトを取得する
        guard let cgImage = newContext.makeImage() else {
            return nil
        }
        //ビットマップイメージに変換する
        let bitmap = NSBitmapImageRep.init(cgImage: cgImage)
        //png形式のDataオブジェクトに変換する
        let exporttData = bitmap.representation(using: .png,
                                                properties: [:])
        return exporttData
    }

    //--------------------------------------------------------------------------
    // TextBoxCtrlDelegate：テキスト入力
    //--------------------------------------------------------------------------
    func writeText(){
        //空白のトリミング
        var temp = tetxtBoxCtrl.textField.stringValue
        temp = temp.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        if temp.count > 0{
            //入力あり
            var textView: UATextView
            if status == 1{ //新規
                guard let rect = rectShape.path?.boundingBox else{
                    return
                }
                textView = UATextView.init(frame:rect)
                self.addSubview(textView)
                //配列に保存
                textViewList.append(textView)
                selectedTextView = textView
                rectShape.removeFromSuperlayer()
                status = 2 //既存選択中
            }else if status == 2{ //既存
                if selectedTextView !=  nil{
                    textView = selectedTextView!
                    textView.text = tetxtBoxCtrl.textField.stringValue
                }else{
                    return
                }
            }else{
                return
            }
            //更新
            textView.text = tetxtBoxCtrl.textField.stringValue //テキスト
            //フォントサイズ
            textView.fontSize = fontSizeList[tetxtBoxCtrl.cmbFontSize.indexOfSelectedItem]
            //文字色
            textView.textColorIndex = tetxtBoxCtrl.cmbTextColor.indexOfSelectedItem
            textView.lineWidth = 2
            textView.needsDisplay = true
        }else{
            //削除
            if status == 1{
                rectShape.removeFromSuperlayer()
            }else if status == 2{
                if selectedTextView !=  nil{
                    for i in 0 ..< textViewList.count{
                        if selectedTextView == textViewList[i]{
                            selectedTextView?.removeFromSuperview()
                            textViewList.remove(at: i)
                            selectedTextView = nil
                            break
                        }
                    }
                }
            }
        }
    }
    //内部メソッド
    //--------------------------------------------------------------------------
    // テキスト入力ウィンドウを開く
    //--------------------------------------------------------------------------
    private func showTextBox(_ point: CGPoint){
        var basePoint = point
        //クリックした点をスクリーン座標に変換する
        if let rect = self.window?.contentView?.superview?.frame,
            let winRect = self.window?.convertToScreen(rect){
            basePoint.x += winRect.origin.x
            basePoint.y += winRect.origin.y - (tetxtBoxCtrl.window?.contentView?.frame.size.height)!
        }
        //テキスト入力サブウィンドウを開く
        tetxtBoxCtrl.window?.setFrameOrigin(basePoint) //ウィンドウの表示位置
        tetxtBoxCtrl.showWindow(self)
        if status == 1{//新規
            tetxtBoxCtrl.setFontSize()
            tetxtBoxCtrl.setTextColor()
        
            tetxtBoxCtrl.textField.stringValue = ""
        }else if status == 2{ //既存選択中
            if let textView = selectedTextView{
                //既存テキストの取得
                tetxtBoxCtrl.textField.stringValue = textView.text
                //既存フォントサイズ
                for i in 0 ..< fontSizeList.count{
                    if textView.fontSize == fontSizeList[i]{
                        tetxtBoxCtrl.cmbFontSize.selectItem(at: i)
                        tetxtBoxCtrl.setFontSize()
                        break
                    }
                }
                //既存の色
                tetxtBoxCtrl.cmbTextColor.selectItem(at: textView.textColorIndex)
                tetxtBoxCtrl.setTextColor()
            }
        }
    }
    //--------------------------------------------------------------------------
    // 矩形がビューの中にあるか？
    //--------------------------------------------------------------------------
    private func insideView(_ rect: CGRect ) ->Bool{
        if rect.origin.x + rect.size.width / 2 < 0 {
            return false
        }else if rect.origin.y + rect.size.height / 2 < 0{
            return false
        }else if rect.origin.y + rect.size.height / 2 > self.frame.size.height{
            return false
        }else if rect.origin.x + rect.size.width / 2 > self.frame.size.width{
            return false
        }
        return true
    }
}
