import SwiftUI
import PhotosUI
import ffmpegkit

struct MoviePicker: UIViewControllerRepresentable {
    @Binding var currentScale: Float
    @Binding var isProcessing: Bool
    @Binding var alertMessage: String
    @Binding var isShowingPicker: Bool

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
            // ปิดหน้าต่างการเลือกคลังภาพทันที
            parent.isShowingPicker = false
            
            guard let result = results.first else { return }
            let provider = result.itemProvider
            
            // สั่งเปิดตัวหมุนโหลด (ProgressView) บน Main Thread เพื่อแสดงสถานะแก่ผู้ใช้
            DispatchQueue.main.async {
                self.parent.isProcessing = true
            }
            
            // ตรวจสอบชนิดข้อมูล (Type Identifier) สำหรับไฟล์วิดีโอ
            var typeIdentifier = "public.mpeg-4"
            if !provider.hasItemConformingToTypeIdentifier(typeIdentifier),
               let firstType = provider.registeredTypeIdentifiers.first {
                typeIdentifier = firstType
            }
            
            // ดึงไฟล์วิดีโอต้นฉบับจากตัวเลือกคลังภาพ
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
                
                // [แก้ไข] ดึงเวลาปัจจุบันในรูปแบบ วันเดือนปีชั่วโมงนาทีวินาที (เช่น 260714225601)
                let formatter = DateFormatter()
                formatter.dateFormat = "yyMMddHHmmss"
                let timeStamp = formatter.string(from: Date())
                
                let inputPath = (tempDir as NSString).appendingPathComponent("Input_\(timeStamp).MP4")
                let outputPath = (tempDir as NSString).appendingPathComponent("Output_\(timeStamp).MP4")
                
                let fileManager = FileManager.default
                
                // ล้างไฟล์ Path เก่าออกเผื่อไว้ก่อนเพื่อความชัวร์
                try? fileManager.removeItem(atPath: inputPath)
                try? fileManager.removeItem(atPath: outputPath)
                
                // ถือครองสิทธิ์ชั่วคราว (Security-scoped) ก่อนการคัดลอกไฟล์ ป้องกัน Sandbox บล็อกไฟล์บน SwiftUI
                let accessSecurity = url?.startAccessingSecurityScopedResource() ?? false
                if let sourceUrl = url {
                    try? fileManager.copyItem(atPath: sourceUrl.path, toPath: inputPath)
                }
                if accessSecurity { url?.stopAccessingSecurityScopedResource() }
                
                // ตรวจเช็คว่าไฟล์ต้นฉบับก๊อบปี้เข้ามาใน Sandbox แอปสำเร็จหรือไม่ ถ้าล้มเหลวให้ยกเลิกการโหลดทันที
                if !fileManager.fileExists(atPath: inputPath) {
                    DispatchQueue.main.async {
                        self.parent.isProcessing = false
                        self.parent.alertMessage = "ไฟล์ต้นฉบับคัดลอกเข้า Sandbox ไม่สำเร็จ"
                    }
                    return
                }
                
                // ประกอบคำสั่งสำหรับรันประมวลผลผ่าน FFmpeg
                let cmd = "-itsscale \(self.parent.currentScale) -i \(inputPath) -codec copy \(outputPath)"
                
                // รันคำสั่งแปลงวิดีโอแบบเบื้องหลัง (Async) 
                FFmpegKit.executeAsync(cmd) { [weak self] session in
                    guard let self = self, let code = session?.getReturnCode() else { return }
                    
                    DispatchQueue.main.async {
                        // ไม่ว่าจะรันสำเร็จหรือผิดพลาด ให้เคลียร์ตัวหมุนโหลด (ProgressView) ออกทันที
                        self.parent.isProcessing = false
                        
                        if ReturnCode.isSuccess(code) {
                            // ส่งผลลัพธ์วิดีโอไปบันทึกลงสู่ม้วนฟิล์ม/คลังอัลบั้มในอุปกรณ์
                            PHPhotoLibrary.shared().performChanges({
                                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: URL(fileURLWithPath: outputPath))
                            }) { success, error in
                                
                                // สั่งทำลายและลบไฟล์ชั่วคราวทั้ง 2 ตัวทิ้งทันทีเมื่องานเสร็จสิ้น เคลียร์ Cache Sandbox ให้โล่ง 100%
                                try? fileManager.removeItem(atPath: inputPath)
                                try? fileManager.removeItem(atPath: outputPath)
                                
                                DispatchQueue.main.async {
                                    if success {
                                        self.parent.alertMessage = "แปลงไฟล์และบันทึกลงคลังภาพความละเอียด 1080p สำเร็จ!"
                                    } else {
                                        self.parent.alertMessage = "แปลงสำเร็จแต่บันทึกลงอัลบั้มไม่ได้ ตรวจสอบสิทธิ์เข้าถึงคลังภาพ"
                                    }
                                }
                            }
                        } else {
                            // สั่งลบไฟล์ขยะทิ้งทันทีหากคำสั่ง FFmpeg ล้มเหลว
                            try? fileManager.removeItem(atPath: inputPath)
                            try? fileManager.removeItem(atPath: outputPath)
                            
                            self.parent.alertMessage = "คำสั่ง FFmpeg ทำงานล้มเหลว"
                        }
                    }
                }
            }
        }
    }
}
