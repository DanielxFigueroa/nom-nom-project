import Foundation
import Observation

/// A lightweight app-wide signal that recipe data changed (created / updated /
/// deleted / favorited). Recipe list screens observe `token` and reload when it
/// changes, so mutations made on one screen reflect on the others without a
/// manual pull-to-refresh.
@MainActor
@Observable
final class RecipesRefresh {
    private(set) var token = 0

    func trigger() {
        token &+= 1
    }
}
