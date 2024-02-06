import SwiftUI

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ProjectsView()
                .preferredColorScheme(.light)
        }
    }
}
