import SwiftUI

struct HomeHeaderView: View {
    let completedCount: Int
    let totalLevels: Int
    var onSettings: () -> Void

    @Environment(AppServices.self) private var services

    var body: some View {
        HStack(alignment: .center, spacing: PathloomSpacing.sm) {
            PathloomLogo(header: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            if totalLevels > 0 {
                Text("\(completedCount)/\(totalLevels)")
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                    .foregroundStyle(PathloomPalette.mutedText)
                    .monospacedDigit()
                    .accessibilityLabel("\(completedCount) of \(totalLevels) levels completed")
            }

            Button {
                services.audio.play(.buttonTap)
                services.haptics.lightTap()
                onSettings()
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(PathloomPalette.primary)
                    .frame(width: AppConstants.minimumTouchTarget, height: AppConstants.minimumTouchTarget)
                    .background(PathloomPalette.card, in: Circle())
            }
            .buttonStyle(ScalePressButtonStyle())
            .accessibilityLabel("Settings")
            .accessibilityHint("Opens game settings")
        }
    }
}
