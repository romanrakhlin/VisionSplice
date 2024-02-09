//
//  EditorView.swift
//  
//
//  Created by Roman Rakhlin on 2/6/24.
//

import SwiftUI

struct EditorView: View {
    
    @EnvironmentObject var cameraViewModel: CameraViewModel
    
    var sourceItem: FrameItemSource
    
    @StateObject private var videoModel = VideoModel()
    @StateObject private var playerViewModel = VideoPlayerViewModel()
    
    @State var selectedFrame: (any FrameItem)?
    
    @State var isCreatePresented = false
    @State var isActionsSheetPresented = false
    
    @State private var playerView: VideoPlayerView?
    
    var body: some View {
        VStack {
            ZStack {
                HStack(alignment: .center) {
                    Button {
                        print("Close")
                    } label: {
                        Image(systemName: "xmark")
                            .resizable()
                            .frame(width: 18, height: 18)
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Button {
                        print("Close")
                    } label: {
                        Text("Create")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(Constants.primaryColor)
                    }
                }
                
                HStack(alignment: .center) {
                    Spacer()
                    
                    Text("Editor")
                        .font(.system(size: 24, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                    
                    Spacer()
                }
            }
            .padding(.top, 10)
            .padding(.horizontal, 20)
            
            ZStack {
                ZStack {
                    if playerViewModel.assetState != .ready {
                        HStack {
                            Spacer()
                            VStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                            Spacer()
                        }
                    } else {
                        playerView
                    }
                }
                .background(Constants.secondaryColor)
                .cornerRadius(10)
                .padding(.top, 20)
                .padding(.horizontal, 80)
                
                HStack(alignment: .center) {
                    Button {
                        print("Pick music")
                    } label: {
                        Image(systemName: "music.note")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .padding()
                            .background {
                                Circle()
                                    .fill(Constants.primaryColor)
                                    .frame(width: 38, height: 38)
                            }
                    }
                    
                    Spacer()
                }
                .padding(.leading, 10)
            }
            
            FramesCarouselView(
                videoModel: videoModel, 
                selectedFrame: $selectedFrame,
                isCreatePresented: $isCreatePresented,
                isActionsSheetPresented: $isActionsSheetPresented
            )
            .actionSheet(isPresented: $isActionsSheetPresented) {
                ActionSheet(title: Text("Change this frame?"), message: nil, buttons: [
//                    .default(Text("Crop"), action: {
//                        print("Crop frame")
//                    }),
                    .default(Text("Replace"), action: {
                        print("Replace frame")
                    }),
                    .destructive(Text("Remove"), action: {
//                        guard let selectedFrame else { return }
//                        videoModel.removeItem(at: selectedFrame)
                    }),
                    .cancel()
                ])
            }
        }
        .background(Constants.backgroundColor)
        .onAppear {
            playerView = VideoPlayerView(model: playerViewModel)
            appendItem(with: sourceItem, setupPlayer: true)
        }
        .fullScreenCover(isPresented: $isCreatePresented) {
            CameraView(viewModel: cameraViewModel)
                .environmentObject(cameraViewModel)
        }
        .onChange(of: cameraViewModel.selectedAsset) { asset in
            guard let asset else { return }
            appendItem(with: asset)
        }
        .onChange(of: cameraViewModel.selectedImage) { image in
            guard let image else { return }
            appendItem(with: image)
        }
    }
    
    private func appendItem(with sourceItem: FrameItemSource, setupPlayer: Bool = false) {
        Task(priority: .userInitiated) {
            do {
                try await videoModel.append(from: sourceItem)
            } catch {
                let nsError = error as NSError
                let description = nsError.localizedRecoverySuggestion ?? nsError.localizedDescription

                // TODO: - show fail alert here
                assertionFailure(error.localizedDescription)
            }
            
            if setupPlayer {
                await MainActor.run {
                    let previewPlayerItem = videoModel.createPlayerItem
                    playerViewModel.playerItem = previewPlayerItem
                }
            }
        }
    }
}
