import SwiftUI
import AVKit
import PhotosUI

struct MainView: View {
    @StateObject private var vm = StudioViewModel()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // شريط علوي
                HStack {
                    Text("WHITE STUDIO")
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding()
                .background(.ultraThinMaterial)

                // مشغل الفيديو الحقيقي أو شاشة الترحيب
                ZStack {
                    if let player = vm.player {
                        VideoPlayer(player: player)
                            .aspectRatio(contentMode: .fill)
                            .edgesIgnoringSafeArea(.all)
                    } else {
                        VStack(spacing: 15) {
                            Image(systemName: "film")
                                .font(.system(size: 50))
                                .foregroundColor(.white.opacity(0.5))
                            Text(vm.statusText)
                                .foregroundColor(.white)
                                .font(.system(size: 14))
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // شريط الأدوات السفلي الفعّال
                VStack(spacing: 12) {
                    Text(vm.statusText)
                        .font(.system(size: 11))
                        .foregroundColor(.yellow)

                    HStack(spacing: 15) {
                        // زر اختيار فيديو حقيقي من الهاتف
                        PhotosPicker(selection: $vm.selectedItem, matching: .videos) {
                            Label("اختر فيديو", systemImage: "plus.circle.fill")
                                .font(.system(size: 13, weight: .bold))
                                .padding(10)
                                .background(.blue, in: Capsule())
                                .foregroundColor(.white)
                        }
                        .onChange(of: vm.selectedItem) { newItem in
                            Task { await vm.loadVideo(from: newItem) }
                        }

                        // زر استخراج الصوت الحقيقي
                        Button(action: { vm.extractAudio() }) {
                            Label("استخراج الصوت", systemImage: "waveform")
                                .font(.system(size: 13, weight: .bold))
                                .padding(10)
                                .background(.purple, in: Capsule())
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
            }
        }
    }
}
