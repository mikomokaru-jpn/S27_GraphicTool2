/*------------------------------------------------------------------------------
AppDelegate.swift

Property
 window: NSWindow! (outlet)
 view: UAView! (outlet)
 imageData: Data?
 
Instance Method
 func applicationDidFinishLaunching(_:)
 func selectFile(_:)
 func create(_:)
 func erase(_:)
 func windowWillClose(_:) <NSWindowDelegate>
------------------------------------------------------------------------------*/
import Cocoa
@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {

    @IBOutlet weak var window: NSWindow!
    @IBOutlet weak var view: UAView!
    
    var imageData: Data? //ユーザデフォルトに保存するイメージデータ
    
    //--------------------------------------------------------------------------
    // アプリケーション起動時
    //--------------------------------------------------------------------------
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        if let saveData:Any? = UserDefaults.standard.data(forKey: "SAVE_IMAGE"){
            if let data = saveData as? Data{
                if let cgImageSource = CGImageSourceCreateWithData(data as CFData, nil ){
                    if let cgImage = CGImageSourceCreateImageAtIndex(cgImageSource, 0, nil){
                        self.imageData = data //イメージデータの確保
                        self.view.displayImage(image: cgImage)
                        self.view.needsDisplay = true
                    }
                }
            }
        }
        let plistURL = URL(fileURLWithPath: NSHomeDirectory() + "/Documents/GraphicTool1.plist")
        if let array = NSArray.init(contentsOf: plistURL){
            for item in array{
                if let record = item as? NSDictionary{
                    if  let text = record["text"] as? String,
                        let x = record["x"] as? CGFloat,
                        let y = record["y"] as? CGFloat,
                        let width = record["width"] as? CGFloat,
                        let height = record["height"] as? CGFloat,
                        let fontSize = record["fontSize"] as? CGFloat,
                        let textColorIndex = record["textColorIndex"] as? Int
                    {
                        let textView = UATextView.init(frame: NSMakeRect(x, y, width, height))
                        textView.text = text
                        textView.fontSize = fontSize
                        textView.textColorIndex = textColorIndex
                        view.textViewList.append(textView)
                        view.addSubview(textView)
                    }else{
                        print("GraphicTool1.plist read error")
                    }
                }
            }
        }
    }
    //--------------------------------------------------------------------------
    // 開く：ファイルからイメージを読み込む
    //--------------------------------------------------------------------------
    @IBAction func selectFile(_ sender: NSButton){
        let openPanel = NSOpenPanel.init()
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = false
        openPanel.message = "イメージファイルを選択する"
        let url = NSURL.fileURL(withPath: NSHomeDirectory() + "/Pictures")
        //最初に位置付けるディレクトリパス
        openPanel.directoryURL = url
        //オープンパネルを開く
        openPanel.beginSheetModal(for: self.window, completionHandler: { (result) in
            if result == .OK{
                //ディレクトリの選択
                let url: URL = openPanel.urls[0]
                /*
                if let cgImageSource = CGImageSourceCreateWithURL(url as CFURL, nil){
                    if let cgImage = CGImageSourceCreateImageAtIndex(cgImageSource, 0, nil){
                        self.view.displayImage(image: cgImage)
                    }
                }
                */
                do{
                    self.imageData = try Data.init(contentsOf: url) //イメージデータの確保
                    if let cgImageSource = CGImageSourceCreateWithData(self.imageData! as CFData, nil ){
                        if let cgImage = CGImageSourceCreateImageAtIndex(cgImageSource, 0, nil){
                            self.view.displayImage(image: cgImage)
                           _ = self.view.textViewList.map{$0.removeFromSuperview()}
                           self.view.textViewList = [UATextView]()
                        }
                    }
                }catch{
                    return
                }
            }
        })
    }
    //--------------------------------------------------------------------------
    // 出力：イメージを出力する
    //--------------------------------------------------------------------------
    @IBAction func create(_ sender: NSButton){
        guard let data = self.view.createImage() else{
            return
        }
        let savaPanel = NSSavePanel.init()
        savaPanel.title = "ファイルを保存する"
        savaPanel.nameFieldStringValue = "savefile.png"
        savaPanel.beginSheetModal(for: self.window, completionHandler: {(result) in
            if result == .OK{
                if let url = savaPanel.url{
                    do {
                        try data.write(to:url)
                    }catch{
                        print(error.localizedDescription)
                    }
                }
            }
        
        })
    }
    //--------------------------------------------------------------------------
    // 全消去：イメージと入力テキストを消去する
    //--------------------------------------------------------------------------
    @IBAction func erase(_ sender: NSButton){
        if view.cgImage != nil{
            let alert = NSAlert()
            alert.messageText = "全消去"
            alert.informativeText = "イメージと入力テキストを消去します。よろしいですか？"
            alert.addButton(withTitle: "OK")
            alert.addButton(withTitle: "キャンセル")
            alert.alertStyle = .critical
            if alert.runModal() == NSApplication.ModalResponse.alertFirstButtonReturn{
                _ = self.view.textViewList.map{$0.removeFromSuperview()}
                self.view.textViewList = [UATextView]()
                view.cgImage = nil
                view.needsDisplay = true
                self.imageData = nil
            }
        }
    }
    //--------------------------------------------------------------------------
    //NSWindowDelegate・ウィンドウクローズ時
    //--------------------------------------------------------------------------
    func windowWillClose(_ notification: Notification) {
        //plist出力：コンボボックスの値
        var plistURL = URL(fileURLWithPath: NSHomeDirectory() + "/Documents/GraphicTool2.plist")
        if let cmbFontSize = view.tetxtBoxCtrl.cmbFontSize,
           let cmbTextColor = view.tetxtBoxCtrl.cmbTextColor{
            let cmbInfo: NSDictionary = ["indexFontSize": cmbFontSize.indexOfSelectedItem,
                                         "indexTextColor": cmbTextColor.indexOfSelectedItem]
            cmbInfo.write(to: plistURL,  atomically: true)
        }
        //ユーザデフォルトの出力：イメージとテキスト
        UserDefaults.standard.set(self.imageData, forKey: "SAVE_IMAGE")//イメージデータの保存
        plistURL = URL(fileURLWithPath: NSHomeDirectory() + "/Documents/GraphicTool1.plist")
        let array = NSMutableArray.init()
        for view in view.textViewList{
            let record = NSMutableDictionary.init()
            record["margin"] = view.margin
            record["text"] = view.text
            record["fontSize"] = view.fontSize
            record["lineWidth"] = view.lineWidth
            record["textColorIndex"] = view.textColorIndex
            record["x"] = view.frame.origin.x
            record["y"] = view.frame.origin.y
            record["width"] = view.frame.size.width
            record["height"] = view.frame.size.height
            array.add(record)
        }
        array.write(to: plistURL,  atomically: true)
    }

}

