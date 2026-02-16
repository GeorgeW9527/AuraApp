//
//  CloudBaseManager.swift
//  Aura
//
//  腾讯云开发 CloudBase 管理器
//

import Foundation
import CloudBase

/// 腾讯云 CloudBase 管理器 - 单例模式
class CloudBaseManager: ObservableObject {
    static let shared = CloudBaseManager()
    
    private var app: TCloudBaseApp!
    private var auth: TCloudBaseAuth!
    private var database: TCloudBaseDatabase!
    private var storage: TCloudBaseStorage!
    
    @Published var currentUser: TCloudBaseUser?
    @Published var isAuthenticated = false
    
    private init() {
        // 配置腾讯云
        let config = TCloudBaseConfig()
        config.envId = CloudBaseConfig.envId
        config.region = CloudBaseConfig.region
        
        self.app = TCloudBaseApp(config: config)
        self.auth = app.auth()
        self.database = app.database()
        self.storage = app.storage()
        
        // 监听认证状态
        checkAuthState()
        
        print("☁️ 腾讯云 CloudBase 初始化完成")
    }
    
    // MARK: - 认证状态检查
    
    private func checkAuthState() {
        if let user = auth.currentUser() {
            self.currentUser = user
            self.isAuthenticated = true
            print("🔐 用户已登录: \(user.uid ?? "未知")")
        } else {
            self.currentUser = nil
            self.isAuthenticated = false
            print("🔐 用户未登录")
        }
    }
    
    // MARK: - 用户认证
    
    /// 邮箱注册
    func signUp(email: String, password: String) async throws -> TCloudBaseUser {
        print("📝 开始注册: \(email)")
        
        return try await withCheckedThrowingContinuation { continuation in
            auth.signUpWithEmail(email, password: password) { [weak self] user, error in
                if let error = error {
                    print("❌ 注册失败: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                } else if let user = user {
                    print("✅ 注册成功: \(user.uid ?? "未知")")
                    self?.currentUser = user
                    self?.isAuthenticated = true
                    continuation.resume(returning: user)
                } else {
                    let error = NSError(domain: "CloudBaseError", code: -1,
                                      userInfo: [NSLocalizedDescriptionKey: "注册失败"])
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// 邮箱登录
    func signIn(email: String, password: String) async throws -> TCloudBaseUser {
        print("🔑 开始登录: \(email)")
        
        return try await withCheckedThrowingContinuation { continuation in
            auth.signInWithEmail(email, password: password) { [weak self] user, error in
                if let error = error {
                    print("❌ 登录失败: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                } else if let user = user {
                    print("✅ 登录成功: \(user.uid ?? "未知")")
                    self?.currentUser = user
                    self?.isAuthenticated = true
                    continuation.resume(returning: user)
                } else {
                    let error = NSError(domain: "CloudBaseError", code: -1,
                                      userInfo: [NSLocalizedDescriptionKey: "登录失败"])
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// 退出登录
    func signOut() throws {
        print("👋 退出登录")
        auth.signOut()
        currentUser = nil
        isAuthenticated = false
    }
    
    /// 重置密码
    func resetPassword(email: String) async throws {
        print("📧 发送重置密码邮件: \(email)")
        
        return try await withCheckedThrowingContinuation { continuation in
            auth.sendPasswordResetEmail(email) { error in
                if let error = error {
                    print("❌ 密码重置失败: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                } else {
                    print("✅ 密码重置邮件已发送")
                    continuation.resume()
                }
            }
        }
    }
    
    // MARK: - 数据库操作
    
    /// 保存数据
    func saveData<T: Encodable>(collection: String, data: T) async throws -> String {
        guard let userId = currentUser?.uid else {
            throw NSError(domain: "CloudBaseError", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "用户未登录"])
        }
        
        print("💾 保存数据到集合: \(collection)")
        
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(data)
        guard let dict = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            throw NSError(domain: "CloudBaseError", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "数据序列化失败"])
        }
        
        var dataDict = dict
        dataDict["userId"] = userId
        dataDict["timestamp"] = Date().timeIntervalSince1970
        
        return try await withCheckedThrowingContinuation { continuation in
            database.collection(collection).add(dataDict) { docId, error in
                if let error = error {
                    print("❌ 数据保存失败: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                } else if let docId = docId {
                    print("✅ 数据保存成功: \(docId)")
                    continuation.resume(returning: docId)
                } else {
                    let error = NSError(domain: "CloudBaseError", code: -1,
                                      userInfo: [NSLocalizedDescriptionKey: "保存失败"])
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// 查询数据
    func fetchData<T: Decodable>(collection: String, as type: T.Type) async throws -> [T] {
        guard let userId = currentUser?.uid else {
            throw NSError(domain: "CloudBaseError", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "用户未登录"])
        }
        
        print("📥 从集合获取数据: \(collection)")
        
        return try await withCheckedThrowingContinuation { continuation in
            database.collection(collection)
                .where(field: "userId", op: .equal, value: userId)
                .orderBy(field: "timestamp", order: .desc)
                .get { result, error in
                    if let error = error {
                        print("❌ 数据获取失败: \(error.localizedDescription)")
                        continuation.resume(throwing: error)
                        return
                    }
                    
                    guard let result = result else {
                        continuation.resume(returning: [])
                        return
                    }
                    
                    do {
                        let decoder = JSONDecoder()
                        var items: [T] = []
                        
                        for doc in result.documents {
                            if let data = doc.data {
                                let jsonData = try JSONSerialization.data(withJSONObject: data)
                                let item = try decoder.decode(T.self, from: jsonData)
                                items.append(item)
                            }
                        }
                        
                        print("✅ 获取到 \(items.count) 条数据")
                        continuation.resume(returning: items)
                    } catch {
                        print("❌ 数据解析失败: \(error.localizedDescription)")
                        continuation.resume(throwing: error)
                    }
                }
        }
    }
    
    /// 删除数据
    func deleteData(collection: String, documentId: String) async throws {
        print("🗑️ 删除数据: \(collection)/\(documentId)")
        
        return try await withCheckedThrowingContinuation { continuation in
            database.collection(collection).document(documentId).delete { error in
                if let error = error {
                    print("❌ 数据删除失败: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                } else {
                    print("✅ 数据删除成功")
                    continuation.resume()
                }
            }
        }
    }
    
    // MARK: - 云存储操作
    
    /// 上传图片
    func uploadImage(_ image: UIImage, path: String) async throws -> String {
        guard let userId = currentUser?.uid else {
            throw NSError(domain: "CloudBaseError", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "用户未登录"])
        }
        
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            throw NSError(domain: "CloudBaseError", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "图片处理失败"])
        }
        
        print("📤 上传图片: \(path) (\(imageData.count) bytes)")
        
        let cloudPath = "users/\(userId)/\(path)"
        
        return try await withCheckedThrowingContinuation { continuation in
            storage.uploadFile(imageData, cloudPath: cloudPath) { result, error in
                if let error = error {
                    print("❌ 图片上传失败: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                } else if let fileId = result?.fileID {
                    print("✅ 图片上传成功: \(fileId)")
                    
                    // 获取下载链接
                    self.storage.getFileDownloadURL(fileId) { url, error in
                        if let error = error {
                            print("❌ 获取下载链接失败: \(error.localizedDescription)")
                            continuation.resume(throwing: error)
                        } else if let url = url {
                            print("✅ 获取下载链接成功: \(url)")
                            continuation.resume(returning: url)
                        } else {
                            let error = NSError(domain: "CloudBaseError", code: -1,
                                              userInfo: [NSLocalizedDescriptionKey: "获取链接失败"])
                            continuation.resume(throwing: error)
                        }
                    }
                } else {
                    let error = NSError(domain: "CloudBaseError", code: -1,
                                      userInfo: [NSLocalizedDescriptionKey: "上传失败"])
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// 下载图片
    func downloadImage(from url: String) async throws -> UIImage {
        print("📥 下载图片: \(url)")
        
        guard let imageUrl = URL(string: url) else {
            throw NSError(domain: "CloudBaseError", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "无效的图片URL"])
        }
        
        let (data, _) = try await URLSession.shared.data(from: imageUrl)
        guard let image = UIImage(data: data) else {
            throw NSError(domain: "CloudBaseError", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "图片解析失败"])
        }
        
        print("✅ 图片下载成功")
        return image
    }
    
    /// 删除图片
    func deleteImage(fileId: String) async throws {
        print("🗑️ 删除图片: \(fileId)")
        
        return try await withCheckedThrowingContinuation { continuation in
            storage.deleteFile([fileId]) { result, error in
                if let error = error {
                    print("❌ 图片删除失败: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                } else {
                    print("✅ 图片删除成功")
                    continuation.resume()
                }
            }
        }
    }
}

// MARK: - 配置

struct CloudBaseConfig {
    /// 环境 ID（需要在腾讯云控制台获取）
    static let envId = "YOUR_ENV_ID"
    
    /// 地域（可选值：ap-shanghai, ap-guangzhou, ap-beijing 等）
    static let region = "ap-shanghai"
}
