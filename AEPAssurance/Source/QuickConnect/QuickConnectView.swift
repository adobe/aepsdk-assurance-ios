//
//  QuickConnectView.swift
//  AEPAssurance
//
//  Created by pprakash on 2/9/22.
//

import Foundation
import UIKit
import AEPServices

class QuickConnectView {
    
    
    func show() {
        guard let window = UIApplication.shared.assuranceGetKeyWindow() else {
            Log.warning(label: AssuranceConstants.LOG_TAG, "QuickConnect View unable to get the keyWindow, ")
             return
         }
    }
    
}
