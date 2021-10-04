/*------------------------------------------------------------------------------
TextBoxCtrl.swift

Protocol
 func writeText()
 
Property
 windowNibName: NSNib.Name?  (override)
 delagate: TextBoxCtrlDelegate?
 
Initializer
 init()
 required init?(coder:)
 
Instance Method
 override func windowDidLoad()
 func closeTextBox(_:)
 func erase(_:)
 func selectFontSize(_:)
 func selectTextColor(_:)
 func setFontSize()
 func setTextColor()
 func windowDidBecomeMain(_:) <NSWindowDelegate>
 func control(_:textView:doCommandBy:) <NSControlTextEditingDelegate>
------------------------------------------------------------------------------*/
import Cocoa

//プロトコル宣言
protocol TextBoxCtrlDelegate: class {
    func writeText()
}
class TextBoxCtrl: NSWindowController, NSTextFieldDelegate {
    @IBOutlet weak var textField : NSTextField!
    @IBOutlet weak var cmbFontSize: NSComboBox!
    @IBOutlet weak var cmbTextColor: NSComboBox!
    @IBOutlet weak var btnUpdate: NSButton!

    //windowNibNameプロパティ
    override var windowNibName: NSNib.Name?  {
        return NSNib.Name(rawValue: "TextBox")
    }
    weak var delagate: TextBoxCtrlDelegate? = nil
    //--------------------------------------------------------------------------
    //イニシャライザ
    //--------------------------------------------------------------------------
    init(){
        super.init(window: nil)
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented");
    }
    //--------------------------------------------------------------------------
    //ウィンドウロード時
    //--------------------------------------------------------------------------
    override func windowDidLoad() {
        super.windowDidLoad()
        window?.contentView?.wantsLayer = true
        window?.contentView?.layer?.backgroundColor = NSColor.lightGray.cgColor
        window?.level = .floating
        //コンボボックスの初期値
        cmbFontSize.selectItem(at: 0)
        cmbTextColor.selectItem(at: 0)
        let plistURL = URL(fileURLWithPath: NSHomeDirectory() + "/Documents/GraphicTool2.plist")
        if let dict = NSDictionary.init(contentsOf: plistURL){
            if let value = dict["indexFontSize"] as? Int{
                cmbFontSize.selectItem(at: value)
            }
            if let value = dict["indexTextColor"] as? Int{
                cmbTextColor.selectItem(at: value)
            }
        }
        //カーソルの位置
        window?.makeFirstResponder(textField)
    }
    //--------------------------------------------------------------------------
    //閉じるボタン
    //--------------------------------------------------------------------------
    @IBAction func closeTextBox(_ sender: NSButton){
        self.delagate?.writeText()
        self.close()                    //ウィンドウを閉じる
    }
    //--------------------------------------------------------------------------
    //消去ボタン
    //--------------------------------------------------------------------------
    @IBAction func erase(_ sender: NSButton){
        textField.stringValue = ""
    }
    //--------------------------------------------------------------------------
    //メニュー：フォントサイズの設定
    //--------------------------------------------------------------------------
    @IBAction func selectFontSize(_ sender: NSComboBox){
        setFontSize()
    }
    //--------------------------------------------------------------------------
    //メニュー：テキスト色の設定
    //--------------------------------------------------------------------------
    @IBAction func selectTextColor(_ sender: NSComboBox){
        setTextColor()
    }
    //--------------------------------------------------------------------------
    //フォントサイズの設定
    //--------------------------------------------------------------------------
    func setFontSize(){
        let fontSize =  fontSizeList[cmbFontSize.indexOfSelectedItem]
        textField.font = NSFont.systemFont(ofSize: fontSize)
        window?.makeFirstResponder(textField)
    }
    //--------------------------------------------------------------------------
    //テキスト色の設定
    //--------------------------------------------------------------------------
    func setTextColor(){
        let color = textColorList[cmbTextColor.indexOfSelectedItem]
        textField.textColor = color
        window?.makeFirstResponder(textField)
    }
    //--------------------------------------------------------------------------
    // NSWindowDelegate: ウィンドウがメインウィンドウになったとき
    //--------------------------------------------------------------------------
    func windowDidBecomeMain(_ notification: Notification){
        window?.makeFirstResponder(textField)
    }
    //--------------------------------------------------------------------------
    //NSControlTextEditingDelegate：returnキーで改行する
    //--------------------------------------------------------------------------
    func control(_ control: NSControl,
                 textView: NSTextView,
                 doCommandBy commandSelector: Selector) -> Bool{
        if commandSelector == #selector(NSResponder.insertNewline(_:)) {
            textView.insertNewlineIgnoringFieldEditor(self)
            return true
        }
        return false
    }
}
