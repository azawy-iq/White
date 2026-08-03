import Foundation
import AVKit
import PhotosUI
import SwiftUI

@MainActor
class StudioViewModel: ObservableObject {
    @Published var videoURL: URL?
    @Published var player: AVPlayer?
    @Published var selectedItem: PhotosPickerItem?
    @Published var statusText: String = "التطبيق مستعد - اختر فيديو للبدء"
    @Published var extractedAudioURL: URL?

    init() {}

    func loadVideo(from item: PhotosPickerItem?) async {
        guard let item = item else { return }
        do {
            if let movie = try await item.loadTransferable(type: MovieTransferable.self) {
                self.videoURL = movie.url
                self.player = AVPlayer(url: movie.url)
                self.player?.play()
                self.statusText = "تم تحميل وتشغيل الفيديو بنجاح!"
            }
        } catch {
            self.statusText = "فشل في تحميل الفيديو"
        }
    }

    func extractAudio() {
        guard let sourceURL = videoURL else {
            statusText = "الرجاء اختيار فيديو أولاً!"
            return
        }
        
        statusText = "جاري استخراج الصوت الحقيقي..."
        let asset = AVAsset(url: sourceURL)
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent("Audio_\(UUID().uuidString).m4a")
        
        if FileManager.default.fileExists(atPath: outputURL.path) {
            try? FileManager.default.removeItem(at: outputURL)
        }
        
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) else {
            statusText = "خطأ في تهيئة معالج الصوت"
            return
        }
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .m4a
        exportSession.exportAsynchronously {
            DispatchQueue.main.async {
                if exportSession.status == .completed {
                    self.extractedAudioURL = outputURL
                    self.statusText = "🎵 تم استخراج وحفظ ملف الصوت بنجاح!"
                } else {
                    self.statusText = "فشل استخراج الصوت"
                }
            }
        }
    }
}

struct MovieTransferable: Transferable {
    let url: URL
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { movie in
            SentTransferredFile(movie.url)
        } importing: { received in
            let copy = FileManager.default.temporaryDirectory.appendingPathComponent(received.file.lastPathComponent)
            if FileManager.default.fileExists(atPath: copy.path) { try? FileManager.default.removeItem(at: copy) }
            try FileManager.default.copyItem(at: received.file, to: copy)
            return MovieTransferable(url: copy)
        }
    }
}
