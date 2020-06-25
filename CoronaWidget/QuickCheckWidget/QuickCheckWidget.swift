//
//  QuickCheckWidget.swift
//  QuickCheckWidget
//
//  Created by João Gabriel Pozzobon dos Santos on 23/06/20.
//

import WidgetKit
import SwiftUI
import Intents

struct Provider: TimelineProvider {
    public func snapshot(with context: Context, completion: @escaping (CoronaDataEntry) -> ()) {
        let currentDate = Date()
        
        CoronaDataLoader.fetch { result in
            let data: CoronaData
            if case .success(let fetchedData) = result { data = fetchedData } else {
                data = CoronaData(confirmed: 0, deaths: 0, recovered: 0, total: 1)
            }
            let entry = CoronaDataEntry(date: currentDate, data: data)
            completion(entry)
        }
    }

    public func timeline(with context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let currentDate = Date()
        let refreshDate = Calendar.current.date(byAdding: .hour, value: 1, to: currentDate)!

        CoronaDataLoader.fetch { result in
            let data: CoronaData
            if case .success(let fetchedData) = result { data = fetchedData } else {
                data = CoronaData(confirmed: 0, deaths: 0, recovered: 0, total: 1)
            }
            let entry = CoronaDataEntry(date: currentDate, data: data)
            let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
            completion(timeline)
        }
    }
}

struct CoronaDataEntry: TimelineEntry {
    public let date: Date
    public let data: CoronaData
}

struct QuickCheckPlaceholderView : View {
    var body: some View {
        HStack {
            VStack (alignment: .leading) {
                TitleLabel(text: "Confirmed")
                NumberLabel(text: "-")
                Spacer()
                TitleLabel(text: "Deaths")
                NumberLabel(text: "-")
                Spacer()
                TitleLabel(text: "Recovered")
                NumberLabel(text: "-")
            }
            
            Spacer()
            BarView(yellow: 1.0/3.0, red: 1.0/3.0, green: 1.0/3.0).frame(minWidth: 0, maxWidth: 12.5)
        }.padding(25)
    }
}

struct QuickCheckWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        HStack {
            VStack (alignment: .leading) {
                TitleLabel(text: "Confirmed")
                NumberLabel(text: formatNumber(number: entry.data.confirmed))
                Spacer()
                TitleLabel(text: "Deaths")
                NumberLabel(text: formatNumber(number: entry.data.deaths))
                Spacer()
                TitleLabel(text: "Recovered")
                NumberLabel(text: formatNumber(number: entry.data.recovered))
            }
            
            Spacer()
            
            let yellow = calculateProportion(portion: entry.data.confirmed, total: entry.data.total)
            let red = calculateProportion(portion: entry.data.deaths, total: entry.data.total)
            let green = calculateProportion(portion: entry.data.recovered, total: entry.data.total)
            BarView(yellow: yellow, red: red, green: green).frame(minWidth: 0, maxWidth: 12.5)
        }.padding(25)
    }
}

struct TitleLabel: View {
    var text: String
    var body: some View {
        Text(text)
            .font(.system(size: 15, weight: .bold))
    }
}

struct NumberLabel: View {
    var text: String
    var body: some View {
        Text(text)
            .font(.system(size: 15, weight: .light))
    }
}

func formatNumber(number: Int) -> String {
    return String(format: "%d", locale: Locale.current, number)
}

func calculateProportion(portion: Int, total: Int) -> CGFloat {
    return CGFloat(portion) /
        CGFloat(total)
}


struct BarView: View {
    var yellow: CGFloat
    var red: CGFloat
    var green: CGFloat
    
    var body: some View {
        GeometryReader { metrics in
            VStack (alignment: .center, spacing: 0) {
                Color.yellow.frame(height: metrics.size.height * yellow)
                Color.red.frame(height: metrics.size.height * red)
                Color.green.frame(height: metrics.size.height * green)
            }.clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
        }
    }
}

struct CoronaData {
    let confirmed: Int
    let deaths: Int
    let recovered: Int
    let total: Int
}

struct CoronaDataLoader {
    static func fetch(completion: @escaping (Result<CoronaData, Error>) -> Void) {
        let coronaDataURL = URL(string: "https://api.covid19api.com/summary")!
        let task = URLSession.shared.dataTask(with: coronaDataURL) { (data, response, error) in
            guard error == nil else {
                completion(.failure(error!))
                return
            }
            let coronaData = getStatistics(fromData: data!)
            completion(.success(coronaData))
        }
        task.resume()
    }
    
    static func getStatistics(fromData data: Foundation.Data) -> CoronaData {
        let json = try! JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
        
        let global = json["Global"] as! [String: Any]
        
        print(json)
        
        let confirmed = global["TotalConfirmed"] as! Int
        let deaths = global["TotalDeaths"] as! Int
        let recovered = global["TotalRecovered"] as! Int
        
        let total = confirmed+deaths+recovered
        return CoronaData(confirmed: confirmed, deaths: deaths, recovered: recovered, total: total)
    }
}

@main
struct QuickCheckWidget: Widget {
    private let kind: String = "QuickCheckWidget"

    public var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: Provider(),
            placeholder: QuickCheckPlaceholderView()
        ) { entry in
            QuickCheckWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Quick Check")
        .description("Take a quick look at the newest COVID-19 statistics.")
        .supportedFamilies([.systemSmall])
    }
}
