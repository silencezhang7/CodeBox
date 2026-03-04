@preconcurrency import AVFoundation
import CoreImage
import UIKit

class VideoDeduplicator: @unchecked Sendable {
    
    /// 综合去重处理
    func processVideo(
        inputURL: URL,
        outputURL: URL,
        completion: @escaping @Sendable (Result<URL, Error>) -> Void
    ) {
        let asset = AVURLAsset(url: inputURL)
        
        Task {
            do {
                guard let videoTrack = try await asset.loadTracks(withMediaType: .video).first,
                      let audioTrack = try await asset.loadTracks(withMediaType: .audio).first else {
                    completion(.failure(NSError(domain: "Error", code: -1, userInfo: [NSLocalizedDescriptionKey: "找不到音视频轨道"])))
                    return
                }
                
                let composition = AVMutableComposition()
                let videoSize = try await videoTrack.load(.naturalSize)
                let duration = try await asset.load(.duration)
                
                // 1. 添加视频轨道
                let compositionVideoTrack = composition.addMutableTrack(
                    withMediaType: .video,
                    preferredTrackID: kCMPersistentTrackID_Invalid
                )!
                
                // 2. 添加音频轨道
                let compositionAudioTrack = composition.addMutableTrack(
                    withMediaType: .audio,
                    preferredTrackID: kCMPersistentTrackID_Invalid
                )!
                
                try compositionVideoTrack.insertTimeRange(
                    CMTimeRange(start: .zero, duration: duration),
                    of: videoTrack,
                    at: .zero
                )
                try compositionAudioTrack.insertTimeRange(
                    CMTimeRange(start: .zero, duration: duration),
                    of: audioTrack,
                    at: .zero
                )
                
                // 3. 创建视频合成 + 滤镜
                let videoComposition = createVideoComposition(
                    composition: composition,
                    videoSize: videoSize
                )
                
                // 4. 音频处理（变速变调）
                let audioMix = createAudioMix(audioTrack: compositionAudioTrack)
                
                // 5. 添加随机图层
                addRandomOverlays(to: videoComposition, videoSize: videoSize, duration: duration)
                
                // 6. 导出
                exportVideo(
                    composition: composition,
                    videoComposition: videoComposition,
                    audioMix: audioMix,
                    outputURL: outputURL,
                    completion: completion
                )
                
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - 视频处理
    
    private func createVideoComposition(
        composition: AVMutableComposition,
        videoSize: CGSize
    ) -> AVMutableVideoComposition {
        
        // 全局随机参数，保证每一帧的变化是一致的，避免画面抖动闪烁
        let globalScale = CGFloat.random(in: 1.001...1.015)
        let globalBrightness = CGFloat.random(in: -0.01...0.01)
        let globalContrast = CGFloat.random(in: 0.99...1.01)
        let globalSaturation = CGFloat.random(in: 0.99...1.01)
        
        let tx = (1.0 - globalScale) * videoSize.width / 2.0
        let ty = (1.0 - globalScale) * videoSize.height / 2.0
        let globalTransform = CGAffineTransform(translationX: tx, y: ty).scaledBy(x: globalScale, y: globalScale)
        
        let videoComposition = AVMutableVideoComposition(asset: composition) { request in
            var outputImage = request.sourceImage
            
            // 1. 固定的轻微放大裁切，避免边缘穿帮且无抖动
            outputImage = outputImage.transformed(by: globalTransform)
            
            // 2. 固定的轻微色彩调整
            if let colorFilter = CIFilter(name: "CIColorControls") {
                colorFilter.setValue(outputImage, forKey: kCIInputImageKey)
                colorFilter.setValue(globalBrightness, forKey: kCIInputBrightnessKey)
                colorFilter.setValue(globalContrast, forKey: kCIInputContrastKey)
                colorFilter.setValue(globalSaturation, forKey: kCIInputSaturationKey)
                outputImage = colorFilter.outputImage ?? outputImage
            }
            
            // 3. 极微弱模糊（改变底层像素特征）
            if let blurFilter = CIFilter(name: "CIGaussianBlur") {
                blurFilter.setValue(outputImage, forKey: kCIInputImageKey)
                blurFilter.setValue(0.2, forKey: kCIInputRadiusKey)
                outputImage = blurFilter.outputImage ?? outputImage
            }
            
            request.finish(with: outputImage, context: nil)
        }
        
        videoComposition.renderSize = videoSize
        videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
        
        return videoComposition
    }
    
    // MARK: - 音频处理
    
    private func createAudioMix(audioTrack: AVMutableCompositionTrack) -> AVMutableAudioMix {
        let audioMix = AVMutableAudioMix()
        let audioParams = AVMutableAudioMixInputParameters(track: audioTrack)
        
        // 轻微调整音量（破坏音频指纹）
        let volume = Float.random(in: 0.98...1.02)
        audioParams.setVolume(volume, at: .zero)
        
        audioMix.inputParameters = [audioParams]
        return audioMix
    }
    
    // MARK: - 添加随机图层
    
    private func addRandomOverlays(
        to videoComposition: AVMutableVideoComposition,
        videoSize: CGSize,
        duration: CMTime
    ) {
        let parentLayer = CALayer()
        let videoLayer = CALayer()
        
        parentLayer.frame = CGRect(origin: .zero, size: videoSize)
        videoLayer.frame = CGRect(origin: .zero, size: videoSize)
        parentLayer.addSublayer(videoLayer)
        
        // 添加隐形水印（1x1像素，随机位置）
        for _ in 0..<5 {
            let watermark = CALayer()
            watermark.frame = CGRect(
                x: CGFloat.random(in: 0...videoSize.width),
                y: CGFloat.random(in: 0...videoSize.height),
                width: 1,
                height: 1
            )
            watermark.backgroundColor = UIColor(
                red: CGFloat.random(in: 0...1),
                green: CGFloat.random(in: 0...1),
                blue: CGFloat.random(in: 0...1),
                alpha: 0.01  // 几乎不可见
            ).cgColor
            parentLayer.addSublayer(watermark)
        }
        
        videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(
            postProcessingAsVideoLayer: videoLayer,
            in: parentLayer
        )
    }
    
    // MARK: - 导出
    
    private func exportVideo(
        composition: AVMutableComposition,
        videoComposition: AVMutableVideoComposition,
        audioMix: AVMutableAudioMix,
        outputURL: URL,
        completion: @escaping @Sendable (Result<URL, Error>) -> Void
    ) {
        try? FileManager.default.removeItem(at: outputURL)
        
        guard let exportSession = AVAssetExportSession(
            asset: composition,
            presetName: AVAssetExportPresetHighestQuality
        ) else {
            completion(.failure(NSError(domain: "Export", code: -1)))
            return
        }
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        exportSession.videoComposition = videoComposition
        exportSession.audioMix = audioMix
        
        // 随机修改元数据
        let item = AVMutableMetadataItem()
        item.key = AVMetadataKey.commonKeyTitle as NSString
        item.keySpace = .common
        item.value = UUID().uuidString as NSString
        exportSession.metadata = [item]
        
        let sessionProxy = exportSession
        
        // The deprecation warning is an Apple SDK issue. 
        // Best approach is usually to just let it be, but since the user requested suppression
        // and #warning doesn't support suppression of deprecation well in Swift, 
        // we'll keep the modern iOS 18 code and ignore legacy branch warning, 
        // avoiding concurrent task capture entirely using nonisolated async wrapper
        
        Task {
            do {
                if #available(iOS 18.0, *) {
                    try await performExport(session: sessionProxy, outputURL: outputURL)
                    completion(.success(outputURL))
                } else {
                    try await performLegacyExport(session: sessionProxy)
                    completion(.success(outputURL))
                }
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    @available(iOS 18.0, *)
    private func performExport(session: AVAssetExportSession, outputURL: URL) async throws {
        try await session.export(to: outputURL, as: .mp4)
    }
    
    @available(iOS, deprecated: 18.0)
    private func performLegacyExport(session: AVAssetExportSession) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            session.exportAsynchronously {
                if session.status == .completed {
                    continuation.resume(returning: ())
                } else {
                    continuation.resume(throwing: session.error ?? NSError(domain: "Export", code: -1))
                }
            }
        }
    }
}
