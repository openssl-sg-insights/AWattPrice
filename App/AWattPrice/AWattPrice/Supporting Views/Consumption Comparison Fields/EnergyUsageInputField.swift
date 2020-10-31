//
//  EnergyUsageInputField.swift
//  AWattPrice
//
//  Created by Léon Becker on 30.10.20.
//

import SwiftUI

/// Input field for the energy usage which the consumer shall consume
struct EnergyUsageInputField: View {
    @EnvironmentObject var cheapestHourManager: CheapestHourManager
    
    let emptyFieldError: Bool
    let wrongInputError: Bool
    
    init(errorValues: [Int]) {
        if errorValues.contains(3) {
            emptyFieldError = true
            wrongInputError = false
        } else if errorValues.contains(4) {
            emptyFieldError = false
            wrongInputError = true
        } else {
            emptyFieldError = false
            wrongInputError = false
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("totalConsumption")
                    .font(.title3)
                    .bold()
                Spacer()
            }
            
            HStack {
                TextField("inKwh", text: $cheapestHourManager.energyUsageString.animation())
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.leading)
                    .padding(.trailing, 5)
                
                if cheapestHourManager.energyUsageString != "" {
                    Text("kWh")
                        .transition(.opacity)
                }
            }
            .padding(.leading, 17)
            .padding(.trailing, 14)
            .padding([.top, .bottom], 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke((emptyFieldError || wrongInputError) ? Color.red : Color(hue: 0.0000, saturation: 0.0000, brightness: 0.8706), lineWidth: 2)
            )
            
            if emptyFieldError {
                Text("emptyFieldError")
                    .font(.caption)
                    .foregroundColor(Color.red)
            }
            
            if wrongInputError {
                Text("wrongInputError")
                    .font(.caption)
                    .foregroundColor(Color.red)
            }
        }
        .frame(maxWidth: .infinity)
    }
}


struct EnergyUsageField_Previews: PreviewProvider {
    static var previews: some View {
        EnergyUsageInputField(errorValues: [])
            .environmentObject(CheapestHourManager())
    }
}
