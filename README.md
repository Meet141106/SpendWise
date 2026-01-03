# SpendWise - Student Expense Intelligence & Fraud Awareness System

![Flutter](https://img.shields.io/badge/Flutter-3.10+-blue)
![Dart](https://img.shields.io/badge/Dart-3.0+-blue)
![License](https://img.shields.io/badge/License-MIT-green)

**SpendWise** is a student-focused expense intelligence and fraud awareness system built for hackathon preliminary rounds. This is NOT a generic expense tracker—it's a decision-support system that helps students understand spending behavior, detect anomalies, and avoid hidden financial risks.

## 🎯 Core Features

### ✅ Offline-First & Privacy-First
- All data stored locally using SQLite
- No authentication/login required
- No cloud dependency
- No bank APIs or integrations
- Complete privacy—your data never leaves your device

### 🧠 SSIA Algorithm (Student Spending Intelligence Algorithm)
Custom, original, explainable algorithm designed specifically for student spending patterns.

### 📊 Student-Centric Insights
- Category-wise spending breakdown
- Weekly vs monthly comparison
- Burn rate indicator
- Subscription cost impact
- Safe-to-spend amount calculator

### 🚨 Fraud & Anomaly Detection
- Duplicate payment detection
- Spending spike alerts
- Micro-transaction warnings
- Subscription trap detection

### 📥 Smart Data Input
- Manual expense entry
- CSV import with flexible date parsing
- Auto-categorization using keyword matching
- SMS parsing (future-ready)

---

## 🧠 SSIA Algorithm - Technical Deep Dive

The **Student Spending Intelligence Algorithm (SSIA)** is the core innovation of SpendWise. It operates in **4 phases**:

### Phase 1: Transaction Normalization
**Purpose:** Convert raw expense data into a behavioral unit

**Input:**
- `amount` - Transaction amount
- `merchant` - Merchant name
- `timestamp` - Transaction date/time
- `paymentMode` - UPI, Cash, Card, or Subscription

**Output (Normalized Transaction Vector):**
- `category` - Auto-detected or user-specified
- `time_bucket` - Morning (5 AM-12 PM), Afternoon (12 PM-6 PM), Night (6 PM-5 AM)
- `spend_intensity` - Amount ÷ personal category average
- `recurrence_flag` - Boolean indicating subscription/recurring payment

**Logic:**
```dart
// Time bucket determination
if (hour >= 5 && hour < 12) return 'morning';
else if (hour >= 12 && hour < 18) return 'afternoon';
else return 'night';

// Spend intensity calculation
spend_intensity = amount / personal_category_average;
// 1.0 = exactly average
// > 1.0 = above average (higher intensity)
// < 1.0 = below average (lower intensity)
```

---

### Phase 2: Student Behavior Profiling
**Purpose:** Build a Personal Spending Fingerprint (PSF) stored locally

**PSF Components:**
1. **Category Averages** - Average spend per category (Food, Transport, Education, etc.)
2. **Typical Spending Hours** - Hour-wise frequency map
3. **Weekly Burn Rate** - Total spend in last 7 days
4. **Fixed Recurring Costs** - Detected subscriptions and regular payments
5. **Personal Risk Tolerance Band** - Calculated from spending variance (0.0-1.0)

**Recurring Cost Detection Logic:**
```dart
// Group transactions by merchant
// For each merchant with 2+ transactions:
//   - Calculate intervals between transactions
//   - Check if intervals are consistent (±3 days tolerance)
//   - Classify as daily, weekly, or monthly
//   - Store as recurring cost
```

**Risk Tolerance Calculation:**
```dart
// Calculate coefficient of variation (CV)
CV = standard_deviation / mean

// Map to tolerance band
if (CV < 0.3) return 0.2;  // Low variance = low tolerance
if (CV < 0.7) return 0.5;  // Medium variance = medium tolerance
return 0.8;                 // High variance = high tolerance
```

---

### Phase 3: Contextual Risk Scoring (CORE INNOVATION)
**Purpose:** Compute Contextual Risk Score (CRS) for every transaction

**CRS Factors (Weighted):**

#### 1. Amount Deviation (40% weight)
```dart
deviation = |amount - category_average| / category_average

if (deviation < 0.5)      score = 0.0 - 0.3  // Low risk
else if (deviation < 2.0) score = 0.3 - 0.7  // Medium risk
else                      score = 0.7 - 1.0  // High risk

Reason: "3.2× your usual food spend"
```

#### 2. Time Deviation (20% weight)
```dart
if (!is_typical_spending_hour(hour)) {
  score = 0.6
  Reason: "Unusual spending time: late night (2:00)"
}
```

#### 3. Frequency Spike (25% weight)
```dart
// Check for same merchant in last 24 hours
if (same_merchant_count >= 3) {
  score = 0.9
  Reason: "3 payments to Swiggy in 24 hours"
}
```

#### 4. Recurrence Anomaly (15% weight)
```dart
// For subscriptions
if (new_subscription) {
  score = 0.6
  Reason: "New subscription detected: Netflix"
}
else if (amount_changed > 20%) {
  score = 0.7
  Reason: "Subscription amount changed: ₹499 → ₹999"
}
```

**Risk Level Mapping:**
```dart
// Adjusted by personal risk tolerance band
amber_threshold = 0.3 + (risk_tolerance * 0.2)  // 0.3 - 0.5
red_threshold = 0.6 + (risk_tolerance * 0.2)    // 0.6 - 0.8

if (CRS >= red_threshold)   return 'red';
if (CRS >= amber_threshold) return 'amber';
return 'green';
```

---

### Phase 4: Actionable Insight Generation
**Purpose:** Convert CRS into human-readable alerts with reasons and suggested actions

**Alert Types:**
1. **Duplicate Payment** - Same merchant + amount + short time window
2. **Spending Spike** - Amount significantly higher than personal average
3. **Micro-Transaction** - Multiple small payments adding up
4. **Subscription Trap** - New or changed subscription

**Example Alerts:**

```
🔄 Duplicate Payment Detected
Reason: Duplicate payment detected: ₹150 to Swiggy within the last hour.
Action: Check your payment history and contact the merchant if this was charged twice by mistake.

📈 Spending Spike
Reason: This expense (₹800) is 3.2× higher than your usual food spend.
Action: Review if this was a planned expense. Consider setting a budget limit for food.

🪤 Subscription Alert
Reason: New subscription detected: Netflix at ₹999/month.
Action: This costs ₹999/month ≈ 20 canteen meals. Review if you'll use it regularly.
```

**Insights Summary:**
- **Burn Rate Indicator:** "At this pace, money lasts 15 days"
- **Subscription Impact:** "₹999/month = 20 canteen meals"
- **Safe-to-Spend:** Balance - fixed upcoming costs

---

## 📁 Project Structure

```
lib/
├── main.dart                          # App entry point
├── models/
│   ├── transaction.dart               # Transaction model
│   ├── spending_fingerprint.dart      # PSF model
│   ├── risk_alert.dart                # Alert model
│   └── category.dart                  # Category definitions
├── core/
│   ├── ssia/
│   │   ├── ssia_engine.dart           # Main SSIA orchestrator
│   │   ├── phase1_normalization.dart  # Phase 1 logic
│   │   ├── phase2_profiling.dart      # Phase 2 logic
│   │   ├── phase3_risk_scoring.dart   # Phase 3 logic (CORE)
│   │   └── phase4_insights.dart       # Phase 4 logic
│   └── database/
│       └── database_helper.dart       # SQLite database
├── services/
│   ├── transaction_service.dart       # Business logic
│   └── csv_import_service.dart        # CSV import
├── screens/
│   ├── dashboard_screen.dart          # Main dashboard
│   ├── expenses_screen.dart           # Expenses list
│   ├── insights_screen.dart           # Insights view
│   └── alerts_screen.dart             # Alerts view
└── widgets/
    ├── metric_card.dart               # Metric display
    ├── transaction_card.dart          # Transaction item
    ├── alert_card.dart                # Alert item
    ├── category_chart.dart            # Pie chart
    └── add_expense_dialog.dart        # Add expense form
```

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.10+
- Dart 3.0+
- Android Studio / VS Code

### Installation

1. **Clone the repository**
```bash
cd SpendWise
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Run the app**
```bash
flutter run
```

---

## 📊 CSV Import Format

SpendWise supports CSV import with the following format:

```csv
amount,merchant,date,paymentMode,category,note
150.50,Swiggy,2025-12-28 14:30,UPI,Food,Lunch order
50.00,Metro Card,2025-12-28 09:15,Card,Transport,Daily commute
999.00,Netflix,2025-12-01 00:00,Subscription,Subscriptions,Monthly subscription
```

**Supported Date Formats:**
- ISO: `2025-12-28 14:30`
- DD/MM/YYYY: `28/12/2025 14:30`
- DD-MM-YYYY: `28-12-2025 14:30`

**Optional Fields:**
- `category` - Auto-detected if not provided
- `note` - Additional details

---

## 🎨 Design Philosophy

### Premium Dark Theme
- **Background:** Deep blue-gray (`#0F0F1E`)
- **Surface:** Dark blue-gray (`#1A1A2E`)
- **Primary:** Vibrant purple-blue (`#667EEA`)
- **Accent Gradients:** Multiple vibrant gradients for visual hierarchy

### Typography
- **Headings:** Bold, high contrast
- **Body:** Medium weight, readable
- **Labels:** Subtle, secondary color

### Micro-interactions
- Smooth transitions
- Haptic feedback (future)
- Loading states
- Pull-to-refresh

---

## 🔒 Privacy & Security

### Data Storage
- **Local-only:** All data stored in SQLite on device
- **No cloud sync:** No data leaves your device
- **No authentication:** No user accounts or login

### Permissions
- **Storage:** Read/write for CSV import
- **SMS (future):** Optional, for SMS parsing

---

## 🏆 Hackathon Highlights

### What Makes SpendWise Stand Out?

1. **Original Algorithm:** SSIA is custom-built, not a generic ML model
2. **Explainable AI:** Every decision has a clear reason
3. **Student-First:** Designed specifically for student spending patterns
4. **Privacy-First:** No data collection, no cloud dependency
5. **Actionable Insights:** Not just analytics—actual suggestions
6. **Offline-First:** Works completely offline

### Demo Flow (2-Minute Pitch)

1. **Show empty state** → Add first expense
2. **Auto-categorization** → Merchant "Swiggy" → Food
3. **Add more expenses** → Build spending fingerprint
4. **Trigger alert** → High amount → Spending spike detected
5. **Show insights** → Burn rate, subscription impact
6. **CSV import** → Bulk import demo data
7. **Show alerts** → Duplicate payment, subscription trap

---

## 📝 Future Enhancements

- [ ] SMS parsing for automatic expense capture
- [ ] Budget setting and tracking
- [ ] Expense splitting for group expenses
- [ ] Export reports as PDF
- [ ] Dark/Light theme toggle
- [ ] Multi-currency support
- [ ] Backup/Restore to local file

---

## 🤝 Contributing

This is a hackathon project. Contributions are welcome!

---

## 📄 License

MIT License - See LICENSE file for details

---

## 👨‍💻 Author

Built with ❤️ for students, by students.

**SpendWise** - Smart spending, smarter students.

---

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- fl_chart for beautiful charts
- sqflite for local database
- All open-source contributors

---

## 📧 Contact

For questions or feedback, please open an issue on GitHub.

---

**Remember:** This is NOT just an expense tracker. It's an intelligence system that helps you make better financial decisions. 🧠💡
