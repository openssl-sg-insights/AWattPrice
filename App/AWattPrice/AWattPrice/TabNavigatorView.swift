//
//  MainView.swift
//  AwattarApp
//
//  Created by Léon Becker on 13.09.20.
//

import SwiftUI

/// Allows the user to select between different tabs to access different functionalities/views of the app. This tab navigator view is shown at the very bottom of the screen.
struct TabNavigatorView: View {
    @EnvironmentObject var awattarData: AwattarData
    @EnvironmentObject var currentSetting: CurrentSetting
    
    @State var tabSelection = 1
    
    var body: some View {
        VStack {
            if currentSetting.setting != nil {
                if currentSetting.setting!.splashScreensFinished == true {
                    TabView(selection: $tabSelection) {
                        HomeView() // HomeView is the selection
                            .tabItem {
                                Image(systemName: "bolt")
                                Text("elecPrice")
                            }
                            .tag(1)

                        ConsumptionComparisonView()
                            .tabItem {
                                Image(systemName: "rectangle.and.text.magnifyingglass")
                                Text("cheapestPrice")
                            }
                            .tag(2)
                    }
                } else if currentSetting.setting!.splashScreensFinished == false {
                    SplashScreenStartView()
                }
            }
        }
    }
}

struct TabNavigatorView_Previews: PreviewProvider {
    static var previews: some View {
        TabNavigatorView()
    }
}
