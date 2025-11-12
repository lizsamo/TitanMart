//
//  MeetupSchedulerView.swift
//  TitanMart
//

import SwiftUI

struct MeetupSchedulerView: View {
    @Binding var meetingLocation: String
    @Binding var meetingTime: Date?
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedDate = Date()
    @State private var selectedTime = Date()
    @State private var notes = ""
    
    // Generate next 7 weekdays
    var availableDates: [Date] {
        let calendar = Calendar.current
        let today = Date()
        var dates: [Date] = []
        
        for dayOffset in 1...14 {
            if let date = calendar.date(byAdding: .day, value: dayOffset, to: today) {
                let components = calendar.dateComponents([.weekday], from: date)
                if let weekday = components.weekday, (2...6).contains(weekday) {
                    dates.append(date)
                }
            }
        }
        return dates
    }
    
    // Generate time slots (9 AM - 5 PM, 30-min intervals)
    var timeSlots: [Date] {
        let calendar = Calendar.current
        var slots: [Date] = []
        
        for hour in 9...17 {
            for minute in [0, 30] {
                if let slot = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: selectedDate) {
                    slots.append(slot)
                }
            }
        }
        return slots
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Selected Location Display
                Section(header: Text("Selected Location")) {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(meetingLocation)
                            .font(.headline)
                            .foregroundColor(.titanBlue)
                        
                        if let location = CampusLocation.popularMeetupSpots.first(where: { $0.name == meetingLocation }) {
                            Text(location.instructions)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, Spacing.xs)
                }
                
                // Date Selection
                Section(header: Text("Meetup Date")) {
                    Picker("Select Date", selection: $selectedDate) {
                        ForEach(availableDates, id: \.self) { date in
                            Text(date, style: .date)
                                .tag(date)
                        }
                    }
                    .pickerStyle(.navigationLink)
                }
                
                // Time Selection
                Section(header: Text("Meetup Time")) {
                    Picker("Select Time", selection: $selectedTime) {
                        ForEach(timeSlots, id: \.self) { time in
                            Text(time, style: .time)
                                .tag(time)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 150)
                }
                
                // Additional Notes
                Section(header: Text("Additional Notes (Optional)")) {
                    TextField("Any special instructions for the seller...", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                // Schedule Button
                Section {
                    Button(action: scheduleMeetup) {
                        HStack {
                            Image(systemName: "calendar.badge.plus")
                            Text("Schedule Meetup")
                            Spacer()
                            Text(combinedDateTime, style: .date)
                                .font(.caption)
                            Text(combinedDateTime, style: .time)
                                .font(.caption)
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.titanBlue)
                        .cornerRadius(CornerRadius.medium)
                    }
                }
            }
            .navigationTitle("Schedule Meetup")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button("Cancel") {
                dismiss()
            })
        }
    }
    
    private var combinedDateTime: Date {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: selectedTime)
        
        return calendar.date(
            from: DateComponents(
                year: dateComponents.year,
                month: dateComponents.month,
                day: dateComponents.day,
                hour: timeComponents.hour,
                minute: timeComponents.minute
            )
        ) ?? selectedDate
    }
    
    private func scheduleMeetup() {
        meetingTime = combinedDateTime
        print("✅ Meetup scheduled: \(meetingLocation) at \(combinedDateTime)")
        dismiss()
    }
}

#Preview {
    MeetupSchedulerView(
        meetingLocation: .constant("Pollak Library - Front Entrance"),
        meetingTime: .constant(nil)
    )
}
