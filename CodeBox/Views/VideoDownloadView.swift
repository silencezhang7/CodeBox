import SwiftUI
import AVKit
import Photos

struct VideoDownloadView: View {
    @State private var inputLink: String = ""
    @State private var isParsing: Bool = false
    @State private var parsedVideoURL: URL? = nil
    @State private var errorMessage: String? = nil
    @State private var isDownloading: Bool = false
    @State private var downloadProgress: Double = 0.0
    @State private var showSuccessAlert: Bool = false
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Input Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("输入视频分享链接")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    ZStack(alignment: .topLeading) {
                        if inputLink.isEmpty {
                            Text("在此粘贴抖音、快手等平台分享链接...")
                                .foregroundColor(Color(uiColor: .placeholderText))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 16)
                                .allowsHitTesting(false)
                        }
                        
                        TextEditor(text: $inputLink)
                            .focused($isInputFocused)
                            .frame(height: 120)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .scrollContentBackground(.hidden)
                            .background(Color(uiColor: .tertiarySystemFill))
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isInputFocused ? Color.blue : Color.gray.opacity(0.2), lineWidth: isInputFocused ? 2 : 1)
                    )
                    .animation(.easeInOut(duration: 0.2), value: isInputFocused)
                    
                    HStack {
                        Button("清空") {
                            inputLink = ""
                            parsedVideoURL = nil
                            errorMessage = nil
                        }
                        .foregroundColor(.red)
                        
                        Spacer()
                        
                        Button {
                            if let clipboardText = UIPasteboard.general.string {
                                inputLink = clipboardText
                            }
                        } label: {
                            Label("粘贴", systemImage: "doc.on.clipboard")
                        }
                    }
                    .font(.subheadline)
                }
                .padding()
                .background(Color(uiColor: .systemBackground))
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                
                // Parse Button
                Button {
                    Task {
                        await parseVideo()
                    }
                } label: {
                    HStack {
                        if isParsing {
                            ProgressView()
                                .tint(.white)
                                .padding(.trailing, 5)
                        }
                        Text(isParsing ? "解析中..." : "一键解析")
                            .fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(inputLink.isEmpty || isParsing ? Color.blue.opacity(0.5) : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(inputLink.isEmpty || isParsing)
                
                // Error Message
                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.footnote)
                        .padding(.top, 5)
                }
                
                // Result Section
                if let videoURL = parsedVideoURL {
                    VStack(spacing: 16) {
                        Text("解析成功")
                            .font(.headline)
                            .foregroundColor(.green)
                        
                        VideoPlayer(player: AVPlayer(url: videoURL))
                            .frame(height: 300)
                            .cornerRadius(12)
                        
                        Button {
                            Task {
                                await downloadAndSaveVideo(url: videoURL)
                            }
                        } label: {
                            HStack {
                                if isDownloading {
                                    ProgressView(value: downloadProgress, total: 1.0)
                                        .progressViewStyle(LinearProgressViewStyle(tint: .white))
                                        .frame(width: 100)
                                        .padding(.trailing, 10)
                                } else {
                                    Image(systemName: "square.and.arrow.down")
                                }
                                Text(isDownloading ? "保存中..." : "保存到相册")
                                    .fontWeight(.bold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isDownloading ? Color.green.opacity(0.5) : Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(isDownloading)
                    }
                    .padding()
                    .background(Color(uiColor: .systemBackground))
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                }
            }
            .padding()
        }
        .background(Color(uiColor: .secondarySystemBackground).ignoresSafeArea())
        .navigationTitle("无水印视频")
        .navigationBarTitleDisplayMode(.inline)
        .alert("保存成功", isPresented: $showSuccessAlert) {
            Button("确定", role: .cancel) { }
        } message: {
            Text("视频已成功保存到您的相册。")
        }
    }
    
    // MARK: - Logic
    
    private func extractURL(from text: String) -> String? {
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let matches = detector?.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
        
        for match in matches ?? [] {
            if let url = match.url {
                return url.absoluteString
            }
        }
        return nil
    }
    
    private func parseVideo() async {
        isParsing = true
        errorMessage = nil
        parsedVideoURL = nil
        
        guard let urlString = extractURL(from: inputLink), let url = URL(string: urlString) else {
            errorMessage = "未检测到有效的链接，请检查输入内容"
            isParsing = false
            return
        }
        
        do {
            let parsedUrl: URL
            if url.host?.contains("douyin.com") == true {
                parsedUrl = try await parseDouyin(url: url)
            } else if url.host?.contains("kuaishou.com") == true {
                parsedUrl = try await parseKuaishou(url: url)
            } else {
                throw NSError(domain: "ParseError", code: 0, userInfo: [NSLocalizedDescriptionKey: "目前仅支持抖音和快手分享链接"])
            }
            
            await MainActor.run {
                self.parsedVideoURL = parsedUrl
                self.isParsing = false
                self.isInputFocused = false
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = "解析出错: \(error.localizedDescription)"
                self.isParsing = false
                self.isInputFocused = false
            }
        }
    }
    
    private func parseDouyin(url: URL) async throws -> URL {
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_2 like Mac OS X) AppleWebKit/605.1.15", forHTTPHeaderField: "User-Agent")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, let finalURL = httpResponse.url else {
            throw NSError(domain: "ParseError", code: 0, userInfo: [NSLocalizedDescriptionKey: "无法获取重定向后的真实链接"])
        }
        
        let urlPath = finalURL.path
        let pathComponents = urlPath.split(separator: "/")
        guard let videoId = pathComponents.last else {
            throw NSError(domain: "ParseError", code: 0, userInfo: [NSLocalizedDescriptionKey: "无法从链接中提取视频ID"])
        }
        
        let detailURLString = "https://www.iesdouyin.com/share/video/\(videoId)"
        guard let detailURL = URL(string: detailURLString) else {
            throw NSError(domain: "ParseError", code: 0, userInfo: [NSLocalizedDescriptionKey: "无效的详情页链接"])
        }
        
        var detailRequest = URLRequest(url: detailURL)
        detailRequest.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_2 like Mac OS X) AppleWebKit/605.1.15", forHTTPHeaderField: "User-Agent")
        
        let (detailData, _) = try await URLSession.shared.data(for: detailRequest)
        guard let detailHTML = String(data: detailData, encoding: .utf8) else {
            throw NSError(domain: "ParseError", code: 0, userInfo: [NSLocalizedDescriptionKey: "无法解析详情页内容"])
        }
        
        let pattern = "window\\._ROUTER_DATA\\s*=\\s*(.*?)</script>"
        let regex = try NSRegularExpression(pattern: pattern, options: .dotMatchesLineSeparators)
        let nsRange = NSRange(detailHTML.startIndex..<detailHTML.endIndex, in: detailHTML)
        
        guard let match = regex.firstMatch(in: detailHTML, options: [], range: nsRange) else {
            throw NSError(domain: "ParseError", code: 0, userInfo: [NSLocalizedDescriptionKey: "未找到视频数据"])
        }
        
        let jsonRange = match.range(at: 1)
        guard let swiftRange = Range(jsonRange, in: detailHTML) else {
            throw NSError(domain: "ParseError", code: 0, userInfo: [NSLocalizedDescriptionKey: "截取JSON数据失败"])
        }
        
        let jsonString = String(detailHTML[swiftRange]).trimmingCharacters(in: .whitespacesAndNewlines)
        guard let jsonData = jsonString.data(using: .utf8),
              let jsonObject = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            throw NSError(domain: "ParseError", code: 0, userInfo: [NSLocalizedDescriptionKey: "JSON解析失败"])
        }
        
        guard let loaderData = jsonObject["loaderData"] as? [String: Any],
              let pageData = loaderData["video_(id)/page"] as? [String: Any],
              let videoInfoRes = pageData["videoInfoRes"] as? [String: Any],
              let itemList = videoInfoRes["item_list"] as? [[String: Any]],
              let firstItem = itemList.first,
              let video = firstItem["video"] as? [String: Any],
              let playAddr = video["play_addr"] as? [String: Any],
              let urlList = playAddr["url_list"] as? [String],
              let originalVideoUrlStr = urlList.first else {
            throw NSError(domain: "ParseError", code: 0, userInfo: [NSLocalizedDescriptionKey: "无法从数据中找到视频播放地址"])
        }
        
        let noWatermarkUrlStr = originalVideoUrlStr.replacingOccurrences(of: "playwm", with: "play")
        guard let noWatermarkUrl = URL(string: noWatermarkUrlStr) else {
            throw NSError(domain: "ParseError", code: 0, userInfo: [NSLocalizedDescriptionKey: "无效的无水印视频链接"])
        }
        
        return noWatermarkUrl
    }
    
    private func parseKuaishou(url: URL) async throws -> URL {
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_2 like Mac OS X) AppleWebKit/605.1.15", forHTTPHeaderField: "User-Agent")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        guard let html = String(data: data, encoding: .utf8) else {
            throw NSError(domain: "ParseError", code: 0, userInfo: [NSLocalizedDescriptionKey: "无法解析详情页内容"])
        }
        
        let pattern = "\"url\":\"(https://[^\"]+\\.mp4[^\"]*)\""
        let regex = try NSRegularExpression(pattern: pattern, options: [])
        let nsRange = NSRange(html.startIndex..<html.endIndex, in: html)
        
        let matches = regex.matches(in: html, options: [], range: nsRange)
        var extractedUrls: [String] = []
        for match in matches {
            if let range = Range(match.range(at: 1), in: html) {
                var str = String(html[range])
                str = str.replacingOccurrences(of: "\\u002F", with: "/")
                extractedUrls.append(str)
            }
        }
        
        guard let bestUrlString = extractedUrls.last, let parsedUrl = URL(string: bestUrlString) else {
            throw NSError(domain: "ParseError", code: 0, userInfo: [NSLocalizedDescriptionKey: "无法从快手页面中提取视频链接"])
        }
        
        return parsedUrl
    }
    
    private func downloadAndSaveVideo(url: URL) async {
        isDownloading = true
        downloadProgress = 0.0
        
        do {
            // 1. Download with real progress using AsyncStream
            let downloader = RealDownloader()
            let (targetURL, response) = try await downloader.download(url: url) { @Sendable progress in
                Task { @MainActor in
                    self.downloadProgress = progress * 0.95
                }
            }
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                throw URLError(.badServerResponse)
            }
            
            // 2. Request Photo Library access
            let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
            guard status == .authorized || status == .limited else {
                throw NSError(domain: "AuthError", code: 1, userInfo: [NSLocalizedDescriptionKey: "没有相册保存权限"])
            }
            
            // 3. Save to Photos using UIKit
            await withCheckedContinuation { continuation in
                let saver = VideoSaver()
                saver.saveVideo(at: targetURL) { error in
                    if let error = error {
                        print("Save error: \(error.localizedDescription)")
                    }
                    continuation.resume()
                }
            }
            
            // 4. 清理临时文件
            try? FileManager.default.removeItem(at: targetURL)
            
            await MainActor.run {
                downloadProgress = 1.0
                isDownloading = false
                showSuccessAlert = true
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = "保存失败: \(error.localizedDescription)"
                self.isDownloading = false
                self.downloadProgress = 0.0
            }
        }
    }
}

final class RealDownloader: NSObject, URLSessionDownloadDelegate, @unchecked Sendable {
    private var continuation: CheckedContinuation<(URL, URLResponse), Error>?
    private var progressCallback: ((Double) -> Void)?
    
    func download(url: URL, progress: @escaping (Double) -> Void) async throws -> (URL, URLResponse) {
        self.progressCallback = progress
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            let config = URLSessionConfiguration.default
            let session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
            let task = session.downloadTask(with: url)
            task.resume()
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        if totalBytesExpectedToWrite > 0 {
            let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
            DispatchQueue.main.async {
                self.progressCallback?(progress)
            }
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory
        let targetURL = tempDir.appendingPathComponent(UUID().uuidString + ".mp4")
        
        do {
            if fileManager.fileExists(atPath: targetURL.path) {
                try fileManager.removeItem(at: targetURL)
            }
            try fileManager.moveItem(at: location, to: targetURL)
            
            guard let response = downloadTask.response else {
                throw URLError(.badServerResponse)
            }
            continuation?.resume(returning: (targetURL, response))
        } catch {
            continuation?.resume(throwing: error)
        }
        continuation = nil
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            continuation?.resume(throwing: error)
            continuation = nil
        }
    }
}

class VideoSaver: NSObject {
    var completion: ((Error?) -> Void)?
    
    func saveVideo(at url: URL, completion: @escaping (Error?) -> Void) {
        self.completion = completion
        if UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(url.path) {
            UISaveVideoAtPathToSavedPhotosAlbum(url.path, self, #selector(video(_:didFinishSavingWithError:contextInfo:)), nil)
        } else {
            completion(NSError(domain: "VideoSaver", code: -1, userInfo: [NSLocalizedDescriptionKey: "视频格式与相册不兼容"]))
        }
    }
    
    @objc func video(_ videoPath: String, didFinishSavingWithError error: Error?, contextInfo info: UnsafeRawPointer) {
        completion?(error)
    }
}
