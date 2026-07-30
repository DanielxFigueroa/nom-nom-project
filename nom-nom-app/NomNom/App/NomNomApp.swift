import SwiftUI

@main
struct NomNomApp: App {
    @State private var auth = AuthModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(auth)
                .task { await auth.start() }
        }
    }
}
