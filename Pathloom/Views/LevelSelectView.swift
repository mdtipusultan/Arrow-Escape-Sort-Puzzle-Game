import SwiftUI

struct LevelSelectView: View {
    var focusLevelID: Int? = nil
    var onSelect: (Int) -> Void

    var body: some View {
        LevelMapView(focusLevelID: focusLevelID, onSelect: onSelect)
    }
}
