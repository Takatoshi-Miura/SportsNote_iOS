import SwiftUI

/// 目標表示
struct TargetSummaryView: View {
    let yearlyTargets: [Target]
    let monthlyTargets: [Target]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 年目標
            HStack(alignment: .top) {
                Text("\(LocalizedStrings.year):")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .frame(width: 30, alignment: .leading)

                if let title = yearlyTargets.first?.title {
                    Text(title)
                        .font(.subheadline)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Text(LocalizedStrings.notSet)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.horizontal, 8)

            // 月目標
            HStack(alignment: .top) {
                Text("\(LocalizedStrings.month):")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .frame(width: 30, alignment: .leading)

                if let title = monthlyTargets.first?.title {
                    Text(title)
                        .font(.subheadline)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Text(LocalizedStrings.notSet)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.horizontal, 8)
        }
        .padding(.vertical, 8)
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(10)
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 8)
    }
}
