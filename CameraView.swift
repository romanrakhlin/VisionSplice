import SwiftUI

struct CameraView: View {
    
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel = CameraViewModel()
    
    let action: (URL, Data) -> Void
    
    private let maxVideoDuration: Int = 10
    
    public var body: some View {
        ZStack {
            if !viewModel.isTaken {
                CameraViewController()
                    .environmentObject(viewModel)
                    .edgesIgnoringSafeArea(.all)
            } else {
                CameraResultView(url: viewModel.previewURL)
                    .edgesIgnoringSafeArea(.all)
            }
            
            VStack {
                if !viewModel.isTaken {
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
                            viewModel.position = viewModel.position == .back ? .front : .back
                            viewModel.setUp()
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
                    
                    HStack(alignment: .center) {
                        Button {
                            if viewModel.video {
                                viewModel.stopRecording()
                                // in the end of taking video -> camera.video need to become false again
                            } else {
                                viewModel.takePic()
                            }
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(viewModel.video ? .red : .white)
                                    .frame(width: viewModel.video ? 95 : 75, height: viewModel.video ? 95 : 75)
                                
                                Circle()
                                    .stroke(viewModel.video ? .red : .white, lineWidth: 2)
                                    .frame(width: viewModel.video ? 105 : 85, height: viewModel.video ? 105 : 85)
                            }
                            
                        }
                        .simultaneousGesture(
                            LongPressGesture(minimumDuration: 0.4).onEnded({ value in
                                if viewModel.recordPermission == .granted {
                                    withAnimation {
                                        viewModel.video = true
                                        viewModel.setUp()
                                        viewModel.startRecordinng()
                                    }
                                }
                            })
                        )
                        .buttonStyle(.plain)
                    }
                    .padding(.bottom)
                } else {
                    HStack {
                        Button {
                            viewModel.retakePic()
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
            viewModel.checkPermission()
            viewModel.checkAudioPermission()
        }
        .alert(isPresented: $viewModel.alert) {
            Alert(title: Text(NSLocalizedString("youFoundInterlocutor", comment: "")),
                  primaryButton: .default(Text(NSLocalizedString("goToSettings", comment: "")), action: {
                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
            }),
                  secondaryButton: .cancel(Text(NSLocalizedString("cancel", comment: ""))))
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
}
