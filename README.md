# SmartHealthFood

An AI-powered mobile app that helps people eat healthier. Take a photo of your meal and get an instant estimate of its calories, nutrition, allergens and health score, then track your daily progress and find healthy places to eat nearby.

> Final Year Project (FYP) — [Your Full Name], [Programme], [University], [Year]
> Supervisor: [Supervisor's Name]

---

## About the project

Many people want to eat better but find it slow and confusing to look up and log the nutrition of every meal. SmartHealthFood makes it quick: point the camera at your food, and the app uses the Google Gemini API to recognise the dish and estimate its nutrition. Your meals are saved to your account so you can follow your calorie intake over the week, set your own daily goal, and discover healthy restaurants on a map.

## Features

- **AI food scanner** – take a photo or choose one from the gallery to get the food name, estimated calories, protein, carbs, fat, fibre, sugar, sodium, allergens, diet tags, ingredients and a health score. A "Try again" button appears with a clear message if the analysis fails or times out.
- **Dashboard** – a progress ring for today's calories, a 7-day bar chart with your goal line, and your recent scans. The ring turns orange and shows "+N cal over" when you pass your goal.
- **Personal calorie goal** – type your own goal, or calculate an estimate from age, sex, height, weight, activity level and aim.
- **Food history** – see every scan, search by food name or date, and delete items.
- **Healthy restaurants map** – browse healthy places around Tanjung Malim on an OpenStreetMap map, filter by diet tag, see your distance, and get walking, cycling or driving routes with realistic travel times.
- **Nutrition chat** – ask the AI assistant questions about food and healthy eating.
- **Profile and security** – edit your name and photo, change your password, verify your email, log out, or request account deletion.
- **Light and dark mode**, with a floating bottom navigation bar.

## Tech stack

| Area | Technology |
| --- | --- |
| App | Flutter (Dart) |
| AI | Google Gemini API |
| Backend | Supabase (authentication, PostgreSQL database, storage) |
| Maps and routes | flutter_map, OpenStreetMap tiles, OSRM routing (OpenStreetMap Germany servers) |
| Location | geolocator |
| Other packages | supabase_flutter, google_fonts, image_picker, http, latlong2 |

## Screenshots

<!-- Add your screenshots to a /screenshots folder and link them here, for example: -->
<!-- ![Dashboard](screenshots/dashboard.png) -->

## Getting started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- A [Supabase](https://supabase.com) project
- A Gemini API key from [Google AI Studio](https://aistudio.google.com)

### 1. Clone and install
```bash
git clone https://github.com/YOUR-USERNAME/YOUR-REPO.git
cd YOUR-REPO
flutter pub get
```

### 2. Add your API key
The key is passed in when the app is built, and is **not** stored in the code.

Copy `env.example.json` to `env.json` and put your key in it:
```json
{
  "GEMINI_API_KEY": "your_key_here"
}
```
`env.json` is listed in `.gitignore`, so it is never uploaded.

### 3. Set up Supabase
1. Put your project URL and **anon** key in `lib/main.dart`. Never use the `service_role` key in the app.
2. Create a `profiles` table:
   ```sql
   create table if not exists profiles (
     id uuid primary key references auth.users(id) on delete cascade,
     name text,
     avatar_url text,
     daily_calorie_goal integer,
     deletion_requested_at timestamptz
   );
   ```
3. Create the food history table used by `lib/services/supabase_service.dart`.
   <!-- TODO: add the table definition for your food history here -->
4. Create a **public** storage bucket named `avatars`.
5. Turn on **Row Level Security** for every table, with policies that let each user read and write only their own rows.

### 4. Run the app
```bash
# On a connected phone or emulator
flutter run --dart-define-from-file=env.json

# In Chrome
flutter run -d chrome --dart-define-from-file=env.json
```

### 5. Build an APK
```bash
flutter build apk --release --dart-define-from-file=env.json
```
The file is created at `build/app/outputs/flutter-apk/app-release.apk`.

## Project structure

```
lib/
├── main.dart            # App entry, themes, navigation shell
├── screens/             # Dashboard, Scan, History, Places, Chat, Profile, Login
├── widgets/             # Reusable widgets (progress ring, calorie goal dialog)
├── services/            # Supabase, Gemini API, storage, shared state
├── models/              # Data models (food history, analysis result)
└── themes/              # Colours and theme settings
```

## Limitations and future work

- Nutrition values are **estimates** from a photo and can be wrong. They are not medical advice. Talk to a doctor or dietitian for personal guidance.
- The restaurant list is **sample data** for the Tanjung Malim area. A future version could load real places from a database or a places API.
- The Gemini key is built into the app, so it can be extracted from the APK. For a public release, move the AI call to a server such as a Supabase Edge Function.
- Account deletion only sends a request. A server-side function is needed to remove the account and its data.
- Possible additions: halal ingredient warnings, macro goals, and weekly reports.

## Acknowledgements

- Map data © [OpenStreetMap](https://www.openstreetmap.org/copyright) contributors
- AI by Google Gemini
- Backend by Supabase

## Author

**MUHAMMAD HAZWAN BIN AHRI**
UPSI · muhdhazwan363@gmail.com

## License

[Choose a license, for example MIT, or write "All rights reserved" if you prefer.]
