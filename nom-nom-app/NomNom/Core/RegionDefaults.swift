import Foundation

enum RegionDefaults {
    static func measurementSystem() -> MeasurementSystem {
        if #available(iOS 16.0, *) {
            if Locale.current.region?.identifier == "US" || Locale.current.measurementSystem == .us {
                return .imperial
            }
        } else {
            if Locale.current.regionCode == "US" {
                return .imperial
            }
        }
        return .metric
    }
}
