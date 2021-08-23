//
//  ViewController.swift
//  NGSpaceCompany
//
//  Created by Ilya Minichev on 23.08.2021.
//

import UIKit
import WebKit

class ViewController: UIViewController {

    private let webView = WKWebView(frame: .zero)
        
        override func viewDidLoad() {
            super.viewDidLoad()
            
            let app = UIApplication.shared
            
            let statusBarHeight: CGFloat = app.statusBarFrame.size.height
            
            let statusbarView = UIView()
            
            statusbarView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
            view.addSubview(statusbarView)
            
            statusbarView.translatesAutoresizingMaskIntoConstraints = false
            statusbarView.heightAnchor
                .constraint(equalToConstant: statusBarHeight).isActive = true
            statusbarView.widthAnchor
                .constraint(equalTo: view.widthAnchor, multiplier: 1.0).isActive = true
            statusbarView.topAnchor
                .constraint(equalTo: view.topAnchor).isActive = true
            statusbarView.centerXAnchor
                .constraint(equalTo: view.centerXAnchor).isActive = true
            
            webView.translatesAutoresizingMaskIntoConstraints = false
            self.view.addSubview(self.webView)
            NSLayoutConstraint.activate([
                self.webView.leftAnchor.constraint(equalTo: self.view.leftAnchor),
                self.webView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
                self.webView.rightAnchor.constraint(equalTo: self.view.rightAnchor),
                self.webView.topAnchor.constraint(equalTo: self.view.topAnchor),
            ])
            self.view.setNeedsLayout()
            
            if let url = URL(string: "https://ngspacecompany.exileng.com/") {
                let request = URLRequest(url: url)
                webView.load(request)
                
                webView.uiDelegate = self
                webView.navigationDelegate = self
                
                let source: String = "var meta = document.createElement('meta');" +
                    "meta.name = 'viewport';" +
                    "meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';" +
                    "var head = document.getElementsByTagName('head')[0];" +
                    "head.appendChild(meta);"
                
                let script: WKUserScript = WKUserScript(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
                
                webView.configuration.userContentController.addUserScript(script)
            }
            
            
            self.view.bringSubviewToFront(statusbarView);
            
        }
        
        override var preferredStatusBarStyle : UIStatusBarStyle {
            
            return UIStatusBarStyle.lightContent
            
        }
        
    }

    extension WKWebView {
        
        enum PrefKey {
            static let cookie = "cookies"
        }
        
        func writeDiskCookies(for domain: String, completion: @escaping () -> ()) {
            fetchInMemoryCookies(for: domain) { data in
                print("write data", data)
                UserDefaults.standard.setValue(data, forKey: PrefKey.cookie + domain)
                completion();
            }
        }
        
        
        func loadDiskCookies(for domain: String, completion: @escaping () -> ()) {
            if let diskCookie = UserDefaults.standard.dictionary(forKey: (PrefKey.cookie + domain)){
                fetchInMemoryCookies(for: domain) { freshCookie in
                    
                    let mergedCookie = diskCookie.merging(freshCookie) { (_, new) in new }
                    
                    for (cookieName, cookieConfig) in mergedCookie {
                        let cookie = cookieConfig as! Dictionary<String, Any>
                        
                        var expire : Any? = nil
                        
                        if let expireTime = cookie["Expires"] as? Double{
                            expire = Date(timeIntervalSinceNow: expireTime)
                        }
                        
                        let newCookie = HTTPCookie(properties: [
                            .domain: cookie["Domain"] as Any,
                            .path: cookie["Path"] as Any,
                            .name: cookie["Name"] as Any,
                            .value: cookie["Value"] as Any,
                            .secure: cookie["Secure"] as Any,
                            .expires: expire as Any
                        ])
                        
                        self.configuration.websiteDataStore.httpCookieStore.setCookie(newCookie!)
                    }
                    
                    completion()
                }
                
            }
            else{
                completion()
            }
        }
        
        func fetchInMemoryCookies(for domain: String, completion: @escaping ([String: Any]) -> ()) {
            var cookieDict = [String: AnyObject]()
            WKWebsiteDataStore.default().httpCookieStore.getAllCookies { (cookies) in
                for cookie in cookies {
                    if cookie.domain.contains(domain) {
                        cookieDict[cookie.name] = cookie.properties as AnyObject?
                    }
                }
                completion(cookieDict)
            }
        }}

    let url = URL(string: "https://ngspacecompany.exileng.com/")!

    extension ViewController: WKUIDelegate, WKNavigationDelegate {
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            //load cookie of current domain
            webView.loadDiskCookies(for: url.host!){
                decisionHandler(.allow)
            }
        }
        
        public func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
            //write cookie for current domain
            webView.writeDiskCookies(for: url.host!){
                decisionHandler(.allow)
            }
        }
    }
