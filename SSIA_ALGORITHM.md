# SSIA Algorithm - Detailed Technical Specification

## Overview

The **Student Spending Intelligence Algorithm (SSIA)** is a custom, explainable, logic-driven algorithm designed specifically for analyzing student spending behavior. Unlike generic machine learning models, SSIA is fully transparent and provides human-readable explanations for every decision.

---

## Algorithm Architecture

SSIA operates in **4 sequential phases**:

```
Raw Transaction → Phase 1 → Phase 2 → Phase 3 → Phase 4 → Actionable Insights
                 Normalize  Profile   Score     Generate
```

---

## Phase 1: Transaction Normalization

### Purpose
Convert raw expense data into a standardized behavioral unit that can be analyzed consistently.

### Input Parameters
- `amount` (double) - Transaction amount in ₹
- `merchant` (string) - Merchant or payee name
- `timestamp` (DateTime) - Transaction date and time
- `paymentMode` (string) - UPI, Cash, Card, or Subscription
- `category` (string, optional) - Expense category
- `note` (string, optional) - Additional details

### Output (Normalized Transaction Vector)
- `category` (string) - Auto-detected or user-specified category
- `time_bucket` (string) - Time classification: morning, afternoon, or night
- `spend_intensity` (double) - Relative spending intensity
- `recurrence_flag` (boolean) - Indicates recurring payment

### Logic Implementation

#### 1. Time Bucket Classification
```dart
String getTimeBucket(DateTime timestamp) {
  final hour = timestamp.hour;
  
  if (hour >= 5 && hour < 12) {
    return 'morning';    // 5 AM - 12 PM
  } else if (hour >= 12 && hour < 18) {
    return 'afternoon';  // 12 PM - 6 PM
  } else {
    return 'night';      // 6 PM - 5 AM
  }
}
```

**Rationale:** Student spending patterns vary significantly by time of day. Morning expenses are typically transport and breakfast, afternoon includes lunch and education, while night spending often involves food delivery and entertainment.

#### 2. Spend Intensity Calculation
```dart
double calculateSpendIntensity(double amount, String category, PSF fingerprint) {
  final categoryAverage = fingerprint.getCategoryAverage(category);
  
  if (categoryAverage == 0.0) {
    return 1.0;  // Neutral for first transaction in category
  }
  
  return amount / categoryAverage;
}
```

**Interpretation:**
- `1.0` = Exactly average spending
- `> 1.0` = Above average (higher intensity)
- `< 1.0` = Below average (lower intensity)
- `2.0` = Double the usual amount
- `0.5` = Half the usual amount

**Example:**
- Category average for Food: ₹150
- Current transaction: ₹450
- Spend intensity: 450 / 150 = **3.0** (3× normal)

#### 3. Recurrence Flag
```dart
bool determineRecurrenceFlag(String paymentMode) {
  return paymentMode == 'Subscription';
}
```

**Rationale:** Subscriptions require special monitoring as they represent recurring costs that impact long-term budgets.

---

## Phase 2: Student Behavior Profiling

### Purpose
Build a **Personal Spending Fingerprint (PSF)** that serves as the student's unique baseline for comparison.

### PSF Components

#### 1. Category Averages
```dart
Map<String, double> calculateCategoryAverages(List<Transaction> transactions) {
  final categoryTotals = <String, double>{};
  final categoryCounts = <String, int>{};

  for (final transaction in transactions) {
    categoryTotals[transaction.category] = 
        (categoryTotals[transaction.category] ?? 0) + transaction.amount;
    categoryCounts[transaction.category] = 
        (categoryCounts[transaction.category] ?? 0) + 1;
  }

  final categoryAverages = <String, double>{};
  for (final category in categoryTotals.keys) {
    categoryAverages[category] = 
        categoryTotals[category]! / categoryCounts[category]!;
  }

  return categoryAverages;
}
```

**Example Output:**
```
{
  'Food': 185.50,
  'Transport': 45.00,
  'Education': 320.00,
  'Subscriptions': 999.00,
  'Shopping': 450.00
}
```

#### 2. Typical Spending Hours
```dart
Map<int, int> calculateTypicalSpendingHours(List<Transaction> transactions) {
  final hourFrequency = <int, int>{};

  for (final transaction in transactions) {
    final hour = transaction.timestamp.hour;
    hourFrequency[hour] = (hourFrequency[hour] ?? 0) + 1;
  }

  return hourFrequency;
}
```

**Example Output:**
```
{
  9: 12,   // 12 transactions at 9 AM
  13: 25,  // 25 transactions at 1 PM (lunch peak)
  20: 18,  // 18 transactions at 8 PM (dinner)
  ...
}
```

**Usage:** Identifies unusual spending times (e.g., 3 AM transaction)

#### 3. Weekly Burn Rate
```dart
double calculateWeeklyBurnRate(List<Transaction> transactions) {
  final now = DateTime.now();
  final oneWeekAgo = now.subtract(const Duration(days: 7));

  final recentTransactions = transactions.where(
    (t) => t.timestamp.isAfter(oneWeekAgo),
  );

  final totalSpent = recentTransactions.fold<double>(
    0.0,
    (sum, t) => sum + t.amount,
  );

  // Extrapolate if less than 7 days of data
  if (transactions.isEmpty) return 0.0;
  
  final oldestTransaction = transactions.reduce(
    (a, b) => a.timestamp.isBefore(b.timestamp) ? a : b,
  );
  
  final daysSinceOldest = now.difference(oldestTransaction.timestamp).inDays;
  
  if (daysSinceOldest < 7) {
    final totalAllTime = transactions.fold<double>(
      0.0,
      (sum, t) => sum + t.amount,
    );
    return (totalAllTime / (daysSinceOldest + 1)) * 7;
  }

  return totalSpent;
}
```

**Example:**
- Last 7 days spending: ₹2,100
- Weekly burn rate: ₹2,100
- Daily burn rate: ₹300

#### 4. Fixed Recurring Costs Detection
```dart
List<RecurringCost> detectRecurringCosts(List<Transaction> transactions) {
  final recurringCosts = <RecurringCost>[];
  final merchantGroups = <String, List<Transaction>>{};

  // Group by merchant
  for (final transaction in transactions) {
    if (!merchantGroups.containsKey(transaction.merchant)) {
      merchantGroups[transaction.merchant] = [];
    }
    merchantGroups[transaction.merchant]!.add(transaction);
  }

  // Analyze each merchant group
  for (final entry in merchantGroups.entries) {
    final merchant = entry.key;
    final merchantTransactions = entry.value;

    if (merchantTransactions.length < 2) continue;

    // Sort by timestamp
    merchantTransactions.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Calculate intervals between transactions
    final intervals = <int>[];
    for (int i = 1; i < merchantTransactions.length; i++) {
      final daysBetween = merchantTransactions[i].timestamp
          .difference(merchantTransactions[i - 1].timestamp)
          .inDays;
      intervals.add(daysBetween);
    }

    if (intervals.isEmpty) continue;
    
    final avgInterval = intervals.reduce((a, b) => a + b) / intervals.length;
    
    // Check if intervals are consistent (±3 days tolerance)
    final isRegular = intervals.every(
      (interval) => (interval - avgInterval).abs() <= 3,
    );

    if (isRegular) {
      // Determine frequency
      String frequency;
      if (avgInterval <= 1.5) {
        frequency = 'daily';
      } else if (avgInterval <= 10) {
        frequency = 'weekly';
      } else {
        frequency = 'monthly';
      }

      // Calculate average amount
      final avgAmount = merchantTransactions.fold<double>(
        0.0,
        (sum, t) => sum + t.amount,
      ) / merchantTransactions.length;

      recurringCosts.add(RecurringCost(
        merchant: merchant,
        amount: avgAmount,
        frequency: frequency,
        lastDetected: merchantTransactions.last.timestamp,
      ));
    }
  }

  return recurringCosts;
}
```

**Example Detection:**
```
Netflix:
  - Transaction 1: Dec 1, ₹999
  - Transaction 2: Jan 1, ₹999
  - Transaction 3: Feb 1, ₹999
  → Interval: ~30 days (consistent)
  → Detected as: Monthly subscription, ₹999
```

#### 5. Personal Risk Tolerance Band
```dart
double calculateRiskToleranceBand(List<Transaction> transactions) {
  if (transactions.length < 3) return 0.5; // Default medium

  final amounts = transactions.map((t) => t.amount).toList();
  final mean = amounts.reduce((a, b) => a + b) / amounts.length;
  
  // Calculate standard deviation
  final variance = amounts.fold<double>(
    0.0,
    (sum, amount) => sum + ((amount - mean) * (amount - mean)),
  ) / amounts.length;
  
  final stdDev = sqrt(variance);
  
  // Coefficient of variation (CV)
  final cv = mean > 0 ? stdDev / mean : 0;
  
  // Map CV to tolerance band (0.0 - 1.0)
  if (cv < 0.3) return 0.2;  // Low variance = low tolerance
  if (cv < 0.7) return 0.5;  // Medium variance = medium tolerance
  return 0.8;                 // High variance = high tolerance
}
```

**Interpretation:**
- **Low tolerance (0.0-0.3):** Consistent spender, stricter alerts
- **Medium tolerance (0.3-0.7):** Balanced spender, moderate alerts
- **High tolerance (0.7-1.0):** Variable spender, lenient alerts

**Example:**
```
Student A: ₹100, ₹120, ₹110, ₹105 → Low variance → Low tolerance (0.2)
Student B: ₹50, ₹200, ₹80, ₹300 → High variance → High tolerance (0.8)
```

---

## Phase 3: Contextual Risk Scoring (CORE INNOVATION)

### Purpose
Compute a **Contextual Risk Score (CRS)** for every transaction based on multiple behavioral factors.

### CRS Formula
```
CRS = (Amount_Score × 0.40) + 
      (Time_Score × 0.20) + 
      (Frequency_Score × 0.25) + 
      (Recurrence_Score × 0.15)
```

### Factor 1: Amount Deviation (40% weight)

```dart
ScoreResult scoreAmountDeviation(Transaction transaction, PSF fingerprint) {
  final categoryAvg = fingerprint.getCategoryAverage(transaction.category);
  
  if (categoryAvg == 0.0) {
    return ScoreResult(score: 0.0);  // No baseline
  }

  final deviation = (transaction.amount - categoryAvg).abs() / categoryAvg;
  
  double score;
  String? reason;
  
  if (deviation < 0.5) {
    // Within 50% of average
    score = deviation * 0.6;  // Max 0.3
  } else if (deviation < 2.0) {
    // 50% - 200% of average
    score = 0.3 + (deviation - 0.5) * 0.27;  // 0.3 - 0.7
    final multiplier = (transaction.amount / categoryAvg).toStringAsFixed(1);
    reason = '${multiplier}× your usual ${transaction.category.toLowerCase()} spend';
  } else {
    // > 200% of average
    score = 0.7 + ((deviation - 2.0) / 3.0).clamp(0.0, 0.3);  // 0.7 - 1.0
    final multiplier = (transaction.amount / categoryAvg).toStringAsFixed(1);
    reason = '${multiplier}× higher than your typical ${transaction.category.toLowerCase()} expense';
  }
  
  return ScoreResult(score: score, reason: reason);
}
```

**Example Scenarios:**

| Amount | Category Avg | Deviation | Score | Risk | Reason |
|--------|-------------|-----------|-------|------|--------|
| ₹150 | ₹150 | 0.0 | 0.0 | Low | Normal |
| ₹200 | ₹150 | 0.33 | 0.2 | Low | Slightly above |
| ₹300 | ₹150 | 1.0 | 0.44 | Medium | 2.0× usual spend |
| ₹600 | ₹150 | 3.0 | 0.8 | High | 4.0× usual spend |

### Factor 2: Time Deviation (20% weight)

```dart
ScoreResult scoreTimeDeviation(Transaction transaction, PSF fingerprint) {
  final hour = transaction.timestamp.hour;
  final isTypical = fingerprint.isTypicalSpendingHour(hour);
  
  if (isTypical || fingerprint.totalTransactions < 10) {
    return ScoreResult(score: 0.0);
  }
  
  // Unusual hour detected
  String timeLabel;
  if (hour >= 0 && hour < 5) {
    timeLabel = 'late night (${hour}:00)';
  } else if (hour >= 22) {
    timeLabel = 'late night (${hour}:00)';
  } else {
    timeLabel = '${hour}:00';
  }
  
  return ScoreResult(
    score: 0.6,
    reason: 'Unusual spending time: $timeLabel',
  );
}
```

**Example:**
- Typical hours: 9 AM, 1 PM, 8 PM
- Transaction at 3 AM → Score: 0.6, Reason: "Unusual spending time: late night (3:00)"

### Factor 3: Frequency Spike (25% weight)

```dart
ScoreResult scoreFrequencySpike(
  Transaction transaction,
  List<Transaction> recentTransactions,
) {
  final oneDayAgo = transaction.timestamp.subtract(const Duration(days: 1));
  
  final sameMerchantRecent = recentTransactions.where((t) =>
    t.merchant.toLowerCase() == transaction.merchant.toLowerCase() &&
    t.timestamp.isAfter(oneDayAgo) &&
    t.timestamp.isBefore(transaction.timestamp)
  ).toList();
  
  if (sameMerchantRecent.isEmpty) {
    return ScoreResult(score: 0.0);
  }
  
  final count = sameMerchantRecent.length + 1;
  
  if (count >= 3) {
    return ScoreResult(
      score: 0.9,
      reason: '$count payments to ${transaction.merchant} in 24 hours',
    );
  } else if (count == 2) {
    return ScoreResult(
      score: 0.5,
      reason: 'Repeated payment to ${transaction.merchant} today',
    );
  }
  
  return ScoreResult(score: 0.0);
}
```

**Example:**
- Swiggy at 1 PM: ₹200
- Swiggy at 8 PM: ₹250
- Swiggy at 10 PM: ₹180
→ Score: 0.9, Reason: "3 payments to Swiggy in 24 hours"

### Factor 4: Recurrence Anomaly (15% weight)

```dart
ScoreResult scoreRecurrenceAnomaly(
  Transaction transaction,
  PSF fingerprint,
) {
  if (transaction.paymentMode != 'Subscription') {
    return ScoreResult(score: 0.0);
  }
  
  final isKnownRecurring = fingerprint.fixedRecurringCosts.any(
    (cost) => cost.merchant.toLowerCase() == transaction.merchant.toLowerCase(),
  );
  
  if (isKnownRecurring) {
    final knownCost = fingerprint.fixedRecurringCosts.firstWhere(
      (cost) => cost.merchant.toLowerCase() == transaction.merchant.toLowerCase(),
    );
    
    final deviation = (transaction.amount - knownCost.amount).abs() / knownCost.amount;
    
    if (deviation > 0.2) {
      return ScoreResult(
        score: 0.7,
        reason: 'Subscription amount changed: ₹${knownCost.amount} → ₹${transaction.amount}',
      );
    }
    
    return ScoreResult(score: 0.0);
  } else {
    return ScoreResult(
      score: 0.6,
      reason: 'New subscription detected: ${transaction.merchant}',
    );
  }
}
```

### Risk Level Mapping

```dart
String mapCRSToRiskLevel(double crs, double riskToleranceBand) {
  // Adjust thresholds based on risk tolerance
  final amberThreshold = 0.3 + (riskToleranceBand * 0.2);  // 0.3 - 0.5
  final redThreshold = 0.6 + (riskToleranceBand * 0.2);    // 0.6 - 0.8
  
  if (crs >= redThreshold) {
    return 'red';      // High Risk
  } else if (crs >= amberThreshold) {
    return 'amber';    // Unusual
  } else {
    return 'green';    // Normal
  }
}
```

**Example Mapping:**

| CRS | Low Tolerance (0.2) | Medium Tolerance (0.5) | High Tolerance (0.8) |
|-----|---------------------|------------------------|----------------------|
| 0.2 | Green | Green | Green |
| 0.4 | Amber | Green | Green |
| 0.6 | Red | Amber | Amber |
| 0.8 | Red | Red | Red |

---

## Phase 4: Actionable Insight Generation

### Purpose
Convert CRS into human-readable alerts with explainable reasons and actionable suggestions.

### Alert Type Detection

```dart
String detectAlertType(Transaction transaction, List<Transaction> allTransactions) {
  // 1. Duplicate Payment
  final duplicates = allTransactions.where((t) =>
    t.id != transaction.id &&
    t.merchant.toLowerCase() == transaction.merchant.toLowerCase() &&
    (t.amount - transaction.amount).abs() < 1.0 &&
    t.timestamp.difference(transaction.timestamp).inMinutes.abs() < 60
  );
  
  if (duplicates.isNotEmpty) {
    return 'duplicate_payment';
  }

  // 2. Spending Spike
  if (transaction.spendIntensity > 2.5) {
    return 'spending_spike';
  }

  // 3. Micro-transactions
  if (transaction.amount < 50) {
    final recentSmall = allTransactions.where((t) =>
      t.amount < 50 &&
      t.timestamp.isAfter(transaction.timestamp.subtract(const Duration(hours: 24)))
    );
    
    if (recentSmall.length >= 5) {
      return 'micro_transaction';
    }
  }

  // 4. Subscription Trap
  if (transaction.paymentMode == 'Subscription' || transaction.recurrenceFlag) {
    return 'subscription_trap';
  }

  return 'spending_spike';  // Default
}
```

### Insight Generation Examples

#### 1. Duplicate Payment Alert
```
Icon: 🔄
Type: Duplicate Payment Detected
Risk: Red
Reason: Duplicate payment detected: ₹150 to Swiggy within the last hour.
Action: Check your payment history and contact the merchant if this was charged twice by mistake.
```

#### 2. Spending Spike Alert
```
Icon: 📈
Type: Spending Spike
Risk: Amber
Reason: This expense (₹800) is 3.2× higher than your usual food spend.
Action: Review if this was a planned expense. Consider setting a budget limit for food.
```

#### 3. Micro-Transaction Alert
```
Icon: 💸
Type: Frequent Small Payments
Risk: Amber
Reason: 7 small transactions (₹280 total) in the last 24 hours.
Action: Small expenses add up quickly. Consider consolidating purchases or using cash to track better.
```

#### 4. Subscription Trap Alert
```
Icon: 🪤
Type: Subscription Alert
Risk: Red
Reason: New subscription detected: Netflix at ₹999/month.
Action: This costs ₹999/month ≈ 20 canteen meals. Review if you'll use it regularly.
```

### Insights Summary Generation

```dart
Map<String, dynamic> generateInsightsSummary({
  required List<Transaction> transactions,
  required PSF fingerprint,
  double? currentBalance,
}) {
  // 1. Category-wise spending
  final categorySpending = <String, double>{};
  for (final transaction in transactions) {
    categorySpending[transaction.category] = 
        (categorySpending[transaction.category] ?? 0) + transaction.amount;
  }

  // 2. Weekly vs monthly comparison
  final now = DateTime.now();
  final oneWeekAgo = now.subtract(const Duration(days: 7));
  final oneMonthAgo = now.subtract(const Duration(days: 30));
  
  final weeklySpend = transactions
      .where((t) => t.timestamp.isAfter(oneWeekAgo))
      .fold<double>(0.0, (sum, t) => sum + t.amount);
  
  final monthlySpend = transactions
      .where((t) => t.timestamp.isAfter(oneMonthAgo))
      .fold<double>(0.0, (sum, t) => sum + t.amount);

  // 3. Burn rate indicator
  final dailyBurnRate = fingerprint.dailyBurnRate;
  final daysRemaining = currentBalance != null && dailyBurnRate > 0
      ? (currentBalance / dailyBurnRate).floor()
      : null;

  // 4. Subscription cost impact
  final totalSubscriptions = fingerprint.fixedRecurringCosts
      .where((cost) => cost.frequency == 'monthly')
      .fold<double>(0.0, (sum, cost) => sum + cost.amount);
  
  final canteenMealsEquivalent = (totalSubscriptions / 50).floor();

  // 5. Safe to spend amount
  final safeToSpend = currentBalance != null
      ? currentBalance - fingerprint.totalFixedMonthlyCosts
      : null;

  return {
    'categorySpending': categorySpending,
    'weeklySpend': weeklySpend,
    'monthlySpend': monthlySpend,
    'dailyBurnRate': dailyBurnRate,
    'daysRemaining': daysRemaining,
    'totalSubscriptions': totalSubscriptions,
    'canteenMealsEquivalent': canteenMealsEquivalent,
    'safeToSpend': safeToSpend,
  };
}
```

**Example Output:**
```json
{
  "categorySpending": {
    "Food": 2450.00,
    "Transport": 680.00,
    "Education": 1200.00,
    "Subscriptions": 1998.00,
    "Shopping": 890.00
  },
  "weeklySpend": 1850.00,
  "monthlySpend": 7218.00,
  "dailyBurnRate": 264.29,
  "daysRemaining": 11,
  "totalSubscriptions": 1998.00,
  "canteenMealsEquivalent": 39,
  "safeToSpend": 1002.00
}
```

---

## Algorithm Performance Characteristics

### Time Complexity
- **Phase 1 (Normalization):** O(1) per transaction
- **Phase 2 (Profiling):** O(n) for full rebuild, O(1) for incremental update
- **Phase 3 (Risk Scoring):** O(n) for checking recent transactions
- **Phase 4 (Insights):** O(n) for generating all alerts

### Space Complexity
- **PSF Storage:** O(c + h + r) where c = categories, h = hours, r = recurring costs
- **Transaction Storage:** O(n) where n = number of transactions

### Scalability
- Optimized for **100-10,000 transactions**
- Incremental PSF updates for real-time performance
- Efficient indexing for date-range queries

---

## Key Differentiators from Generic ML

1. **Explainability:** Every score has a clear mathematical formula
2. **Transparency:** No black-box decisions
3. **Student-Specific:** Designed for student spending patterns
4. **Privacy:** No external data or training required
5. **Deterministic:** Same input always produces same output
6. **Lightweight:** No ML dependencies or model files

---

## Conclusion

SSIA is a **production-ready, hackathon-grade algorithm** that demonstrates:
- Original algorithmic thinking
- Student-centric design
- Complete explainability
- Privacy-first architecture
- Offline-first capability

This is NOT a generic expense tracker—it's an **intelligent decision-support system** built specifically for students.
