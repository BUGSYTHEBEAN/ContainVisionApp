//
//  InfoView.swift
//  contain
//
//  Created by Andrei Freund on 3/29/24.
//

import SwiftUI

struct InfoView: View {
    var body: some View {
        VStack {
            Text("How to Play").font(.largeTitle)
            Text("1. Pinch and drag to position the next planet").frame(maxWidth: 400, alignment: .leading)
            Text("2. Tap to drop the planet at the current location").frame(maxWidth: 400, alignment: .leading)
            Text("3. Like planets combine on touch").frame(maxWidth: 400, alignment: .leading)
            Text("4. Score = 10 * planet index per combine").frame(maxWidth: 400, alignment: .leading)
            Text("5. You lose if a planet falls out of the container").frame(maxWidth: 400, alignment: .leading)
            Text("6. Re-set the game at any time with the reload button").frame(maxWidth: 400, alignment: .leading)
        }
    }
}

#Preview {
    InfoView()
}
