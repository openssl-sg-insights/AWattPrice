//
//  EnergyData.swift
//  AWattPrice
//
//  Created by Léon Becker on 13.08.21.
//

import Combine
import Foundation

struct EnergyPricePoint: Decodable {
    var startTime: Date
    var endTime: Date
    var marketprice: Double
    
    enum CodingKeys: String, CodingKey {
        case startTime = "start_timestamp"
        case endTime = "end_timestamp"
        case marketprice
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        startTime = try values.decode(Date.self, forKey: .startTime)
        endTime = try values.decode(Date.self, forKey: .endTime)
        
        var decodedMarketprice = try values.decode(Double.self, forKey: .marketprice)
        decodedMarketprice = decodedMarketprice.euroMWhToCentkWh
        if decodedMarketprice.isZero, decodedMarketprice.sign == .minus {
            decodedMarketprice = abs(decodedMarketprice)
        }
        marketprice = decodedMarketprice
    }
    
    static let marketpricesAreInIncreasingOrder: (EnergyPricePoint, EnergyPricePoint) -> Bool = { lhsPricePoint, rhsPricePoint in
        rhsPricePoint.marketprice > lhsPricePoint.marketprice ? true : false
    }
}

struct EnergyData: Decodable {
    let prices: [EnergyPricePoint]

    /// Prices which have start equal or past the start of the current hour.
    let currentPrices: [EnergyPricePoint]
    /// Current prices cheapest price point.
    let minCostPricePoint: EnergyPricePoint?
    /// Current prices expensivest
    let maxCostPricePoint: EnergyPricePoint?
    /// Current prices time range from the start time of the earliest to the end time of the latest price point.
    let minMaxTimeRange: ClosedRange<Date>?

    enum CodingKeys: CodingKey {
        case prices
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        prices = try values.decode([EnergyPricePoint].self, forKey: .prices)
        
        let now = Date()
        let hourStart = Calendar.current.startOfHour(for: now)
        currentPrices = prices
            .compactMap { $0.startTime >= hourStart ? $0 : nil }
            .sorted { lhsPricePoint, rhsPricePoint in
                rhsPricePoint.startTime > lhsPricePoint.startTime ? true : false
            }

        minCostPricePoint = currentPrices.min(by: EnergyPricePoint.marketpricesAreInIncreasingOrder)
        maxCostPricePoint = currentPrices.max(by: EnergyPricePoint.marketpricesAreInIncreasingOrder)
        
        if let firstCurrentPrice = currentPrices.first,
           let lastCurrentPrice = currentPrices.last
        {
            minMaxTimeRange = firstCurrentPrice.startTime...lastCurrentPrice.endTime
        } else {
            minMaxTimeRange = nil
        }
    }
    
    static func jsonDecoder() -> JSONDecoder {
        let jsonDecoder = JSONDecoder()
        jsonDecoder.dateDecodingStrategy = .secondsSince1970
        return jsonDecoder
    }
    
    static func download(region: Region) -> AnyPublisher<EnergyData, Error> {
        let apiClient = APIClient()
        let energyDataRequest = APIRequestFactory.energyDataRequest(region: region)
        return apiClient.request(to: energyDataRequest)
    }
}

