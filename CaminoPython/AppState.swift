import SwiftUI

final class AppState: ObservableObject {
    @Published var tripTitle: String = "Via Francigena 2025" // update from DB after Settings save
}
