import SwiftUI

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ProjectsView()
//            EditorView(sourceItem: UIImage(named: "Pumpkin")!)
                .preferredColorScheme(.dark)
        }
    }
}
