//
//  EditorView.swift
//  gat
//
//  Created by Vũ Kiên on 05/02/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import UIKit
import WebKit

class CustomEditorView: UIView {

    var webView: WKWebView!
    
    var html: String = ""
    var isEditingEnabled: Bool = true
    
    var placeholder: String = ""
    var isScrollEnabled: Bool = false {
        didSet {
            self.webView.scrollView.isScrollEnabled = self.isScrollEnabled
        }
    }
    fileprivate var isConfigure = false {
        didSet {
            if self.isConfigure {
                self.runJS("initEditor('\(self.placeholder)');")
                if !self.html.isEmpty {
                    self.runJS("setReviewContent('\(self.html)');", errorHandle: { (error) in
//                        print("Error: \((error as? WKError)?.errorUserInfo)")
                        if let error = error as? WKError {
                            _ = error.errorUserInfo
                        }
                    })
                }
                self.setEditing(enable: self.isEditingEnabled)
                
            }
        }
    }
    
    // MARK: Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setup()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.layoutIfNeeded()
        
    }
    
    fileprivate func setup() {
        self.layoutIfNeeded()
        self.webView = WKWebView(frame: self.bounds)
        self.webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.webView.backgroundColor = .white
        
        self.webView.scrollView.bounces = false
        self.webView.scrollView.delegate = self
        self.webView.scrollView.clipsToBounds = false
        self.webView.scrollView.isScrollEnabled = isScrollEnabled

        self.webView.navigationDelegate = self
        self.webView.removeInputAccessory()

        self.addSubview(self.webView)
        if let url = Bundle.main.url(forResource: "index", withExtension: "html") {
            let request = URLRequest(url: url)
            self.webView.load(request)
        }
    }

    fileprivate func runJS(_ js: String, response: ((Any) -> Void)? = nil, errorHandle: ((Error) -> Void)? = nil) {
        self.webView.evaluateJavaScript(js) { (result, error) in
            if let error = error {
                errorHandle?(error)
            }
            if let result = result {
                response?(result)
            }
        }
    }
    
    func getContent(urls: [String], content: @escaping(String) -> Void, error: ((Error) -> Void)? = nil) {
        self.runJS("getReviewContentHTML(\(urls));", response: { (result) in
            if let value = result as? String {
                content(value)
            } else {
                content("")
            }
        }, errorHandle: { (e) in
            error?(e)
        })
    }
    
    func getListImageBase64(_ results: @escaping([String]?) -> Void, error: ((Error) -> Void)? = nil) {
        self.runJS("getArrImageBase64()", response: { (result) in
            results(result as? [String])
        }, errorHandle: error)
    }
    
    func insertImage(url: String) {
        self.runJS("setUrlImage('\(url)');")
    }
    
    
    func getIntro(_ results: @escaping(String) -> Void, error: ((Error) -> Void)? = nil) {
        self.runJS("getReviewIntro()", response: { (result) in
            results((result as? String) ?? "")
        }) { (e) in
            error?(e)
        }
    }
    
    func resizeHtml(height: CGFloat, isShowKeyboard: Bool) {
        self.runJS("resizeHtml(\(height), \(isShowKeyboard));", response: { (result) in
            print(result)
        }) { (error) in
            print("error: \(error.localizedDescription)")
        }
    }
    
    fileprivate func setEditing(enable: Bool) {
        self.runJS("showToolbar(\(enable))") { (error) in
            print(error.localizedDescription)
        }
    }
}

extension CustomEditorView: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
//        if !self.isScrollEnabled {
//            scrollView.bounds = self.webView.bounds
//        }
    }
}

extension CustomEditorView: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.isConfigure = true
    }
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
    }
}

extension CustomEditorView: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

