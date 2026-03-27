//
//  ContentView.swift
//  PlayerSwiftUI
//
//  Created by D. Neha Reddy on 27/03/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            NavigationLink(destination: FastPixPlayerView()) {
                
                VStack(spacing: 16) {
                    
                    Text("FastPix Player")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                    
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.2))
                            .frame(width: 90, height: 90)
                        
                        Image(systemName: "play.fill")
                            .resizable()
                            .frame(width: 30, height: 30)
                            .foregroundColor(.white)
                    }
                    
                    Text("Play Videos")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
                .background(
                    LinearGradient(
                        colors: [Color.blue.opacity(0.7), Color.purple.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(20)
                .shadow(color: Color.blue.opacity(0.4), radius: 10, x: 0, y: 6)
                .padding(.horizontal, 24)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.ignoresSafeArea())
            .navigationBarHidden(true) // 👈 Clean OTT look
        }
        .navigationViewStyle(.stack)
    }
}
