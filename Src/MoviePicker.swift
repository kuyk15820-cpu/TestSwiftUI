import SwiftUI
import PhotosUI
import ffmpegkit

struct MoviePicker: UIViewControllerRepresentable {
    @Binding var currentScale: Float
    @Binding var isProcessing: Bool
    @Binding var alertMessage: String
    @Binding var isShowingPicker: Bool // เชื่อมสถานะการเปิดปิดตรงๆ

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.filter = .videos
        config.preferredAssetRepresentationMode = .current
        
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
            // ปิดตัวเลือกระบบภาพ
            picker.dismiss(animated: true) {
                // ปิดการเรนเดอร์ Element ใน SwiftUI หลังจาก UI หน้าต่างผลลัพธ์ย่อยหายไปแล้ว
                self.parent.isShowingPicker = false
            }
            
            guard let result = results.first else { return }
            let provider = result.itemProvider
            
            // สั่งให้ตัวโหลดเริ่มทำงานทันทีบน Main เธรด
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
                
                // ถือครองสิทธิ์ชั่วคราวเพื่อคัดลอกไฟล์ต้นฉบับ
                let accessSecurity = url?.startAccessingSecurityScopedResource() ?? false
                if let sourceUrl = url {
                    try? fileManager.copyItem(atPath: sourceUrl.path, toPath: inputPath)
                }
                if accessSecurity { url?.stopAccessingSecurityScopedResource() }
                
                // ดักจับเช็คไฟล์ ถ้าคัดลอกไฟล์ดิบมาใส่โฟลเดอร์แอปไม่สำเร็จ จะไม่ปล่อยให้รันค้าง
                if !fileManager.fileExists(atPath: inputPath) {
                    DispatchQueue.main.async {
                        self.parent.isProcessing = false
                        self.parent.alertMessage = "ไฟล์ต้นฉบับคัดลอกเข้า Sandbox ไม่สำเร็จ"
                    }
                    return
                }
                
                let cmd = "-itsscale \(self.parent.currentScale) -i \(inputPath) -codec copy \(outputPath)"
                
                FFmpegKit.executeAsync(cmd) { [weak self] session in
                    guard let self = self, let code = session?.getReturnCode() else { return }
                    
                    DispatchQueue.main.async {
                        // ไม่ว่าสำเร็จหรือล้มเหลว ต้องเคลียร์ตัวหมุนโหลดออกเสมอ!
                        self.parent.isProcessing = false
                        
                        if ReturnCode.isSuccess(code) {
                            PHPhotoLibrary.shared().performChanges({
                                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: URL(fileURLWithPath: outputPath))
                            }) { success, error in
                                DispatchQueue.main.async {
                                    if success {
                                        self.parent.alertMessage = "แปลงไฟล์และบันทึกลงคลังภาพความละเอียด 1080p สำเร็จ!"
                                    } else {
                                        self.parent.alertMessage = "แปลงสำเร็จแต่บันทึกลงอัลบั้มไม่ได้ ตรวจสอบสิทธิ์เข้าถึงคลังภาพ"
                                    }
                                }
                            }
                        } else {
                            self.parent.alertMessage = "คำสั่ง FFmpeg ทำงานล้มเหลว"
                        }
                    }
                }
            }
        }
    }
}
