# BloomingtonBuzz

BloomingtonBuzz is an iOS application that helps users discover and explore events happening around Indiana University Bloomington. The app provides a map-based interface to find nearby events, filter them by type and distance, and access event details.

## Features

- **Map View**: Interactive map showing events around the IU Bloomington campus
- **Event Discovery**: Browse events happening on specific dates
- **Location-Based Filtering**: Find events near your current location
- **Distance Filter**: Set a custom radius to view events within a specified distance
- **Event Categorization**: Events are categorized by type (academic, sports, cultural, social, etc.)
- **Event Details**: View comprehensive information about events including time, location, and description
- **Navigation**: Get directions to event locations

## Requirements

- iOS 18.0+
- Xcode 16.0+
- Swift 5.0+

## Installation

1. Clone the repository:
   ```
   git clone https://github.com/yourusername/BloomingtonBuzz.git
   ```

2. Open the project in Xcode:
   ```
   cd BloomingtonBuzz
   open BloomingtonBuzz.xcodeproj
   ```

3. Install dependencies using Swift Package Manager (if prompted)

4. Build and run the project on your simulator or device

## Architecture

BloomingtonBuzz follows a standard SwiftUI architecture:

- **Models**: Data structures representing events and related information
- **Views**: SwiftUI views for displaying the user interface
- **Services**: Components handling data fetching, location services, and storage

## Key Components

- **EventService**: Manages event data retrieval and filtering
- **LocationManager**: Handles device location tracking and authorization
- **MapView**: Displays events on an interactive map
- **Event**: Model representing event data with details like time, location, and type

## Future Enhancements

- Real-time event data from the IU Events API
- Favorites and bookmarking functionality
- Push notifications for upcoming events
- Calendar integration
- User accounts and personalized recommendations

## License

[Include appropriate license information here]

## Acknowledgements

- Indiana University for event information
- [Add any other acknowledgements or third-party libraries used]

## Contributors

- Ishan Apte - Lead Developer

## Contact

For any questions, suggestions, or feedback, please feel free to:
- Open an issue on GitHub
- Email: [Add your email address]
- Connect on LinkedIn: [Add your LinkedIn profile]