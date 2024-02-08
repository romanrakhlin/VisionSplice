import SwiftUI

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            EditorView(sourceItem: UIImage(named: "Pumpkin")!)
                .preferredColorScheme(.light)
        }
    }
}
