//
//  PriceBelowNotificationView.swift
//  AWattPrice
//
//  Created by Léon Becker on 24.12.20.
//

import Combine
import Resolver
import SwiftUI

struct PriceDropsBelowValueNotificationInfoView: View {
    let completeExtraTextLineTwo: Text

    init() {
        completeExtraTextLineTwo =
            Text("notificationPage.notification.priceDropsBelowValue.description.firstLine.pt1")
                + Text("notificationPage.notification.priceDropsBelowValue.description.firstLine.pt2")
                .fontWeight(.heavy)
                + Text("notificationPage.notification.priceDropsBelowValue.description.firstLine.pt3")
                + Text("notificationPage.notification.priceDropsBelowValue.description.firstLine.pt4")
                .fontWeight(.heavy)
                + Text("notificationPage.notification.priceDropsBelowValue.description.firstLine.pt5")
                + Text("notificationPage.notification.priceDropsBelowValue.description.firstLine.pt6")
                .fontWeight(.heavy)
                + Text("notificationPage.notification.priceDropsBelowValue.description.firstLine.pt7")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Divider()

            VStack(alignment: .leading, spacing: 12) {
                completeExtraTextLineTwo
                    .foregroundColor(.blue)
            }
            .font(.caption)
            .lineSpacing(2)
        }
    }
}

class PriceBelowNotificationViewModel: ObservableObject {
    @Injected var currentSetting: CurrentSetting
    @ObservedObject var notificationSetting: CurrentNotificationSetting = Resolver.resolve()
    var notificationService: NotificationService = Resolver.resolve()

    @Published var notificationIsEnabled: Bool = false
    @Published var priceBelowValue: String = ""
    
    let uploadObserver: DownloadPublisherLoadingViewObserver
    
    var cancellables = [AnyCancellable]()
    
    init() {
        uploadObserver = DownloadPublisherLoadingViewObserver(intervalBeforeExceeded: 0.4)
        
        uploadObserver.objectWillChange.receive(on: DispatchQueue.main).sink(receiveValue: { self.objectWillChange.send() }).store(in: &cancellables)

        notificationIsEnabled = notificationSetting.entity!.priceDropsBelowValueNotification
        $notificationIsEnabled.dropFirst().sink(receiveValue: priceBelowNotificationToggled).store(in: &cancellables)
        priceBelowValue = notificationSetting.entity!.priceBelowValue.priceString ?? ""
        $priceBelowValue.dropFirst().sink(receiveValue: updateWishPrice).store(in: &cancellables)
    }
    
    var isUploading: Bool {
        [.uploadingAndTimeExceeded, .uploadingAndTimeNotExceeded].contains(uploadObserver.loadingPublisher)
    }
    
    var showUploadIndicators: Bool {
        uploadObserver.loadingPublisher == .uploadingAndTimeExceeded
    }
    
    func priceBelowNotificationToggled(to newSelection: Bool) {
        var notificationConfiguration = NotificationConfiguration.create(nil, currentSetting, notificationSetting)
        notificationConfiguration.notifications.priceBelow.active = newSelection
        let uploadFailure = { DispatchQueue.main.async { self.notificationIsEnabled = self.notificationSetting.entity!.priceDropsBelowValueNotification } }

        notificationService.changeNotificationConfiguration(notificationConfiguration, notificationSetting, skipWantNotificationCheck: true, uploadStarted: { downloadPublisher in
            self.uploadObserver.register(for: downloadPublisher.ignoreOutput().eraseToAnyPublisher())
            downloadPublisher.sink(receiveCompletion: { completion in
                switch completion { case .finished: self.notificationSetting.changePriceDropsBelowValueNotifications(to: newSelection)
                                    case .failure: uploadFailure() }
            }, receiveValue: {_ in}).store(in: &self.cancellables)
        }, cantStartUpload:  uploadFailure)
    }
    
    func updateWishPrice(to newWishPriceString: String) {
        guard let newWishPrice = newWishPriceString.integerValue else { priceBelowValue = ""; return }
        var notificationConfiguration = NotificationConfiguration.create(nil, currentSetting, notificationSetting)
        notificationConfiguration.notifications.priceBelow.belowValue = newWishPrice
        let uploadFailure = { DispatchQueue.main.async { self.priceBelowValue = self.notificationSetting.entity!.priceBelowValue.priceString ?? "" } }
        
        notificationService.changeNotificationConfiguration(notificationConfiguration, notificationSetting, skipWantNotificationCheck: true, uploadStarted: { downloadPublisher in
            self.uploadObserver.register(for: downloadPublisher.ignoreOutput().eraseToAnyPublisher())
            downloadPublisher.sink(receiveCompletion: { completion in
                switch completion { case .finished: self.notificationSetting.changePriceBelowValue(to: newWishPrice)
                                    case .failure: uploadFailure() }
            }, receiveValue: {_ in}).store(in: &self.cancellables)
            self.notificationSetting.changePriceBelowValue(to: newWishPrice)
        }, cantStartUpload: uploadFailure)
    }
}

struct PriceBelowNotificationView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.keyboardObserver) var keyboardObserver
    
    @StateObject var viewModel = PriceBelowNotificationViewModel()
    @State var keyboardCurrentlyClosed = false
    
    let showHeader: Bool
    
    init(showHeader: Bool = false) {
        self.showHeader = showHeader
    }
    
    var body: some View {
        VStack {
            CustomInsetGroupedListItem(
                header: showHeader ? Text("general.notifications") : nil,
                footer: nil
            ) {
                ZStack {
                    VStack(spacing: 20) {
                        toggleView

                        if viewModel.notificationIsEnabled {
                            wishPriceInputField

                            PriceDropsBelowValueNotificationInfoView()
                        }
                    }
                    .opacity(viewModel.showUploadIndicators ? 0.5 : 1)
                    .grayscale(viewModel.showUploadIndicators ? 0.5 : 0)
                    
                    if viewModel.showUploadIndicators {
                        loadingView
                    }
                }
                .disabled(viewModel.isUploading)
            }
        }
    }

    var toggleView: some View {
        Toggle("notificationPage.notification.priceDropsBelowValue", isOn: $viewModel.notificationIsEnabled)
    }

    var wishPriceInputField: some View {
        VStack(alignment: .leading) {
            Text("notificationPage.notification.priceDropsBelowValue.wishPrice")
                .textCase(.uppercase)
                .foregroundColor(.gray)
                .font(.caption)

            HStack {
                NumberField(text: $viewModel.priceBelowValue, placeholder: "general.cent.long".localized(), plusMinusButton: true, withDecimalSeperator: false)
                    .fixedSize(horizontal: false, vertical: true)

                Text("general.centPerKwh")
                    .transition(.opacity)
            }
            .onReceive(keyboardObserver.keyboardHeight) { newKeyboardHeight in
                if newKeyboardHeight == 0 {
                    keyboardCurrentlyClosed = true
                } else {
                    keyboardCurrentlyClosed = false
                }
            }
            .modifier(GeneralInputView(markedRed: false))
        }
    }
    
    var loadingView: some View {
        ProgressView()
            .progressViewStyle(CircularProgressViewStyle(tint: .white))
    }
}
struct TestView: View {
    @Environment(\.isEnabled) private var isEnabled

    @State var test = true
    
    var body: some View {
        Toggle("", isOn: $test)
            .disabled(true)
    }
}

struct PriceBelowNotifictionView_Previews: PreviewProvider {
    static var previews: some View {
        TestView()
    }
}
