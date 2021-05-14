/*
 Copyright 2021 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
 */

import Foundation
import WebKit
import AEPServices

class WebViewSocketConnection : NSObject, SocketConnectable, WKNavigationDelegate, WKScriptMessageHandler {
    
    private let MAX_WAIT_FOR_WEBVIEW = 10.0;
    private let AEPASSURANCE_LOCK_LOOP_WAIT_TIME = 0.1;
    private let pageContent = "<HTML><HEAD></HEAD><BODY></BODY></HTML>"
    
    // todo rename
    typealias messageHandlerBlock = (WKScriptMessage) -> Void
    
    var socketDelegate: SocketDelegate
    var socketState: SocketState = .UNKNOWN
    var webView : WKWebView?
    var loadNav : WKNavigation?
    private var socketEventHandlers = ThreadSafeDictionary<String, messageHandlerBlock>(identifier: "com.adobe.assurance.socketEventHandler")
    private let queue = DispatchQueue(label: "com.adobe.assurance.WebViewSocketConnection") // serial queue
    
    
    /// Initialization of WebViewSocketConnection
    init(withDelegate delegate : SocketDelegate) {
        socketDelegate = delegate
        super.init()
        // read the webSocket javascript from the built resouces
        let socketJavascript = String(bytes: SocketScript.content, encoding: .utf8)!
                
        // grab the main queue to set up webview for socket connection
        // Webview Initialization should be run on main thread
        DispatchQueue.main.async {
            self.webView = WKWebView(frame: CGRect.zero)
            self.webView?.configuration.userContentController.addUserScript(WKUserScript(source: socketJavascript, injectionTime: .atDocumentEnd, forMainFrameOnly: false))
            self.loadNav = self.webView?.loadHTMLString(self.pageContent, baseURL: nil)!
            
            self.setupCallbacks()
            self.webView?.navigationDelegate = self
        }
    }
    
    func connect(withUrl url: URL) {
        self.socketState = .CONNECTING
        queue.async {
            let connectCommand = String(format: "connect(\"%@\");", url.absoluteString)
            self.runJavascriptCommand(connectCommand, { error in
                if(error != nil) {
                    Log.debug(label: AssuranceConstants.LOG_TAG, "An error occurred while opening connection - \(String(describing: error?.localizedDescription))")
                }
            })
        }
    }
    
    func disconnect() {
        self.socketState = .CLOSING
        queue.async {
            self.runJavascriptCommand("disconnect();", { error in
                if(error != nil) {
                    Log.debug(label: AssuranceConstants.LOG_TAG, "An error occurred while closing connection - \(String(describing: error?.localizedDescription))")
                }
            })
        }
    }
    
    func sendEvent(_ event: AssuranceEvent) {
        queue.async {
            let jsonData = (try? JSONEncoder().encode(event)) ?? Data()
            let dataString = jsonData.base64EncodedString(options: .endLineWithLineFeed)
            let jsCommand = String(format: "sendData(\"%@\");", dataString)
            self.runJavascriptCommand(jsCommand, { error in
                if(error != nil) {
                    Log.debug(label: AssuranceConstants.LOG_TAG, "An error occurred while sending data - \(String(describing: error?.localizedDescription))")
                }
            })
        }
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        let block = self.socketEventHandlers[message.name]
        block?(message)
    }
        
    // Called after page is loaded
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if (navigation == self.loadNav){
            Log.debug(label: AssuranceConstants.LOG_TAG, "WKWebView initialization complete with socket connection javascipt.")
        }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        if (navigation == self.loadNav){
            Log.debug(label: AssuranceConstants.LOG_TAG, "WKWebView failed to load bundled JS for socket. Error: \(error.localizedDescription)")
        }
    }
    
    // todo rename function
    private func setupCallbacks() {
        registerSocketCallback("log", with: { message in
            Log.debug(label: AssuranceConstants.LOG_TAG, "Javascript log output : \(message.body)")
        })
        
        registerSocketCallback("onopen", with: { message in
            self.socketState = .OPEN;
            self.socketDelegate.webSocketDidConnect(self)
        })
        
        registerSocketCallback("onerror", with: { message in
            self.socketDelegate.webSocketOnError(self)
        })
        
        registerSocketCallback("onclose", with: { message in
            self.socketState = .CLOSED;
            self.socketDelegate.webSocketOnError(self)
        })
        
        registerSocketCallback("onmessage", with: { message in
            
            guard let messageBody = message.body as? String else {
                Log.debug(label: AssuranceConstants.LOG_TAG, "Unable to read the socket message as string. Ignoring the incoming event.")
                return
            }
            guard let data = messageBody.data(using: .utf8) else {
                Log.debug(label: AssuranceConstants.LOG_TAG, "Unable to convert the received socket message to data. Ignoring the incoming event.")
                return
            }
            guard let receivedEvent = AssuranceEvent.from(jsonData: data) else {
                return
            }
            
            self.socketDelegate.webSocket(self, didReceiveEvent: receivedEvent)
        })
        
    }
        
    private func registerSocketCallback(_ name : String, with block : @escaping messageHandlerBlock) {
        self.webView?.configuration.userContentController.add(self, name: name)
        self.socketEventHandlers[name] = block
    }
    
    private func runJavascriptCommand(_ jsCommand : String,_ callbackError : @escaping (Error?)->Void) {
        DispatchQueue.main.async {
            self.webView?.evaluateJavaScript(jsCommand, completionHandler: { returnValue, error in
                callbackError(error)
            })
        }
    }

}
