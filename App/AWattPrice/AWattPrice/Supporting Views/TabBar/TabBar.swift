//
//  TabBar.swift
//  AWattPrice
//
//  Created by Léon Becker on 28.11.20.
//

import SwiftUI

struct TabBar: View {
    @Environment(\.colorScheme) var colorScheme
    
    @ObservedObject var tabBarItems = TBItems()

    var body: some View {
        VStack {
            ZStack {
                HomeView()
                    .opacity(tabBarItems.selectedItemIndex == 0 ? 1 : 0)
                        
                ConsumptionComparisonView()
                    .opacity(tabBarItems.selectedItemIndex == 1 ? 1 : 0)
            }
            
            Spacer(minLength: 0)
            ZStack {
                TBBarShape()
                    .foregroundColor(colorScheme == .light ? Color(red: 0.96, green: 0.96, blue: 0.96) : Color(red: 0.07, green: 0.07, blue: 0.07))
                    .edgesIgnoringSafeArea(.all)

                HStack {
                    ForEach(0..<tabBarItems.items.count, id: \.self) { i in
                        HStack {
                            Spacer()
                            VStack(spacing: 6) {
                                Image(systemName: tabBarItems.items[i].imageName)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 20, height: 20)

                                Text(tabBarItems.items[i].itemSubtitle)
                                    .font(.caption)
                            }
                            .foregroundColor(i == tabBarItems.selectedItemIndex ? Color.blue : Color(red: 0.56, green: 0.56, blue: 0.56))
                            Spacer()
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            tabBarItems.changeSelected(i)
                        }
                    }
                }
            }
            .frame(height: 50)
        }
    }
}

struct TabBar_Previews: PreviewProvider {
    static var previews: some View {
        TabBar()
    }
}
