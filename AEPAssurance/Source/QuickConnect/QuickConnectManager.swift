//
//  QuickConnectManager.swift
//  AEPAssurance
//
//  Created by pprakash on 2/9/22.
//

import Foundation

class QuickConnectManager {
    
    private let parentExtension : Assurance
    private let view : QuickConnectView
    
    init(assurance : Assurance) {
        parentExtension = assurance;
        view = QuickConnectView()
        detectShakeGesture()
    }
    
    func detectShakeGesture() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleShakeGesture),
                                               name: NSNotification.Name(AssuranceConstants.QuickConnect.SHAKE_NOTIFICATION_KEY),
                                               object: nil)
    }
    
    
    @objc private func handleShakeGesture() {
        parentExtension.shouldProcessEvents = true
        //parentExtension.invalidateTimer()
        DispatchQueue.main.async {
            //self.view?.appear()
        }

    }
    
}
