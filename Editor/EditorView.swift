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
    
    @State var frames: [Int] = [1, 2, 3, 4, 5]
    
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
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(Constants.primaryColor)
                }
            }
            .padding(.horizontal, 20)
            
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Constants.secondaryColor)
            }
            .padding(.top, 20)
            .padding(.horizontal, 80)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 18) {
                    ForEach(frames.indices) { _ in
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Constants.secondaryColor)
                                .frame(width: UIDevice.current.userInterfaceIdiom == .pad ? 120 : 60)
                                .frame(height: UIDevice.current.userInterfaceIdiom == .pad ? 160 : 80)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.top, 20)
            .padding(.bottom)
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
