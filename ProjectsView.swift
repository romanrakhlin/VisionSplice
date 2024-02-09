import SwiftUI
import AVFoundation

struct ProjectsView: View {
    
    @StateObject private var cameraViewModel = CameraViewModel()
    
    @State private var isCameraPresented = false
    @State private var isEditorPresented = false
    
    private var source: FrameItemSource?
    
    let data = (1...7).map { "Item \($0)" }
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]
    
    var body: some View {
        EditorView(sourceItem: UIImage(named: "Pumpkin")!)
            .environmentObject(cameraViewModel)
//        VStack {
//            HStack {
//                Text("Projects")
//                    .font(.system(size: 40, weight: .heavy, design: .rounded))
//                    .foregroundColor(.white)
//                
//                Spacer()
//            }
//            .padding(.horizontal, 20)
//            
//            Spacer()
//            
//            ScrollView {
//                LazyVGrid(columns: columns, spacing: 20) {
//                    ForEach(data, id: \.self) { item in
//                        ZStack {
//                            RoundedRectangle(cornerRadius: 12)
//                                .fill(Constants.secondaryColor)
//                            
//                            Image(systemName: "plus")
//                                .font(.system(size: 22, weight: .bold, design: .rounded))
//                                .foregroundColor(.white)
//                        }
//                        .frame(width: 120, height: 120)
//                        .onTapGesture { isCameraPresented.toggle() }
//                    }
//                }
//                .padding(.horizontal, 20)
//            }
//            
////            Button {
////                isCreatePressed.toggle()
////            } label: {
////                Text("Press me")
////            }
//        }
//        .background(Constants.backgroundColor)
//        .fullScreenCover(isPresented: $isCameraPresented) {
//            CameraView(viewModel: cameraViewModel)
//                .onDisappear {
//                    isEditorPresented.toggle()
//                }
//        }
//        .fullScreenCover(isPresented: $isEditorPresented) {
//            if let url = cameraViewModel.previewURL {
//                EditorView(sourceItem: AVAsset(url: url))
//            }
//        }
    }
}
