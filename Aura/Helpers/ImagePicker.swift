//
//  ImagePicker.swift
//  Aura
//
//  Created by jiazhen yan on 2026/2/10.
//

import SwiftUI
import PhotosUI

struct ImagePicker: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentationMode
    @Binding var image: UIImage?
    var onImageSelected: () -> Void
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.presentationMode.wrappedValue.dismiss()
            
            guard let provider = results.first?.itemProvider else { 
                print("⚠️ 用户取消了图片选择")
                return 
            }
            
            if provider.canLoadObject(ofClass: UIImage.self) {
                print("📸 开始加载图片...")
                provider.loadObject(ofClass: UIImage.self) { image, error in
                    if let error = error {
                        print("❌ 图片加载失败: \(error.localizedDescription)")
                        return
                    }
                    
                    DispatchQueue.main.async {
                        if let uiImage = image as? UIImage {
                            print("✅ 图片加载成功，尺寸: \(uiImage.size)")
                            self.parent.image = uiImage
                            self.parent.onImageSelected()
                        } else {
                            print("❌ 无法转换为UIImage")
                        }
                    }
                }
            }
        }
    }
}
