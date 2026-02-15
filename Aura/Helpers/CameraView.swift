//
//  CameraView.swift
//  Aura
//
//  Created by jiazhen yan on 2026/2/10.
//

import SwiftUI
import UIKit

struct CameraView: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentationMode
    @Binding var image: UIImage?
    var onImageCaptured: () -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                print("📸 相机拍摄成功，尺寸: \(uiImage.size)")
                parent.image = uiImage
                parent.presentationMode.wrappedValue.dismiss()
                // 延迟调用以确保界面已关闭
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.parent.onImageCaptured()
                }
            } else {
                print("❌ 无法获取拍摄的图片")
                parent.presentationMode.wrappedValue.dismiss()
            }
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            print("⚠️ 用户取消了拍照")
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
