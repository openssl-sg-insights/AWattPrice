//
//  EnergyPriceGraph.swift
//  AwattarApp
//
//  Created by Léon Becker on 08.09.20.
//

import CoreHaptics
import SwiftUI

struct GraphHeader: View {
    var body: some View {
        HStack {
            Text("centPerKwh")

            Spacer()

            Text("hourOfDay")
        }
        .font(.subheadline)
    }
}

/// Some single bar settings which is used by each bar
class SingleBarSettings: ObservableObject {
    var centFormatter: NumberFormatter
    var hourFormatter: DateFormatter
    
    var minPrice: Float
    var maxPrice: Float
    
    init(minPrice: Float, maxPrice: Float) {
        centFormatter = NumberFormatter()
        centFormatter.numberStyle = .currency
        centFormatter.currencySymbol = "ct"
        centFormatter.maximumFractionDigits = 2
        centFormatter.minimumFractionDigits = 2
        
        hourFormatter = DateFormatter()
        hourFormatter.dateFormat = "H"
        
        self.minPrice = minPrice
        self.maxPrice = maxPrice
    }
}

/// The interactive graph drawn on the home screen displaying the price for each hour throughout the day
struct EnergyPriceGraph: View {
    @Environment(\.scenePhase) var scenePhase
    
    @EnvironmentObject var awattarData: AwattarData
    @EnvironmentObject var currentSetting: CurrentSetting
    
    @State var graphHourPointData = [(EnergyPricePoint, CGFloat)]()
    @State var hapticEngine: CHHapticEngine? = nil
    @State var currentPointerIndexSelected: Int? = nil
    @State var singleHeight: CGFloat = 0
    @State var singleBarSettings: SingleBarSettings? = nil
    @State var dateMarkPointIndex: Int? = nil
    
    func setGraphValues(energyData: EnergyData, geometry: GeometryProxy) {
        self.singleBarSettings = SingleBarSettings(minPrice: energyData.minPrice, maxPrice: energyData.maxPrice)

        self.singleHeight = geometry.size.height / CGFloat(energyData.prices.count)

        if self.singleHeight != 0 {
            self.graphHourPointData = []
            self.dateMarkPointIndex = nil
            
            let firstItemDate = Date(timeIntervalSince1970: TimeInterval(energyData.prices[0].startTimestamp))
            var currentHeight: CGFloat = 0
            
            for hourPointEntry in energyData.prices {
                graphHourPointData.append((hourPointEntry, currentHeight))
                
                let currentItemDate = Date(timeIntervalSince1970: TimeInterval(hourPointEntry.startTimestamp))

                if !(Calendar.current.compare(firstItemDate, to: currentItemDate, toGranularity: .day) == .orderedSame) && self.dateMarkPointIndex == nil {
                    self.dateMarkPointIndex = Int((currentHeight / singleHeight).rounded(.up))
                }
                 
                currentHeight += singleHeight
            }
        }
    }
    
    func initCHEngine() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        
        do {
            self.hapticEngine = try CHHapticEngine()
            do {
                try hapticEngine?.start()
            } catch {
                self.hapticEngine = nil
            }
        } catch {
            print("There was an error initiating the engine: \(error)")
        }
    }
    
    func shortTapHaptic() {
        guard (self.hapticEngine != nil) else { return }
    
        var hapticEvents = [CHHapticEvent]()
        
        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.4)
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.6)
        let hapticEvent = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0)
        hapticEvents.append(hapticEvent)
        
        do {
            let pattern = try CHHapticPattern(events: hapticEvents, parameters: [])
            let player = try hapticEngine!.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            print("Failed to play haptic pattern: \(error)")
        }
    }
    
    var body: some View {
        // The drag gesture responsible for making the graph interactive.
        // It gets active when the user presses anywhere on the graph.
        // After that the gesture calculates the bar which the user pressed on. This bar and its
        // associated text is than resized to be larger. This is used to display many
        // bars on one screen and still ensure that they can be easily recognized

        let graphDragGesture = DragGesture(minimumDistance: 0)
            .onChanged { location in
                let locationHeight = location.location.y
                
                var newPointerIndexSelected: Int? = Int(((locationHeight / singleHeight) - 1).rounded(.up))

                if newPointerIndexSelected != nil {
                    if newPointerIndexSelected! < 0 || newPointerIndexSelected! > graphHourPointData.count - 1 {
                        newPointerIndexSelected = nil
                    }
                    
                    if newPointerIndexSelected != currentPointerIndexSelected {
                        shortTapHaptic()
                    }
                }
                
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentPointerIndexSelected = newPointerIndexSelected
                }
            }
            .onEnded {_ in
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentPointerIndexSelected = nil
                }
            }
        
        GeometryReader { geometry in
            ZStack {
                if singleBarSettings != nil {
                    ForEach(0..<graphHourPointData.count, id: \.self) { hourPointIndex -> EnergyPriceSingleBar in
                        EnergyPriceSingleBar(
                            singleBarSettings: singleBarSettings!,
                            width: geometry.size.width,
                            height: singleHeight,
                            startHeight: graphHourPointData[hourPointIndex].1,
                            indexSelected: currentPointerIndexSelected,
                            ownIndex: hourPointIndex,
                            maxIndex: graphHourPointData.count - 1,
                            hourDataPoint: graphHourPointData[hourPointIndex].0)
                    }
                }
                if dateMarkPointIndex != nil {
                    DayMarkView(graphPointItem: graphHourPointData[dateMarkPointIndex!], indexSelected: currentPointerIndexSelected, ownIndex: dateMarkPointIndex!, maxIndex: graphHourPointData.count - 1, height: singleHeight)
                }
            }
            .drawingGroup()
            .onAppear {
                initCHEngine()
            }
            .onChange(of: awattarData.dataRetrievalError) { newValue in
                if newValue == true {
                    setGraphValues(energyData: awattarData.energyData!, geometry: geometry)
                }
            }
            .onChange(of: scenePhase) { newScenePhase in
                if newScenePhase == .active {
                    initCHEngine()
                    setGraphValues(energyData: awattarData.energyData!, geometry: geometry)
                }
            }
            .onReceive(awattarData.$energyData) { newEnergyData in
                guard let energyData = newEnergyData else { return }
                setGraphValues(energyData: energyData, geometry: geometry)
            }
        }
        .ignoresSafeArea(.keyboard) // Ignore the keyboard. Without this the graph was been squeezed together when opening the keyboard somewhere in the app
        .contentShape(Rectangle())
        .gesture(graphDragGesture)
    }
}
