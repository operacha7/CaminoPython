import SwiftUI

struct HeaderBar: View {
    @EnvironmentObject var appState: AppState
    let pageName: String

    var body: some View {
        ZStack(alignment: .bottom) {
            // White header background reaches the top (under the Dynamic Island)
            BrandColor.headerBG
                .ignoresSafeArea(edges: .top)

            // Content row inside the header
            HStack(alignment: .bottom, spacing: 12) {
                // LEFT: App name over trip title
                VStack(alignment: .leading, spacing: 2) {
                    Text("Camino Python")
                        .font(.title2.weight(.bold))
                        .foregroundColor(BrandColor.brandText)

                    Text(appState.tripTitle)
                        .font(.headline.weight(.semibold)) // slightly smaller than "Camino Python"
                        .foregroundColor(BrandColor.titleText)
                }

                Spacer(minLength: 0)

                // RIGHT: Page name pill, aligned to bottom of the title
                Text(pageName)
                    .font(.headline.weight(.semibold))   // match trip-title size
                    .foregroundColor(BrandColor.pageNameFG)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(
                        RoundedRectangle(cornerRadius: Layout.pageNameCorner)
                            .fill(BrandColor.pageNameBG)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: Layout.pageNameCorner)
                            .stroke(BrandColor.pageNameBorder, lineWidth: 2)
                    )
                    .alignmentGuide(.bottom) { d in d[.bottom] + 1 } // subtle visual alignment tweak
            }
            .padding(.horizontal, Layout.horizontalPadding)
            .padding(.top, 6)     // breathing room under the Island
            .padding(.bottom, 10) // space before the divider
        }
        .frame(height: Layout.headerHeight)
        .overlay(Divider(), alignment: .bottom)
    }
}

#Preview {
    HeaderBar(pageName: "Settings")
        .environmentObject(AppState())
}
