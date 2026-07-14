import SwiftUI
import PhotosUI
import ffmpegkit
// import PartyUI 

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
                Color.black
                    .ignoresSafeArea()
                
                List {
                    Section {
                        // ปุ่มเลือกวิดีโอ
                        Button {
                            // กดแล้วสั่งให้หน้าต่างเลือกทำงานแบบ Background เอนทิตีแทนการเปิด Sheet
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
                        .buttonStyle(TranslucentButtonStyle())
                        
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
                        .buttonStyle(TranslucentButtonStyle())
                    } header: {
                        Text("ฟังก์ชันหลัก")
                            .foregroundColor(.gray)
                    }
                    .listRowBackground(Color(white: 0.07))
                }
                .scrollContentBackground(.hidden)
                
                // [จุดแก้ไขสำคัญ] เรียกใช้คอมโพเนนต์ระบบเบื้องหลัง ไม่ผ่านชีต เพื่อป้องกันการตัดสิทธิ์ของ Background Process
                if isShowingPicker {
                    MoviePicker(currentScale: $currentScale, isProcessing: $isProcessing, alertMessage: $alertMessage, isShowingPicker: $isShowingPicker)
                        .frame(width: 0, height: 0) // ซ่อนไม่ให้เห็นตัวตน แต่เปิดให้ Lifecycle ทำงานร่วมกันได้
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
            // Alert ตั้งค่าตัวคูณความเร็ว
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
        .environment(\.colorScheme, .dark)
    }
}
