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

struct PricesWidgetView_GraphView_BarsView: View {
    let graph: PricesWidgetView_GraphView.PricesGraph
    let geometry: GeometryProxy
    
    var partitionLines: [Double] {
        var lines = graph.partitionLines
        lines.append(0)
        return lines
    }
    
    var body: some View {
        ZStack {
            // Bars
            HStack(alignment: .bottom, spacing: graph.barSpacing) {
                ForEach(graph.energyPrices, id: \.startTime) { pricePoint in
                    let barWidth = graph.calculateBarWidth(maxWidth: geometry.size.width)
                    let barHeight = graph.calculateBarHeight(price: pricePoint.marketprice, maxHeight: geometry.size.height)
                    
                    PricesWidgetView_BarView(isNegative: pricePoint.marketprice.sign == .minus)
                        .frame(width: barWidth, height: barHeight.magnitude)
                        .position(x: barWidth/2, y: -(barHeight/2)+graph.getYCoodinate(forPrice: 0, maxHeight: geometry.size.height))
                }
            }
            
            // Lines
            ZStack {
                ForEach(partitionLines.indices, id: \.self) { lineIndex in
                    let linePrice = partitionLines[lineIndex]

                    Rectangle()
                        .frame(width: geometry.size.width, height: 1.1)
                        .foregroundColor(.gray)
                        .opacity(0.5)
                        .position(x: geometry.size.width/2, y: graph.getYCoodinate(forPrice: linePrice, maxHeight: geometry.size.height))
                }
            }
        }
    }
}

struct AxisTextViewModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 13))
    }
}

struct PricesWidgetView_GraphView_YTextView: View {
    let graph: PricesWidgetView_GraphView.PricesGraph
    
    let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.alwaysShowsDecimalSeparator = false
        formatter.maximumFractionDigits = 0
        return formatter
    }()
    
    var body: some View {
        ZStack {
            ForEach(graph.partitionLines.indices, id: \.self) { lineIndex in
                let linePrice = graph.partitionLines[lineIndex]
                Text(format(price: linePrice))
                    .modifier(AxisTextViewModifier())
            }
        }
        .frame(maxHeight: .infinity)
        .hidden()
        .overlay {
            GeometryReader { geometry in
                ForEach(graph.partitionLines.indices, id: \.self) { lineIndex in
                    let linePrice = graph.partitionLines[lineIndex]

                    Text(format(price: linePrice))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .position(x: geometry.size.width/2, y: graph.getYCoodinate(forPrice: linePrice, maxHeight: geometry.size.height))
                        .modifier(AxisTextViewModifier())
                }
            }
        }
    }
    
    func format(price: Double) -> String {
        numberFormatter.string(from: price as NSNumber) ?? ""
    }
}

struct PricesWidgetView_GraphView_XTextView: View {
    let graph: PricesWidgetView_GraphView.PricesGraph
    
    let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "H"
        return dateFormatter
    }()
    
    var body: some View {
        ZStack {
            ForEach(graph.namedHours, id: \.self) { hourIndex in
                Text(format(hour: graph.energyPrices[hourIndex].startTime))
                    .modifier(AxisTextViewModifier())
            }
        }
        .frame(maxWidth: .infinity)
        .hidden()
        .overlay {
            GeometryReader { geometry in
                ForEach(graph.namedHours, id: \.self) { hourIndex in
                    Text(hourIndex.description)
                        .position(x: 0.3+graph.getXCoordinate(forHourIndex: hourIndex, maxWidth: geometry.size.width), y: geometry.size.height/2)
                        .modifier(AxisTextViewModifier())
                }
            }
        }
    }
    
    func format(hour: Date) -> String {
        dateFormatter.string(from: hour)
    }
}

struct PricesWidgetView_GraphView: View {
    struct PricesGraph {
        enum ValueRange {
            case positive, negative, positiveAndNegative
        }
        
        let energyPrices: [EnergyPricePoint]
        
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
        
        var partitionLines: [Double] {
            var lines: [Double] = []
            for x in stride(from: 0, to: partitionAmount+1, by: 1) {
                lines.append(minGraphPrice+x*partitionStep)
            }
            return lines
        }
        
        let namedHoursOffset = 3
        /// The hours which are marked on the x axis.
        var namedHours: [Int] {
            var namedHours = [Int]()
            // Select every [namedHoursOffset] price point.
            for pricePointIndex in energyPrices.indices {
                if (pricePointIndex % namedHoursOffset) == 0 {
                    namedHours.append(pricePointIndex)
                }
            }
            return namedHours
        }
        
        let barSpacing: CGFloat = 1.8
        
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
        
        func calculatePositiveStartHeight(maxHeight: CGFloat) -> CGFloat {
            return maxHeight-calculateBarHeight(price: minGraphPrice, maxHeight: maxHeight).magnitude
        }
        
        func calculateBarWidth(maxWidth: CGFloat) -> CGFloat {
            let widthAvailable = maxWidth - barSpacing * CGFloat(energyPrices.count-1)
            return widthAvailable / CGFloat(energyPrices.count)
        }
        
        func calculateBarHeight(price: Double, maxHeight: CGFloat) -> CGFloat {
            return maxHeight * (price / self.priceRange)
        }
        
        func getYCoodinate(forPrice price: Double, maxHeight: CGFloat) -> CGFloat {
            let positiveStartHeight = calculatePositiveStartHeight(maxHeight: maxHeight)
            let priceBarHeight = calculateBarHeight(price: price, maxHeight: maxHeight)
            return positiveStartHeight - priceBarHeight
        }
        
        func getXCoordinate(forHourIndex hourIndex: Int, maxWidth: CGFloat) -> CGFloat {
            let barWidth = calculateBarWidth(maxWidth: maxWidth)
            
            return barWidth/2+CGFloat(hourIndex)*(barWidth+barSpacing)
        }
    }

    let graph: PricesGraph
    
    init(energyPrices: [EnergyPricePoint]) {
        self.graph = PricesGraph(energyPrices: energyPrices)
    }
    
    var body: some View {
        VStack(spacing: 5) {
            HStack(spacing: 3) {
                PricesWidgetView_GraphView_YTextView(graph: graph)
                
                GeometryReader { geometry in
                    PricesWidgetView_GraphView_BarsView(graph: graph, geometry: geometry)
                }
            }
            
            HStack(spacing: 3) {
                PricesWidgetView_GraphView_YTextView(graph: graph)
                    .frame(maxHeight: 0)
                    .hidden()
                PricesWidgetView_GraphView_XTextView(graph: graph)
            }
        }
    }
}

extension HorizontalAlignment {
    struct MidAccountAndName: AlignmentID {
        static func defaultValue(in d: ViewDimensions) -> CGFloat {
            d[.top]
        }
    }

    static let midAccountAndName = HorizontalAlignment(MidAccountAndName.self)
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
                PricesWidgetView_GraphView(energyPrices: next24hPrices)
                    .padding(.top, 5)
            }
        }
        .padding([.top, .bottom, .leading, .trailing], 16)
    }
}


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
