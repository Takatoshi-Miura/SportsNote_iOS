import SwiftUI

// 基本情報セクション
struct BasicInfoSection: View {
    @Binding var date: Date
    @Binding var selectedWeather: Weather
    @Binding var temperature: Int
    let onUpdate: () -> Void

    var body: some View {
        Section(header: Text(LocalizedStrings.basicInfo)) {
            // 日付
            DatePicker(
                LocalizedStrings.date,
                selection: $date,
                displayedComponents: [.date]
            )
            .onChange(of: date) { _ in
                onUpdate()
            }

            // 天気
            HStack {
                Text(LocalizedStrings.weather)
                Spacer()
                Picker("", selection: $selectedWeather) {
                    ForEach(Weather.allCases, id: \.self) { weather in
                        HStack {
                            Image(systemName: weather.icon)
                            Text(weather.title)
                        }
                        .tag(weather)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .onChange(of: selectedWeather) { _ in
                    onUpdate()
                }
            }

            // 気温
            HStack {
                Text(LocalizedStrings.temperature)
                Spacer()
                Stepper("\(temperature) °C", value: $temperature, in: -30...50)
                    .onChange(of: temperature) { _ in
                        onUpdate()
                    }
            }
        }
    }
}
