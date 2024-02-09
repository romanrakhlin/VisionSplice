//
//  GalleryPickerView.swift
//
//
//  Created by Roman Rakhlin on 2/9/24.
//

import SwiftUI
import UIKit
import AVKit

struct GalleryPickerView: UIViewControllerRepresentable {
    
    @Environment(\.dismiss) private var dismiss
    
    @Binding var selectedAssetURL: URL?
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        picker.mediaTypes = ["public.image", "public.movie"]
        picker.videoMaximumDuration = TimeInterval(5)
        
        return picker
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let controller: GalleryPickerView
        
        init(_ controller: GalleryPickerView) {
            self.controller = controller
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            controller.dismiss()
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info:[UIImagePickerController.InfoKey : Any]) {
            if let mediaType = info[UIImagePickerController.InfoKey.mediaType] as? String {
                if mediaType == "public.image" {
                    if
                        let image = info[UIImagePickerController.InfoKey.editedImage] as? UIImage,
                        let data = image.jpegData(compressionQuality: 0.8)
                    {
                        let tempFile = NSTemporaryDirectory() + "\(UUID().uuidString).jpg"
                        try? data.write(to: URL(fileURLWithPath: tempFile))
                        controller.selectedAssetURL = URL(fileURLWithPath: tempFile)
                    }
                } else if mediaType == "public.movie" {
                    controller.selectedAssetURL = info[UIImagePickerController.InfoKey.mediaURL] as? URL
                }
            }
            
            controller.dismiss()
        }
    }
    
    func updateUIViewController(_ picker: UIImagePickerController, context: Context) {}
}
