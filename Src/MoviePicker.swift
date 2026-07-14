import SwiftUI
import PhotosUI
import ffmpegkit

struct MoviePicker: UIViewControllerRepresentable {
    @Binding var currentScale: Float
    @Binding var isProcessing: Bool
    @Binding var alertMessage: String
    @Environment(\.dismiss) var dismiss

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.filter = .videos
        config.preferredAssetRepresentationMode = .current // ดึงไฟล์ดิบ ไม่บีบอัด
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: MoviePicker

        init(parent: MoviePicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            // ปิดหน้า Picker ทันทีเมื่อเลือกเสร็จ
            parent.dismiss()
            
            guard let result = results.first else { return }
            let provider = result.itemProvider
            
            // อัปเดตสถานะ UI บน Main Thread
            DispatchQueue.main.async {
                self.parent.isProcessing = true
            }
            
            var typeIdentifier = "public.mpeg-4"
            if !provider.hasItemConformingToTypeIdentifier(typeIdentifier),
               let firstType = provider.registeredTypeIdentifiers.first {
                typeIdentifier = firstType
            }
            
            provider.loadFileRepresentation(forTypeIdentifier: typeIdentifier) { [weak self] (url, error) in
                guard let self = self else { return }
                
                if error != nil || url == nil {
                    // [แก้ไข] เปลี่ยนจาก .sync เป็น .async ป้องกัน Deadlock
                    DispatchQueue.main.async {
                        self.parent.isProcessing = false
                        self.parent.alertMessage = "เกิดข้อผิดพลาดในการดึงไฟล์ต้นฉบับ"
                    }
                    return
                }
                
                let tempDir = NSTemporaryDirectory()
                let inputPath = (tempDir as NSString).appendingPathComponent("Test.MP4")
                let outputPath = (tempDir as NSString).appendingPathComponent("Test1.MP4")
                
                let fileManager = FileManager.default
                try? fileManager.removeItem(atPath: inputPath)
                try? fileManager.removeItem(atPath: outputPath)
                
                if let sourceUrl = url {
                    try? fileManager.copyItem(atPath: sourceUrl.path, toPath: inputPath)
                }
                
                let cmd = "-itsscale \(self.parent.currentScale) -i \(inputPath) -codec copy \(outputPath)"
                
                FFmpegKit.executeAsync(cmd) { [weak self] session in
                    guard let self = self, let code = session?.getReturnCode() else { return }
                    
                    DispatchQueue.main.async {
                        if ReturnCode.isSuccess(code) {
                            PHPhotoLibrary.shared().performChanges({
                                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: URL(fileURLWithPath: outputPath))
                            }) { success, error in
                                // กลับมาอัปเดต UI ผลลัพธ์บน Main Thread เสมอ
                                DispatchQueue.main.async {
                                    self.parent.isProcessing = false
                                    if success {
                                        self.parent.alertMessage = "แปลงไฟล์และบันทึกลงคลังภาพความละเอียด 1080p สำเร็จ!"
                                    } else {
                                        self.parent.alertMessage = "แปลงสำเร็จแต่บันทึกลงอัลบั้มไม่ได้ ตรวจสอบสิทธิ์เข้าถึงคลังภาพ"
                                    }
                                }
                            }
                        } else {
                            self.parent.isProcessing = false
                            self.parent.alertMessage = "คำสั่ง FFmpeg ทำงานล้มเหลว"
                        }
                    }
                }
            }
        }
    }
}
