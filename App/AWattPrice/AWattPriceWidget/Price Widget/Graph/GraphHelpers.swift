//
//  GraphHelpers.swift
//  AWattPrice
//
//  Created by Léon Becker on 30.01.21.
//

import SwiftUI

class GraphPoint {
    let startX: CGFloat
    let height: CGFloat
    let marketprice: Double
    
    init(_ pointStartX: CGFloat, _ pointHeight: CGFloat, _ pointMarketprice: Double) {
        startX = pointStartX
        height = pointHeight
        marketprice = pointMarketprice
    }
}

class GraphProperties {
    /* Store in an extra class to make it easier to only parse the properties, without
     parsing all GraphPoints.
    */
    
    let allWidth: CGFloat
    let allHeight: CGFloat
    
    let pointWidth: CGFloat
    
    init(_ width: CGFloat, _ height: CGFloat, _ pointWidth: CGFloat) {
        
    }
}

class GraphData {
    /* Strictly speaking allWidth and allHeight aren't needed to be able to
     create the graph. They get stored for reference if needed elsewhere.
    */
    var properties: GraphProperties
    var points = [GraphPoint]()
    
    init(_ graphProperties: GraphProperties) {
        
    }
}

func createGraphData(
    _ energyData: EnergyData, _ geoProxy: GeometryProxy
) -> GraphData {
    let maxWidth = geoProxy.size.width
    let maxHeight = geoProxy.size.height
    let pointWidth = maxWidth / CGFloat(energyData.prices.count)
    
    let graphData = GraphData(
        GraphProperties(
            geoProxy.size.width, maxHeight, pointWidth
        )
    )
    
    var currentStartX: CGFloat = 0
    for point in energyData.prices {
        let pointHeight = (
            CGFloat(point.marketprice / energyData.maxPrice) * maxHeight
        )
        
        let graphPoint = GraphPoint(currentStartX, pointHeight, point.marketprice)
        graphData.points.append(graphPoint)
        
        currentStartX += graphData.properties.pointWidth
    }
    
    return graphData
}
