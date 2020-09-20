//
//  DownloadEnergyData.swift
//  AwattarApp
//
//  Created by Léon Becker on 07.09.20.
//

import Foundation

struct AwattarDataPoint: Codable {
    var startTimestamp: Int
    var endTimestamp: Int
    var marketprice: Float
    var unit: [String]
    
    enum CodingKeys: String, CodingKey {
        case startTimestamp = "start_timestamp"
        case endTimestamp = "end_timestamp"
        case marketprice = "marketprice"
        case unit = "unit"
    }
}

struct AwattarData: Codable {
    var prices: [AwattarDataPoint]
    var minPrice: Float?
    var maxPrice: Float?
    
    enum CodingKeys: String, CodingKey {
        case prices = "prices"
        case minPrice = "min_price"
        case maxPrice = "max_price"
    }
}

struct SourcesData: Codable {
    var awattar: AwattarData
}

struct Profile: Codable, Hashable {
    var name: String
}

struct ProfilesData: Codable {
    var profiles: [Profile]
}

struct ProfileData {
    var profilesData: ProfilesData? = nil

    init() {
        var profileRequest = URLRequest(
                        url: URL(string: "https://www.space8.me:9173/awattar_app/static/chargeProfiles.json")!,
                        cachePolicy: URLRequest.CachePolicy.useProtocolCachePolicy)
        
        profileRequest.httpMethod = "GET"
        
        let _ = URLSession.shared.dataTask(with: profileRequest) { data, response, error in
            let jsonDecoder = JSONDecoder()
            var decodedData = ProfilesData(profiles: [])
            
            if let data = data {
                do {
                    decodedData = try jsonDecoder.decode(ProfilesData.self, from: data)
//                    DispatchQueue.main.async {
                        profilesData = decodedData
//                    }
                } catch {
                    fatalError("Could not decode returned JSON data from server.")
                }
            }
        }.resume()
    }
}

class EnergyData {
    var energyData: SourcesData? = nil

    init() {
        var energyRequest = URLRequest(
                        url: URL(string: "https://www.space8.me:9173/awattar_app/data/")!,
                        cachePolicy: URLRequest.CachePolicy.useProtocolCachePolicy)
        
        energyRequest.httpMethod = "GET"
        
        let _ = URLSession.shared.dataTask(with: energyRequest) { data, response, error in
            let jsonDecoder = JSONDecoder()
            var decodedData = SourcesData(awattar: AwattarData(prices: [], maxPrice: nil))
            
            if let data = data {
                do {
                    decodedData = try jsonDecoder.decode(SourcesData.self, from: data)
                    DispatchQueue.main.async {
                        self.energyData = decodedData
                    }
                } catch {
                    fatalError("Could not decode returned JSON data from server.")
                }
            }
        }.resume()
    }
}

var energyData: EnergyData = EnergyData()
