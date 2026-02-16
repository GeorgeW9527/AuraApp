//
//  FirebaseManager.swift
//  Aura
//
//  Firebase 配置和管理器
//

import Foundation
import Combine
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

/// Firebase 管理器 - 单例模式
class FirebaseManager: ObservableObject {
    static let shared = FirebaseManager()
    
    let auth: Auth
    let firestore: Firestore
    let storage: Storage
    
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    
    private init() {
        // 配置 Firebase（只在这里初始化一次）
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
            print("🔥 Firebase 初始化完成")
        }
        
        self.auth = Auth.auth()
        self.firestore = Firestore.firestore()
        self.storage = Storage.storage()
        
        // 监听认证状态变化
        self.auth.addStateDidChangeListener { [weak self] _, user in
            self?.currentUser = user
            self?.isAuthenticated = user != nil
            print("🔐 认证状态变化: \(user?.email ?? "未登录")")
        }
    }
    
    // MARK: - 用户认证
    
    /// 邮箱注册
    func signUp(email: String, password: String) async throws -> User {
        print("📝 开始注册: \(email)")
        let result = try await auth.createUser(withEmail: email, password: password)
        print("✅ 注册成功: \(result.user.uid)")
        return result.user
    }
    
    /// 邮箱登录
    func signIn(email: String, password: String) async throws -> User {
        print("🔑 开始登录: \(email)")
        let result = try await auth.signIn(withEmail: email, password: password)
        print("✅ 登录成功: \(result.user.uid)")
        return result.user
    }
    
    /// 退出登录
    func signOut() throws {
        print("👋 退出登录")
        try auth.signOut()
    }
    
    /// 重置密码
    func resetPassword(email: String) async throws {
        print("📧 发送重置密码邮件: \(email)")
        try await auth.sendPasswordReset(withEmail: email)
        print("✅ 密码重置邮件已发送")
    }
    
    // MARK: - Firestore 数据操作
    
    /// 保存数据到 Firestore
    func saveData<T: Encodable>(collection: String, documentId: String, data: T) async throws {
        guard let userId = currentUser?.uid else {
            throw NSError(domain: "FirebaseError", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "用户未登录"])
        }
        
        print("💾 保存数据: \(collection)/\(userId)/\(documentId)")
        let docRef = firestore.collection(collection).document(userId).collection("items").document(documentId)
        try docRef.setData(from: data)
        print("✅ 数据保存成功")
    }
    
    /// 从 Firestore 获取数据
    func fetchData<T: Decodable>(collection: String, documentId: String, as type: T.Type) async throws -> T {
        guard let userId = currentUser?.uid else {
            throw NSError(domain: "FirebaseError", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "用户未登录"])
        }
        
        print("📥 获取数据: \(collection)/\(userId)/\(documentId)")
        let docRef = firestore.collection(collection).document(userId).collection("items").document(documentId)
        let document = try await docRef.getDocument()
        
        guard document.exists else {
            throw NSError(domain: "FirebaseError", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "数据不存在"])
        }
        
        let data = try document.data(as: T.self)
        print("✅ 数据获取成功")
        return data
    }
    
    /// 获取集合中的所有数据
    func fetchCollection<T: Decodable>(collection: String, as type: T.Type) async throws -> [T] {
        guard let userId = currentUser?.uid else {
            throw NSError(domain: "FirebaseError", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "用户未登录"])
        }
        
        print("📥 获取集合: \(collection)/\(userId)")
        let collectionRef = firestore.collection(collection).document(userId).collection("items")
        let snapshot = try await collectionRef.getDocuments()
        
        let items = try snapshot.documents.compactMap { document -> T? in
            try document.data(as: T.self)
        }
        
        print("✅ 获取到 \(items.count) 条数据")
        return items
    }
    
    /// 删除数据
    func deleteData(collection: String, documentId: String) async throws {
        guard let userId = currentUser?.uid else {
            throw NSError(domain: "FirebaseError", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "用户未登录"])
        }
        
        print("🗑️ 删除数据: \(collection)/\(userId)/\(documentId)")
        let docRef = firestore.collection(collection).document(userId).collection("items").document(documentId)
        try await docRef.delete()
        print("✅ 数据删除成功")
    }
    
    // MARK: - Storage 文件操作
    
    /// 上传图片到 Storage
    func uploadImage(_ image: UIImage, path: String) async throws -> String {
        guard let userId = currentUser?.uid else {
            throw NSError(domain: "FirebaseError", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "用户未登录"])
        }
        
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            throw NSError(domain: "FirebaseError", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "图片处理失败"])
        }
        
        print("📤 上传图片: \(path) (\(imageData.count) bytes)")
        let storageRef = storage.reference().child("users/\(userId)/\(path)")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
        let downloadURL = try await storageRef.downloadURL()
        
        print("✅ 图片上传成功: \(downloadURL.absoluteString)")
        return downloadURL.absoluteString
    }
    
    /// 下载图片
    func downloadImage(from url: String) async throws -> UIImage {
        print("📥 下载图片: \(url)")
        guard let imageUrl = URL(string: url) else {
            throw NSError(domain: "FirebaseError", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "无效的图片URL"])
        }
        
        let (data, _) = try await URLSession.shared.data(from: imageUrl)
        guard let image = UIImage(data: data) else {
            throw NSError(domain: "FirebaseError", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "图片解析失败"])
        }
        
        print("✅ 图片下载成功")
        return image
    }
    
    /// 删除图片
    func deleteImage(path: String) async throws {
        guard let userId = currentUser?.uid else {
            throw NSError(domain: "FirebaseError", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "用户未登录"])
        }
        
        print("🗑️ 删除图片: \(path)")
        let storageRef = storage.reference().child("users/\(userId)/\(path)")
        try await storageRef.delete()
        print("✅ 图片删除成功")
    }
}

// MARK: - UIImage Extension

import UIKit

extension UIImage {
    /// 调整图片大小
    func resized(to size: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(origin: .zero, size: size))
        return UIGraphicsGetImageFromCurrentImageContext() ?? self
    }
}
