/// Category Model
/// Defines expense categories with keywords for auto-categorization
class ExpenseCategory {
  final String name;
  final String icon;
  final String colorHex;
  final List<String> keywords;

  const ExpenseCategory({
    required this.name,
    required this.icon,
    required this.colorHex,
    required this.keywords,
  });

  /// All available categories
  static const List<ExpenseCategory> all = [
    ExpenseCategory(
      name: 'Food',
      icon: '🍔',
      colorHex: '#F59E0B',
      keywords: [
        'swiggy', 'zomato', 'food', 'restaurant', 'cafe', 'canteen',
        'mess', 'dominos', 'pizza', 'burger', 'kfc', 'mcdonald',
        'subway', 'starbucks', 'chai', 'tea', 'coffee', 'breakfast',
        'lunch', 'dinner', 'snacks', 'biryani', 'thali'
      ],
    ),
    ExpenseCategory(
      name: 'Transport',
      icon: '🚗',
      colorHex: '#3B82F6',
      keywords: [
        'uber', 'ola', 'rapido', 'metro', 'bus', 'auto', 'rickshaw',
        'petrol', 'fuel', 'parking', 'toll', 'train', 'railway',
        'cab', 'taxi', 'bike', 'scooter', 'transport'
      ],
    ),
    ExpenseCategory(
      name: 'Education',
      icon: '📚',
      colorHex: '#8B5CF6',
      keywords: [
        'book', 'course', 'udemy', 'coursera', 'fees', 'tuition',
        'library', 'stationery', 'pen', 'notebook', 'xerox',
        'photocopy', 'print', 'assignment', 'project', 'study',
        'exam', 'test', 'coaching'
      ],
    ),
    ExpenseCategory(
      name: 'Subscriptions',
      icon: '🔄',
      colorHex: '#EF4444',
      keywords: [
        'netflix', 'prime', 'spotify', 'youtube', 'hotstar',
        'subscription', 'monthly', 'renewal', 'membership',
        'premium', 'plan', 'adobe', 'canva', 'notion'
      ],
    ),
    ExpenseCategory(
      name: 'Shopping',
      icon: '🛍️',
      colorHex: '#EC4899',
      keywords: [
        'amazon', 'flipkart', 'myntra', 'ajio', 'shopping',
        'clothes', 'shoes', 'electronics', 'gadget', 'mobile',
        'laptop', 'headphone', 'watch', 'bag', 'wallet'
      ],
    ),
    ExpenseCategory(
      name: 'Miscellaneous',
      icon: '📦',
      colorHex: '#6B7280',
      keywords: [],
    ),
  ];

  /// Get category by name
  static ExpenseCategory getByName(String name) {
    return all.firstWhere(
      (cat) => cat.name == name,
      orElse: () => all.last, // Default to Miscellaneous
    );
  }

  /// Auto-detect category from merchant name
  static String detectCategory(String merchant) {
    final merchantLower = merchant.toLowerCase();
    
    for (final category in all) {
      for (final keyword in category.keywords) {
        if (merchantLower.contains(keyword.toLowerCase())) {
          return category.name;
        }
      }
    }
    
    return 'Miscellaneous';
  }
}
