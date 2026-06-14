import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = BookViewModel()

    var body: some View {
        NavigationSplitView {
            SidebarView(viewModel: viewModel)
                .navigationSplitViewColumnWidth(min: 180, ideal: 220, max: 300)
        } detail: {
            BookPageView(viewModel: viewModel)
        }
        .onAppear {
            viewModel.loadHTMLFiles()
        }
    }
}
