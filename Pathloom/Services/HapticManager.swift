import UIKit

protocol HapticPlaying: AnyObject {
    var isEnabled: Bool { get set }
    func lightTap()
    func blocked()
    func success()
    func selection()
}

@MainActor
final class HapticManager: HapticPlaying {
    var isEnabled: Bool = true

    private let light = UIImpactFeedbackGenerator(style: .light)
    private let rigid = UIImpactFeedbackGenerator(style: .rigid)
    private let notify = UINotificationFeedbackGenerator()
    private let select = UISelectionFeedbackGenerator()

    init() {
        light.prepare()
        rigid.prepare()
        notify.prepare()
        select.prepare()
    }

    func lightTap() {
        guard isEnabled else { return }
        light.impactOccurred(intensity: 0.7)
        light.prepare()
    }

    func blocked() {
        guard isEnabled else { return }
        rigid.impactOccurred(intensity: 0.55)
        rigid.prepare()
    }

    func success() {
        guard isEnabled else { return }
        notify.notificationOccurred(.success)
        notify.prepare()
    }

    func selection() {
        guard isEnabled else { return }
        select.selectionChanged()
        select.prepare()
    }
}
