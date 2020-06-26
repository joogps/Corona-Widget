//
//  CoronaDataLoader.swift
//  CoronaWidget
//
//  Created by João Gabriel Pozzobon dos Santos on 25/06/20.
//

import Foundation

struct CoronaDataLoader {
    static func fetch(from url: String, completion: @escaping (Result<Data, Error>) -> Void) {
        let dataURL = URL(string: url)!
        let task = URLSession.shared.dataTask(with: dataURL) { (data, response, error) in
            guard error == nil else {
                completion(.failure(error!))
                return
            }
            completion(.success(data!))
        }
        task.resume()
    }
    
    static func parseSummary(from data: Data, regionalData: Bool = false, completion: @escaping (Result<CoronaData, Error>) -> Void) {
        let json = try! JSONSerialization.jsonObject(with: data, options: [])
        
        var confirmed: Int
        var deaths: Int
        var recovered: Int
        
        if regionalData {
            let data = json as! [[String: Any]]
            
            if data.count > 0 {
                let latestData = data[abs(data.count-2)]
                
                confirmed = latestData["Confirmed"] as! Int
                deaths = latestData["Deaths"] as! Int
                recovered = latestData["Recovered"] as! Int
            } else {
                return
            }
        } else {
            let latestData = json as! [String: Any]
            
            confirmed = latestData["TotalConfirmed"] as! Int
            deaths = latestData["TotalDeaths"] as! Int
            recovered = latestData["TotalRecovered"] as! Int
        }
        
        let total = confirmed+deaths+recovered
        
        let coronaData = CoronaData(confirmed: confirmed, deaths: deaths, recovered: recovered, total: total)
        completion(.success(coronaData))
    }
    
    static func parseCountries(from data: Data, completion: @escaping (Result<[CoronaCountry], Error>) -> Void) {
        let json = try! JSONSerialization.jsonObject(with: data, options: []) as! [[String: Any]]
        
        let coronaCountries: [CoronaCountry] = json.map { country in
            let name = country["Country"]
            let slug = country["Slug"]
            
            return CoronaCountry(name: name as! String, slug: slug as! String)
        }
        
        completion(.success(coronaCountries))
    }
}

struct CoronaCountry {
    let name: String
    let slug: String
}
