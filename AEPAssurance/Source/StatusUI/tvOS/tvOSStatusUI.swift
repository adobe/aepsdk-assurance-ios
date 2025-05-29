////
//// Copyright 2024 Adobe. All rights reserved.
//// This file is licensed to you under the Apache License, Version 2.0 (the "License");
//// you may not use this file except in compliance with the License. You may obtain a copy
//// of the License at http://www.apache.org/licenses/LICENSE-2.0
////
//// Unless required by applicable law or agreed to in writing, software distributed under
//// the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
//// OF ANY KIND, either express or implied. See the License for the specific language
//// governing permissions and limitations under the License.
////
//
//#if os(tvOS)
//import Foundation
//import UIKit
//
///// tvOS-specific implementation of the StatusUIPresentable protocol.
//class tvOSStatusUI: StatusUIPresentable {
//    var presentationDelegate: AssurancePresentationDelegate
//    var displayed: Bool = false
//    var debugButtonPresenter: FloatingButtonPresenter!
//    private var isConnected: Bool = false
//
//    required init(presentationDelegate: AssurancePresentationDelegate) {
//        self.presentationDelegate = presentationDelegate
//    }
//
//    func display() {
//        DispatchQueue.main.async {
//            if self.debugButtonPresenter == nil {
//                self.debugButtonPresenter = FloatingButtonPresenter(dismissAction: { [weak self] in
//                    guard let self = self else { return }
//                    self.presentationDelegate.disconnectClicked()
//                })
//                self.debugButtonPresenter.show()
//                self.displayed = true
//            }
//            print("tvOSStatusUI: Displaying UI")
//        }
//    }
//
//    // Helper method to find the top-most view controller
//    private func findTopViewController(_ viewController: UIViewController) -> UIViewController? {
//        if let presentedViewController = viewController.presentedViewController {
//            return findTopViewController(presentedViewController)
//        }
//
//        if let navigationController = viewController as? UINavigationController {
//            return findTopViewController(navigationController.topViewController ?? navigationController)
//        }
//
//        if let tabBarController = viewController as? UITabBarController {
//            return findTopViewController(tabBarController.selectedViewController ?? tabBarController)
//        }
//
//        return viewController
//    }
//
//    func updateForSocketInActive() {
//        isConnected = false
//        debugButtonPresenter?.updateButtonImage(imageData: Data(bytes: InactiveIcon.content, count: InactiveIcon.content.count))
//        print("tvOSStatusUI: Updating UI for socket inactive")
//    }
//
//    func updateForSocketConnected() {
//        isConnected = true
//        debugButtonPresenter?.updateButtonImage(imageData: Data(bytes: ActiveIcon.content, count: ActiveIcon.content.count))
//        print("tvOSStatusUI: Updating UI for socket connected")
//    }
//
//    func remove() {
//        DispatchQueue.main.async {
//            self.debugButtonPresenter?.dismiss()
//            self.debugButtonPresenter = nil
//            self.displayed = false
//            print("tvOSStatusUI: Removing UI")
//        }
//    }
//
//    func addClientLog(_ message: String, visibility: AssuranceClientLogVisibility) {
//        print("tvOSStatusUI: Adding client log - \(message) with visibility \(visibility)")
//    }
//}
//#endif
