import SwiftUI
import SwiftData
import PhotosUI

struct LoginView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false
    @AppStorage("currentUsername") private var currentUsername: String = ""
    
    @State private var username = ""
    @State private var password = ""
    @State private var showingRegister = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "shippingbox.fill")
                    .font(.system(size: 80))
                    .foregroundColor(Color(red: 0.35, green: 0.60, blue: 0.75))
                    .padding(.bottom, 10)
                
                Text("欢迎使用码上取")
                    .font(.largeTitle)
                    .bold()
                
                VStack(spacing: 16) {
                    TextField("用户名", text: $username)
                        .padding()
                        .background(Color(uiColor: .secondarySystemBackground))
                        .cornerRadius(12)
                        .autocapitalization(.none)
                    
                    SecureField("密码", text: $password)
                        .padding()
                        .background(Color(uiColor: .secondarySystemBackground))
                        .cornerRadius(12)
                }
                .padding(.horizontal, 24)
                
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.subheadline)
                }
                
                Button(action: login) {
                    Text("登录")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(red: 0.35, green: 0.60, blue: 0.75))
                        .cornerRadius(12)
                }
                .padding(.horizontal, 24)
                .padding(.top, 10)
                
                Button(action: { showingRegister = true }) {
                    Text("没有账号？点击注册")
                        .font(.subheadline)
                        .foregroundColor(Color(red: 0.35, green: 0.60, blue: 0.75))
                }
                
                Spacer()
            }
            .padding(.top, 60)
            .navigationDestination(isPresented: $showingRegister) {
                RegisterView()
            }
        }
    }
    
    private func login() {
        if users.contains(where: { $0.username == username && $0.passwordHash == password }) {
            currentUsername = username
            withAnimation {
                isLoggedIn = true
            }
        } else {
            errorMessage = "用户名或密码错误"
        }
    }
}

struct RegisterView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var users: [User]
    
    @State private var username = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var errorMessage = ""
    
    @State private var avatarItem: PhotosPickerItem?
    @State private var avatarImage: Image?
    @State private var avatarData: Data?
    
    var body: some View {
        let currentAvatarImage = avatarImage
        VStack(spacing: 24) {
            PhotosPicker(selection: $avatarItem, matching: .images) {
                if let avatarImage = currentAvatarImage {
                    avatarImage
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.gray.opacity(0.2), lineWidth: 1))
                } else {
                    ZStack {
                        Circle()
                            .fill(Color(uiColor: .secondarySystemBackground))
                            .frame(width: 100, height: 100)
                        Image(systemName: "camera.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .onChange(of: avatarItem) { _, _ in
                Task { @MainActor in
                    if let data = try? await avatarItem?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        // 压缩图片数据，防止过大导致 SwiftData 保存失败
                        let compressedData = uiImage.jpegData(compressionQuality: 0.5)
                        avatarData = compressedData
                        avatarImage = Image(uiImage: uiImage)
                    }
                }
            }
            
            Text("点击设置头像")
                .font(.caption)
                .foregroundColor(.secondary)
            
            VStack(spacing: 16) {
                TextField("用户名", text: $username)
                    .padding()
                    .background(Color(uiColor: .secondarySystemBackground))
                    .cornerRadius(12)
                    .autocapitalization(.none)
                
                SecureField("密码", text: $password)
                    .padding()
                    .background(Color(uiColor: .secondarySystemBackground))
                    .cornerRadius(12)
                    
                SecureField("确认密码", text: $confirmPassword)
                    .padding()
                    .background(Color(uiColor: .secondarySystemBackground))
                    .cornerRadius(12)
            }
            .padding(.horizontal, 24)
            
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.subheadline)
            }
            
            Button(action: register) {
                Text("注册")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 24)
            .padding(.top, 10)
            
            Spacer()
        }
        .padding(.top, 40)
        .navigationTitle("注册账号")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func register() {
        if username.isEmpty || password.isEmpty {
            errorMessage = "用户名和密码不能为空"
            return
        }
        if password != confirmPassword {
            errorMessage = "两次输入的密码不一致"
            return
        }
        if users.contains(where: { $0.username == username }) {
            errorMessage = "用户名已存在"
            return
        }
        
        let newUser = User(username: username, passwordHash: password, avatarData: avatarData)
        modelContext.insert(newUser)
        try? modelContext.save()
        dismiss()
    }
}
