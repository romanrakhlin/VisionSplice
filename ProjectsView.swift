import SwiftUI

struct ProjectsView: View {
    
    @StateObject private var cameraViewModel = CameraViewModel()
    
    @State private var isCreatePressed = false
    
    var body: some View {
        VStack {
            Button {
                isCreatePressed.toggle()
            } label: {
                Text("Press me")
            }
        }
        .fullScreenCover(isPresented: $isCreatePressed) {
            CameraView(action: { url, data in
                print(url)
                print(data.count)
            })
            .environmentObject(cameraViewModel)
        }
    }
}
