# 📈 High-Performance Technical Trading App

A premium, low-latency stock trading application built in Flutter. This application features multiple watchlists, a real-time mock market-data feed with adjustable tick rates, a simulated order ticket with margin validation, and a portfolio holdings tracker.

---

## 📽️ Video Walkthrough & Demo

### **[👉 Watch the Walkthrough Video (Loom Link) 👈](YOUR_LOOM_VIDEO_LINK_HERE)**

*(Alternatively, if you downloaded the repository, you can watch the recording directly in the browser via GitHub or open the video file located at `docs/walkthrough.mp4`.)*

<video src="docs/walkthrough.mp4" controls width="100%" poster="docs/app_screenshot.png">
  Your browser does not support the video tag. Please click the link above to watch the walkthrough.
</video>

---

## ✨ Features

- **📊 Live Market Feed**: Real-time simulated price feed for 10 marquee stocks (NSE) with positive/negative color flash feedback.
- **⚡ Stress Test Controller**: Test the app's responsiveness under high load:
  - Toggle **Stress Test Mode** to generate over **60+ price updates per second**.
  - Adjust the **Custom Tick Interval** slider dynamically from **50ms to 2000ms**.
- **📋 Multiple Watchlists**: 
  - Switch, create, rename, or delete watchlists.
  - Add/remove stocks using a bottom sheet picker.
  - Reorder stocks using drag-and-drop handles.
  - Swipe-to-dismiss deletion.
- **💳 Simulated Order Ticket**: 
  - Buy/Sell side selection (custom design with neon state indicators).
  - Live LTP and real-time projected order value calculation.
  - Real-time margin checking (validates balance for BUY orders, validates shares owned for SELL orders).
  - Premium **Slide-to-Confirm** slider button with directional animations.
- **💼 Holdings Portfolio**:
  - Live aggregated portfolio header card (Invested Value, Current Value, Net P&L).
  - Sort holdings list dynamically by **P&L**, **Symbol**, or **Value** (with arrow indicators).
- **⚙️ Settings & Order History**:
  - View detailed transaction logs.
  - A **Reset All** action to clear data and restore defaults.

---

## 🏗️ Architecture & Optimizations

The application is built using a **Repository-Service pattern** combined with **Flutter BLoC (`flutter_bloc`)** state management:
1. **Isolated Rebuilds**: List items (`WatchlistStockRow`, `MarketStockRow`, `HoldingRowItem`) listen specifically to their stock symbol via `context.select<MarketsCubit, Stock?>()`. Only the row that gets a price tick rebuilds, keeping frame rates pinned at 60/120fps even during 60+ ticks/sec stress testing.
2. **Custom Painters**: Mini-graphs (Sparklines) are rendered directly onto a vector-based canvas using a custom `Painter` instead of heavy layout widgets.
3. **Local Persistence**: State variables (wallet balance, order logs, holdings, watchlists) are persisted using `shared_preferences`.

---

## 🚀 How to Run the Project

### Prerequisites
Make sure you have [Flutter SDK](https://docs.flutter.dev/get-started/install) installed on your system.

### Steps to Run:
1. **Clone the Repository**:
   ```bash
   git clone <your-repository-url>
   cd trading_app
   ```
2. **Install Dependencies**:
   ```bash
   flutter pub get
   ```
3. **Run Static Analysis**:
   ```bash
   flutter analyze
   ```
4. **Run Unit Tests**:
   ```bash
   flutter test
   ```
5. **Run the App**:
   - For Mobile (Android/iOS) / Web / Desktop:
     ```bash
     flutter run -d chrome  # Run on Chrome
     flutter run            # Choose from available devices
     ```

---

## 🛠️ Step-by-Step: Git Upload & Attaching Your Demo Video

Here are instructions on how to push your code to GitHub and attach your demo screen recording:

### Step 1: Initialize Git and Push to GitHub
1. Create a **Public** repository on [GitHub](https://github.com). Let's call it `trading_app`. Do **not** initialize it with a README or gitignore.
2. Open terminal in the project directory (`Documents/trading_app`) and run:
   ```bash
   # Initialize local git repo
   git init
   
   # Add all files to staging
   git add .
   
   # Commit files
   git commit -m "Initial release of Technical Trading App"
   
   # Set primary branch to main
   git branch -M main
   
   # Link local repo to your GitHub remote
   git remote add origin https://github.com/YOUR_GITHUB_USERNAME/trading_app.git
   
   # Push files
   git push -u origin main
   ```

### Step 2: Attach the Walkthrough Video (Two Methods)

#### Method A: Direct Upload to Git (Recommended for neat README rendering)
GitHub supports HTML5 video rendering inside Markdown files!
1. Create a directory named `docs` in your project folder.
2. Save your screen recording as `walkthrough.mp4` and place it inside `docs/`. (Keep the size under 50MB for faster download times).
3. Commit and push the video file:
   ```bash
   git add docs/walkthrough.mp4
   git commit -m "docs: Add walkthrough video"
   git push
   ```
4. GitHub will automatically load and play the video within the README file under the **Video Walkthrough** section!

#### Method B: Loom Link (Recommended if the video file is large)
1. Record your screen using [Loom](https://www.loom.com).
2. Copy the share link.
3. Open `README.md` and replace the placeholder link `YOUR_LOOM_VIDEO_LINK_HERE` with your Loom URL.
