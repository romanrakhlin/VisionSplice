import SwiftUI

struct CameraView: View {
    
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: CameraViewModel
    
    @State private var sessionIsRunning = false
    @State private var arebuttonsBlocked = false
    @State private var isGalleryPickerPresented = false
    @State private var selectedAssetURL: URL?
    
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
                    .onTapGesture(count: 2) { flipCamera() }
            } else {
                CameraResultView(cameraViewModel: viewModel)
                    .edgesIgnoringSafeArea(.all)
            }
            
            VStack {
                if !viewModel.isShootTaken {
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
                        .disabled(arebuttonsBlocked)
                        
                        Spacer()
                        
                        Button {
                            flipCamera()
                        } label: {
                            Image(systemName: "arrow.triangle.2.circlepath.camera.fill")
                                .foregroundColor(.black)
                                .padding()
                                .background(.white)
                                .clipShape(Circle())
                        }
                        .disabled(arebuttonsBlocked)
                        .opacity(sessionIsRunning == true ? 1 : 0)
                    }
                    .padding(.top)
                    .opacity(viewModel.isRecording ? 0 : 1)
                    
                    Spacer()
                    
                    HStack(alignment: .bottom) {
                        Button {
                            print("effect")
                        } label: {
                            Image(systemName: "camera.filters")
                                .font(.system(size: 36, weight: .regular, design: .rounded))
                                .foregroundColor(.white)
                                .shadow(radius: 4)
                        }
                        .padding(.bottom, 14)
                        .disabled(arebuttonsBlocked)
                        
                        Spacer()

                        VStack(spacing: 10) {
                            Text("Hold to record")
                                .foregroundColor(.white.opacity(0.8))
                                .font(.system(size: 12, weight: .light, design: .rounded))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 9)
                                .background {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(.black.opacity(0.2))
                                }
                            
                            Button {
                                if viewModel.isVideo {
                                    viewModel.stopRecording()
                                    // in the end of taking video -> camera.video need to become false again
                                } else {
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
                                LongPressGesture(minimumDuration: 0.4).onEnded({ value in
                                    withAnimation {
                                        viewModel.isVideo = true
                                    }
                                    
                                    viewModel.startRecordinng()
                                })
                            )
                            .buttonStyle(.plain)
                            .disabled(arebuttonsBlocked)
                        }
                        
                        Spacer()
                        
                        Button {
                            arebuttonsBlocked = true
                            isGalleryPickerPresented.toggle()
                        } label: {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 36, weight: .regular, design: .rounded))
                                .foregroundColor(.white)
                                .shadow(radius: 4)
                        }
                        .padding(.bottom, 14)
                        .disabled(arebuttonsBlocked)
                    }
                    .padding(.bottom)
                    .opacity(sessionIsRunning == true ? 1 : 0)
                } else {
                    HStack {
                        Button {
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
                            viewModel.isFinished = true
                            presentationMode.wrappedValue.dismiss()
                        } label: {
                            Text("Use this content")
                                .foregroundColor(.black)
                                .font(.system(size: 14, weight: .regular, design: .rounded))
                                .kerning(0.12)
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
            
            if arebuttonsBlocked {
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
                .background(.black.opacity(0.4))
            }
        }
        .background(.black)
        .onAppear {
            viewModel.reset()
            viewModel.controllSession(start: true)
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
                .onDisappear { arebuttonsBlocked = false }
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
