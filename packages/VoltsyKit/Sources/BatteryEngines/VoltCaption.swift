// Sources/BatteryEngines/VoltCaption.swift
// Short, warm one-liner shown under Volt on Home, mapping the current mood to character
// voice (spec F4). Pure — unit-tested.
import VoltsyCore

public enum VoltCaption {
    public static func text(for mood: VoltMood) -> String {
        switch mood {
        case .energetic:   return "Feeling great and full of energy!"
        case .content:     return "Comfy right here in the sweet spot."
        case .tired:       return "Getting a little sleepy… a top-up soon?"
        case .critical:    return "Running low — let's find a charger!"
        case .charging:    return "Mmm, soaking up the power."
        case .overcharged: return "I've been full a while — you can unplug me."
        case .overheating: return "I'm running warm — maybe take my case off?"
        case .zen:         return "Resting in Low Power Mode to make it last."
        }
    }
}
