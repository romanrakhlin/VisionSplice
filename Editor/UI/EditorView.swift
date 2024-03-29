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
    @EnvironmentObject var shareViewModel: ShareViewModel
    
    @StateObject private var videoViewModel = VideoViewModel()
    @StateObject private var playerViewModel = VideoPlayerViewModel()
    
    @State var selectedFrame: (any FrameItem)?
    @State var isCreatePresented = false
    @Binding var isSharePresented: Bool
    @State var isCreateButtonEnabled = false
    @State var isLoadingPresented = false
    @State var isCloseAlertPresented = false
    @State private var playerView: VideoPlayerView?
    @State private var isErrorAlertPresented = false
    @State private var errorAlertTitle: String?
    
    var sourceItem: FrameItemSource
    
    var body: some View {
        ZStack {
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
                                Haptics.play(.light)
                                isCloseAlertPresented = true
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 22, weight: .medium, design: .rounded))
                                    .foregroundColor(.white)
                            }
                            .alert("Are you sure?", isPresented: $isCloseAlertPresented) {
                                Button("Close", role: .destructive) {
                                    presentationMode.wrappedValue.dismiss()
                                }
                                Button("Cancel", role: .cancel) {}
                            } message: {
                                Text("All changes will be lost.")
                            }
                            
                            Spacer()
                            
                            Button {
                                Haptics.play(.heavy)
                                playerViewModel.pause()
                                isLoadingPresented = true
                                
                                Task(priority: .userInitiated) {
                                    do {
                                        let (playerItem, videoURL, thumbnailURL) = try await videoViewModel.export()

                                        shareViewModel.playerItem = playerItem
                                        
                                        let result = ResultModel(
                                            id: UUID().uuidString,
                                            video: videoURL,
                                            thumbnail: thumbnailURL,
                                            date: Date.now
                                        )
                                        projectsViewModel.create(result: result)
                                        
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                            isLoadingPresented = false
                                            presentationMode.wrappedValue.dismiss()
                                            isSharePresented = true
                                        }
                                    } catch {
                                        print(error)
                                        errorAlertTitle = "Export Failed"
                                        isLoadingPresented = false
                                        isErrorAlertPresented = true
                                    }
                                }
                            } label: {
                                Text("Create")
                                    .foregroundColor(.black)
                                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 14)
                                    .background(Color.white)
                                    .clipShape(Capsule())
                            }
                            .disabled(!isCreateButtonEnabled)
                        }
                        
                        Spacer()
                        
                        HStack(alignment: .center) {
                            Button {
                                Haptics.play(.light)
                                
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
                                Haptics.play(.light)
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
                
                VStack {
                    if selectedFrame != nil {
                        HStack(spacing: 18) {
                            Button {
                                Haptics.play(.medium)
                                
                                isCreatePresented = true
                            } label: {
                                Image(systemName: "repeat")
                                    .font(.system(size: 24, weight: .medium, design: .rounded))
                                    .foregroundColor(.white)
                            }

                            Button {
                                Haptics.play(.medium)
                                
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
                                Haptics.play(.medium)
                                
                               print("Mute frame")
                            } label: {
                                Image(systemName: "speaker.wave.3") // speaker.slash.fill
                                    .font(.system(size: 24, weight: .regular, design: .rounded))
                                    .foregroundColor(.white)
                            }
                            
                            Button {
                                Haptics.play(.medium)
                                
                                print("Crop Frame")
                            } label: {
                                Image(systemName: "crop")
                                    .font(.system(size: 24, weight: .regular, design: .rounded))
                                    .foregroundColor(.white)
                            }
                            
                            Button {
                                Haptics.play(.medium)
                                
                                print("Trim Frame")
                            } label: {
                                Image(systemName: "scissors")
                                    .font(.system(size: 24, weight: .regular, design: .rounded))
                                    .foregroundColor(.white)
                            }
                        }
                    } else {
                        VStack(spacing: 4) {
                            Text("Select frame to modify it.")
                                .font(.system(size: 16, weight: .light, design: .rounded))
                                .foregroundColor(.white.opacity(0.5))
                            
                            Text("Hold frame to change the order.")
                                .font(.system(size: 16, weight: .light, design: .rounded))
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                }
                .frame(height: 36)
                .padding(.bottom, 10)
            }
            .background(Constants.backgroundColor)
            
            if isLoadingPresented {
                VStack {
                    Spacer()
                    
                    HStack {
                        Spacer()
                        
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(.thickMaterial)
                                .frame(width: 82, height: 82)
                            
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.4, anchor: .center)
                        }
                        
                        Spacer()
                    }
                    
                    Spacer()
                }
                .background(.black.opacity(0.3))
            }
        }
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
        .alert(errorAlertTitle ?? "Error Occured", isPresented: $isErrorAlertPresented) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Try one more time.")
        }
    }
    
    private func appendItem(with sourceItem: FrameItemSource) {
        Task(priority: .userInitiated) {
            do {
                try await videoViewModel.append(from: sourceItem)
            } catch {
                let nsError = error as NSError
                let description = (nsError).localizedRecoverySuggestion ?? nsError.localizedDescription
                errorAlertTitle = description
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
                errorAlertTitle = description
            }
        }
    }
}
