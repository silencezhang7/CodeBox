import UIKit
import Photos
import SwiftData

@Observable
@MainActor
final class ScreenshotMonitor {
    var isProcessing = false
    var lastError: String?

    private var modelContext: ModelContext?
    private var observationTask: Task<Void, Never>?

    func start(context: ModelContext) {
        self.modelContext = context
        observationTask = Task { [weak self] in
            for await _ in NotificationCenter.default.notifications(named: UIApplication.userDidTakeScreenshotNotification) {
                guard let self else { break }
                try? await Task.sleep(nanoseconds: 800_000_000)
                await self.processLatestScreenshot()
            }
        }
    }

    func stop() {
        observationTask?.cancel()
        observationTask = nil
    }

    private func processLatestScreenshot() async {
        guard let context = modelContext else { return }

        let activeId = UserDefaults.standard.string(forKey: "active_model_id") ?? ""
        guard !activeId.isEmpty,
              let aiModel = try? context.fetch(FetchDescriptor<AIModel>()).first(where: { $0.id.uuidString == activeId }) else {
            lastError = "未勾选 AI 模型，截图识别需要配置并勾选模型"
            return
        }

        guard let imageData = await fetchLatestScreenshot() else {
            lastError = "无法获取截图"
            return
        }

        isProcessing = true
        lastError = nil
        defer { isProcessing = false }

        do {
            let result = try await AIRecognitionService.recognizeImage(imageData: imageData, model: aiModel)
            guard result.type != .other || !result.code.isEmpty else { return }
            let item = ClipboardItem(
                content: result.code, originalContent: nil, typeRaw: result.type.rawValue,
                sourcePlatform: result.platform, stationName: result.stationName, stationAddress: result.stationAddress
            )
            context.insert(item)
            try context.save()
        } catch {
            lastError = error.localizedDescription
        }
    }

    private func fetchLatestScreenshot() async -> Data? {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        guard status == .authorized || status == .limited else { return nil }

        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.fetchLimit = 1
        options.predicate = NSPredicate(format: "mediaSubtype == %d", PHAssetMediaSubtype.photoScreenshot.rawValue)

        guard let asset = PHAsset.fetchAssets(with: .image, options: options).firstObject else { return nil }

        return await withCheckedContinuation { continuation in
            let reqOptions = PHImageRequestOptions()
            reqOptions.isSynchronous = false
            reqOptions.deliveryMode = .highQualityFormat
            PHImageManager.default().requestImageDataAndOrientation(for: asset, options: reqOptions) { data, _, _, _ in
                continuation.resume(returning: data)
            }
        }
    }
}
