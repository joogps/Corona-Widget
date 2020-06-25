//
//  IntentHandler.swift
//  QuickCheckIntentExtension
//
//  Created by João Gabriel Pozzobon dos Santos on 24/06/20.
//

import Intents

class IntentHandler: INExtension, ConfigurationIntentHandling {
    func provideRegionOptionsCollection(for intent: ConfigurationIntent, with completion: @escaping (INObjectCollection<Region>?, Error?) -> Void) {
        CoronaCountriesLoader.fetch { result in
            switch result {
                case .success(let coronaCountries):
                    var regions: [Region] = coronaCountries.map { coronaCountry in
                                return Region(
                                    identifier: coronaCountry.slug,
                                    display: coronaCountry.name
                                )
                            }
                    
                    regions.insert(Region(identifier: "lobal", display: "Global"), at: 0)
                    let collection = INObjectCollection(items: regions)
                    completion(collection, nil)
                case .failure(let error):
                    print(error.localizedDescription)
                }
        }
    }
}

struct CoronaCountry {
    let name: String
    let slug: String
}

struct CoronaCountriesLoader {
    static func fetch(completion: @escaping (Result<[CoronaCountry], Error>) -> Void) {
        let dataURL = URL(string: "https://api.covid19api.com/summary")!
        let task = URLSession.shared.dataTask(with: dataURL) { (data, response, error) in
            guard error == nil else {
                completion(.failure(error!))
                return
            }
            let coronaData = parse(fromData: data!)
            completion(.success(coronaData))
        }
        task.resume()
    }
    
    static func parse(fromData data: Foundation.Data) -> [CoronaCountry] {
        let json = try! JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
        
        let countries = json["Countries"] as! Array<NSDictionary>
        
        let coronaCountries: [CoronaCountry] = countries.map { country in
            let name = country["Country"]
            let slug = country["Slug"]
            
            return CoronaCountry(name: name as! String, slug: slug as! String)
        }
        
        return coronaCountries
    }
}
