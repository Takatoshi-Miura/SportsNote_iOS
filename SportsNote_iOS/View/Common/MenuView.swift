import SwiftUI

struct MenuButton: View {
    @Binding var isMenuOpen: Bool
    
    var body: some View {
        Button(action: {
            isMenuOpen.toggle()
        }) {
            Image(systemName: "line.horizontal.3")
                .imageScale(.large)
        }
    }
}

struct MenuView: View {
    @Binding var isMenuOpen: Bool
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Color.black.opacity(0.3)
                    .onTapGesture {
                        isMenuOpen = false
                    }
                
                VStack(alignment: .leading) {
                    Text("Menu Item 1")
                    Text("Menu Item 2")
                    Text("Menu Item 3")
                }
                .frame(width: geometry.size.width * 0.7, height: geometry.size.height)
                .background(Color.gray)
                .offset(x: isMenuOpen ? 0 : -geometry.size.width)
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
}
