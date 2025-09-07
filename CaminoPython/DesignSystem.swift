import SwiftUI

enum BrandColor {
    // from Standard Page doc
    static let background = Color(hex: 0x4C5270) // page bg
    static let headerBG   = Color.white
    static let brandText  = Color(hex: 0x4C5270) // "Camino Python"
    static let titleText  = Color(hex: 0xCF491B) // trip title
    static let pageNameBG = Color(hex: 0xCF491B)
    static let pageNameFG = Color.white
    static let pageNameBorder = Color(hex: 0xD8E1E6)

    static let footerBG  = Color.clear           // footer sits over page bg
    static let buttonBG  = Color(hex: 0xFFC06C)
    static let buttonFG  = Color(hex: 0x4C5270)
}

// simple hex helper
extension Color {
    init(hex: UInt32, alpha: Double = 1.0) {
        let r = Double((hex & 0xFF0000) >> 16) / 255.0
        let g = Double((hex & 0x00FF00) >> 8) / 255.0
        let b = Double(hex & 0x0000FF) / 255.0
        self = Color(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}

enum Layout {
    static let headerHeight: CGFloat = 68
    static let footerHeight: CGFloat = 88
    static let horizontalPadding: CGFloat = 16
    static let pageNameCorner: CGFloat = 8
}
