import SwiftUI
import PhotosUI
import ffmpegkit
// import PartyUI // เปิดใช้ถ้าติดตั้งผ่าน package เรียบร้อย

struct MainView: View {
    // กำหนดค่าคงที่สำหรับ itsscale เป็น 2.0
    private let currentScale: Float = 2.0
    
    @State private var isShowingPicker = false
    @State private var isShowingSettings = false
    @State private var alertMessage = ""
    @State private var isProcessing = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // พื้นหลังสีดำสนิท
                Color.black
                    .ignoresSafeArea()
                
                // รูปแบบการจัดวาง UX/UI ใหม่ (Modern Card Layout)
                VStack(spacing: 24) {
                    
                    // ส่วนแสดงสถานะการทำงานปัจจุบัน (Status Banner)
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.blue)
                            Text("โหมดการทำงานปัจจุบัน")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.gray)
                        }
                        
                        Text("สโลว์โมชันคงที่ 2.0x (Slow-Motion)")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text("ระบบจะทำการดึงไฟล์ดิบตรงจากคลังภาพ ไม่ผ่านการบีบอัดของเบราว์เซอร์ และเร่งขยายเฟรมเวลาขึ้น 2 เท่าด้วย FFmpeg")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                            .lineSpacing(4)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(white: 0.07))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(white: 0.15), lineWidth: 1)
                    )
                    
                    Spacer()
                    
                    // ปุ่มหลักในการเลือกวิดีโอ (เด่นชัดอยู่กลางหน้าจอ/ตำแหน่งกดง่าย)
                    Button {
                        isShowingPicker = true
                    } label: {
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("เลือกวิดีโอจากคลังภาพ")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                Text("เริ่มกระบวนการแปลงไฟล์ทันที")
                                    .font(.system(size: 13))
                                    .foregroundColor(.lightGray)
                            }
                            Spacer()
                            Image(systemName: "video.badge.plus.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                        }
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(TranslucentButtonStyle()) // ใช้ดีไซน์ PartyUI
                    
                    Spacer()
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                // เรียกใช้คอมโพเนนต์เบื้องหลังแบบ FullScreenCover ตามโครงสร้างที่ทำงานได้เสถียรที่สุด
                .fullScreenCover(isPresented: $isShowingPicker) {
                    MoviePicker(
                        currentScale: .constant(currentScale), // ส่งค่าคงที่ 2.0 ไปในรูปแบบ Binding Constant
                        isProcessing: $isProcessing,
                        alertMessage: $alertMessage,
                        isShowingPicker: $isShowingPicker
                    )
                    .background(BackgroundCleanerView())
                }
                
                // Spinner แสดงเมื่อกำลังประมวลผลวิดีโอ
                if isProcessing {
                    Color.black.opacity(0.6)
                        .ignoresSafeArea()
                    VStack(spacing: 15) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                            .scaleEffect(1.5)
                        Text("กำลังประมวลผล...")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .padding(25)
                    .background(Color(white: 0.12))
                    .cornerRadius(15)
                }
            }
            .navigationTitle("TT-Tool")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isShowingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundColor(.blue)
                    }
                }
            }
            .sheet(isPresented: $isShowingSettings) {
                SettingsView()
            }
            // Alert แสดงสถานะการทำงานตอนท้าย
            .alert("ระบบทำงาน", isPresented: Binding<Bool>(
                get: { !alertMessage.isEmpty },
                set: { _ in alertMessage = "" }
            )) {
                Button("ตกลง", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
        }
        .environment(\.colorScheme, .dark)
    }
}

// โครงสร้างเสริมเคลียร์สีพื้นหลังหน้าต่าง FullScreen
struct BackgroundCleanerView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        DispatchQueue.main.async {
            view.superview?.superview?.backgroundColor = .clear
        }
        return view
    }
    func updateUIView(_ uiView: UIView, context: Context) {}
}
