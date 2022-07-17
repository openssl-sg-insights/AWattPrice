//
//  App_APIRequest.swift
//  AWattPrice
//
//  Created by Léon Becker on 16.07.22.
//

import Foundation

extension APIRequestFactory {
    static func notificationRequest(_ notificationConfiguration: NotificationConfiguration) -> PlainAPIRequest? {
        guard notificationConfiguration.token != nil else {
            print("Token of the notification configuration is still nil.")
            return nil
        }
        
        let encoder = JSONEncoder()
        let encodedTasks: Data
        do {
            encodedTasks = try encoder.encode(notificationConfiguration)
        } catch {
            print("Couldn't encode notification configuration: \(error).")
            return nil
        }
        
        let requestURL = apiURL
            .appendingPathComponent("notifications", isDirectory: true)
            .appendingPathComponent("save_configuration", isDirectory: true)
        var urlRequest = URLRequest(
            url: requestURL,
            cachePolicy: .reloadIgnoringLocalAndRemoteCacheData,
            timeoutInterval: 30
        )
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = encodedTasks
        
        return PlainAPIRequest(urlRequest: urlRequest, expectedResponseCode: 200)
    }
}
