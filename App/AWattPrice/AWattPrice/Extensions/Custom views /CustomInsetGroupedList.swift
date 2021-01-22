//
//  ListItem.swift
//  AWattPrice
//
//  Created by Léon Becker on 31.10.20.
//

import SwiftUI

struct CustomInsetGroupedList<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                content
                    .padding(.top, 10)
            }
        }
        .padding(.top, 0.5)
    }
}

struct CustomInsetGroupedListItem<Content: View>: View { // All content which is parsed must only conform to View
    @Environment(\.colorScheme) var colorScheme
    let header: Text?
    let footer: Text?
    let content: Content
    var backgroundColorDisabled = false
    var backgroundColor: Color?

    init(header: Text? = nil, footer: Text? = nil, @ViewBuilder content: () -> Content) {
        self.header = header
        self.footer = footer
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if header != nil {
                header
                    .textCase(.uppercase)
                    .font(.caption)
                    .foregroundColor(Color(hue: 0.7083, saturation: 0.0312, brightness: 0.5020))
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack {
                content
            }
            .padding([.leading, .trailing], 15)
            .padding([.top, .bottom], 9)
            .frame(maxWidth: .infinity)
            .ifTrue(backgroundColorDisabled == false) { content in
                content
                    .background(colorScheme == .light ?
                        Color(red: 0.96, green: 0.95, blue: 0.97) :
                        Color(hue: 0.6667, saturation: 0.0340, brightness: 0.1424))
            }
            .cornerRadius(10)

            if footer != nil {
                footer
                    .font(.caption2)
                    .foregroundColor(Color(hue: 0.7083, saturation: 0.0213, brightness: 0.5973))
                    .lineSpacing(2)
                    .padding(.trailing, 10)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding([.leading, .trailing], 16)
    }

    func disableBackgroundColor(_ disable: Bool) -> Self {
        if disable == true {
            var copy = self
            copy.backgroundColorDisabled = true
            return copy
        } else {
            return self
        }
    }
}

struct ListItem_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            CustomInsetGroupedList {
                CustomInsetGroupedListItem(
                    header: Text("Test Header"),
                    footer: Text("Test footer")
                ) {
                    VStack {
                        Text("Test Content")
                    }
                }
            }
            .navigationBarTitle("Test")
        }
    }
}
