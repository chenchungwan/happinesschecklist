import SwiftUI

struct CategoryInfoView: View {
    let category: ContentView.Category
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(categoryDescription)
                        .font(.body)
                        .padding(.horizontal)
                }
                .padding(.top)
            }
            .navigationTitle(categoryTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var categoryTitle: String {
        switch category {
        case .gratitude: return "Gratitude"
        case .kindness: return "Kindness"
        case .connection: return "Connection"
        case .meditation: return "Meditation"
        case .savor: return "Savor"
        case .exercise: return "Exercise"
        case .sleep: return "Sleep"
        }
    }
    
    private var categoryDescription: String {
        switch category {
        case .gratitude:
            return """
            Gratitude is a positive emotional state in which one recognizes and appreciates what one has received in life.
            
            Research shows that taking time to experience gratitude can make you happier and even healthier. Take 5-10 minutes to write down one thing for which you are grateful. They can be little things or big things. But you really have to focus on them and actually write them down. You can just write a word or short phrase, but as you write these things down, take a moment to be mindful of the things you're writing about (e.g., imagine the person or thing you're writing about, etc.).
            """
        case .kindness:
            return """
            Research shows that happy people are motivated to do kind things for others. Try to perform at least one act of kindness beyond what you normally do.
            
            These do not have to be over-the-top or time-intensive acts, but they should be something that really helps or impacts another person. For example, help your colleague with something, give a few dollars or some time to a cause you believe in, say something kind to a stranger, write a thank you note, give blood, and so on.
            """
        case .connection:
            return """
            Research shows that happy people spend more time with others and have a richer set of social connections than unhappy people. Studies even show that the simple act of talking to a stranger on the street can boost our mood more than we expect.
            
            Try to focus on making one new social connection per day. It can be a small 5-minute act like sparking a conversation with someone on public transportation, asking a coworker about his/her day, or even chatting to the barista at a coffee shop. The key is that you must take the time needed to genuinely connect with another person. Notice how you feel when you jot it down.
            """
        case .meditation:
            return """
            Meditation is a practice of intentionally turning your attention away from distracting thoughts toward a single point of reference (e.g., the breath, bodily sensations, compassion, a specific thought, etc.).
            
            Research shows that meditation can have a number of positive benefits, including more positive moods, increased concentration, and more feelings of social connection. Spend (at least) 10 minutes per day meditating. Find a quiet spot where you won't be disturbed while you're meditating. And remember—meditation isn't about the meditation itself; it's about building a skill that we can use later.
            """
        case .savor:
            return """
            Savoring is the act of stepping outside of an experience to review and appreciate it. Savoring intensifies and lengthens the positive emotions that come with doing something you love.
            
            Practice the art of savoring by picking one experience to truly savor each day. It could be a nice shower, a delicious meal, a great walk outside, or any experience that you really enjoy. When you take part in this savored experience, be sure to practice some common techniques that enhance savoring. These techniques include: sharing the experience with another person, thinking about how lucky you are to enjoy such an amazing moment, keeping a souvenir or photo of that activity, and making sure you stay in the present moment the entire time.
            """
        case .exercise:
            return """
            Research suggests that ~30 minutes a day of exercise can boost your mood in addition to making your body healthier. Spend each day getting your body moving with at least 30 minutes of exercise.
            
            Set aside a location and time (write it in your calendar!). Then hit the treadmill at the gym, do an online yoga class, or throw on some headphones and dance around your room to cheesy pop songs. This isn't supposed to be a marathon-level of activity; it's just to get your body moving a bit more than usual. Be sure to take a moment to notice how much better you feel after getting some exercise in.
            """
        case .sleep:
            return """
            One of the reasons we're so unhappy in our modern lives is that we're consistently sleep deprived. Research shows that sleep can improve your mood more than we often expect.
            
            For the next week, aim to get at least seven hours of sleep. I know, I know. You're super busy this week. There are deadlines to meet, friends to see, errands to run, etc. But sleep is going to make you feel better— both physically and mentally. Also be sure to practice good sleep hygiene too— no devices before bed and try to avoid caffeine and alcohol late in the day.
            """
        }
    }
}
