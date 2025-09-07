import SwiftUI

struct FooterBar: View {
    var onHome: () -> Void
    var onMenu: () -> Void
    var onSettings: () -> Void

    var body: some View {
        ZStack {
            BrandColor.footerBG
                .ignoresSafeArea(edges: .bottom)

            HStack(alignment: .center, spacing: 0) {
                // LEFT: Home (takes 1/3 width, centered)
                FooterButton(systemName: "house.fill", title: "Home", action: onHome)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .frame(height: Layout.footerHeight)   // equal lane height

                // CENTER: Menu pill (takes 1/3 width, centered)
                VStack(spacing: 6) {
                    Button(action: onMenu) {
                        Text("Menu")
                            .font(.headline.weight(.semibold))
                            .foregroundColor(BrandColor.buttonFG)
                            .padding(.horizontal, 16)           // more breathing room
                            .frame(minWidth: 140)               // longer pill
                            .frame(height: 32)                  // taller -> rounder capsule
                            .background(Capsule().fill(BrandColor.buttonBG))
                            .contentShape(Capsule())
                    }
                    .buttonStyle(.plain)

                    // Hidden label to match the Home/Settings vertical structure
                    Text("Menu")
                        .font(.footnote.weight(.semibold))
                        .opacity(0)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .frame(height: Layout.footerHeight)      // equal lane height

                // RIGHT: Settings (takes 1/3 width, centered)
                FooterButton(systemName: "gearshape.fill", title: "Settings", action: onSettings)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .frame(height: Layout.footerHeight)   // equal lane height
            }
            .padding(.horizontal, Layout.horizontalPadding)
            .frame(height: Layout.footerHeight)
        }
        .overlay(Divider(), alignment: .top)
        .frame(height: Layout.footerHeight)
    }
}

private struct FooterButton: View {
    let systemName: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(BrandColor.buttonBG)
                        .frame(width: 44, height: 44)
                    Image(systemName: systemName)
                        .imageScale(.medium)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(BrandColor.buttonFG)
                }
                Text(title)
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(BrandColor.buttonFG)
            }
        }
        .buttonStyle(.plain)
    }
}
