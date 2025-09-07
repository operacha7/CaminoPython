import SwiftUI

struct StandardPage<Content: View>: View {
    @EnvironmentObject var appState: AppState

    let pageName: String
    let onHome: () -> Void
    let onMenu: () -> Void
    let onSettings: () -> Void
    @ViewBuilder var content: () -> Content

    var body: some View {
        ZStack {
            // Base background
            BrandColor.background.ignoresSafeArea()

            // Main scrollable content
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    content()
                        .padding(.horizontal, Layout.horizontalPadding)
                        .padding(.bottom, Layout.footerHeight + 4) // clear footer overlay
                }
            }
        }
        // Header pinned to the top
        .safeAreaInset(edge: .top) {
            HeaderBar(pageName: pageName)
        }
        // Footer overlaid at absolute bottom (ignores bottom safe area)
        .overlay(alignment: .bottom) {
            FooterBar(onHome: onHome, onMenu: onMenu, onSettings: onSettings)
                .ignoresSafeArea(edges: .bottom)
                .padding(.bottom, -10) // tuck closer to device edge
        }
    }
}
