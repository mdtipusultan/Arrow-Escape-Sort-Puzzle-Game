import SwiftUI
import UIKit

/// Sets a `ScrollView`'s content offset from inside its content tree.
/// `ScrollViewReader.scrollTo` cannot target `.position`ed map nodes, so Journey
/// was landing ~38% down the canvas (around level 125) instead of the current level.
struct MapScrollOffsetController: UIViewRepresentable {
    var targetY: CGFloat
    var contentHeight: CGFloat
    var animated: Bool
    var applyToken: String
    var onApplied: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.isUserInteractionEnabled = false
        view.backgroundColor = .clear
        view.isAccessibilityElement = false
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.onApplied = onApplied
        context.coordinator.schedule(
            view: uiView,
            targetY: targetY,
            contentHeight: contentHeight,
            animated: animated,
            token: applyToken
        )
    }

    @MainActor
    final class Coordinator {
        var onApplied: (() -> Void)?
        private var lastToken: String?
        private var lastSuccessfulToken: String?

        func schedule(
            view: UIView,
            targetY: CGFloat,
            contentHeight: CGFloat,
            animated: Bool,
            token: String
        ) {
            if lastSuccessfulToken == token { return }
            lastToken = token
            attempt(
                view: view,
                targetY: targetY,
                contentHeight: contentHeight,
                animated: animated,
                token: token,
                remaining: 20
            )
        }

        private func attempt(
            view: UIView,
            targetY: CGFloat,
            contentHeight: CGFloat,
            animated: Bool,
            token: String,
            remaining: Int
        ) {
            guard lastToken == token else { return }

            let finish = {
                self.lastSuccessfulToken = token
                self.onApplied?()
            }

            guard remaining > 0 else {
                finish()
                return
            }

            guard let scrollView = view.mapScrollView(matchingContentHeight: contentHeight),
                  scrollView.bounds.height > 1,
                  scrollView.contentSize.height >= contentHeight * 0.8
            else {
                let delay = remaining > 14 ? 0 : 20
                Task { @MainActor [weak self] in
                    if delay > 0 {
                        try? await Task.sleep(for: .milliseconds(delay))
                    }
                    self?.attempt(
                        view: view,
                        targetY: targetY,
                        contentHeight: contentHeight,
                        animated: animated,
                        token: token,
                        remaining: remaining - 1
                    )
                }
                return
            }

            let y = MapScrollPositioning.offset(
                targetY: targetY,
                contentHeight: scrollView.contentSize.height,
                viewportHeight: scrollView.bounds.height
            )
            if abs(scrollView.contentOffset.y - y) > 1 {
                scrollView.setContentOffset(CGPoint(x: scrollView.contentOffset.x, y: y), animated: animated)
            }
            finish()
        }
    }
}

private extension UIView {
    func mapScrollView(matchingContentHeight contentHeight: CGFloat) -> UIScrollView? {
        var current: UIView? = self
        while let view = current {
            if let scrollView = view as? UIScrollView {
                return scrollView
            }
            if let scrollView = view.subviews.compactMap({ $0 as? UIScrollView }).first {
                return scrollView
            }
            current = view.superview
        }
        return window?.tallestScrollView(nearHeight: contentHeight)
    }

    func tallestScrollView(nearHeight contentHeight: CGFloat) -> UIScrollView? {
        var matches: [UIScrollView] = []
        collectScrollViews(into: &matches)
        return matches
            .filter { $0.contentSize.height >= min(contentHeight * 0.8, 2_000) }
            .max(by: { $0.contentSize.height < $1.contentSize.height })
    }

    func collectScrollViews(into matches: inout [UIScrollView]) {
        if let scrollView = self as? UIScrollView {
            matches.append(scrollView)
        }
        for subview in subviews {
            subview.collectScrollViews(into: &matches)
        }
    }
}
