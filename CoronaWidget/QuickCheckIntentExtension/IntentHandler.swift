//
//  IntentHandler.swift
//  QuickCheckIntentExtension
//
//  Created by João Gabriel Pozzobon dos Santos on 24/06/20.
//

import Intents

class IntentHandler: INExtension, ConfigurationIntentHandling {
    func provideRegionOptionsCollection(for intent: ConfigurationIntent, with completion: @escaping (INObjectCollection<Region>?, Error?) -> Void) {
        CoronaDataLoader.fetch(from: "https://api.covid19api.com/countries") { data in
            if case .success(let fetchedData) = data {
                CoronaDataLoader.parseCountries(from: fetchedData) { result in
                    if case .success(let coronaCountries) = result {
                        var regions: [Region] = coronaCountries.map { coronaCountry in
                                return Region(
                                    identifier: coronaCountry.slug,
                                    display: coronaCountry.name
                                )
                            }
                        
                        regions.insert(Region(identifier: "global", display: "Global"), at: 0)
                        let collection = INObjectCollection(items: regions)
                        completion(collection, nil)
                    }
                }
            }
        }
    }
}
