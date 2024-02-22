//
//  CameraView.swift
//
//
//  Created by Roman Rakhlin on 2/8/24.
//

import SwiftUI

struct CameraView: View {
    
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: CameraViewModel
    
    @State private var sessionIsRunning = false
    @State private var areButtonsBlocked = true
    @State private var isGalleryPickerPresented = false
    @State private var selectedAssetURL: URL?
    @State private var isHintPresented = false
    
    private let maxVideoDuration: Int = 10
    
    public var body: some View {
        ZStack {
            if !viewModel.isShootTaken {
                ProgressView()
                    .progressViewStyle(.circular)
                    .opacity(sessionIsRunning == true ? 0 : 1)
                
                CameraViewControllerRepresentable()
                    .edgesIgnoringSafeArea(.all)
                    .environmentObject(viewModel)
                    .onTapGesture(count: 2) {
                        Haptics.play(.rigid)
                        flipCamera()
                    }
            } else {
                CameraResultView(cameraViewModel: viewModel)
                    .edgesIgnoringSafeArea(.all)
            }
            
            VStack {
                if !viewModel.isShootTaken {
                    HStack {
                        Button {
                            Haptics.play(.light)
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
                            Haptics.play(.rigid)
                            flipCamera()
                        } label: {
                            Image(systemName: "arrow.triangle.2.circlepath.camera.fill")
                                .foregroundColor(.black)
                                .padding()
                                .background(.white)
                                .clipShape(Circle())
                        }
                        .disabled(areButtonsBlocked)
                        .opacity(sessionIsRunning == true ? 1 : 0)
                    }
                    .opacity(viewModel.isRecording ? 0 : 1)
                    
                    Spacer()
                    
                    HStack(alignment: .bottom) {
                        Button {
                            print("Effect")
                        } label: {
                            Image(systemName: "camera.filters")
                                .font(.system(size: 36, weight: .regular, design: .rounded))
                                .foregroundColor(.white)
                                .shadow(radius: 4)
                        }
                        .padding(.bottom, 14)
                        .disabled(areButtonsBlocked)
                        .opacity(0)
                        
                        Spacer()

                        VStack(spacing: 10) {
                            if isHintPresented {
                                Text("Hold to record")
                                    .foregroundColor(.white.opacity(0.8))
                                    .font(.system(size: 12, weight: .light, design: .rounded))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 9)
                                    .background {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(.black.opacity(0.2))
                                    }
                                    .transition(.move(edge: .bottom))
                                    .animation(.easeInOut(duration: 0.5), value: isHintPresented)
                            }
                            
                            Button {
                                if viewModel.isVideo {
                                    Haptics.play(.soft)
                                    viewModel.stopRecording()
                                    // in the end of taking video -> camera.video need to become false again
                                } else {
                                    Haptics.play(.medium)
                                    viewModel.takeShoot()
                                }
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(viewModel.isVideo ? Constants.redColor : .white)
                                        .frame(width: viewModel.isVideo ? 85 : 70, height: viewModel.isVideo ? 85 : 70)
                                    
                                    Circle()
                                        .stroke(viewModel.isVideo ? Constants.redColor.opacity(0.5) : .white.opacity(0.5), lineWidth: 6)
                                        .frame(width: viewModel.isVideo ? 100 : 85, height: viewModel.isVideo ? 100 : 85)
                                }
                                
                            }
                            .simultaneousGesture(
                                LongPressGesture(minimumDuration: 0.4)
                                    .onEnded({ _ in
                                        withAnimation {
                                            viewModel.isVideo = true
                                        }
                                        
                                        Haptics.play(.soft)
                                        viewModel.startRecordinng()
                                    })
                            )
                            .buttonStyle(.plain)
                            .disabled(areButtonsBlocked)
                        }
                        
                        Spacer()
                        
                        Button {
                            Haptics.play(.medium)
                            areButtonsBlocked = true
                            isGalleryPickerPresented.toggle()
                        } label: {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 36, weight: .regular, design: .rounded))
                                .foregroundColor(.white)
                                .shadow(radius: 4)
                        }
                        .padding(.bottom, 14)
                        .disabled(areButtonsBlocked)
                        .opacity(viewModel.isRecording ? 0 : 1)
                    }
                    .opacity(sessionIsRunning == true ? 1 : 0)
                } else {
                    HStack {
                        Button {
                            Haptics.play(.light)
                            viewModel.retakeShoot()
                        } label: {
                            Image(systemName: "chevron.backward")
                                .foregroundColor(.black)
                                .padding()
                                .background(.white)
                                .clipShape(Circle())
                        }
                        
                        Spacer()
                    }
                    .opacity(sessionIsRunning == true ? 1 : 0)
                    
                    Spacer()
                    
                    HStack {
                        Spacer()
                        
                        Button {
                            Haptics.play(.medium)
                            viewModel.isFinished = true
                            presentationMode.wrappedValue.dismiss()
                        } label: {
                            Text("Use this content")
                                .foregroundColor(.black)
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .padding(.vertical, 10)
                                .padding(.horizontal, 20)
                                .background(Color.white)
                                .clipShape(Capsule())
                        }
                    }
                    .opacity(sessionIsRunning == true ? 1 : 0)
                }
            }
            .padding(.horizontal)
            .padding(.vertical)
        }
        .background(.black)
        .onAppear {
            viewModel.reset()
            viewModel.controllSession(start: true)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                withAnimation {
                    areButtonsBlocked = false
                    isHintPresented = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.4) {
                    withAnimation {
                        isHintPresented = false
                    }
                }
            }
        }
        .onDisappear {
            viewModel.controllSession(start: false)
            viewModel.reset()
        }
        .alert(isPresented: $viewModel.showAlert) {
            if viewModel.alertIncludeSettings {
                Alert(
                    title: Text(viewModel.alertText),
                    primaryButton: .default(
                        Text("Allow Aceess"),
                        action: { UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!) }
                    ),
                    secondaryButton: .cancel(Text("Cancel"))
                )
            } else {
                Alert(
                    title: Text(viewModel.alertText),
                    dismissButton: .cancel(Text("OK"))
                )
            }
        }
        .onReceive(Timer.publish(every: 0.01, on: .main, in: .common).autoconnect()) { _ in
            sessionIsRunning = viewModel.session.isRunning
            
            if viewModel.recordedDuration <= Double(maxVideoDuration) && viewModel.isRecording {
                viewModel.recordedDuration += 0.01
            }
            
            if viewModel.recordedDuration >= Double(maxVideoDuration) && viewModel.isRecording {
                viewModel.stopRecording()
            }
        }
        .sheet(isPresented: $isGalleryPickerPresented) {
            GalleryPickerView(selectedAssetURL: $selectedAssetURL)
                .edgesIgnoringSafeArea(.all)
                .onDisappear { areButtonsBlocked = false }
        }
        .onChange(of: selectedAssetURL) { newValue in
            viewModel.manuallySetPreview(newValue)
        }
    }
    
    private func flipCamera() {
        viewModel.position = viewModel.position == .back ? .front : .back
        viewModel.reconfigure()
    }
}
