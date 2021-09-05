//
//  NotificationService+Requests.swift
//  AWattPrice
//
//  Created by Léon Becker on 30.08.21.
//

import Combine
import Foundation

extension NotificationService {
    private func sendNotificationRequest(request: PlainAPIRequest) -> AnyPublisher<Never, Error> {
        let response = APIClient().request(to: request)
        
        response
            .receive(on: DispatchQueue.main)
            .sink { completion in
                if case .failure(let error) = completion {
                    print("Couldn't sent notification tasks: \(error).")
                }
            } receiveValue: { _ in }
            .store(in: &cancellables)
        
        return response
    }
    
    /// Try to receive the required notification access permissions and send the notification request.
    func runNotificationRequest(interface: APINotificationInterface, appSetting: CurrentSetting, notificationSetting: CurrentNotificationSetting, onSuccess: (() -> ())? = nil) {
        guard accessState == .granted, pushState == .apnsRegistrationSuccessful, isUploading.tryLock() == true,
              let extendedInterface = extendNotificationInterface(interface, appSetting: appSetting, notificationSetting: notificationSetting)
        else { return }
        let packedTasks = extendedInterface.getPackedTasks()
        
        guard let apiRequest = APIRequestFactory.notificationRequest(packedTasks: packedTasks) else { return }
        let request = sendNotificationRequest(request: apiRequest)
        request
            .sink { completion in
                if case .finished = completion {
                    extendedInterface.copyToSettings(appSetting: appSetting, notificationSetting: notificationSetting)
                    onSuccess?()
                }
                self.isUploading.releaseLock()
            } receiveValue: { _ in }
            .store(in: &cancellables)
    }
    
    /// Extends the notification interface by adding missing tasks which are required to be sent with this notification request.
    func extendNotificationInterface(_ interface: APINotificationInterface, appSetting: CurrentSetting, notificationSetting: CurrentNotificationSetting) -> APINotificationInterface? {
        guard let tokenContainer = self.tokenContainer, let appSettingEntity = appSetting.entity else { return nil }
        
        if tokenContainer.nextUploadState == .addTokenTask, let region = Region(rawValue: appSettingEntity.regionIdentifier) {
            interface.addAddTokenTask(AddTokenPayload(region: region, tax: appSettingEntity.pricesWithVAT), overwrite: false)
        } else if tokenContainer.nextUploadState == .uploadAllNotificationConfig {
            guard interface.extendToAllNotificationConfig(appSetting: appSetting, notificationSetting: notificationSetting) != nil else { return nil }
        }
        
        return interface
    }
    
    func uploadAllNotificationConfig(appSetting: CurrentSetting, notificationSetting: CurrentNotificationSetting, onSuccess: (() -> ())? = nil, onFailure: (() -> ())? = nil) {
        guard let token = tokenContainer?.token else { return }
        let interface = APINotificationInterface(token: token)
        guard interface.extendToAllNotificationConfig(appSetting: appSetting, notificationSetting: notificationSetting) != nil else {
            onSuccess?(); return
        }
        runNotificationRequest(interface: interface, appSetting: appSetting, notificationSetting: notificationSetting) {
            onFailure?(); return
        }
    }
}
