//
//  LocationPickerView.swift
//  TitanMart
//

import SwiftUI

struct LocationPickerView: View {
    @Binding var selectedLocation: String
    @Environment(\.dismiss) var dismiss
    @State private var buildingFilter = "All"
    
    var filteredLocations: [CampusLocation] {
        if buildingFilter == "All" {
            return CampusLocation.popularMeetupSpots
        } else {
            return CampusLocation.popularMeetupSpots.filter { $0.buildingCode == buildingFilter }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Building Filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.sm) {
                        ForEach(["All"] + CampusLocation.allBuildings, id: \.self) { building in
                            Button(building) {
                                buildingFilter = building
                            }
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, Spacing.md)
                            .padding(.vertical, Spacing.sm)
                            .background(buildingFilter == building ? Color.titanBlue : Color(.systemGray6))
                            .foregroundColor(buildingFilter == building ? .white : .primary)
                            .cornerRadius(CornerRadius.medium)
                        }
                    }
                    .padding(.horizontal, Spacing.lg)
                    .padding(.vertical, Spacing.md)
                }
                .background(Color.cardBackground)
                
                // Locations List
                List(filteredLocations) { location in
                    Button(action: {
                        selectedLocation = location.name
                        dismiss()
                    }) {
                        LocationRow(location: location)
                    }
                    .listRowBackground(Color.clear)
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("Choose Campus Location")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Cancel") {
                dismiss()
            })
        }
    }
}

struct LocationRow: View {
    let location: CampusLocation
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text(location.name)
                    .font(.headline)
                    .foregroundColor(.titanBlue)
                
                Spacer()
                
                Text(location.buildingCode)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xs)
                    .background(Color.titanBlue.opacity(0.1))
                    .foregroundColor(.titanBlue)
                    .cornerRadius(CornerRadius.small)
            }
            
            Text(location.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(location.instructions)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .padding(.vertical, Spacing.sm)
        .contentShape(Rectangle())
    }
}

#Preview {
    LocationPickerView(selectedLocation: .constant(""))
}
