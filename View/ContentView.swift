import SwiftUI

// FIXME: remove when we use better test data
extension String: Identifiable {
	public var id: String {
		return self
	}
}

struct ContentView: View {

	// FIXME: test data, fetch from database
	var cardGames: [String] = ["Hello", "World"]

    var body: some View {
		NavigationView {
			List(cardGames) { cardGame in
				Text(cardGame)
			}
			Text("Hello, World!")
				.frame(maxWidth: .infinity, maxHeight: .infinity)
		}
    }
}


struct ContentView_Previews: PreviewProvider {
	static var previews: some View {
		ContentView()
	}
}
