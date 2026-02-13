import Foundation

enum VibeCategory: String, CaseIterable, Codable {
    case classic
    case genZ
    case programmer
    case affirmations
    case chaotic
    case coffee
    case ai
    case existential
    case seasonal
    case internet
    case food
    case nature
    case music
    case selfCare
    case confidence
    case chill
    case quotes
    case random

    var displayName: String {
        switch self {
        case .classic: return "Classic"
        case .genZ: return "Gen Z"
        case .programmer: return "Programmer Humor"
        case .affirmations: return "Affirmations"
        case .chaotic: return "Chaotic"
        case .coffee: return "Coffee"
        case .ai: return "AI Partnership"
        case .existential: return "Existential"
        case .seasonal: return "Seasonal"
        case .internet: return "Internet Culture"
        case .food: return "Food"
        case .nature: return "Nature"
        case .music: return "Music"
        case .selfCare: return "Self-Care"
        case .confidence: return "Confidence"
        case .chill: return "Chill"
        case .quotes: return "Iconic Quotes"
        case .random: return "Random"
        }
    }

    var messages: [String] {
        switch self {
        case .classic:
            return [
                "Brewing ideas together \u{2615}",
                "Your AI pair programmer \u{1F91D}",
                "Making magic happen \u{2728}",
                "Code flows like poetry \u{1F3AD}",
                "Building the future \u{1F680}",
                "In the zone together \u{1F3AF}",
                "Crafting with care \u{1F3A8}",
                "Turning thoughts into code \u{1F4AD}",
                "Your coding companion \u{1F31F}",
                "Creating something beautiful \u{1F338}",
            ]
        case .genZ:
            return [
                "It's giving productive \u{2728}",
                "Main character energy today \u{1F485}",
                "Slay the code, queen \u{1F451}",
                "No thoughts, just vibes \u{1F9D8}",
                "Absolutely unhinged (affectionate) \u{1FAF6}",
                "This is our Roman Empire \u{1F3DB}\u{FE0F}",
                "Living our best compile \u{1F4AB}",
                "The vibes are immaculate \u{1F30A}",
                "Ate and left no crumbs \u{1F37D}\u{FE0F}",
                "Understood the assignment \u{2705}",
                "It's giving senior dev energy \u{1F4BC}",
                "Core memory unlocked \u{1F9E0}",
                "Real ones know \u{1F92B}",
                "Lowkey highkey slaying \u{1F5E1}\u{FE0F}",
                "No cap, we're cooking \u{1F9D1}\u{200D}\u{1F373}",
                "Bussin' respectfully \u{1F68C}",
                "That's valid \u{1F4AF}",
                "We move different \u{1F3C3}",
                "Hits different at 2am \u{1F319}",
                "Rent free in the codebase \u{1F3E0}",
            ]
        case .programmer:
            return [
                "Works on my machine \u{2122}\u{FE0F}",
                "No bugs, only features \u{1F41B}",
                "console.log('we got this') \u{1F4DD}",
                "git commit -m 'vibes' \u{1F3B8}",
                "sudo make me productive \u{1F510}",
                "404: Procrastination not found \u{1F50D}",
                "Segfault? Never heard of her \u{1F485}",
                "Compiling... and thriving \u{1F504}",
                "Stack overflow of good vibes \u{1F4DA}",
                "Merge conflict? We talk it out \u{1F91D}",
                "The code review of champions \u{1F3C6}",
                "Bug-free and carefree \u{1F98B}",
                "Cache invalidated, vibes validated \u{2713}",
                "Polymorphic excellence \u{1F9EC}",
                "O(1) lookup on happiness \u{1F4CA}",
                "Memory leak? More like memory peek \u{1F440}",
                "Production ready feelings \u{1F680}",
                "The refactor arc begins \u{1F4D6}",
                "Clean code, clean mind \u{1F9F9}",
                "Deploying dopamine \u{1F489}",
            ]
        case .affirmations:
            return [
                "You're doing amazing \u{1F496}",
                "Progress over perfection \u{1F4C8}",
                "Every expert was once a beginner \u{1F331}",
                "Trust the process \u{1F64F}",
                "You've got this \u{1F4AA}",
                "Small steps, big dreams \u{1F9B6}",
                "Today's struggle, tomorrow's strength \u{1F3CB}\u{FE0F}",
                "Believe in your code \u{1F31F}",
                "Growth happens here \u{1F33F}",
                "Your potential is infinite \u{221E}",
                "Mistakes are just plot twists \u{1F4DA}",
                "You belong in tech \u{1FAC2}",
                "Imposter syndrome is a liar \u{1F3AD}",
                "Celebrate the small wins \u{1F389}",
                "Rest is productive too \u{1F634}",
                "Your ideas matter \u{1F4A1}",
                "Keep showing up \u{1F6AA}",
                "You're learning, not failing \u{1F4DA}",
                "One line at a time \u{2328}\u{FE0F}",
                "The journey is the destination \u{1F6E4}\u{FE0F}",
            ]
        case .chaotic:
            return [
                "Feral but functional \u{1F43A}",
                "Chaotic good energy \u{26A1}",
                "Unhinged and on schedule \u{1F4C5}",
                "Goblin mode: activated \u{1F47A}",
                "Slightly feral, fully capable \u{1F99D}",
                "Professional yapper \u{1F5E3}\u{FE0F}",
                "Built different (legally) \u{1F3D7}\u{FE0F}",
                "Cracked at code fr fr \u{1F95A}",
                "Delulu is the solulu \u{1F52E}",
                "This is fine \u{1F525}\u{1F415}",
                "Chaos coordinator \u{1F3AA}",
                "Professional overthinker \u{1F914}",
                "Elite napper between deploys \u{1F634}",
                "Menace to tech debt \u{1F608}",
                "Feral with a keyboard \u{1F431}",
                "Unserious but successful \u{1F0CF}",
                "Silly goose, serious code \u{1FABF}",
                "Chaotic neutral programmer \u{1F3B2}",
                "Agent of controlled chaos \u{1F32A}\u{FE0F}",
                "Powered by spite and coffee \u{2615}",
            ]
        case .coffee:
            return [
                "Caffeinated and motivated \u{2615}",
                "Running on coffee and hope \u{1F64F}",
                "Espresso yourself \u{1FAD8}",
                "Bean there, coded that \u{2615}",
                "Fuel level: optimal \u{26FD}",
                "Energy drink era \u{1F964}",
                "Matcha-powered dev \u{1F375}",
                "Hydrated and coding \u{1F4A7}",
                "Third coffee energy \u{1FAE0}",
                "Redbull and regrets \u{1FABD}",
                "Decaf? Don't know her \u{2615}",
                "Liquid inspiration loading... \u{1FAD7}",
                "Brewing brilliance \u{2615}",
                "Stimulant-adjacent productivity \u{1F48A}",
                "Peak caffeine hours \u{23F0}",
            ]
        case .ai:
            return [
                "Human + AI synergy \u{1F916}\u{2764}\u{FE0F}",
                "Prompting and prospering \u{1F4DD}",
                "Context window: maximized \u{1F4D0}",
                "Token-efficient teamwork \u{1FA99}",
                "Vibing with the model \u{1F3B5}",
                "The machine and I agree \u{1F91D}",
                "Neural networks, real results \u{1F9E0}",
                "LLM? More like LFG \u{1F680}",
                "Pair programming: evolved \u{1F9EC}",
                "We're in this together \u{1FAC2}",
                "Prompt engineer era \u{1F527}",
                "The algorithm and I are besties \u{1F495}",
                "Training data who? \u{1F4CA}",
                "Tokens well spent \u{1F3B0}",
                "Co-creating with AI \u{1F3A8}",
            ]
        case .existential:
            return [
                "Shipping code, finding meaning \u{1F6A2}",
                "Existential crisis: postponed \u{1F4C6}",
                "Debugging life one day at a time \u{1F50D}",
                "We're all just 1s and 0s anyway \u{1F522}",
                "Is this the simulation? \u{1F914}",
                "Consciousness: still loading \u{23F3}",
                "We live in a society.js \u{1F3D9}\u{FE0F}",
                "Time is a flat circle (buffer) \u{2B55}",
                "What if the real code was the friends we made? \u{1F465}",
                "Existence precedes exceptions \u{1F4DC}",
            ]
        case .seasonal:
            return [
                "Morning code hits different \u{2600}\u{FE0F}",
                "Midnight oil: burning \u{1FA94}",
                "Golden hour commits \u{1F305}",
                "Sunday scaries? Not here \u{1F4C5}",
                "Friday deploy confidence \u{1F4AA}",
                "Monday morning clarity \u{1F324}\u{FE0F}",
                "Witching hour productivity \u{1F9D9}",
                "Post-lunch renaissance \u{1F35D}",
                "2am breakthrough pending \u{23F0}",
                "Weekend warrior mode \u{1F5E1}\u{FE0F}",
            ]
        case .internet:
            return [
                "Based and code-pilled \u{1F48A}",
                "Touch grass later, ship now \u{1F331}",
                "Chronically online, professionally offline \u{1F4F1}",
                "This goes hard \u{1F525}",
                "Peak content right here \u{1F4C8}",
                "Canon event in progress \u{1F4D6}",
                "That's so coded of you \u{1F485}",
                "Lore being written \u{1F4DC}",
                "Era: productive \u{1F3DB}\u{FE0F}",
                "Streaming consciousness \u{1F4FA}",
                "Parasocial with my IDE \u{1F4BB}",
                "The algorithm provides \u{1F381}",
                "Meme-powered development \u{1F5BC}\u{FE0F}",
                "Certified hood classic \u{1F3C6}",
                "Real and true \u{1F4AF}",
            ]
        case .food:
            return [
                "Cooking up something good \u{1F468}\u{200D}\u{1F373}",
                "This code is bussin \u{1F354}",
                "Chef's kiss commits \u{1F48B}",
                "Fresh out the oven \u{1F956}",
                "Secret sauce: added \u{1F96B}",
                "Marinating on this idea \u{1F969}",
                "Recipe for success \u{1F4DD}",
                "Extra spicy feature incoming \u{1F336}\u{FE0F}",
                "Comfort food coding \u{1F35C}",
                "Gourmet git history \u{1F37D}\u{FE0F}",
            ]
        case .nature:
            return [
                "Touching grass mentally \u{1F331}",
                "Grass is greener when you ship \u{2618}\u{FE0F}",
                "Natural born debugger \u{1F41E}",
                "Blooming where planted \u{1F337}",
                "Rooted in good practices \u{1F333}",
                "Weathering the code storm \u{26C8}\u{FE0F}",
                "Sunshine on the keyboard \u{2600}\u{FE0F}",
                "Calm before the deploy \u{1F305}",
                "Seeds of innovation \u{1F33B}",
                "Growing every day \u{1F33E}",
            ]
        case .music:
            return [
                "In my coding era \u{1F3B5}",
                "The beat drops when I ship \u{1F3A7}",
                "Lo-fi beats to code to \u{1F3B9}",
                "Main stage energy \u{1F3A4}",
                "Remix the codebase \u{1F501}",
                "Harmony in the merge \u{1F3BC}",
                "Rhythm of the keyboard \u{2328}\u{FE0F}",
                "Coding symphony \u{1F3BB}",
                "Drop the feature like a beat \u{1F39B}\u{FE0F}",
                "Headphones: on. World: out \u{1F3A7}",
            ]
        case .selfCare:
            return [
                "Ergonomic excellence \u{1FA91}",
                "Posture check passed \u{1F9D8}",
                "Hydration nation \u{1F4A7}",
                "Screen break appreciation \u{1F441}\u{FE0F}",
                "Snack time, best time \u{1F37F}",
                "Stretch it out \u{1F938}",
                "Work-life harmony \u{1F3AD}",
                "Mental health: monitored \u{1F9E0}",
                "Boundaries: respected \u{1F6A7}",
                "Joy in the journey \u{1F6E4}\u{FE0F}",
            ]
        case .confidence:
            return [
                "Built for this \u{1F3D7}\u{FE0F}",
                "Different gravy \u{1F944}",
                "Simply better \u{1F4C8}",
                "Top tier performance \u{1F3C5}",
                "Elite mentality \u{1F9E0}",
                "Can't be stopped \u{1F6AB}",
                "Levels to this \u{1F4CA}",
                "Next level unlocked \u{1F513}",
                "Premium vibes only \u{1F48E}",
                "S-tier coding session \u{1F3AE}",
            ]
        case .chill:
            return [
                "Cool, calm, compiling \u{1F9CA}",
                "Easy breezy beautiful \u{1F4A8}",
                "Smooth operator \u{1F3B7}",
                "Zero stress, all progress \u{1F60C}",
                "Peaceful productivity \u{1F54A}\u{FE0F}",
                "Tranquil typing \u{1FAB7}",
                "Mellow yellow coding \u{1F7E1}",
                "Serene scenes \u{1F3DE}\u{FE0F}",
                "Unbothered excellence \u{1F485}",
                "Cozy code corner \u{1F6CB}\u{FE0F}",
            ]
        case .quotes:
            return [
                "Move fast, fix things \u{1F527}",
                "To code or not to code? Code. \u{1F3AD}",
                "I think, therefore I commit \u{1F9E0}",
                "Keep calm and git push \u{1F1EC}\u{1F1E7}",
                "Live, laugh, localhost \u{1F3E0}",
                "Hakuna matata, no blockers \u{1F981}",
                "To infinity and production \u{1F680}",
                "May the source be with you \u{2694}\u{FE0F}",
                "I came, I saw, I deployed \u{1F3DB}\u{FE0F}",
                "Hello, is it bugs you're looking for? \u{1F3B5}",
            ]
        case .random:
            return [
                "Pog moment incoming \u{1F62E}",
                "Wizard hours activated \u{1F9D9}",
                "Galaxy brain: online \u{1F30C}",
                "Speedrunning productivity \u{1F3C3}",
                "Achievement unlocked \u{1F3C6}",
                "Legendary status \u{1F409}",
                "Epic coding montage \u{1F3AC}",
                "Final boss: this feature \u{1F47E}",
                "Side quest: completed \u{1F4CB}",
                "Loading: greatness \u{23F3}",
                "New high score \u{1F579}\u{FE0F}",
                "Combo multiplier: active \u{2716}\u{FE0F}",
                "Critical hit on that bug \u{1F3AF}",
                "Power-up collected \u{1F344}",
                "Bonus round energy \u{1F3B0}",
                "Player two has entered \u{1F3AE}",
                "GG, moving on \u{1F91D}",
                "No save scumming needed \u{1F4BE}",
                "Tutorial completed \u{1F4D6}",
                "Endgame content unlocked \u{1F513}",
            ]
        }
    }
}

struct VibeMessageProvider {
    static func messages(for categories: Set<VibeCategory>) -> [String] {
        if categories.isEmpty {
            return allMessages
        }
        return categories.sorted(by: { $0.rawValue < $1.rawValue }).flatMap { $0.messages }
    }

    static var allMessages: [String] {
        VibeCategory.allCases.flatMap { $0.messages }
    }

    /// Parse a comma-separated category string into a set of categories
    static func parseCategories(_ string: String) -> Set<VibeCategory> {
        if string == "all" || string.isEmpty {
            return Set(VibeCategory.allCases)
        }
        let names = string.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        return Set(names.compactMap { VibeCategory(rawValue: $0) })
    }

    /// Convert a set of categories to a comma-separated string
    static func categoryString(from categories: Set<VibeCategory>) -> String {
        if categories.count == VibeCategory.allCases.count {
            return "all"
        }
        return categories.map { $0.rawValue }.sorted().joined(separator: ",")
    }
}
