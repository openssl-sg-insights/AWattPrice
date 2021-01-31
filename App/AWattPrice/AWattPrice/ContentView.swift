//
//  TabBar.swift
//  AWattPrice
//
//  Created by Léon Becker on 28.11.20.
//

import SwiftUI

/// Start of the application.
struct ContentView: View {
    @Environment(\.appGroupManager) var appGroupManager
    @Environment(\.networkManager) var networkManager
    @Environment(\.scenePhase) var scenePhase

    @EnvironmentObject var backendComm: BackendCommunicator
    @EnvironmentObject var crtNotifiSetting: CurrentNotificationSetting
    @EnvironmentObject var currentSetting: CurrentSetting
    @EnvironmentObject var notificationAccess: NotificationAccess

    @ObservedObject var tabBarItems = TBItems()

    @State var initialAppearFinished: Bool? = false

    var body: some View {
        VStack {
            if currentSetting.entity != nil {
                VStack(spacing: 0) {
                    if currentSetting.entity!.splashScreensFinished == true {
                        ZStack {
                            SettingsPageView()
                                .opacity(tabBarItems.selectedItemIndex == 0 ? 1 : 0)
                                .environmentObject(tabBarItems)

                            HomeView()
                                .opacity(tabBarItems.selectedItemIndex == 1 ? 1 : 0)

                            CheapestTimeView()
                                .opacity(tabBarItems.selectedItemIndex == 2 ? 1 : 0)
                        }

                        Spacer(minLength: 0)

                        TabBar()
                            .environmentObject(tabBarItems)
                    } else {
                        SplashScreenStartView()
                    }
                }
                .onAppear {
                    initiateAppGroup()
                    // Check Notification access
                    if currentSetting.entity!.showWhatsNew == false && currentSetting.entity!.splashScreensFinished == true {
                        managePushNotificationsOnAppAppear(notificationAccessRepresentable: notificationAccess, registerForRemoteNotifications: true) {}
                    }
                    initialAppearFinished = nil
                }
                .onChange(of: scenePhase) { newScenePhase in
                    if initialAppearFinished == nil {
                        initialAppearFinished = true
                        return
                    }
                    if newScenePhase == .active, initialAppearFinished == true, currentSetting.entity!.showWhatsNew == false, currentSetting.entity!.splashScreensFinished == true {
                        managePushNotificationsOnAppAppear(notificationAccessRepresentable: self.notificationAccess, registerForRemoteNotifications: false) {}
                    }
                }
                .onAppear {
                    // Check Show Whats New
                    if currentSetting.entity!.splashScreensFinished == false && currentSetting.entity!.showWhatsNew == true {
                        currentSetting.changeShowWhatsNew(newValue: false)
                    }
                }
                .onChange(of: crtNotifiSetting.entity!.changesButErrorUploading) { errorOccurred in
                    if errorOccurred == true {
                        backendComm.tryNotificationUploadAfterFailed(
                            Int(currentSetting.entity!.regionIdentifier),
                            currentSetting.entity!.pricesWithVAT ? 1 : 0,
                            crtNotifiSetting,
                            networkManager
                        )
                    }
                }
            }
        }
        .ignoresSafeArea(.keyboard)
        .onChange(of: scenePhase) { newScenePhase in
            if newScenePhase == .active {
                UIApplication.shared.applicationIconBadgeNumber = 0
            }
        }
    }
}

extension ContentView {
    func initiateAppGroup() {
        let _ = appGroupManager.setGroup(AppGroups.awattpriceGroup)
        print(appGroupManager.groupID)
        appGroupManager.writeEnergyDataToGroup(energyData: EnergyData(prices: []))
    }
}
