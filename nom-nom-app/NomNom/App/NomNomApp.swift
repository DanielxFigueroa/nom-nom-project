import SwiftUI

@main
struct NomNomApp: App {
    @State private var auth = AuthModel()
    @State private var recipesRefresh = RecipesRefresh()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(auth)
                .environment(recipesRefresh)
                .task { await auth.start() }
        }
    }
}
