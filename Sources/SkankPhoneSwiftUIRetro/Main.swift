import SwiftUI

@main
struct SkankPhoneApp: App {
    var body: some Scene {
        WindowGroup {
            VStack(spacing: 20) {
                Text("SkankPhone Retro")
                    .font(.largeTitle)
                    .bold()
                
                Button("測試按鈕") {
                    print("Hello World!")
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
}
