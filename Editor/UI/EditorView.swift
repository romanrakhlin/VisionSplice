//
//  EditorView.swift
//  
//
//  Created by Roman Rakhlin on 2/6/24.
//

import SwiftUI

struct EditorView: View {
    
    @Environment(\.presentationMode) var presentationMode
    
    @EnvironmentObject var cameraViewModel: CameraViewModel
    
    var sourceItem: FrameItemSource
    
    @StateObject private var videoViewModel = VideoViewModel()
    @StateObject private var playerViewModel = VideoPlayerViewModel()
    @ObservedObject var shareViewModel: ShareViewModel
    
    @State var selectedFrame: (any FrameItem)?
    
    @State var isCreatePresented = false
    @State var isActionsSheetPresented = false
    @Binding var isSharePresented: Bool
    
    @State private var playerView: VideoPlayerView?
    
    var body: some View {
        VStack {
            ZStack {
                HStack(alignment: .center) {
                    Button {
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .resizable()
                            .frame(width: 18, height: 18)
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Button {
                        playerViewModel.pause()
                        
                        Task(priority: .userInitiated) {
                            let playerItem = try await videoViewModel.export()
                            shareViewModel.playerItem = playerItem
                        }
                        
                        presentationMode.wrappedValue.dismiss()
                        isSharePresented = true
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
                                    .progressViewStyle(.circular)
                                Spacer()
                            }
                            Spacer()
                        }
                    } else {
                        if !videoViewModel.items.isEmpty {
                            playerView
                        } else {
                            Spacer()
                        }
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
                cameraViewModel: cameraViewModel,
                videoModel: videoViewModel,
                selectedFrame: $selectedFrame,
                isCreatePresented: $isCreatePresented,
                isActionsSheetPresented: $isActionsSheetPresented
            )
            .actionSheet(isPresented: $isActionsSheetPresented) {
                ActionSheet(title: Text("Manipulate frame"), message: nil, buttons: [
                    .default(Text("Replace"), action: {
                        isCreatePresented = true
                    }),
                    .destructive(Text("Remove"), action: {
                        guard 
                            let selectedFrame,
                            let indexToRemove = videoViewModel.indexForItem(selectedFrame)
                        else { return }
                        
                        videoViewModel.removeItem(at: indexToRemove)
                    }),
                    .cancel()
                ])
            }
        }
        .background(Constants.backgroundColor)
        .onAppear {
            playerView = VideoPlayerView(viewModel: playerViewModel)
            appendItem(with: sourceItem)
        }
        .fullScreenCover(isPresented: $isCreatePresented) {
            CameraView(viewModel: cameraViewModel)
        }
        .onChange(of: cameraViewModel.isFinished) { isFinished in
            guard isFinished else { return }
            
            if 
                let selectedFrame,
                let selectedIndex = videoViewModel.indexForItem(selectedFrame)
            { // In case of replace
                if let asset = cameraViewModel.selectedAsset {
                    replaceItem(with: asset, at: selectedIndex)
                } else if let image = cameraViewModel.selectedImage {
                    replaceItem(with: image, at: selectedIndex)
                }
            } else { // In case of append
                if let asset = cameraViewModel.selectedAsset {
                    appendItem(with: asset)
                } else if let image = cameraViewModel.selectedImage {
                    appendItem(with: image)
                }
            }
        }
    }
    
    private func appendItem(with sourceItem: FrameItemSource) {
        Task(priority: .userInitiated) {
            do {
                try await videoViewModel.append(from: sourceItem)
            } catch {
                let nsError = error as NSError
                let description = nsError.localizedRecoverySuggestion ?? nsError.localizedDescription

                // TODO: - show fail alert here
                assertionFailure(error.localizedDescription)
            }
            
            if videoViewModel.items.count == 1 {
                await MainActor.run {
                    self.updatePlayer()
                }
            }
        }
    }
    
    private func replaceItem(with sourceItem: FrameItemSource, at index: Int) {
        Task(priority: .userInitiated) {
            do {
                try await videoViewModel.replaceItem(at: index, with: sourceItem)
            } catch {
                let nsError = error as NSError
                let description = nsError.localizedRecoverySuggestion ?? nsError.localizedDescription

                // TODO: - show fail alert here
                assertionFailure(error.localizedDescription)
            }
        }
    }
    
    private func updatePlayer() {
        playerViewModel.playerItem = videoViewModel.createPlayerItem
    }
}
