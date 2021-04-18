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

import AEPCore
import AEPServices
import Foundation

public class Assurance: NSObject, Extension {
    
    public var name = AssuranceConstants.EXTENSION_NAME
    public var friendlyName = AssuranceConstants.FRIENDLY_NAME
    public static var extensionVersion = AssuranceConstants.EXTENSION_VERSION
    public var metadata: [String : String]?
    public var runtime: ExtensionRuntime
    
    public func onRegistered() {
        // TODO
    }
    
    public func onUnregistered() {}
    
    public required init?(runtime: ExtensionRuntime) {
        self.runtime = runtime
    }
    
    public func readyForEvent(_ event: Event) -> Bool {
        return true
    }
    
}

