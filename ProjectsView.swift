import SwiftUI
import AVFoundation

struct ProjectsView: View {
    
    @StateObject private var cameraViewModel = CameraViewModel()
    @StateObject private var shareViewModel = ShareViewModel()
    
    @State private var isCameraPresented = false
    @State private var isEditorPresented = false
    @State private var isSharePresented = false
    
    @State private var sourceItem: FrameItemSource? = nil
    
    let data = (1...7).map { "Item \($0)" }
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]
    
    var body: some View {
        VStack {
//            EditorView(
//                sourceItem: UIImage(named: "Pumpkin")!,
//                shareViewModel: shareViewModel,
//                isSharePresented: $isSharePresented
//            )
//            .environmentObject(cameraViewModel)
            
            HStack {
                Text("Projects")
                    .font(.system(size: 40, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            
            Spacer()
            
            ScrollView {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(data, id: \.self) { item in
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Constants.secondaryColor)
                            
                            Image(systemName: "plus")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        .frame(width: 120, height: 120)
                        .onTapGesture { isCameraPresented = true }
                    }
                }
                .padding(.horizontal, 20)
            }
            
//            Button {
//                isCreatePressed.toggle()
//            } label: {
//                Text("Press me")
//            }
        }
        .background(Constants.backgroundColor)
        .fullScreenCover(isPresented: $isCameraPresented) {
            CameraView(viewModel: cameraViewModel)
        }
        .onChange(of: cameraViewModel.isFinished) { isFinished in
            guard isFinished else { return }
            
            if let asset = cameraViewModel.selectedAsset {
                sourceItem = asset
            } else if let image = cameraViewModel.selectedImage {
                sourceItem = image
            }
            
            isEditorPresented = true
        }
        .fullScreenCover(isPresented: $isEditorPresented) {
            if let sourceItem {
                EditorView(
                    sourceItem: sourceItem,
                    shareViewModel: shareViewModel,
                    isSharePresented: $isSharePresented
                )
                .environmentObject(cameraViewModel)
                .onDisappear { self.sourceItem = nil }
            }
        }
        .fullScreenCover(isPresented: $isSharePresented) {
            ShareView(viewModel: shareViewModel)
        }
    }
}
