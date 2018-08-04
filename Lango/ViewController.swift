//
//  ViewController.swift
//  Lango
//

import Cocoa

class ViewController: NSViewController, NSTextFieldDelegate
 {

    @IBOutlet weak var input: NSTextField!
    
    @IBOutlet weak var inProgress: NSProgressIndicator!
    
    @IBOutlet weak var result: NSTextField!
    
    @IBOutlet weak var sourceLang: NSPopUpButton!
    
    var timer = Timer()
    
    let CONFIG_TRANSLATE_KEY = "Translate key"
    let URL = "https://translate.yandex.net/api/v1.5/tr.json/translate?key=%@&text=%@&lang=%@-en"
    
    let sourceLangs = ["es", "de", "fr", "jp"]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        input.delegate = self
        
        sourceLang.action = #selector(onSrcLangChanged)
        sourceLang.target = self
        sourceLang.removeAllItems()
        sourceLang.addItems(withTitles: sourceLangs)
        sourceLang.selectItem(at: 0)
    }
    
    @objc func onSrcLangChanged(sender : NSPopUpButton) {
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
        }
    }
    
    override func keyDown(with event: NSEvent) {
        print("key code" + String(event.keyCode))
    }
    
    override func controlTextDidChange(_ obj: Notification) {
        if let inputField = obj.object as? NSTextField, self.input.identifier == inputField.identifier {
            let inputText = input.stringValue
            print("text changed " + inputText)
            
            result.stringValue = ""
            timer.invalidate()
            if inputText.isEmpty {
                return
            }

            timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { timer in
                self.findAnswer(word: inputText)
            }
        }
    }
    
    func findAnswer(word: String) {
        if let cached = UserDefaults.standard.string(forKey: word) {
            print("got cached " + cached)
            result.stringValue = cached
            return
        }
        
        sendRequest(word: word)
    }
    
    func sendRequest(word: String) {
        let srcLang = sourceLang.titleOfSelectedItem!
        guard let key = Bundle.main.infoDictionary?[CONFIG_TRANSLATE_KEY] as? String else {
            print("invalid api key");
            return
        }
        
        let path = String(format: URL, key, word, srcLang)
        guard let url = Foundation.URL(string: path) else {
            print("Error: cannot create URL")
            return
        }
        
        let urlRequest = URLRequest(url: url)
        let session = URLSession.shared
        
        let task = session.dataTask(with: urlRequest, completionHandler: {data, response, error -> Void in
            
            do {
                let json = try JSONSerialization.jsonObject(with: data!, options: []) as! [String: AnyObject]
                if let names = json["text"] as? [String] {
                    var returned = ""
                    for name in names {
                        returned = name + "\n"
                    }
                    
                    print("returned " + returned)
                    UserDefaults.standard.set(returned, forKey: word)
                    DispatchQueue.main.async {
                        print("showing result for " + returned)
                        self.result.stringValue = returned
                    }
                }
            } catch let error as NSError {
                print("Failed to load: \(error.localizedDescription)")
            }
            DispatchQueue.main.async {
                self.inProgress.isHidden = true
                self.inProgress.stopAnimation(nil)
            }
        })
        task.resume()
        inProgress.isHidden = false
        inProgress.startAnimation(nil)
    }
    
    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
}

