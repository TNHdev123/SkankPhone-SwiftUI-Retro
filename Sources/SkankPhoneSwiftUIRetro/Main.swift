import SwiftUI
import Combine
import UIKit

// 全域狀態：用嚟控制目前顯示咩畫面
enum AppState {
    case main, phone, camera, sms
}

@main
struct SkankPhoneApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .statusBarHidden(true)
                .hideHomeBarIfPossible()
        }
    }
}

// 根據 iOS 16 判斷隱藏 Home Bar
extension View {
    @ViewBuilder
    func hideHomeBarIfPossible() -> some View {
        if #available(iOS 16.0, *) {
            self.persistentSystemOverlays(.hidden)
        } else {
            self
        }
    }
}

// 共用元件：頂部灰色狀態列
struct StatusBarView: View {
    @State private var currentTime = ""
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        HStack {
            Spacer()
            Text(currentTime)
                .foregroundColor(.white)
                .font(.system(size: 16, weight: .regular))
        }
        .padding(.horizontal, 10)
        .frame(height: 35)
        .background(Color(white: 0.6))
        .onReceive(timer) { input in updateTime(date: input) }
        .onAppear { updateTime(date: Date()) }
    }
    
    private func updateTime(date: Date) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        currentTime = formatter.string(from: date)
    }
}

// 根視圖：負責切換畫面（在此處進行全域安全區控制）
struct RootView: View {
    @State private var currentApp: AppState = .main
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // 用 Group 包住切換邏輯，全域移除頂部安全區
            Group {
                switch currentApp {
                case .main:
                    MainMenuView(currentApp: $currentApp)
                case .phone:
                    PhoneView(currentApp: $currentApp)
                case .camera:
                    CameraView(currentApp: $currentApp)
                case .sms:
                    SMSView(currentApp: $currentApp)
                }
            }
            .ignoresSafeArea(edges: .top) // <- 全域生效，所有子畫面頂部都會貼緊螢幕最上方
        }
    }
}

// 主選單視圖
struct MainMenuView: View {
    @Binding var currentApp: AppState
    
    let buttonLabels = [
        "Phone", "SMS", "Web", "Media",
        "Network\nSettings", "Power\nSettings",
        "More Other", "Playground",
        "Test Tools", "Operator"
    ]
    let columns = [GridItem(.flexible(), spacing: 20), GridItem(.flexible(), spacing: 20)]

    var body: some View {
        VStack(spacing: 0) {
            StatusBarView()
            Spacer().frame(height: 15)
            Text("Num: [No Data]").foregroundColor(.white).font(.system(size: 18))
            Spacer().frame(height: 25)
            
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(buttonLabels, id: \.self) { label in
                    Button(action: {
                        switch label { 
                        case "Phone":
                            currentApp = .phone
                        case "SMS":
                            currentApp = .sms
                        default:
                            print("\(label) tapped")
                        }
                    }) {
                        Text(label)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.black) // 修正：改回正常的黑色
                            .font(.system(size: 18, weight: .bold))
                            .frame(maxWidth: .infinity, minHeight: 60)
                            .background(Color(red: 0.2, green: 0.6, blue: 1.0))
                            .cornerRadius(12)
                    }
                }
            }
            .padding(.horizontal, 30)
            
            Spacer()
            
            VStack(spacing: 5) {
                Text("S/N: 5K809BGGWH8").foregroundColor(.white).font(.system(size: 14))
                Text("[Skank is the new black] [04.04.05_G]").foregroundColor(.white).font(.system(size: 12))
            }
            .padding(.bottom, 20)
        }
    }
}
