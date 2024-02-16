//
//  ShareView.swift
//
//
//  Created by Roman Rakhlin on 2/16/24.
//

import SwiftUI

struct ShareView: View {
    
    @Environment(\.presentationMode) var presentationMode
    
    @StateObject private var playerViewModel = VideoPlayerViewModel()
    @State private var playerView: VideoPlayerView?
    @State private var isSuccessAlertPresented = false
    
    @ObservedObject var viewModel: ShareViewModel
    
    var body: some View {
        ZStack {
            if let _ = viewModel.playerItem {
                playerView
                    .edgesIgnoringSafeArea(.all)
            } else {
                ProgressView()
            }
            
            VStack {
                HStack {
                    Button {
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.black)
                            .padding()
                            .background(.white)
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    Button {
                        isSuccessAlertPresented = viewModel.share()
                    } label: {
                        Image(systemName: "square.and.arrow.down.on.square")
                            .foregroundColor(.black)
                            .padding()
                            .background(.white)
                            .clipShape(Circle())
                    }
                    .disabled(viewModel.playerItem == nil)
                }
                
                Spacer()
            }
            .padding(.top, 10)
            .padding(.horizontal, 20)
        }
        .onAppear {
            playerViewModel.isPauseDisabled = true
            playerView = VideoPlayerView(viewModel: playerViewModel)
        }
        .onChange(of: viewModel.playerItem) { playerItem in
            guard let playerItem else { return }
            playerViewModel.playerItem = playerItem
        }
        .alert("Video Successfully Saved!", isPresented: $isSuccessAlertPresented) {
            Button("OK", role: .cancel) { }
        }
    }
}
