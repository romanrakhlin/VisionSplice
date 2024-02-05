import SwiftUI

struct ContentView: View {
    var body: some View {
        CameraView(action: { url, data in
            print(url)
            print(data.count)
        })
    }
}
