/*------------------------------------------------------------------------------
UATextView.swift

Property
 margin: CGFloat
 text: String
 fontSize: CGFloat
 textColorIndex: Int
 textColor: NSColor
 lineWidth: CGFloat
 atrText: NSMutableAttributedString? (private)
 
Initializer
 override init(frame:)
 required init?(coder:)
 
InstanceMethod
 override func draw(_:)
 private func resetAttributes()
------------------------------------------------------------------------------*/
import Cocoa
class UATextView: NSView {
    //水平方向の余白
    var margin: CGFloat = 0
    //表示テキスト
    var text: String = ""{
        didSet{
            let font = NSFont.systemFont(ofSize: fontSize)
            self.atrText = NSMutableAttributedString.init(string: self.text,
                           attributes: [.font: font, .foregroundColor: textColor])
        }
    }
    //フォントサイズ
    var fontSize: CGFloat = 10{
        didSet{
            self.resetAttributes()
        }
    }
    //文字色
    var textColorIndex: Int = 0{
        didSet{
            self.resetAttributes()
        }
    }
    var textColor: NSColor = NSColor.black
    //枠線
    var lineWidth: CGFloat = 0
    //属性付き文字列
    private var atrText: NSMutableAttributedString?
    
    //--------------------------------------------------------------------------
    // イニシャライザ
    //--------------------------------------------------------------------------
    override init(frame frameRect: NSRect) {
        //スーパクラスのイニシャライズ
        super.init(frame: frameRect)
    }
    //イニシャライザ２
    required init?(coder aDecoder: NSCoder) {
        //起動することはない
        fatalError("init(coder:) has not been implemented");
    }
    
    //--------------------------------------------------------------------------
    //ビューの再表示
    //--------------------------------------------------------------------------
    override func draw(_ dirtyRect: NSRect) {
        if let atrText = self.atrText{
            var newRect = dirtyRect
            newRect.origin.x += margin
            newRect.size.width -= margin*2
            atrText.draw(in: newRect)
            let path = NSBezierPath.init(rect: dirtyRect)
            if self.lineWidth > 0{
                path.lineWidth = self.lineWidth
                NSColor.black.setStroke()
                path.stroke()
            }
        }
    }
    //--------------------------------------------------------------------------
    //属性のリセット
    //--------------------------------------------------------------------------
    private func resetAttributes(){
        let font = NSFont.systemFont(ofSize: fontSize)
        textColor = textColorList[textColorIndex]
        if let atrText = self.atrText{
            atrText.addAttributes([.font: font, .foregroundColor: textColor],
                                  range: NSMakeRange(0, atrText.length))
        }
    }
}
