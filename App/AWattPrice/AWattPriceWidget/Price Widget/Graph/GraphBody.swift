//
//  GraphBody.swift
//  AWattPriceWidgetExtension
//
//  Created by Léon Becker on 30.01.21.
//

import SwiftUI

struct GraphBody: View {
    let graphData: GraphData
    
    init(_ graphData: GraphData) {
        self.graphData = graphData
    }
    
    var body: some View {
        ZStack {
            ForEach(graphData.points, id: \.startX) { point in
                GraphPointView(
                    point,
                    graphProperties: graphData.properties
                )
            }
            
            ForEach(graphData.texts, id: \.centerX) { text in
                GraphTextView(text)
            }
        }
    }
}
