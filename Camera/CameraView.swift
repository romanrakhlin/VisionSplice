import SwiftUI

struct CameraView: View {
    
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var viewModel: CameraViewModel
    
    let action: (URL, Data) -> Void
    
    private let maxVideoDuration: Int = 10
    
    public var body: some View {
        ZStack {
            if !viewModel.isFinished {
                ProgressView()
                    .progressViewStyle(.circular)
                
                CameraViewController()
                    .environmentObject(viewModel)
                    .onTapGesture(count: 2) { flipCamera() }
                    .edgesIgnoringSafeArea(.all)
            } else {
                CameraResultView(url: $viewModel.previewURL)
                    .edgesIgnoringSafeArea(.all)
            }
            
            VStack {
                if !viewModel.isFinished {
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
                            flipCamera()
                        } label: {
                            Image(systemName: "arrow.triangle.2.circlepath.camera.fill")
                                .foregroundColor(.black)
                                .padding()
                                .background(.white)
                                .clipShape(Circle())
                        }
                    }
                    .padding(.top)
                    .opacity(viewModel.isRecording ? 0 : 1)
                    
                    Spacer()
                    
                    HStack(alignment: .bottom) {
                        Button {
                            print("effect")
                        } label: {
                            Rectangle()
                                .frame(width: 50, height: 50)
                        }
                        .padding(.bottom, 14)
                        
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
                        }
                        
                        Spacer()
                        
                        Button {
                            print("Gallery")
                        } label: {
                            Rectangle()
                                .frame(width: 50, height: 50)
                        }
                        .padding(.bottom, 14)
                    }
                    .padding(.bottom)
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
                    
                    Spacer()
                    
                    HStack {
                        Spacer()
                        
                        Button {
                            if let url = viewModel.previewURL {
                                action(url, viewModel.mediaData)
                                presentationMode.wrappedValue.dismiss()
                            }
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
                }
            }
            .padding(.horizontal)
        }
        .onAppear {
            viewModel.controllSession(start: true)
        }
        .onDisappear {
            viewModel.controllSession(start: false)
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
            if viewModel.recordedDuration <= Double(maxVideoDuration) && viewModel.isRecording {
                viewModel.recordedDuration += 0.01
            }
            
            if viewModel.recordedDuration >= Double(maxVideoDuration) && viewModel.isRecording {
                viewModel.stopRecording()
            }
        }
    }
    
    private func flipCamera() {
        viewModel.position = viewModel.position == .back ? .front : .back
        viewModel.reconfigure()
    }
}
