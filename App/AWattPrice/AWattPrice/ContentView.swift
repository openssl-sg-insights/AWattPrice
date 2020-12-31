//
//  TabBar.swift
//  AWattPrice
//
//  Created by Léon Becker on 28.11.20.
//

import SwiftUI

/// Start of the application.
struct ContentView: View {
    @Environment(\.networkManager) var networkManager
    @Environment(\.scenePhase) var scenePhase
    @EnvironmentObject var crtNotifiSetting: CurrentNotificationSetting
    @EnvironmentObject var currentSetting: CurrentSetting

    @ObservedObject var tabBarItems = TBItems()
    
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
                        .onAppear {
                            managePushNotificationsOnAppStart()
                            let vatDispatchQueue = DispatchQueue(label: "VATUpdatingQueue")
                            vatDispatchQueue.async {
                                let timer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { _ in
                                    let currentVATToUse = getCurrentVATToUse()
                                    if currentVATToUse != currentSetting.currentVATToUse {
                                        DispatchQueue.main.async {
                                            currentSetting.currentVATToUse = currentVATToUse
                                        }
                                    }
                                }
                                let runLoop = RunLoop.current
                                runLoop.add(timer, forMode: .default)
                                runLoop.run()
                            }
                        }
                        
                        Spacer(minLength: 0)
                        
                        TabBar()
                            .environmentObject(tabBarItems)
                    } else {
                        SplashScreenStartView()
                    }
                }
                .onAppear {
                    if currentSetting.entity!.splashScreensFinished == false && currentSetting.entity!.showWhatsNew == true {
                        currentSetting.changeShowWhatsNew(newValue: false)
                    }
                }
                .onChange(of: crtNotifiSetting.entity!.changesButErrorUploading) { newValue in
                    if newValue == true {
                        tryNotificationUploadAfterFailed(
                            Int(currentSetting.entity!.regionIdentifier),
                            currentSetting.entity!.pricesWithVAT ? 1 : 0,
                            crtNotifiSetting,
                            networkManager)
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
