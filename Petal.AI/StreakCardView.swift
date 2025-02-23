import SwiftUI

struct StreakCardView: View {
    @State private var weeklyStreak: [Bool] = Array(repeating: false, count: 7)
    @State private var streakCount = 0
    @State private var lastInteractionDate: Date? = nil
    
    private func getDayName(for dayIndex: Int) -> String {
        let days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        return days[dayIndex]
    }
    
    private func updateStreak() {
        let calendar = Calendar.current
        let today = Date()
        
        // Get start of current week (Sunday)
        let currentWeekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today))!
        
        // Get dates for current week
        let weekDates = (0..<7).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: currentWeekStart)
        }
        
        // Reset weekly streak array for the new week
        weeklyStreak = Array(repeating: false, count: 7)
        
        // Update this week's streak based on recent interactions
        for (index, date) in weekDates.enumerated() {
            // Check if there was an interaction on this day
            let dayStart = calendar.startOfDay(for: date)
            let interaction = UserDefaults.standard.object(forKey: "lastInteractionDate_\(dayStart)") as? Date
            weeklyStreak[index] = interaction != nil
        }
        
        // Save weekly streak to UserDefaults
        UserDefaults.standard.set(weeklyStreak, forKey: "weeklyStreak")
        
        // Calculate streak count based on consecutive days of interaction
        var count = 0
        if let lastInteraction = lastInteractionDate {
            // Check if there's an interaction today
            if calendar.isDateInToday(lastInteraction) {
                count = 1
                var currentDate = calendar.startOfDay(for: today)
                
                // Check previous days
                while true {
                    guard let previousDate = calendar.date(byAdding: .day, value: -1, to: currentDate) else { break }
                    
                    // Check if there was an interaction on the previous day
                    let previousInteraction = UserDefaults.standard.object(forKey: "lastInteractionDate_\(previousDate)") as? Date
                    if previousInteraction != nil {
                        count += 1
                        currentDate = previousDate
                    } else {
                        break
                    }
                }
            }
        }
        
        streakCount = count
        
        // Save today's interaction date with a unique key
        if let interaction = lastInteractionDate,
           calendar.isDateInToday(interaction) {
            UserDefaults.standard.set(interaction, forKey: "lastInteractionDate_\(calendar.startOfDay(for: today))")
        }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Weekly Streak")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.bottom, 5)
            
            VStack(spacing: 16) {
                // Current week
                VStack(alignment: .leading, spacing: 8) {
                    Text("This Week")
                        .foregroundColor(.white)
                        .font(.subheadline)
                    
                    HStack(spacing: 12) {
                        ForEach(0..<7, id: \.self) { day in
                            VStack {
                                Circle()
                                    .fill(weeklyStreak[day] ? Theme.accentColor : Color.white.opacity(0.3))
                                    .frame(width: 35, height: 35)
                                Text(getDayName(for: day))
                                    .font(.caption)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    
                    // Streak Counter
                    HStack {
                        Text("Your Learning Streak is \(streakCount) day(s)")
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .padding(.top, 8)
                    }
                }
            }
        }
        .onAppear {
            // Load the saved streak and last interaction date from UserDefaults
            if let savedStreak = UserDefaults.standard.array(forKey: "weeklyStreak") as? [Bool] {
                weeklyStreak = savedStreak
            }
            lastInteractionDate = UserDefaults.standard.object(forKey: "lastInteractionDate") as? Date
            updateStreak() // Update streak when the view appears
        }
    }
}
