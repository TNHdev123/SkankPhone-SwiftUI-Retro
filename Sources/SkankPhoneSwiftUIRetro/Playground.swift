import SwiftUI
import CoreMotion
import AVFoundation
import UIKit

// --- 1. Playground 主選單介面 ---
struct PlaygroundView: View {
    @Binding var currentApp: AppState
    
    @State private var showAccelerometer = false
    @State private var showTileGame = false
    @State private var showMissionControl = false
    
    let skankBlue = Color(red: 0.2, green: 0.6, blue: 1.0)
    let skankRed = Color(red: 0.95, green: 0.25, blue: 0.0)
    
    var body: some View {
        ZStack {
            if showAccelerometer {
                AccelerometerView(showAccelerometer: $showAccelerometer)
            } else if showTileGame {
                TileGameView(currentApp: $currentApp)
            } else if showMissionControl {
                MissionControlView(currentApp: $currentApp)
            } else {
                // 主介面
                VStack(spacing: 0) {
                    StatusBarView()
                    
                    Spacer().frame(height: 30)
                    
                    VStack(spacing: 12) {
                        playgroundButton(title: "Tracker") {}
                        playgroundButton(title: "Accelerometer") { showAccelerometer = true }
                        playgroundButton(title: "Tile Game") { showTileGame = true }
                        playgroundButton(title: "Mission: Control") { showMissionControl = true }
                    }
                    .padding(.horizontal, 30)
                    
                    Spacer()
                    
                    // Main Menu 置底按鈕
                    Button(action: {
                        currentApp = .main
                    }) {
                        Text("Main Menu")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.black)
                            .frame(width: 160, height: 40)
                            .background(skankRed)
                            .cornerRadius(8)
                    }
                    .padding(.bottom, 40)
                }
                .background(Color.black.ignoresSafeArea())
            }
        }
    }
    
    private func playgroundButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(skankBlue)
                .cornerRadius(8)
        }
    }
}


// --- 2. Accelerometer (陀螺儀) 介面 ---
struct AccelerometerView: View {
    @Binding var showAccelerometer: Bool
    @StateObject private var motion = MotionManager()
    
    let skankRed = Color(red: 0.95, green: 0.25, blue: 0.0)
    let skankBlue = Color(red: 0.2, green: 0.6, blue: 1.0)
    
    var body: some View {
        VStack(spacing: 0) {
            // 頂部座標顯示欄 (無系統狀態列)
            HStack {
                Text(String(format: "x: %.2f", motion.x))
                    .foregroundColor(Color.green.opacity(0.8))
                Spacer()
                Text(String(format: "y: %.2f", motion.y))
                    .foregroundColor(.white)
                Spacer()
                Text(String(format: "z: %.2f", motion.z))
                    .foregroundColor(.white)
                Spacer()
                Text("6:14")
                    .foregroundColor(.white)
                Image(systemName: "play.fill")
                    .foregroundColor(.white)
                    .font(.system(size: 10))
            }
            .font(.system(size: 14, weight: .bold))
            .padding(.horizontal, 10)
            .padding(.top, 40)
            .padding(.bottom, 5)
            .background(Color.gray.opacity(0.4))
            
            // Reset 按鈕
            Button(action: {
                motion.reset()
            }) {
                Text("Reset")
                    .font(.system(size: 14))
                    .foregroundColor(.black)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(skankRed)
                    .cornerRadius(6)
            }
            .padding(.top, 5)
            
            Spacer()
            
            // 藍色大正方形框與紅點
            ZStack {
                Rectangle()
                    .stroke(skankBlue, lineWidth: 4)
                    .frame(width: 280, height: 280)
                
                Circle()
                    .fill(skankRed)
                    .frame(width: 26, height: 26)
                    .offset(x: motion.dotX, y: motion.dotY)
            }
            
            Spacer()
            
            // Back 按鈕 (返回 Playground 選單)
            Button(action: {
                showAccelerometer = false
            }) {
                Text("Back")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black)
                    .frame(width: 160, height: 40)
                    .background(skankRed)
                    .cornerRadius(8)
            }
            .padding(.bottom, 40)
        }
        .background(Color.black.ignoresSafeArea())
        .onAppear { motion.start() }
        .onDisappear { motion.stop() }
    }
}

// 陀螺儀數據處理邏輯
class MotionManager: ObservableObject {
    private var manager = CMMotionManager()
    @Published var x: Double = 0.0
    @Published var y: Double = 0.0
    @Published var z: Double = 0.0
    
    @Published var dotX: CGFloat = 0.0
    @Published var dotY: CGFloat = 0.0
    
    func start() {
        if manager.isAccelerometerAvailable {
            manager.accelerometerUpdateInterval = 1.0 / 60.0
            manager.startAccelerometerUpdates(to: OperationQueue.main) { [weak self] data, _ in
                guard let self = self, let data = data else { return }
                self.x = data.acceleration.x
                self.y = data.acceleration.y
                self.z = data.acceleration.z
                
                // 裝置上方斜落去，球會滑向上方
                let newX = self.dotX + CGFloat(data.acceleration.x * 12)
                let newY = self.dotY - CGFloat(data.acceleration.y * 12)
                
                self.dotX = max(min(newX, 125), -125)
                self.dotY = max(min(newY, 125), -125)
            }
        }
    }
    
    func stop() {
        manager.stopAccelerometerUpdates()
    }
    
    func reset() {
        dotX = 0
        dotY = 0
    }
}


// --- 3. Tile Game (相機) 介面 ---
struct TileGameView: View {
    @Binding var currentApp: AppState
    @StateObject private var camera = TileGameCameraModel() // 已改名
    
    let skankBlue = Color(red: 0.2, green: 0.6, blue: 1.0)
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 上半部：相機畫面
                TileGameCameraPreview(camera: camera) // 已改名
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                
                // 下半部：控制面板
                HStack(spacing: 20) {
                    // 灰色方格 (顯示相片)
                    ZStack {
                        Rectangle()
                            .fill(Color.gray.opacity(0.8))
                            .frame(width: 80, height: 80)
                        
                        if let image = camera.capturedImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .clipped()
                        }
                    }
                    .padding(.leading, 30)
                    
                    // Set Image / Clear Image 按鈕
                    Button(action: {
                        if camera.capturedImage == nil {
                            camera.capture()
                        } else {
                            camera.capturedImage = nil
                        }
                    }) {
                        Text(camera.capturedImage == nil ? "Set Image" : "Clear Image")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .background(skankBlue)
                            .cornerRadius(8)
                    }
                    .padding(.trailing, 30)
                }
                .frame(height: 120)
                .background(Color.black)
            }
        }
        // 長按 1 秒直接退回 Main Menu
        .onLongPressGesture(minimumDuration: 1.0) {
            currentApp = .main
        }
        .onAppear { camera.check() }
        .onDisappear { camera.stop() }
    }
}

// 相機控制邏輯 (已改名避免衝突)
class TileGameCameraModel: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {
    @Published var session = AVCaptureSession()
    @Published var capturedImage: UIImage?
    private let output = AVCapturePhotoOutput()
    
    func check() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: setup()
        case .notDetermined: AVCaptureDevice.requestAccess(for: .video) { granted in if granted { self.setup() } }
        default: break
        }
    }
    
    private func setup() {
        DispatchQueue.global(qos: .userInitiated).async {
            guard let device = AVCaptureDevice.default(for: .video),
                  let input = try? AVCaptureDeviceInput(device: device) else { return }
            
            self.session.beginConfiguration()
            if self.session.canAddInput(input) { self.session.addInput(input) }
            if self.session.canAddOutput(self.output) { self.session.addOutput(self.output) }
            self.session.commitConfiguration()
            self.session.startRunning()
        }
    }
    
    func stop() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.session.stopRunning()
        }
    }
    
    func capture() {
        let settings = AVCapturePhotoSettings()
        output.capturePhoto(with: settings, delegate: self)
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let data = photo.fileDataRepresentation(), let image = UIImage(data: data) {
            DispatchQueue.main.async {
                self.capturedImage = image
            }
        }
    }
}

// 自訂 UIKit 視圖類別 (已改名避免衝突)
class TileGameUIKitCameraPreview: UIView {
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
    
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }
}

// (已改名避免衝突)
struct TileGameCameraPreview: UIViewRepresentable {
    @ObservedObject var camera: TileGameCameraModel
    
    func makeUIView(context: Context) -> TileGameUIKitCameraPreview {
        let view = TileGameUIKitCameraPreview()
        view.videoPreviewLayer.session = camera.session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }
    
    func updateUIView(_ uiView: TileGameUIKitCameraPreview, context: Context) {}
}



// --- 4. Mission: Control 橫向介面 ---
struct MissionControlView: View {
    @Binding var currentApp: AppState
    let skankBlue = Color(red: 0.2, green: 0.6, blue: 1.0)
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.ignoresSafeArea()
                
                HStack(spacing: 0) {
                    // 左側：控制面板圖樣
                    ZStack {
                        VStack(spacing: 10) {
                            ZStack {
                                Circle().stroke(Color.white, lineWidth: 2).frame(width: 50)
                                Circle().stroke(Color.white, lineWidth: 1).frame(width: 30)
                                Image(systemName: "play.fill").foregroundColor(.white).rotationEffect(.degrees(-90))
                            }
                            Circle().stroke(Color.white, lineWidth: 1).frame(width: 30)
                                .overlay(Text("Option").font(.system(size: 8)).foregroundColor(.white))
                        }
                        .position(x: 60, y: 80)
                        
                        // 方向鍵
                        VStack(spacing: 30) {
                            Image(systemName: "triangle.fill").foregroundColor(.gray)
                            HStack(spacing: 60) {
                                Image(systemName: "triangle.fill").foregroundColor(.gray).rotationEffect(.degrees(-90))
                                Image(systemName: "triangle.fill").foregroundColor(.gray).rotationEffect(.degrees(90))
                            }
                            Image(systemName: "triangle.fill").foregroundColor(.gray).rotationEffect(.degrees(180))
                        }
                        .position(x: 180, y: geo.size.width / 2)
                    }
                    .frame(maxWidth: .infinity)
                    
                    // 右側：連線表單與 Quit 按鈕
                    VStack(spacing: 0) {
                        Text("192.168.1.7")
                            .font(.system(size: 13))
                            .foregroundColor(.black)
                            .frame(width: 110, height: 32)
                            .background(Color.white)
                        
                        Button(action: {}) {
                            Text("Connect")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 110, height: 32)
                                .background(skankBlue)
                        }
                        
                        Button(action: {
                            currentApp = .main
                        }) {
                            Text("Quit")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 110, height: 32)
                                .background(skankBlue)
                        }
                    }
                    .border(Color.white, width: 2)
                    .padding(.trailing, 30)
                }
            }
            .frame(width: geo.size.height, height: geo.size.width)
            .rotationEffect(.degrees(-90))
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
        .background(Color.black.ignoresSafeArea())
    }
}
