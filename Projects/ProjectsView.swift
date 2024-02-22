import SwiftUI
import Combine

struct ProjectsView: View {
    
    @StateObject private var projectsViewModel = ProjectsViewModel()
    @StateObject private var cameraViewModel = CameraViewModel()
    @StateObject private var shareViewModel = ShareViewModel()
    
    @State private var isCameraPresented = false
    @State private var isEditorPresented = false
    @State private var isSharePresented = false
    @State private var isActionSheetPresented = false
    
    @State private var sourceItem: FrameItemSource?
    @State private var resultToDelete: ResultModel?
    
    var body: some View {
        ZStack {
            VStack {
                HStack {
                    VStack(alignment: .leading) {
                        Text("🍿 My Projects")
                            .font(.system(size: 38, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                }
                .padding(.top, 40)
                .padding(.bottom, 10)
                .padding(.horizontal, 20)
                
                ZStack {
                    ScrollView(showsIndicators: false) {
                        LazyVGrid(
                            columns: Array(
                                repeating: GridItem(.flexible(minimum: 64), spacing: 16),
                                count: UIDevice.current.userInterfaceIdiom == .pad ? 4 : 2
                            ),
                            spacing: 100
                        ) {
                            ForEach(projectsViewModel.results, id: \.self) { result in
                                ResulItemView(
                                    result: result,
                                    shareViewModel: shareViewModel,
                                    isActionSheetPresented: $isActionSheetPresented,
                                    isSharePresented: $isSharePresented,
                                    resultToDelete: $resultToDelete
                                )
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.top, 10)
                        .padding(.horizontal, 20)
                        
                        Spacer(minLength: 200)
                    }
                    .actionSheet(isPresented: $isActionSheetPresented) {
                        ActionSheet(title: Text("Manipulate project"), message: nil, buttons: [
                            .destructive(Text("Delete"), action: {
                                guard let resultToDelete else { return }
                                
                                projectsViewModel.delete(result: resultToDelete)
                                self.resultToDelete = nil
                            }),
                            .cancel()
                        ])
                    }
                    
                    if projectsViewModel.results.isEmpty {
                        VStack(spacing: 4) {
                            Text("Create Your First Project")
                                .font(.system(size: 18, weight: .light, design: .rounded))
                                .foregroundColor(.white.opacity(0.4))
                            
                            Image("arrow")
                                .resizable()
                                .frame(width: 180, height: 180)
                                .scaledToFit()
                                .colorInvert()
                                .opacity(0.4)
                        }
                    }
                }
            }
            
            VStack {
                Spacer()
                
                Button {
                    Haptics.play(.medium)
                    isCameraPresented = true
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Constants.primaryColor)
                            .frame(minHeight: 32, maxHeight: 60)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                        
                        Text("Create New Video")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .background(Constants.secondaryColor)
                }
                .padding(.top, 16)
            }
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
