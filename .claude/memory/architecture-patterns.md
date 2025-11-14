# ContaCashew - Architecture & Design Patterns

## Core Architectural Patterns

### 1. Reactive Stream-Based Architecture

The app uses a reactive architecture where UI components automatically update when underlying data changes.

```dart
// Pattern: StreamBuilder for reactive UI
StreamBuilder<List<Transaction>>(
  stream: database.watchAllTransactions(
    searchFilters: SearchFilters(...),
    limit: 50,
  ),
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      return TransactionList(transactions: snapshot.data!);
    }
    if (snapshot.hasError) {
      return ErrorWidget(snapshot.error);
    }
    return LoadingShimmer();
  }
)
```

**Key Benefits:**
- Automatic UI updates on data changes
- Efficient database query optimization
- Declarative UI programming
- Reduced boilerplate code

**Files:** All pages use this pattern extensively

---

### 2. Page Framework Pattern

Every page in the app follows a standardized structure using `PageFramework`.

```dart
// Location: /home/user/ContaCashew/budget/lib/widgets/framework/pageFramework.dart

class MyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return PageFramework(
      title: "page-title",                    // Localized string key
      dragDownToDismiss: true,                 // Swipe down to close
      backButton: true,                        // Show back button
      horizontalPaddingConstrained: true,      // Responsive padding
      expandedHeight: 56,                      // App bar height
      actions: [                               // App bar actions
        IconButton(icon: Icon(Icons.edit), onPressed: () {}),
      ],
      slivers: [                               // Scrollable content
        SliverToBoxAdapter(child: Header()),
        SliverList(delegate: ...),
      ],
      floatingActionButton: FloatingActionButton(...),
      backgroundColor: Colors.white,
      scrollController: myController,          // Optional custom controller
    );
  }
}
```

**Features:**
- Automatic scroll controller management
- Consistent navigation patterns
- Responsive padding based on screen size
- Pull-to-refresh support
- Drag-to-dismiss gesture
- Sliver-based efficient scrolling

**Example Files:**
- `/home/user/ContaCashew/budget/lib/pages/objectivePage.dart`
- `/home/user/ContaCashew/budget/lib/pages/objectivesListPage.dart`
- `/home/user/ContaCashew/budget/lib/pages/budgetPage.dart`

---

### 3. Widget Composition Pattern

Pages are composed of smaller, reusable widgets following a clear hierarchy.

```dart
// Pattern: Composition over inheritance

// Page Structure
class ObjectivePage extends StatelessWidget {
  Widget build(BuildContext context) {
    return StreamBuilder<Objective>(
      stream: database.getObjective(objectivePk),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return SizedBox.shrink();

        return CustomColorTheme(
          accentColor: dynamicPastel(
            context,
            objective.colour,
            amount: 0.3
          ),
          child: _ObjectivePageContent(
            objective: snapshot.data!
          ),
        );
      }
    );
  }
}

// Content Widget (internal)
class _ObjectivePageContent extends StatefulWidget {
  final Objective objective;
  const _ObjectivePageContent({required this.objective});

  @override
  State<_ObjectivePageContent> createState() => _ObjectivePageContentState();
}

class _ObjectivePageContentState extends State<_ObjectivePageContent> {
  Widget build(BuildContext context) {
    return PageFramework(
      slivers: [
        _buildHeader(),
        _buildProgressSection(),
        _buildTransactionsList(),
      ],
    );
  }

  Widget _buildHeader() { ... }
  Widget _buildProgressSection() { ... }
  Widget _buildTransactionsList() { ... }
}
```

**Hierarchy Pattern:**
```
Page (StatelessWidget)
└── StreamBuilder (data layer)
    └── CustomColorTheme (theming layer)
        └── PageContent (StatefulWidget)
            └── PageFramework (structure layer)
                └── Slivers (content layer)
                    ├── Header widgets
                    ├── Content widgets
                    └── List widgets
```

---

### 4. Database Pattern (Drift ORM)

The app uses Drift (formerly Moor) for type-safe database operations.

```dart
// Location: /home/user/ContaCashew/budget/lib/database/tables.dart

// Table Definition
@DataClassName('Transaction')
class Transactions extends Table {
  TextColumn get transactionPk => text().clientDefault(() => uuid.v4())();
  TextColumn get name => text().withLength(max: 250)();
  RealColumn get amount => real()();
  TextColumn get categoryFk => text().references(Categories, #categoryPk)();
  DateTimeColumn get dateCreated => dateTime()();
  BoolColumn get income => boolean()();
  // ... more columns
}

// Query Pattern (in database class)
Stream<List<Transaction>> watchAllTransactions({
  String? categoryFk,
  String? walletFk,
  SearchFilters? searchFilters,
  int? limit,
}) {
  var query = select(transactions);

  if (categoryFk != null) {
    query.where((t) => t.categoryFk.equals(categoryFk));
  }

  if (searchFilters?.dateTimeRange != null) {
    query.where((t) => t.dateCreated.isBetweenValues(
      searchFilters!.dateTimeRange!.start,
      searchFilters!.dateTimeRange!.end,
    ));
  }

  query.orderBy([(t) => OrderingTerm.desc(t.dateCreated)]);

  if (limit != null) {
    query.limit(limit);
  }

  return query.watch();
}

// Usage in UI
StreamBuilder<List<Transaction>>(
  stream: database.watchAllTransactions(
    categoryFk: widget.categoryPk,
    limit: 100,
  ),
  builder: (context, snapshot) { ... }
)
```

**Key Patterns:**
- **UUID Primary Keys:** All tables use UUID v4 for primary keys
- **Foreign Key References:** Type-safe relationships between tables
- **Streams for Reactivity:** All queries return streams for reactive UI
- **Query Builders:** Flexible, composable query construction
- **Migrations:** Version-controlled schema changes

**Files:**
- `/home/user/ContaCashew/budget/lib/database/tables.dart` - Schema
- `/home/user/ContaCashew/budget/lib/struct/databaseGlobal.dart` - Instance

---

### 5. State Management Pattern

The app uses multiple state management strategies depending on scope:

#### A. Global Settings (Map-Based)
```dart
// Location: /home/user/ContaCashew/budget/lib/struct/settings.dart

// Global state map
Map<String, dynamic> appStateSettings = {};

// Access pattern
String theme = appStateSettings["theme"];
String selectedWallet = appStateSettings["selectedWalletPk"];

// Update pattern
await updateSettings(
  "theme",
  "dark",
  updateGlobalState: true,
  pagesNeedingRefresh: [0, 1, 2], // Tab indices to refresh
);

// Common settings keys:
// - "theme" (light/dark/black)
// - "selectedWalletPk" (current wallet)
// - "materialYou" (bool)
// - "batterySaver" (bool)
// - "animationSpeed" (double)
// - "hasOnboarded" (bool)
```

#### B. Provider Pattern (Cross-Widget State)
```dart
// Watching data
final allWallets = Provider.of<AllWallets>(context);
final selectedWalletPk = Provider.of<SelectedWalletPk>(context);

// Updating
Provider.of<AllWallets>(context, listen: false).setWallets(...);
```

#### C. StatefulWidget Local State
```dart
class _MyPageState extends State<MyPage> {
  bool _isExpanded = false;
  String? _selectedCategory;

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }
}
```

#### D. GlobalKey Pattern (External Access)
```dart
// Define global key
GlobalKey<HomePageState> homePageStateKey = GlobalKey();

// Use in widget
HomePage(key: homePageStateKey)

// Access from anywhere
homePageStateKey.currentState?.refreshState();
```

---

### 6. Navigation Pattern

```dart
// Push route
pushRoute(context, ObjectivePage(objectivePk: "123"));

// Pop route
popRoute(context);

// Pop with data
Navigator.pop(context, selectedValue);

// OpenContainer animation (material motion)
OpenContainerNavigation(
  openPage: DetailPage(),
  button: (openContainer) {
    return MyButton(onTap: openContainer);
  },
)

// Bottom sheet
await openBottomSheet(
  context,
  PopupFramework(
    title: "Select Category",
    child: CategoryPicker(),
  ),
  showScrollbar: true,
  useCustomController: false,
);
```

**Navigation Files:**
- `/home/user/ContaCashew/budget/lib/widgets/framework/pageFramework.dart`
- `/home/user/ContaCashew/budget/lib/widgets/framework/popupFramework.dart`
- `/home/user/ContaCashew/budget/lib/widgets/openContainerNavigation.dart`

---

### 7. Theming Pattern

```dart
// Custom color theme wrapping
CustomColorTheme(
  accentColor: dynamicPastel(context, colorString, amount: 0.3),
  child: MyWidget(),
)

// Accessing theme colors in child widgets
Theme.of(context).colorScheme.primary
Theme.of(context).colorScheme.secondary
getColor(context, "black") // Custom color system

// Dynamic color generation
Color dynamicPastel(
  BuildContext context,
  String? colorString, {
  double amount = 0.2,
  bool inverse = false,
}) { ... }

// Material You support
appStateSettings["materialYou"] == true
```

**Theme Files:**
- `/home/user/ContaCashew/budget/lib/colors.dart`
- `/home/user/ContaCashew/budget/lib/widgets/framework/customColorTheme.dart`

---

### 8. Localization Pattern

```dart
// String localization
Text("page-title".tr())
Text("welcome-message".tr())

// Plural handling
Text("transaction-count".plural(count))

// Parameterized strings
Text("greeting".tr(namedArgs: {"name": userName}))

// Date formatting
getWordedDateShort(DateTime.now())
getWordedDate(DateTime.now(), includeYear: true)
```

**Translation Files:**
- `/home/user/ContaCashew/budget/assets/translations/*.json`

---

### 9. Performance Optimization Patterns

#### A. KeepAlive (Preserve Widget State)
```dart
class _MyWidgetState extends State<MyWidget>
    with AutomaticKeepAliveClientMixin {

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required!
    return ExpensiveWidget();
  }
}
```

#### B. Lazy Indexed Stack (Tabs)
```dart
LazyIndexedStack(
  index: currentTabIndex,
  children: [
    TransactionsTab(),
    BudgetsTab(),
    SubscriptionsTab(),
    MoreTab(),
  ],
)
```

#### C. Visibility Detection (Lazy Loading)
```dart
VisibilityDetector(
  key: Key(widget.transaction.transactionPk),
  onVisibilityChanged: (info) {
    if (info.visibleFraction > 0) {
      // Widget is visible, load data
      setState(() {
        _shouldLoad = true;
      });
    }
  },
  child: widget,
)
```

#### D. Shimmer Loading
```dart
if (!snapshot.hasData) {
  return Shimmer.fromColors(
    baseColor: Colors.grey[300]!,
    highlightColor: Colors.grey[100]!,
    child: PlaceholderWidget(),
  );
}
```

#### E. Animation Control
```dart
// Battery saver check
if (appStateSettings["batterySaver"] == true) {
  // Skip animations
  return widget;
}

// Animation speed control
import 'dart:developer' show Timeline;
timeDilation = double.parse(
  appStateSettings["animationSpeed"].toString()
);
```

---

### 10. Form Handling Pattern

```dart
class _AddTransactionPageState extends State<AddTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.transaction?.amount.toString() ?? ""
    );
    _nameController = TextEditingController(
      text: widget.transaction?.name ?? ""
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveTransaction() async {
    if (_formKey.currentState!.validate()) {
      // Save logic
      await database.createOrUpdateTransaction(...);
      Navigator.pop(context);
    }
  }

  Widget build(BuildContext context) {
    return PageFramework(
      slivers: [
        SliverToBoxAdapter(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "name-required".tr();
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || double.tryParse(value) == null) {
                      return "invalid-amount".tr();
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      ],
      floatingActionButton: FloatingActionButton(
        onPressed: _saveTransaction,
        child: Icon(Icons.save),
      ),
    );
  }
}
```

**Form Widget Files:**
- `/home/user/ContaCashew/budget/lib/widgets/textInput.dart`
- `/home/user/ContaCashew/budget/lib/widgets/selectAmount.dart`
- `/home/user/ContaCashew/budget/lib/widgets/selectCategory.dart`

---

### 11. List Building Pattern

```dart
// Sliver list with sticky headers
SliverStickyHeader(
  header: Container(
    padding: EdgeInsets.all(16),
    child: Text(dateHeader),
  ),
  sliver: SliverList(
    delegate: SliverChildBuilderDelegate(
      (context, index) {
        Transaction transaction = transactions[index];
        return TransactionEntry(
          transaction: transaction,
          openPage: TransactionDetailsPage(
            transactionPk: transaction.transactionPk,
          ),
          listID: "main-list",
        );
      },
      childCount: transactions.length,
    ),
  ),
)

// Grid layout
SliverGrid(
  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
    maxCrossAxisExtent: 200,
    childAspectRatio: 1,
    crossAxisSpacing: 10,
    mainAxisSpacing: 10,
  ),
  delegate: SliverChildBuilderDelegate(
    (context, index) {
      return CategoryCard(category: categories[index]);
    },
    childCount: categories.length,
  ),
)
```

---

### 12. Error Handling Pattern

```dart
// StreamBuilder error handling
StreamBuilder<T>(
  stream: myStream,
  builder: (context, snapshot) {
    if (snapshot.hasError) {
      return ErrorWidget(
        error: snapshot.error.toString(),
        onRetry: () {
          setState(() {}); // Rebuild to retry
        },
      );
    }

    if (snapshot.connectionState == ConnectionState.waiting) {
      return LoadingWidget();
    }

    if (!snapshot.hasData || snapshot.data == null) {
      return EmptyStateWidget();
    }

    return DataWidget(data: snapshot.data!);
  }
)

// Try-catch for async operations
Future<void> saveData() async {
  try {
    await database.createTransaction(...);
    showSnackbar(context, "saved-successfully".tr());
  } catch (e) {
    showSnackbar(context, "error-saving".tr());
    print("Error saving: $e");
  }
}
```

---

## Anti-Patterns to Avoid

1. **Don't bypass PageFramework** - Always use it for consistency
2. **Don't use setState excessively** - Prefer StreamBuilder for data-driven UI
3. **Don't ignore theme colors** - Always use theme-aware colors
4. **Don't hardcode strings** - Use localization keys
5. **Don't create unnecessary StatefulWidgets** - Use StatelessWidget when possible
6. **Don't forget to dispose controllers** - Memory leaks
7. **Don't ignore null safety** - Use proper null checks
8. **Don't skip error handling** - Always handle edge cases

---

## Code Review Checklist

- [ ] Uses PageFramework for pages
- [ ] StreamBuilder for database queries
- [ ] Proper error handling in StreamBuilder
- [ ] Localization for all user-facing strings
- [ ] Theme-aware colors (no hardcoded colors)
- [ ] Controllers disposed properly
- [ ] Null safety handled
- [ ] Performance optimizations where needed (KeepAlive, lazy loading)
- [ ] Consistent naming conventions
- [ ] Proper widget composition (small, reusable widgets)
- [ ] Database migrations if schema changed
- [ ] Multi-currency support considered
- [ ] Dark/light theme tested
- [ ] Accessibility considered (semantic labels, contrast)

---

## References

**Key Architecture Files:**
- `/home/user/ContaCashew/budget/lib/widgets/framework/pageFramework.dart`
- `/home/user/ContaCashew/budget/lib/database/tables.dart`
- `/home/user/ContaCashew/budget/lib/struct/settings.dart`
- `/home/user/ContaCashew/budget/lib/functions.dart`

**Example Implementation:**
- `/home/user/ContaCashew/budget/lib/pages/objectivePage.dart` - Complete page example
- `/home/user/ContaCashew/budget/lib/pages/objectivesListPage.dart` - List page example
- `/home/user/ContaCashew/budget/lib/pages/addObjectivePage.dart` - Form page example
