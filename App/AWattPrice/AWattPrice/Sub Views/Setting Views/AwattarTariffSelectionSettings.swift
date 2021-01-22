//
//  AwattarTariffSelectionSettings.swift
//  AWattPrice
//
//  Created by Léon Becker on 29.10.20.
//

// import SwiftUI
//
// struct AwattarBasicEnergyChargePriceSetting: View {
//    @EnvironmentObject var currentSetting: CurrentSetting
//
//    @State var baseEnergyPriceString = ""
//    @State var firstAppear = true
//
//    struct SettingFooter: View {
//        var body: some View {
//            VStack(alignment: .leading, spacing: 12) {
//                Text("settingsPage.baseElectricityPriceHint")
//
//                Button(action: {
//                    // Let the user visit this website for him/her to get information which depends on the users location
//                    // This isn't yet handled directly in the app
//
//                    UIApplication.shared.open(URL(string: "https://www.awattar.de")!)
//                }) {
//                    HStack {
//                        Text("settingsPage.toAwattarWebsite")
//                        Image(systemName: "chevron.right")
//                    }
//                    .foregroundColor(Color.blue)
//                }
//            }
//            .font(.caption)
//            .foregroundColor(Color.gray)
//        }
//    }
//
//    var body: some View {
//        VStack(alignment: .leading, spacing: 15) {
//            HStack {
//                TextField("centPerKwh",
//                          text: $baseEnergyPriceString)
//                    .keyboardType(.decimalPad)
//                    .ifTrue(firstAppear == false) { content in
//                        content
//                            .onChange(of: baseEnergyPriceString) { newValue in
//                                currentSetting.changeBaseElectricityCharge(newValue: newValue.doubleValue ?? 0)
//                            }
//                    }
//                    .onAppear {
//                        if currentSetting.entity!.awattarBaseElectricityPrice != 0 {
//                            if let priceString = currentSetting.entity!.awattarBaseElectricityPrice.priceString {
//                                baseEnergyPriceString = priceString
//                            }
//                        }
//                        firstAppear = false
//                    }
//
//                if baseEnergyPriceString != "" {
//                    Text("centPerKwh")
//                        .transition(.opacity)
//                }
//            }
//            .padding([.top, .bottom], 7)
//            .padding([.leading, [.trailing]], 10)
//            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hue: 0.6667, saturation: 0.0202, brightness: 0.8686), lineWidth: 2))
//
//            SettingFooter()
//        }
//    }
// }
//
// struct AwattarTariffSelectionSetting: View {
//    @Environment(\.colorScheme) var colorScheme
//    @EnvironmentObject var backendComm: BackendCommunicator
//    @EnvironmentObject var currentSetting: CurrentSetting
//
//    @State var awattarEnergyTariffIndex: Int = 0
//    @State var firstAppear = true
//
//    var body: some View {
//        CustomInsetGroupedListItem(
//            header: Text("settingsPage.awattarTariff"),
//            footer: Text("settingsPage.awattarTariffSelectionTip")
//        ) {
//            VStack(alignment: .center, spacing: 20) {
//                Picker(selection: $awattarEnergyTariffIndex.animation(), label: Text("")) {
//                    Text("general.none").tag(-1)
//                    ForEach(backendComm.profilesData.profiles, id: \.name) { profile in
//                        Text(profile.name).tag(backendComm.profilesData.profiles.firstIndex(of: profile)!)
//                    }
//                }
//                .ifTrue(firstAppear == false) { content in
//                    content
//                        .onChange(of: awattarEnergyTariffIndex) { newValue in
//                            currentSetting.changeAwattarTariffIndex(newValue: Int16(newValue))
//                        }
//                }
//                .onAppear {
//                    awattarEnergyTariffIndex = Int(currentSetting.entity!.awattarTariffIndex)
//                    firstAppear = false
//                }
//                .frame(maxWidth: .infinity)
//                .pickerStyle(SegmentedPickerStyle())
//
//                if awattarEnergyTariffIndex != -1 {
//                    VStack(alignment: .center, spacing: 25) {
//                        VStack(alignment: .center, spacing: 15) {
//                            Image(backendComm.profilesData.profiles[awattarEnergyTariffIndex].imageName)
//                                .resizable()
//                                .scaledToFit()
//                                .frame(width: 60, height: 60, alignment: .center)
//                                .padding(.top, 5)
//
//                            Text(backendComm.profilesData.profiles[awattarEnergyTariffIndex].name)
//                                .bold()
//                                .font(.title3)
//                        }
//                        .frame(maxWidth: .infinity)
//                        .contentShape(Rectangle())
//
//                        AwattarBasicEnergyChargePriceSetting()
//                    }
//                } else {
//                    VStack(alignment: .center, spacing: 15) {
//                        Image(systemName: "multiply.circle")
//                            .resizable()
//                            .scaledToFit()
//                            .frame(width: 60, height: 60, alignment: .center)
//                            .padding(.top, 5)
//                            .foregroundColor(Color.red)
//
//                        Text("general.none")
//                            .bold()
//                            .font(.title3)
//                    }
//                }
//            }
//            .padding(.top, 10)
//            .padding(.bottom, 10)
//        }
//    }
// }
//
// struct AwattarTarifSelectionSettings_Previews: PreviewProvider {
//    static var previews: some View {
//        NavigationView {
//            AwattarTariffSelectionSetting()
//                .environmentObject(BackendCommunicator())
//                .environmentObject(CurrentSetting(managedObjectContext: PersistenceManager().persistentContainer.viewContext))
//        }
//    }
// }
