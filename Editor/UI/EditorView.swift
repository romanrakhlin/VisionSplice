//
//  EditorView.swift
//  
//
//  Created by Roman Rakhlin on 2/6/24.
//

import SwiftUI

struct EditorView: View {
    
//    @EnvironmentObject var cameraViewModel: CameraViewModel
    
//    @State private var isCreatePressed = false
    
    @StateObject private var videoModel = VideoModel()
    
    @State var frames: [String] = ["1", "2", "3", "4"]
    @State var selectedFrame: FrameItem?
    @State var draggedItem: FrameItem?
    
    @State var isActionsSheetPresented = false
    
    var body: some View {
        VStack {
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
                
                Text("Editor")
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button {
                    print("Close")
                } label: {
                    Text("Create")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(Constants.primaryColor)
                }
            }
            .padding(.top, 10)
            .padding(.horizontal, 20)
            
            ZStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Constants.secondaryColor)
                }
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
                draggedItem: $draggedItem,
                isActionsSheetPresented: $isActionsSheetPresented
            )
        }
        .background(Constants.backgroundColor)
//        .fullScreenCover(isPresented: $isCreatePressed) {
//            CameraView(action: { url, data in
//                print(url)
//                print(data.count)
//            })
//            .environmentObject(cameraViewModel)
//        }
    }
}
