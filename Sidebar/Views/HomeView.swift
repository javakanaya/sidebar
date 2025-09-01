//
//  HomeView.swift
//  Sidebar
//
//  Created by Java Kanaya Prada on 01/09/25.
//

import SwiftUI

struct HomeView: View {
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 16) {
                Image(systemName: "house.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Welcome Home")
                    .font(.largeTitle)
                    .fontWeight(.bold)
            }
            
            // Content
            VStack(spacing: 16) {
                Text("This is your home dashboard")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                    DashboardCard(title: "Quick Actions", icon: "bolt.fill", color: .orange)
                    DashboardCard(title: "Recent Items", icon: "clock.fill", color: .green)
                    DashboardCard(title: "Statistics", icon: "chart.bar.fill", color: .purple)
                    DashboardCard(title: "Notifications", icon: "bell.fill", color: .red)
                }
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("Home")
    }
}

struct DashboardCard: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 30))
                .foregroundColor(color)
            
            Text(title)
                .font(.headline)
                .multilineTextAlignment(.center)
        }
        .frame(height: 100)
        .frame(maxWidth: .infinity)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

#Preview {
    NavigationView {
        HomeView()
    }
}
