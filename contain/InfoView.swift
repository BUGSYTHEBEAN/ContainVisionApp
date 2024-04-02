//
//  InfoView.swift
//  contain
//
//  Created by Andrei Freund on 3/29/24.
//

import SwiftUI

struct InfoView: View {
    var body: some View {
        Text("How to play:")
        Text("1. Use the sliders to position the next ball")
        Text("2. Press \"Drop\" to drop the ball at the current position")
        Text("3. Balls of equal size combine to next level")
        Text("4. 10pts * level number per combine")
    }
}

#Preview {
    InfoView()
}
