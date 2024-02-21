//
//  EditorView.swift
//  
//
//  Created by Roman Rakhlin on 2/6/24.
//

import SwiftUI

struct EditorView: View {
    
    @Environment(\.presentationMode) var presentationMode
    
    @EnvironmentObject var projectsViewModel: ProjectsViewModel
    @EnvironmentObject var cameraViewModel: CameraViewModel
    
    var sourceItem: FrameItemSource
    
    @StateObject private var videoViewModel = VideoViewModel()
    @StateObject private var playerViewModel = VideoPlayerViewModel()
    @ObservedObject var shareViewModel: ShareViewModel
    
    @State var selectedFrame: (any FrameItem)?
    
    @State var isCreatePresented = false
    @Binding var isSharePresented: Bool
    @State var isCreateButtonEnabled = false
    
    @State private var playerView: VideoPlayerView?
    
    var body: some View {
        VStack {
            ZStack {
                ZStack {
                    if !videoViewModel.items.isEmpty {
                        playerView
                    } else {
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
                    }
                }
                .background(Constants.secondaryColor)
                .cornerRadius(16)
                .padding(.top, 20)
                .padding(.horizontal, 64)
                
                VStack {
                    HStack(alignment: .center) {
                        Button {
                            presentationMode.wrappedValue.dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 22, weight: .medium, design: .rounded))
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 14) {
                            Button {
                                print("Show alert to pick export resolution.")
                            } label: {
                                Image(systemName: "gearshape")
                                    .font(.system(size: 22, weight: .medium, design: .rounded))
                                    .foregroundColor(.white)
                            }
                            
                            Button {
                                playerViewModel.pause()
                                
                                Task(priority: .userInitiated) {
                                    let (playerItem, videoURL, thumbnailURL) = try await videoViewModel.export()
                                    shareViewModel.playerItem = playerItem
                                    
                                    let result = ResultModel(
                                        id: UUID().uuidString,
                                        video: videoURL,
                                        thumbnail: thumbnailURL,
                                        date: Date.now
                                    )
                                    projectsViewModel.create(result: result)
                                }
                                
                                presentationMode.wrappedValue.dismiss()
                                isSharePresented = true
                            } label: {
                                Text("Create")
                                    .foregroundColor(.black)
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 14)
                                    .background(Color.white)
                                    .clipShape(Capsule())
                            }
                            .disabled(!isCreateButtonEnabled)
                        }
                    }
                    
                    Spacer()
                    
                    HStack(alignment: .center) {
                        Button {
                            guard playerViewModel.assetState == .ready else { return }
                                
                            switch playerViewModel.playbackState {
                            case .stopped, .paused:
                                playerViewModel.play()
                            case .playing:
                                playerViewModel.pause()
                            }
                        } label: {
                            if playerViewModel.playbackState == .playing {
                                Image(systemName: "pause.fill")
                                    .font(.system(size: 22, weight: .medium, design: .rounded))
                                    .foregroundColor(.white)
                            } else {
                                Image(systemName: "play.fill")
                                    .font(.system(size: 22, weight: .medium, design: .rounded))
                                    .foregroundColor(.white)
                            }
                        }
                        
                        Spacer()
                        
                        Button {
                            playerViewModel.videoGravity = playerViewModel.videoGravity == .resizeAspect ? .resizeAspectFill : .resizeAspect
                        } label: {
                            Image(systemName: playerViewModel.videoGravity == .resizeAspect ? "arrow.up.left.and.arrow.down.right" : "arrow.down.forward.and.arrow.up.backward")
                                .font(.system(size: 24, weight: .medium, design: .rounded))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.bottom, 20)
                }
                .padding(.top, 10)
                .padding(.horizontal, 20)
            }
            
            FramesCarouselView(
                cameraViewModel: cameraViewModel,
                videoModel: videoViewModel,
                selectedFrame: $selectedFrame,
                isCreatePresented: $isCreatePresented
            )
            
            HStack(spacing: 18) {
                Button {
                    isCreatePresented = true
                } label: {
                    Image(systemName: "repeat")
                        .font(.system(size: 24, weight: .medium, design: .rounded))
                        .foregroundColor(.white)
                }

                Button {
                    guard
                        let selectedFrame,
                        let indexToRemove = videoViewModel.indexForItem(selectedFrame)
                    else { return }
                    
                    videoViewModel.removeItem(at: indexToRemove)
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 24, weight: .regular, design: .rounded))
                        .foregroundColor(.white)
                }
                
                Button {
                   print("Mute frame")
                } label: {
                    Image(systemName: "speaker.wave.3") // speaker.slash.fill
                        .font(.system(size: 24, weight: .regular, design: .rounded))
                        .foregroundColor(.white)
                }
                
                Button {
                   print("Crop Frame")
                } label: {
                    Image(systemName: "crop")
                        .font(.system(size: 24, weight: .regular, design: .rounded))
                        .foregroundColor(.white)
                }
                
                Button {
                   print("Trim Frame")
                } label: {
                    Image(systemName: "scissors")
                        .font(.system(size: 24, weight: .regular, design: .rounded))
                        .foregroundColor(.white)
                }
            }
            .padding(.bottom, 22)
            .opacity(selectedFrame == nil ? 0 : 1)
        }
        .background(Constants.backgroundColor)
        .onAppear {
            videoViewModel.onStartingRegeneration = {
                playerViewModel.stop()
                playerViewModel.setLoading()
                isCreateButtonEnabled = false
            }
            videoViewModel.onEndingRegeneration = {
                playerViewModel.setReady()
                playerViewModel.play()
                isCreateButtonEnabled = true
            }
            
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
        .onChange(of: isCreatePresented) { isCreatePresented in
            isCreatePresented ? playerViewModel.pause() : playerViewModel.play()
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
                    playerViewModel.playerItem = videoViewModel.createPlayerItem
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
}
