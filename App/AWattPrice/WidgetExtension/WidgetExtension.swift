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

// MARK: Extensions
struct RoundedCorner: Shape {
    var radius: CGFloat
    var corners: UIRectCorner
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

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
    let isNegative: Bool
    
    init(isNegative: Bool = false) {
        self.isNegative = isNegative
    }
    
    var positiveColor = Color(red: 0.86, green: 0.65, blue: 0.24, opacity: 1.0)
    var negativeColor = Color(red: 0.15, green: 0.86, blue: 0.06, opacity: 1.0)
    
    var cornerRadiusCorners: UIRectCorner {
        if isNegative {
            return [.bottomLeft, .bottomRight]
        } else {
            return [.topLeft, .topRight]
        }
    }
    
    var body: some View {
        Rectangle()
            .fill(isNegative ? negativeColor : positiveColor)
            .cornerRadius(3, corners: cornerRadiusCorners)
    }
}

struct PricesWidgetView_ChartView: View {
    struct Graph {
        enum ValueRange {
            case positive, negative, positiveAndNegative
        }
        
        let energyPrices: [EnergyPricePoint]
        let geometry: GeometryProxy
        
        var maxPrice: Double { (energyPrices.max { $1.marketprice > $0.marketprice ? true : false })?.marketprice ?? 0 }
        var minPrice: Double { (energyPrices.min { $1.marketprice > $0.marketprice ? true : false })?.marketprice ?? 0 }
        var valueScope: ValueRange {
            if minPrice >= 0 { return .positive }
            else if maxPrice <= 0 { return .negative }
            else { return .positiveAndNegative }
        }
        
        /// The factor by which the partition step is divisable.
        var partitionFactor: Double = 5
        var partitionAmount: Double = 3
        /// Each partition's value is a multiple of this value. The step is divisable by the partition factor.
        var partitionStep: Double {
            var graphPriceRange: Double
            if valueScope == .positive {
                graphPriceRange = self.maxPrice
            } else if valueScope == .negative {
                graphPriceRange = self.minPrice.magnitude
            } else {
                let graphMinPrice = getNextPriceDivisibleByPartitionFactor(price: minPrice)
                graphPriceRange = graphMinPrice.magnitude+self.maxPrice
            }
            
            var step = graphPriceRange / self.partitionAmount
            step = getNextPriceDivisibleByPartitionFactor(price: step)
            return step
        }
        
        var priceRange: Double {
            self.partitionStep * self.partitionAmount
        }
        var minGraphPrice: Double {
            if valueScope == .positive { return 0 }
            else if valueScope == .negative { return priceRange }
            else { return getNextPriceDivisibleByPartitionFactor(price: minPrice) }
        }

        var positiveStartHeight: CGFloat {
            return geometry.size.height-calculateBarHeight(price: minGraphPrice).magnitude
        }
        
        var barSpacing: CGFloat = 1.8
        var barWidth: CGFloat {
            let widthAvailable = geometry.size.width - self.barSpacing * CGFloat(energyPrices.count-1)
            return widthAvailable / CGFloat(energyPrices.count)
        }
        
        var lines: [Double] {
            var lines: [Double] = [0]
            for x in stride(from: 0, to: partitionAmount+1, by: 1) {
                lines.append(minGraphPrice+x*partitionStep)
            }
            return lines
        }
        
        func getNextPriceDivisibleByPartitionFactor(price: Double) -> Double {
            var nextPrice = price.magnitude
            let nextPriceRemainder = nextPrice.magnitude.truncatingRemainder(dividingBy: self.partitionFactor)
            if nextPriceRemainder != 0 {
                nextPrice = (nextPrice-nextPriceRemainder)+self.partitionFactor
            }
            if price.sign == .minus {
                nextPrice.negate()
            }
            return nextPrice
        }
        
        func calculateBarHeight(price: Double) -> CGFloat {
            return geometry.size.height * (price / self.priceRange)
        }
        
        func getYCoodinate(forPrice price: Double) -> CGFloat {
            let priceBarHeight = calculateBarHeight(price: price)
            return positiveStartHeight - priceBarHeight
        }
    }
    
    let graph: Graph
    
    init(energyPrices: [EnergyPricePoint], geometry: GeometryProxy) {
        self.graph = Graph(energyPrices: energyPrices, geometry: geometry)
    }
    
    var bars: some View {
        HStack(alignment: .bottom, spacing: graph.barSpacing) {
            ForEach(graph.energyPrices, id: \.startTime) { pricePoint in
                let height = graph.calculateBarHeight(price: pricePoint.marketprice)
                
                PricesWidgetView_BarView(isNegative: pricePoint.marketprice.sign == .minus)
                    .frame(width: graph.barWidth, height: height.magnitude)
                    .position(x: graph.barWidth/2, y: -(height/2)+graph.getYCoodinate(forPrice: 0))
            }
        }
    }
    
    var lines: some View {
        ZStack {
            ForEach(graph.lines.indices, id: \.self) { lineIndex in
                let linePrice = graph.lines[lineIndex]

                Rectangle()
                    .frame(width: graph.geometry.size.width, height: 1)
                    .foregroundColor(.black)
//                    .opacity(0.5)
                    .position(x: graph.geometry.size.width/2, y: graph.getYCoodinate(forPrice: linePrice))
            }
        }
    }
    
    var body: some View {
        ZStack {
            bars
            lines
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
                GeometryReader { geometry in
                    PricesWidgetView_ChartView(energyPrices: next24hPrices, geometry: geometry)
                }
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
