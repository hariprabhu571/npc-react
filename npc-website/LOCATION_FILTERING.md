# Location-Based Service Filtering

## Overview
The User Dashboard now supports location-based filtering of services. When a user selects a city, only services available in that location are displayed.

## Features

### 1. Location Selection
- **Manual Input**: Users can type a city name in the location input field
- **Auto-suggestions**: Dropdown shows matching cities as the user types
- **Location Detection**: GPS-based automatic location detection (requires user permission)
- **Enter Key Support**: Press Enter to apply the location filter

### 2. Visual Indicators
- **Filter Status**: Shows which location is currently active
- **Service Count**: Displays the number of services available in the selected location
- **Clear Filter**: Easy way to remove location filter and view all services
- **Loading States**: Shows loading indicators during API calls

### 3. Empty State Handling
- **No Services Message**: When no services are available in a location
- **Helpful Guidance**: Suggests trying different locations or contacting support
- **Quick Reset**: Button to view all services when filtered results are empty

## Technical Implementation

### Frontend Changes
1. **API Service** (`src/services/api.ts`):
   - Modified `getServices()` to accept optional `location` parameter
   - Changed from GET to POST request to support location filtering

2. **User Dashboard** (`src/pages/UserDashboard.tsx`):
   - Updated React Query to include location in the query key
   - Added location-based refetching
   - Enhanced UI with filter indicators and empty states

### Backend Support
The backend (`backend/fetch_services.php`) already supports location filtering:
- Uses `JSON_SEARCH` function to filter services by location
- Accepts `location` parameter via POST request
- Returns filtered results with metadata

## Usage Examples

### Selecting Chennai
When a user selects "Chennai", the system will:
1. Send a POST request to `fetch_services.php` with `location: "Chennai"`
2. Backend filters services where `locations` JSON field contains "Chennai"
3. Frontend displays only services available in Chennai
4. Shows indicator: "Showing X services available in Chennai"

### Available Cities
Based on the sample data, services are available in:
- Chennai
- Coimbatore  
- Erode
- Salem

### Clearing Filter
Users can clear the location filter by:
- Clicking "Clear filter" button
- Clearing the location input field
- This will show all available services

## Data Structure
Services in the database have a `locations` field containing a JSON array of available cities:
```json
{
  "service_id": "1",
  "service_name": "Rat Control",
  "locations": "[\"Chennai\",\"Coimbatore\",\"Erode\",\"Salem\"]"
}
```

## Future Enhancements
1. **Dynamic City List**: Fetch available cities from backend API
2. **Multiple Location Selection**: Allow users to select multiple cities
3. **Location-based Offers**: Extend filtering to offers as well
4. **Geolocation API**: Integrate with proper geocoding service
5. **Location History**: Remember user's preferred locations 