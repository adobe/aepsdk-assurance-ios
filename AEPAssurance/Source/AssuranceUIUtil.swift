//
// Copyright 2021 Adobe. All rights reserved.
// This file is licensed to you under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License. You may obtain a copy
// of the License at http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software distributed under
// the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
// OF ANY KIND, either express or implied. See the License for the specific language
// governing permissions and limitations under the License.
//

import Foundation
import UIKit

class AssuranceUIUtil {

    /// Captures the screenshot of the mobile device.
    /// Callback is called with nil data if there is any failure in capturing a screenshot.
    /// - Parameters:
    ///     - callback: callback  called with image `Data` of screenshot
    func takeScreenshot(_ callback :@escaping (Data?) -> Void) {
        // use main thread to capture the screenshot
        DispatchQueue.main.async {
            // START: Dark mode screenshot capture updates
            // ORIGINAL: guard let layer = UIApplication.shared.assuranceGetKeyWindow()?.layer else {
            guard let window = UIApplication.shared.assuranceGetKeyWindow() else {
                callback(nil)
                return
            }

            // ORIGINAL: let scale = UIScreen.main.scale
            // ORIGINAL: UIGraphicsBeginImageContextWithOptions(layer.frame.size, false, scale)
            let size = window.bounds.size
            UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)

            guard let context = UIGraphicsGetCurrentContext() else {
                callback(nil)
                return
            }

            // ORIGINAL: layer.render(in: context)
            window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)

            let screenshotImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()

            // ORIGINAL: let data = screenshotImage?.jpegData(compressionQuality: 0.9)
            let data = screenshotImage?.pngData()
            callback(data)
            // END: Dark mode screenshot capture updates
        }
    }
}

internal extension UIApplication {
    func assuranceGetKeyWindow() -> UIWindow? {
        keyWindow ?? windows.first
    }
}
