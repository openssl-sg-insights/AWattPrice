//
//  WidgetExtension.swift
//  WidgetExtension
//
//  Created by Léon Becker on 03.07.22.
//

import WidgetKit
import SwiftUI
//import Intents

//struct Provider: IntentTimelineProvider {
//    func placeholder(in context: Context) -> SimpleEntry {
//        SimpleEntry(date: Date(), configuration: ConfigurationIntent())
//    }
//
//    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (SimpleEntry) -> ()) {
//        let entry = SimpleEntry(date: Date(), configuration: configuration)
//        completion(entry)
//    }
//
//    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
//        var entries: [SimpleEntry] = []
//
//        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
//        let currentDate = Date()
//        for hourOffset in 0 ..< 5 {
//            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
//            let entry = SimpleEntry(date: entryDate, configuration: configuration)
//            entries.append(entry)
//        }
//
//        let timeline = Timeline(entries: entries, policy: .atEnd)
//        completion(timeline)
//    }
//}
//
//struct SimpleEntry: TimelineEntry {
//    let date: Date
//    let configuration: ConfigurationIntent
//}
//
//struct WidgetExtensionEntryView : View {
//    var entry: Provider.Entry
//
//    var body: some View {
//        Text(entry.date, style: .time)
//    }
//}
//
//struct WidgetExtension: Widget {
//    let kind: String = "WidgetExtension"
//
//    var body: some WidgetConfiguration {
//        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: Provider()) { entry in
//            WidgetExtensionEntryView(entry: entry)
//        }
//        .configurationDisplayName("My Widget")
//        .description("This is an example widget.")
//    }
//}
//
//@main
//struct Widgets: WidgetBundle {
//    @WidgetBundleBuilder
//    var body: some Widget {
//        WidgetExtension()
//    }
//}
//
//struct WidgetExtension_Previews: PreviewProvider {
//    static var previews: some View {
//        WidgetExtensionEntryView(entry: SimpleEntry(date: Date(), configuration: ConfigurationIntent()))
//            .previewContext(WidgetPreviewContext(family: .systemSmall))
//    }
//}

// MARK: Prices Widget

struct PricesWidget_TimelineEntry: TimelineEntry {
    let date: Date
    let energyData: EnergyData?
    
    static func getPlaceholderEntry() -> Self {
        let dataURL = Bundle.main.url(forResource: "Widget Placeholder Energy Prices", withExtension: "json")!
        let rawData = try! Data(contentsOf: dataURL)
        let data = try! EnergyData.jsonDecoder().decode(EnergyData.self, from: rawData)
        return PricesWidget_TimelineEntry(date: Date(), energyData: data)
    }
}

struct PricesWidget_TimelineProvider: TimelineProvider {
    typealias Entry = PricesWidget_TimelineEntry
    
    // Quickly provide example of widget. Use locally stored price data.
    func placeholder(in context: Context) -> Entry {
        return PricesWidget_TimelineEntry.getPlaceholderEntry()
    }
    
    // Provide the current price data. Use price data downloaded from the server.
    func getSnapshot(in context: Context, completion: @escaping (Entry) -> Void) {
        completion(PricesWidget_TimelineEntry.getPlaceholderEntry())
    }
    
    // Provide the points in time at which to update the widget.
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        completion(Timeline(entries: [PricesWidget_TimelineEntry.getPlaceholderEntry()], policy: .never))
    }
}

struct PricesWidgetView_BarView: View {
    var body: some View {
        Rectangle()
            .fill(Color(red: 0.86, green: 0.65, blue: 0.24, opacity: 1.0))
    }
}

struct PricesWidgetView_ChartView: View {
    let energyPrices: [EnergyPricePoint]
    
    var highestPrice: Double {
        energyPrices.max { $1.marketprice > $0.marketprice ? true : false }?.marketprice ?? 0
    }
    
    var body: some View {
        GeometryReader() { geometry in
            let barSpacing: CGFloat = 1
            
            HStack(alignment: .bottom, spacing: barSpacing) {
                ForEach(energyPrices, id: \.startTime) { pricePoint in
                    let width = (geometry.size.width - barSpacing * CGFloat(energyPrices.count-1)) / CGFloat(energyPrices.count)
                    let height = geometry.size.height * (CGFloat(pricePoint.marketprice) / CGFloat(highestPrice))

                    PricesWidgetView_BarView()
                        .frame(width: width, height: height, alignment: .bottom)
                }
            }
        }
    }
}

struct PricesWidgetView: View {
    var entry: PricesWidget_TimelineProvider.Entry
    
    var next24hPrices: [EnergyPricePoint]? {
        guard let energyData = entry.energyData else { return nil }
        return energyData.prices
    }
    
    var body: some View {
        VStack {
            HStack {
                Text("Next 24h")
                Spacer()
            }
            
            if let next24hPrices = next24hPrices {
                PricesWidgetView_ChartView(energyPrices: next24hPrices)
            }
        }
        .padding([.top, .bottom, .leading, .trailing], 16)
    }
}

struct PricesWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "AWattPrice.Widgets.PricesWidget", provider: PricesWidget_TimelineProvider()) { entry in
            PricesWidgetView(entry: entry)
        }
        .configurationDisplayName("Next 24h Prices")
        .supportedFamilies([.systemMedium])
    }
}

// MARK: Widget Bundle

@main
struct Widgets: WidgetBundle {
    @WidgetBundleBuilder
    var body: some Widget {
        PricesWidget()
    }
}

struct WidgetExtension_Preview: PreviewProvider {
    static var previews: some View {
        PricesWidgetView(entry: PricesWidget_TimelineEntry.getPlaceholderEntry())
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
