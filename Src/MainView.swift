import SwiftUI
import PhotosUI
import ffmpegkit
// import PartyUI // เปิดใช้ถ้าติดตั้งผ่าน package เรียบร้อย

struct MainView: View {
    @State private var currentScale: Float = 2.0
    @State private var isShowingPicker = false
    @State private var isShowingAlert = false
    @State private var isShowingSettings = false
    @State private var alertMessage = ""
    @State private var isProcessing = false
    @State private var inputScaleText = "2.0"
    
    var body: some View {
        NavigationStack {
            ZStack {
                // พื้นหลังสีดำสนิท
                Color.black
                    .ignoresSafeArea()
                
                List {
                    Section {
                        // ปุ่มเลือกวิดีโอ
                        Button {
                            isShowingPicker = true
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("เลือกวิดีโอจากคลังภาพ")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.white)
                                    Text("ดึงไฟล์ต้นฉบับตรงไม่ผ่านเบราว์เซอร์")
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                                Image(systemName: "video.badge.plus")
                                    .foregroundColor(.white)
                            }
                        }
                        .buttonStyle(TranslucentButtonStyle()) // ใช้ PartyUI Style
                        
                        // ปุ่มตั้งค่าความเร็ว
                        Button {
                            inputScaleText = String(format: "%.1f", currentScale)
                            isShowingAlert = true
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("ตั้งค่าความเร็ว (itsscale)")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.white)
                                    Text("ปัจจุบัน: \(String(format: "%.1f", currentScale))x (สโลว์โมชัน)")
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                                Image(systemName: "speedometer")
                                    .foregroundColor(.white)
                            }
                        }
                        .buttonStyle(TranslucentButtonStyle()) // ใช้ PartyUI Style
                    } header: {
                        Text("ฟังก์ชันหลัก")
                            .foregroundColor(.gray)
                    }
                    .listRowBackground(Color(white: 0.07)) // สีเทาเข้มแบบเดิม
                }
                .scrollContentBackground(.hidden)
                
                // Spinner แสดงเมื่อกำลังประมวลผลวิดีโอ
                if isProcessing {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                    ProgressView("กำลังประมวลผล...")
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                        .foregroundColor(.white)
                        .padding()
                        .background(Color(white: 0.15))
                        .cornerRadius(10)
                }
            }
            .navigationTitle("TT-Tool")
            .toolbar {
                // ปุ่มฟันเฟืองสำหรับเปิดหน้า SettingsView ที่คุยกันก่อนหน้านี้
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isShowingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundColor(.blue)
                    }
                }
            }
            // เรียกเปิดหน้า SettingsView แบบ Sheet
            .sheet(isPresented: $isShowingSettings) {
                SettingsView()
            }
            // เรียกเปิดระบบเลือกไฟล์ (PHPicker)
            .sheet(isPresented: $isShowingPicker) {
                MoviePicker(currentScale: $currentScale, isProcessing: $isProcessing, alertMessage: $alertMessage)
            }
            // Alert สำหรับป้อนค่าความเร็ว
            .alert("ตั้งค่าตัวคูณเวลา", isPresented: $isShowingAlert) {
                TextField("เช่น 2.0 หรือ 0.5", text: $inputScaleText)
                    .keyboardType(.decimalPad)
                Button("ตกลง") {
                    if let value = Float(inputScaleText), value > 0 {
                        currentScale = value
                    }
                }
                Button("ยกเลิก", role: .cancel) {}
            } message: {
                Text("ใส่ค่า itsscale ที่ต้องการรันในคำสั่ง FFmpeg")
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
        .environment(\.colorScheme, .dark) // บังคับแสดงผลดาร์กโหมด
    }
}
