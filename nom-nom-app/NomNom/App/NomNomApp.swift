import SwiftUI

@main
struct NomNomApp: App {
    @State private var auth = AuthModel()
    @State private var recipesRefresh = RecipesRefresh()
    @State private var pcosStore = PCOSSettingsStore.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(auth)
                .environment(recipesRefresh)
                .environment(pcosStore)
                .task {
                    await auth.start()
                    if let userID = auth.user?.id {
                        await pcosStore.loadSettings(userID: userID)
                    }
                }
        }
    }
}
