import SwiftUI
import Combine

struct ProjectsView: View {
    
    @StateObject private var projectsViewModel = ProjectsViewModel()
    @StateObject private var cameraViewModel = CameraViewModel()
    @StateObject private var shareViewModel = ShareViewModel()
    
    @State private var isCameraPresented = false
    @State private var isEditorPresented = false
    @State private var isSharePresented = false
    
    @State private var sourceItem: FrameItemSource?
    
    let columns = [
        GridItem(.flexible(minimum: 64), spacing: 12),
        GridItem(.flexible(minimum: 64), spacing: 12),
        GridItem(.flexible(minimum: 64), spacing: 12),
        GridItem(.flexible(minimum: 64), spacing: 12)
    ]
    
    var body: some View {
        ZStack {
            VStack {
                HStack {
                    Text("Projects")
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                .padding(.bottom, 14)
                .padding(.horizontal, 20)
                
                ScrollView(showsIndicators: false) {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(projectsViewModel.results, id: \.id) { result in
                            ResulItemView(result: result)
                                .onTapGesture {
                                    shareViewModel.setPlayerItemWith(url: result.video)
                                    isSharePresented = true
                                }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 14)
                    .padding(.horizontal, 20)
                }
                .background(Constants.backgroundColor)
            }
            .background(Constants.secondaryColor)
            
            VStack {
                Spacer()
                
                Button {
                    isCameraPresented = true
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Constants.primaryColor)
                            .frame(minHeight: 32, maxHeight: 60)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                        
                        Text("Create New Video")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .background(Constants.secondaryColor)
                }
                .padding(.top, 16)
            }
        }
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
                .environmentObject(projectsViewModel)
                .environmentObject(cameraViewModel)
                .onDisappear { self.sourceItem = nil }
            }
        }
        .fullScreenCover(isPresented: $isSharePresented) {
            ShareView(viewModel: shareViewModel)
                .onDisappear { shareViewModel.invalidatePlayerItem() }
        }
    }
}