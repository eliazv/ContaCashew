# ContaCashew - Database Schema Documentation

## Overview

ContaCashew uses **Drift** (formerly Moor), a reactive persistence library for Flutter built on top of SQLite. All tables use UUID v4 for primary keys and support reactive streams for real-time UI updates.

**Database File:** `/home/user/ContaCashew/budget/lib/database/tables.dart`

---

## Core Tables

### 1. Transactions

The central table storing all financial transactions.

```dart
@DataClassName('Transaction')
class Transactions extends Table {
  // Primary Key
  TextColumn get transactionPk => text().clientDefault(() => uuid.v4())();

  // Basic Information
  TextColumn get name => text().withLength(max: 250)();
  RealColumn get amount => real()();
  TextColumn get note => text().withLength(max: 500)();
  TextColumn get noteDetails => text().nullable()(); // Extended notes

  // Categorization
  TextColumn get categoryFk => text().references(Categories, #categoryPk)();
  TextColumn get subCategoryFk => text().nullable()
    .references(Categories, #categoryPk)();
  TextColumn get walletFk => text().references(Wallets, #walletPk)();

  // Timing
  DateTimeColumn get dateCreated => dateTime()();
  DateTimeColumn get dateTimeModified => dateTime().nullable()();

  // Transaction Type
  BoolColumn get income => boolean()(); // Income vs Expense
  BoolColumn get paid => boolean()(); // Paid vs Unpaid
  IntColumn get type => intEnum<TransactionSpecialType>().nullable()();
  // TransactionSpecialType: upcoming, subscription, repetitive, credit, debt

  // Features
  BoolColumn get skipPaid => boolean().withDefault(const Constant(false))();
  BoolColumn get methodAdded => intEnum<MethodAdded>().nullable()();
  TextColumn get transactionOwnerEmail => text().nullable()();
  TextColumn get transactionOriginalOwnerEmail => text().nullable()();
  TextColumn get sharedKey => text().nullable()();

  // Recurrence (for subscriptions/repetitive)
  IntColumn get periodLength => integer().nullable()();
  IntColumn get reoccurrence => intEnum<BudgetReoccurence>().nullable()();
  DateTimeColumn get endDate => dateTime().nullable()();

  // Objectives & Budgets
  TextColumn get objectiveFk => text().nullable()
    .references(Objectives, #objectivePk)();
  TextColumn get budgetFksExclude => text().nullable()(); // Comma-separated

  // Credit/Debt specific
  BoolColumn get createdAnotherFutureTransaction => boolean()
    .withDefault(const Constant(false))();
  TextColumn get upcomingTransactionNotification => text().nullable()();

  // Shared transactions
  TextColumn get sharedStatus => text().nullable()();
  DateTimeColumn get sharedDateUpdated => dateTime().nullable()();
  TextColumn get sharedAllMembersEverAdded => text().nullable()();

  @override
  Set<Column> get primaryKey => {transactionPk};
}
```

**Special Transaction Types:**
```dart
enum TransactionSpecialType {
  upcoming,      // Future scheduled transaction
  subscription,  // Recurring subscription
  repetitive,    // Repeating transaction
  credit,        // Money lent to someone
  debt,          // Money owed to someone
}
```

**Example Queries:**
```dart
// Watch all transactions for a category
Stream<List<Transaction>> watchAllTransactions({
  String? categoryFk,
  String? walletFk,
  SearchFilters? searchFilters,
  int? limit = DEFAULT_LIMIT,
})

// Get single transaction
Future<Transaction> getTransaction(String transactionPk)

// Create or update
Future<Transaction> createOrUpdateTransaction(
  TransactionsCompanion transaction,
  {bool insert = false}
)

// Delete
Future<void> deleteTransaction(String transactionPk)
```

---

### 2. Categories

Hierarchical categorization system for transactions.

```dart
@DataClassName('TransactionCategory')
class Categories extends Table {
  // Primary Key
  TextColumn get categoryPk => text().clientDefault(() => uuid.v4())();

  // Basic Information
  TextColumn get name => text()();
  TextColumn get colour => text().nullable()(); // Hex color code
  TextColumn get iconName => text().nullable()(); // Material icon name
  TextColumn get emojiIconName => text().nullable()(); // Emoji alternative

  // Categorization
  BoolColumn get income => boolean()(); // Income vs Expense category
  IntColumn get order => integer()(); // Display order

  // Hierarchy (subcategories)
  TextColumn get mainCategoryPk => text().nullable()
    .references(Categories, #categoryPk)();

  // Metadata
  DateTimeColumn get dateCreated => dateTime()();
  DateTimeColumn get dateTimeModified => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {categoryPk};
}
```

**Category Hierarchy:**
- Main categories: `mainCategoryPk == null`
- Subcategories: `mainCategoryPk != null` (references parent)

**Example Usage:**
```dart
// Get category with subcategories
Stream<TransactionCategory?> getCategory(String categoryPk)

// Watch all main categories
Stream<List<TransactionCategory>> watchAllCategories({
  bool? isIncome,
  bool mainCategoriesOnly = false,
})

// Get spending by category
Stream<List<CategoryWithTotal>> watchTotalSpentInEachCategoryInTimeRangeFromCategories({
  required DateTime start,
  required DateTime end,
  List<String> categoryFks,
  CategoryBudgetLimit? budgetLimit,
})
```

---

### 3. Wallets (Accounts)

Multiple account/wallet support with different currencies.

```dart
@DataClassName('TransactionWallet')
class Wallets extends Table {
  // Primary Key
  TextColumn get walletPk => text().clientDefault(() => uuid.v4())();

  // Basic Information
  TextColumn get name => text().withLength(max: 250)();
  TextColumn get colour => text().nullable()();
  TextColumn get iconName => text().nullable()();

  // Currency Settings
  TextColumn get currency => text().nullable()(); // Currency code (USD, EUR, etc.)
  IntColumn get decimals => integer().withDefault(const Constant(2))();

  // Display Settings
  IntColumn get order => integer()(); // Display order
  BoolColumn get homePageWidgetDisplay => text().nullable()();
  // JSON config for home page widget

  // Metadata
  DateTimeColumn get dateCreated => dateTime()();
  DateTimeColumn get dateTimeModified => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {walletPk};
}
```

**Currency Handling:**
- Each wallet can have different currency
- Custom decimal precision (0-4 decimals)
- Automatic currency conversion support
- Multi-currency totals

**Example Queries:**
```dart
// Watch all wallets
Stream<List<TransactionWallet>> watchAllWallets({
  String? walletPk,
  bool? hideWalletsInHomePage,
})

// Get wallet balance
Stream<TotalWithCount?> watchTotalWithCountOfWallet({
  bool? isIncome,
  required AllWallets allWallets,
  SearchFilters? searchFilters,
})

// Create or update wallet
Future<TransactionWallet> createOrUpdateWallet(
  WalletsCompanion wallet,
  {bool insert = false}
)
```

---

### 4. Budgets

Time-based spending limits with flexible recurrence.

```dart
@DataClassName('Budget')
class Budgets extends Table {
  // Primary Key
  TextColumn get budgetPk => text().clientDefault(() => uuid.v4())();

  // Basic Information
  TextColumn get name => text()();
  RealColumn get amount => real()(); // Budget limit

  // Time Period
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime()();
  IntColumn get periodLength => integer()(); // Number of periods
  IntColumn get reoccurrence => intEnum<BudgetReoccurence>();
  // BudgetReoccurence: custom, daily, weekly, monthly, yearly

  // Display
  TextColumn get colour => text().nullable()();
  TextColumn get iconName => text().nullable()();
  BoolColumn get pinned => boolean().withDefault(const Constant(false))();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  IntColumn get order => integer()();

  // Filters
  BoolColumn get income => boolean()(); // Income vs Expense budget
  TextColumn get walletFks => text(); // Comma-separated wallet PKs
  TextColumn get categoryFks => text().nullable()(); // Comma-separated
  TextColumn get categoryFksExclude => text().nullable()();

  // Advanced Features
  BoolColumn get addedTransactionsOnly => boolean()
    .withDefault(const Constant(false))();
  TextColumn get memberTransactionFilters => text().nullable()();
  TextColumn get sharedKey => text().nullable()();

  // Budget Wallets (addon/exclusion system)
  TextColumn get walletFk => text().references(Wallets, #walletPk)();
  BoolColumn get isAbsoluteSpendingLimit => boolean()
    .withDefault(const Constant(false))();

  // Metadata
  DateTimeColumn get dateCreated => dateTime()();
  DateTimeColumn get dateTimeModified => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {budgetPk};
}
```

**Budget Recurrence:**
```dart
enum BudgetReoccurence {
  custom,   // Custom date range
  daily,    // Resets daily
  weekly,   // Resets weekly
  monthly,  // Resets monthly
  yearly,   // Resets yearly
}
```

**Budget Types:**
- **Category Budget:** Filter by specific categories
- **Wallet Budget:** Filter by specific wallets
- **Combined Budget:** Multiple filters
- **Absolute Limit:** Hard spending cap

**Example Queries:**
```dart
// Watch all budgets
Stream<List<Budget>> watchAllBudgets({
  String? budgetPk,
  bool? archived,
  String? searchFor,
})

// Watch budget with spending
Stream<BudgetWithSpending> watchBudgetWithSpending(String budgetPk)

// Get current period budgets
Stream<List<Budget>> watchCurrentPeriodBudgets()
```

---

### 5. Objectives (Goals & Loans)

Savings goals and loan tracking.

```dart
@DataClassName('Objective')
class Objectives extends Table {
  // Primary Key
  TextColumn get objectivePk => text().clientDefault(() => uuid.v4())();

  // Type & Basic Info
  IntColumn get type => intEnum<ObjectiveType>(); // goal or loan
  TextColumn get name => text()();
  RealColumn get amount => real()(); // Target amount
  DateTimeColumn get endDate => dateTime().nullable()();

  // Display
  TextColumn get colour => text().nullable()();
  TextColumn get iconName => text().nullable()();
  TextColumn get emojiIconName => text().nullable()();
  BoolColumn get pinned => boolean().withDefault(const Constant(false))();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  IntColumn get order => integer()();

  // Configuration
  BoolColumn get income => boolean()(); // Save vs Earn goal
  TextColumn get walletFk => text().references(Wallets, #walletPk)();

  // Metadata
  DateTimeColumn get dateCreated => dateTime()();
  DateTimeColumn get dateTimeModified => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {objectivePk};
}
```

**Objective Types:**
```dart
enum ObjectiveType {
  goal, // Savings goal
  loan, // Loan (money lent/borrowed)
}
```

**Objective Features:**
- Link transactions to objectives
- Track progress toward target
- Visual progress indicators
- Pinnable to home page
- Archive completed objectives

**Example Queries:**
```dart
// Watch all objectives
Stream<List<Objective>> watchAllObjectives({
  ObjectiveType? objectiveType,
  String? searchFor,
  bool? isIncome,
  bool hideArchived = true,
})

// Get objective with progress
Stream<Objective> getObjective(String objectivePk)

// Get objective total
Stream<double?> watchTotalTowardsObjective({
  required String objectivePk,
  bool? isIncome,
})
```

---

## Supporting Tables

### 6. ScannerTemplate

Templates for quick transaction entry.

```dart
@DataClassName('ScannerTemplate')
class ScannerTemplates extends Table {
  TextColumn get scannerTemplatePk => text().clientDefault(() => uuid.v4())();
  TextColumn get name => text()();
  BoolColumn get income => boolean()();
  TextColumn get walletFk => text().references(Wallets, #walletFk)();
  TextColumn get categoryFk => text().nullable()
    .references(Categories, #categoryPk)();
  TextColumn get defaultAmount => text().nullable()();
  DateTimeColumn get dateCreated => dateTime()();

  @override
  Set<Column> get primaryKey => {scannerTemplatePk};
}
```

### 7. CategoryBudgetLimit

Per-category budget limits within budgets.

```dart
@DataClassName('CategoryBudgetLimit')
class CategoryBudgetLimits extends Table {
  TextColumn get categoryLimitPk => text().clientDefault(() => uuid.v4())();
  TextColumn get budgetFk => text().references(Budgets, #budgetPk)();
  TextColumn get categoryFk => text().references(Categories, #categoryPk)();
  RealColumn get amount => real()();
  DateTimeColumn get dateTimeModified => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {categoryLimitPk};
}
```

---

## Query Patterns

### Common Query Components

#### SearchFilters
```dart
class SearchFilters {
  DateTimeRange? dateTimeRange;
  List<String>? walletPks;
  List<String>? categoryPks;
  List<String>? budgetPks;
  String? searchQuery;
  bool? paidStatus;
  bool? income;
  List<TransactionSpecialType>? excludedTypes;
  // ... more filters
}
```

#### TotalWithCount
```dart
class TotalWithCount {
  final double total;
  final int count;
  final int countUnpaid;
  final double totalUnpaid;
}
```

#### CategoryWithTotal
```dart
class CategoryWithTotal {
  final TransactionCategory category;
  final double total;
  final int transactionCount;
}
```

### Complex Query Examples

#### 1. Total Spent in Time Range
```dart
Stream<double?> watchTotalSpentInTimeRangeFromCategories({
  required DateTime start,
  required DateTime end,
  String? categoryFk,
  List<String>? categoryFks,
  bool? isIncome,
  String? walletPk,
  SearchFilters? searchFilters,
})
```

#### 2. Spending by Category
```dart
Stream<List<CategoryWithTotal>> watchTotalSpentInEachCategoryInTimeRangeFromCategories({
  required DateTime start,
  required DateTime end,
  List<String> categoryFks,
  CategoryBudgetLimit? budgetLimit,
  String? budgetTransactionFilters,
  List<String>? walletPks,
  SearchFilters? searchFilters,
})
```

#### 3. Daily Spending Totals
```dart
Future<Map<String, double>> getDailyTotalsInTimeRange({
  required DateTime start,
  required DateTime end,
  bool? isIncome,
  SearchFilters? searchFilters,
})
```

---

## Database Migrations

When adding new features that require schema changes:

```dart
// In database class
@override
int get schemaVersion => 42; // Increment version

@override
MigrationStrategy get migration => MigrationStrategy(
  onCreate: (Migrator m) async {
    await m.createAll();
  },
  onUpgrade: (Migrator m, int from, int to) async {
    // Migration logic
    if (from < 42) {
      // Add new table/column
      await m.createTable(investments);
      // or
      await m.addColumn(transactions, transactions.newField);
    }
  },
);
```

**Best Practices:**
1. Always increment `schemaVersion`
2. Test migrations on existing data
3. Provide default values for new columns
4. Document migration steps
5. Handle backwards compatibility

---

## Indexes and Performance

**Default Indexes:**
- Primary keys are automatically indexed
- Foreign keys are automatically indexed

**Custom Indexes:**
```dart
@override
List<Set<Column>> get indexes => [
  {dateCreated, walletFk}, // Composite index
  {categoryFk},
];
```

**Query Optimization:**
- Use `limit` for large result sets
- Use `watch()` instead of `get()` for reactive UI
- Use compound indexes for common filters
- Avoid N+1 query patterns

---

## Data Integrity

### Foreign Key Constraints
All foreign keys use `references()`:
```dart
TextColumn get categoryFk => text().references(Categories, #categoryPk)();
```

### Cascading Deletes
Handled manually in application code:
```dart
Future<void> deleteCategory(String categoryPk) async {
  // First update/delete dependent transactions
  await (update(transactions)
    ..where((t) => t.categoryFk.equals(categoryPk)))
    .write(TransactionsCompanion(
      categoryFk: Value(defaultCategoryPk),
    ));

  // Then delete category
  await (delete(categories)
    ..where((c) => c.categoryPk.equals(categoryPk)))
    .go();
}
```

### UUID Primary Keys
All tables use UUID v4 for globally unique identifiers:
```dart
TextColumn get tablePk => text().clientDefault(() => uuid.v4())();
```

**Benefits:**
- No ID conflicts in cloud sync
- Can generate IDs client-side
- Better for distributed systems

---

## Global Database Instance

**Access Pattern:**
```dart
// Import
import 'package:budget/struct/databaseGlobal.dart';

// Usage
database.watchAllTransactions()
database.createOrUpdateTransaction(...)
database.getWallet(walletPk)
```

**File:** `/home/user/ContaCashew/budget/lib/struct/databaseGlobal.dart`

---

## Testing Database Queries

```dart
// Generate preview data for testing
import 'package:budget/database/generatePreviewData.dart';

await generatePreviewData(database);
```

**File:** `/home/user/ContaCashew/budget/lib/database/generatePreviewData.dart`

---

## Future Schema Additions

When adding the investments feature, follow this pattern:

```dart
@DataClassName('Investment')
class Investments extends Table {
  TextColumn get investmentPk => text().clientDefault(() => uuid.v4())();
  TextColumn get name => text().withLength(max: 250)();
  TextColumn get symbol => text().nullable()();
  RealColumn get shares => real()();
  RealColumn get purchasePrice => real()();
  RealColumn get currentPrice => real()();
  DateTimeColumn get purchaseDate => dateTime()();
  TextColumn get walletFk => text().references(Wallets, #walletPk)();
  TextColumn get categoryFk => text().nullable()
    .references(Categories, #categoryPk)();
  DateTimeColumn get dateCreated => dateTime()();
  DateTimeColumn get dateTimeModified => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {investmentPk};
}

@DataClassName('InvestmentPriceHistory')
class InvestmentPriceHistories extends Table {
  TextColumn get priceHistoryPk => text().clientDefault(() => uuid.v4())();
  TextColumn get investmentFk => text().references(Investments, #investmentPk)();
  RealColumn get price => real()();
  DateTimeColumn get date => dateTime()();

  @override
  Set<Column> get primaryKey => {priceHistoryPk};
}
```

---

## References

**Main Files:**
- `/home/user/ContaCashew/budget/lib/database/tables.dart` - Complete schema
- `/home/user/ContaCashew/budget/lib/struct/databaseGlobal.dart` - Database instance
- `/home/user/ContaCashew/budget/lib/database/generatePreviewData.dart` - Test data
