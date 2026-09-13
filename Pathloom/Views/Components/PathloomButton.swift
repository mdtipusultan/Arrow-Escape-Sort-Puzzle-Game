import SwiftUI

struct PathloomButton: View {
    let title: String
    var systemImage: String? = nil
    var prominent: Bool = true
    let action: () -> Void

    @Environment(AppServices.self) private var services

    var body: some View {
        Button {
            services.audio.play(.buttonTap)
            services.haptics.selection()
            action()
        } label: {
            HStack(spacing: 8) {
                if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title)
                    .font(.system(.headline, design: .rounded).weight(.semibold))
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: AppConstants.minimumTouchTarget)
            .padding(.vertical, 6)
            .foregroundStyle(prominent ? Color.white : PathloomPalette.primary)
            .background(
                RoundedRectangle(cornerRadius: PathloomRadius.medium, style: .continuous)
                    .fill(prominent ? PathloomPalette.primary : PathloomPalette.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: PathloomRadius.medium, style: .continuous)
                    .stroke(PathloomPalette.primary.opacity(prominent ? 0 : 0.25), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(.isButton)
    }
}
