//
//  QuickCheckWidget.swift
//  QuickCheckWidget
//
//  Created by João Gabriel Pozzobon dos Santos on 23/06/20.
//

import WidgetKit
import SwiftUI
import Intents

struct Provider: IntentTimelineProvider {
    public func snapshot(for configuration: ConfigurationIntent, with context: Context, completion: @escaping (CoronaDataEntry) -> ()) {
        let currentDate = Date()
        
        let configurationRegion = configuration.region?.identifier ?? "global"
        let regionalData = !(configurationRegion == "global")
        let url = "https://api.covid19api.com/" + (regionalData ?
            "total/country/\(String(describing: configurationRegion))" :
            "world/total")
        
        CoronaDataLoader.fetch(from: url) { data in
            var coronaData = CoronaData(confirmed: 0, deaths: 0, recovered: 0, total: 1)
            
            if case .success(let fetchedData) = data {
                CoronaDataLoader.parseSummary(from: fetchedData, regionalData: regionalData) { result in
                    if case .success(let finalData) = result {
                        coronaData = finalData
                    }
                }
            }
            
            let entry = CoronaDataEntry(date: currentDate, configuration: configuration, data: coronaData)
            completion(entry)
        }
    }

    public func timeline(for configuration: ConfigurationIntent, with context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let currentDate = Date()
        let refreshDate = Calendar.current.date(byAdding: .hour, value: 1, to: currentDate)!
        
        let configurationRegion = configuration.region?.identifier ?? "global"
        let regionalData = !(configurationRegion == "global")
        let url = "https://api.covid19api.com/" + (regionalData ?
            "total/country/\(String(describing: configurationRegion))" :
            "world/total")
        
        CoronaDataLoader.fetch(from: url) { data in
            var coronaData = CoronaData(confirmed: 0, deaths: 0, recovered: 0, total: 1)
            
            if case .success(let fetchedData) = data {
                CoronaDataLoader.parseSummary(from: fetchedData, regionalData: regionalData) { result in
                    if case .success(let finalData) = result {
                        coronaData = finalData
                    }
                }
            }
            
            let entry = CoronaDataEntry(date: currentDate, configuration: configuration, data: coronaData)
            let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
            completion(timeline)
        }
    }
}

struct CoronaDataEntry: TimelineEntry {
    public let date: Date
    public let configuration: ConfigurationIntent
    public let data: CoronaData
}

struct QuickCheckPlaceholderView : View {
    var body: some View {
        HStack {
            VStack (alignment: .leading) {
                StatView(text: "Confirmed", number: "-")
                Spacer()
                StatView(text: "Deaths", number: "-")
                Spacer()
                StatView(text: "Recovered", number: "-")
            }
            
            Spacer()
            
            let aThird = CGFloat(1.0/3.0)
            BarView(yellow: aThird, red: aThird, green: aThird).frame(minWidth: 0, maxWidth: 12.5)
        }.padding(24)
    }
}

struct QuickCheckWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        HStack {
            VStack (alignment: .leading) {
                let showTitle = entry.configuration.showTitle != nil && entry.configuration.showTitle == 1
                let fontSize = CGFloat(showTitle ? 13 : 14)
                
                if showTitle {
                    Text(entry.configuration.region?.displayString ?? "Global").font(.system(size: 14, weight: .heavy))
                    Spacer()
                }
                
                StatView(text: "Confirmed", number: formatNumber(number: entry.data.confirmed), fontSize: fontSize)
                if !showTitle { Spacer() }
                StatView(text: "Deaths", number: formatNumber(number: entry.data.deaths), fontSize: fontSize)
                if !showTitle { Spacer() }
                StatView(text: "Recovered", number: formatNumber(number: entry.data.recovered), fontSize: fontSize)
            }
            
            Spacer()
            
            let yellow = calculateProportion(portion: entry.data.confirmed, total: entry.data.total)
            let red = calculateProportion(portion: entry.data.deaths, total: entry.data.total)
            let green = calculateProportion(portion: entry.data.recovered, total: entry.data.total)
            BarView(yellow: yellow, red: red, green: green).frame(minWidth: 0, maxWidth: 12.5)
        }.padding(24)
    }
}

struct StatView: View {
    var text: String
    var number: String
    var fontSize: CGFloat = 14
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(text)
                .font(.system(size: fontSize, weight: .bold))
            Text(number)
                .font(.system(size: fontSize, weight: .light))
        }
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

@main
struct QuickCheckWidget: Widget {
    private let kind: String = "QuickCheckWidget"

    public var body: some WidgetConfiguration {
        IntentConfiguration(
            kind: kind,
            intent: ConfigurationIntent.self,
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
