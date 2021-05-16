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

enum AssuranceConstants {
    static let EXTENSION_NAME = "com.adobe.assurance"
    static let FRIENDLY_NAME = "Assurance"
    static let EXTENSION_VERSION = "2.0.0"
    static let LOG_TAG = FRIENDLY_NAME

    static let BASE_SOCKET_URL = "wss://connect%@.griffon.adobe.com/client/v1?sessionId=%@&token=%@&orgId=%@&clientId=%@"

    enum Deeplink {
        static let SESSIONID_KEY = "adb_validation_sessionid"
        static let ENVIRONMENT_KEY = "env"
    }

    enum SharedStateName {
        static let CONFIGURATION = "com.adobe.module.configuration"
    }

    enum Vendor {
        static let MOBILE = "com.adobe.griffon.mobile"
        static let SDK = "com.adobe.marketing.mobile.sdk"
    }

    enum SDKEventName {
        static let SHARED_STATE_CHANGE    = "Shared state change"
        static let XDM_SHARED_STATE_CHANGE    = "Shared state change (XDM)"
    }

    enum SDKEventType {
        static let ASSURANCE = "com.adobe.eventType.assurance"
    }

    enum PluginFakeEvent {
        static let NAME    = "eventName"
        static let TYPE    = "eventType"
        static let SOURCE  = "eventSource"
        static let DATA    = "eventData"
    }

    // todo verify the impact of making these keys AEPExtensionEvent*
    enum ACPExtensionEventKey {
        static let NAME    = "ACPExtensionEventName"
        static let TYPE    = "ACPExtensionEventType"
        static let SOURCE  = "ACPExtensionEventSource"
        static let DATA    = "ACPExtensionEventData"
        static let TIMESTAMP    = "ACPExtensionEventTimestamp"
        static let NUMBER    = "ACPExtensionEventNumber"
        static let UNIQUE_IDENTIFIER = "ACPExtensionEventUniqueIdentifier"
        static let RESPONSE_IDENTIFIER = "ACPExtensionEventResponseIdentifier" // todo new key introduces convey to UI team
    }

    enum EventDataKey {
        static let START_SESSION_URL = "startSessionURL"
        static let CONFIG_ORG_ID = "experienceCloud.org"
        static let SHARED_STATE_OWNER = "stateowner"
    }

    enum DataStoreKeys {
        static let SESSION_ID = "assurance.session.Id"
        static let CLIENT_ID = "assurance.client.Id"
        static let ENVIRONMENT = "assurance.environment"
        static let CONFIG_MODIFIED_KEYS = "assurance.control.modifiedConfigKeys"
    }

    enum SharedStateKeys {
        static let CLIENT_ID = "sessionid"
        static let SESSION_ID = "clientid"
        static let INTEGRATION_ID = "integrationid"
    }

    enum EventType {
        static let GENERIC = "generic"
        static let LOG = "log"
        static let CONTROL = "control"
        static let CLIENT = "client"
        static let BLOB = "blob"
    }

    enum PayloadKey {
        static let SHARED_STATE_DATA = "state.data"
        static let XDM_SHARED_STATE_DATA = "xdm.state.data"
        static let METADATA = "metadata"
        static let TYPE = "type"
        static let DETAIL = "detail"
    }

    enum HTMLURLPath {
        static let CANCEL   = "cancel"
        static let CONFIRM  = "confirm"
    }

    enum ClientInfoKeys {
        static let TYPE  = "type"
        static let VERSION   = "version"
        static let DEVICE_INFO  = "deviceInfo"
        static let APP_SETTINGS  = "appSettings"
    }

    enum CommandType {
        static let START_EVENT_FORWARDING  = "startEventForwarding"
        static let UPDATE_CONFIG  = "configUpdate"
        static let FAKE_EVENT  = "fakeEvent"
        static let SCREENSHOT  = "screenshot"
        static let LOG_FORWARDING = "logForwarding"
        static let WILDCARD = "wildcard"
    }
}
