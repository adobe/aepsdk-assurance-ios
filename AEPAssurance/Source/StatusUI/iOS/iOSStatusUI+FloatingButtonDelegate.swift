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
import AEPServices

extension iOSStatusUI : FloatingButtonDelegate {
    
    func onTapDetected() {
        //floatingButton?.dismiss()
        DispatchQueue.main.async {
            self.fullScreenMessage = ServiceProvider.shared.uiService.createFullscreenMessage(payload: String(bytes: PinDialogHTML.content, encoding: .utf8)!, listener: self, isLocalImageUsed: false)
            self.fullScreenMessage?.show()
        }
    }
    
    func onPanDetected() {
        
    }
    
    func onShow() {
        
    }
    
    func onDismiss() {

    }
    
    func onShow(message: FullscreenMessage) {
        
    }
    
    func onDismiss(message: FullscreenMessage) {
        fullScreenMessage = nil
    }
    
    func overrideUrlLoad(message: FullscreenMessage, url: String?) -> Bool {
        return false
    }
    
    func onShowFailure() {
        Log.warning(label: AssuranceConstants.LOG_TAG, "Unable to display the statusUI screen, onShowFailure delegate method is invoked")
    }
        
}
