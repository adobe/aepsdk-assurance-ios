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

/**
 An  extension for URL class to parse the URL and return a dictionary with key value pairs from the query string
 The query values will be URL decoded when they are stored in the output dictionary.
 */
extension URL {
    /**
     A computed variable that returns the dictionary of available query string and value for this URL
     */
    var params: [String: String] {
        guard let components = URLComponents(url: self, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            return [:]
        }
        var dict: [String: String] = [:]
        for item in queryItems {
            if let queryValue = item.value {
                dict[item.name] = queryValue
            }
        }
        return dict
    }
    
    /**
     Appending query string parameters to url
     */
    func appending(_ queryItems: [URLQueryItem]) -> URL? {
        guard var urlComponents = URLComponents(url: self, resolvingAgainstBaseURL: true) else {
            // URL is not conforming to RFC 3986 (maybe it is only conforming to RFC 1808, RFC 1738, and RFC 2732)
            return nil
        }
        // append the query items to the existing ones
        urlComponents.queryItems = (urlComponents.queryItems ?? []) + queryItems

        // return the url from new url components
        return urlComponents.url
    }
}
