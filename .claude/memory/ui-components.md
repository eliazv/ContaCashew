# ContaCashew - UI Components Guide

## Component Library Overview

ContaCashew has 115+ reusable widgets organized in `/home/user/ContaCashew/budget/lib/widgets/`. This guide covers the most important components for building new features.

---

## Page Framework Components

### PageFramework

The standard wrapper for all full-page screens.

**File:** `/home/user/ContaCashew/budget/lib/widgets/framework/pageFramework.dart`

```dart
PageFramework(
  // Header
  title: "page-title",                      // Localized key
  subtitle: "page-subtitle",                // Optional subtitle
  dragDownToDismiss: true,                  // Swipe down to close
  backButton: true,                         // Show back button
  expandedHeight: 56,                       // App bar height

  // Actions
  actions: [
    IconButton(
      icon: Icon(Icons.edit),
      onPressed: () => editItem(),
    ),
  ],

  // Layout
  horizontalPaddingConstrained: true,       // Responsive padding
  listID: "my-list",                        // For multi-select

  // Content (Slivers)
  slivers: [
    SliverToBoxAdapter(child: Header()),
    SliverList(delegate: myDelegate),
  ],

  // Bottom elements
  floatingActionButton: FloatingActionButton(...),
  bottomNavBar: MyBottomNav(),

  // Styling
  backgroundColor: Colors.white,
  appBarBackgroundColor: Colors.blue,
  textColor: Colors.black,

  // Scroll control
  scrollController: myController,           // Optional custom
  onScroll: (scrollPosition) {},
  onBackButton: () async => true,           // Custom back handling
)
```

**Key Features:**
- Automatic scroll management
- Pull-down to refresh support
- Drag-to-dismiss gesture
- Responsive padding based on screen width
- Multi-select support via listID
- Sliver-based efficient scrolling

**Example Usage:**
```dart
class MyPage extends StatelessWidget {
  Widget build(BuildContext context) {
    return PageFramework(
      title: "investments",
      dragDownToDismiss: true,
      slivers: [
        SliverToBoxAdapter(
          child: InvestmentsSummary(),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => InvestmentEntry(investments[index]),
            childCount: investments.length,
          ),
        ),
      ],
      floatingActionButton: FloatingActionButton(
        onPressed: () => pushRoute(context, AddInvestmentPage()),
        child: Icon(Icons.add),
      ),
    );
  }
}
```

---

### PopupFramework

Standard wrapper for bottom sheets and dialogs.

**File:** `/home/user/ContaCashew/budget/lib/widgets/framework/popupFramework.dart`

```dart
await openBottomSheet(
  context,
  PopupFramework(
    title: "select-category",
    subtitle: "choose-transaction-category",
    child: CategoryPicker(
      onSelected: (category) {
        Navigator.pop(context, category);
      },
    ),
    icon: Icons.category,
    trailing: IconButton(
      icon: Icon(Icons.add),
      onPressed: () => addNewCategory(),
    ),
    hasPadding: true,
    underTitleSpace: false,
    dragDownToDismiss: true,
  ),
  showScrollbar: true,
);
```

**Features:**
- Consistent header styling
- Icon support
- Trailing actions
- Drag to dismiss
- Auto-scrollbar

---

## List Components

### TransactionEntry

The primary component for displaying transactions in lists.

**File:** `/home/user/ContaCashew/budget/lib/widgets/transactionEntry/transactionEntry.dart`

```dart
TransactionEntry(
  // Navigation
  openPage: TransactionDetailsPage(
    transactionPk: transaction.transactionPk,
  ),

  // Data
  transaction: transaction,
  category: category,                       // Can be null
  subCategory: subCategory,                 // Can be null

  // List management
  listID: "main-transactions-list",         // For multi-select
  selected: false,
  onSelected: (transaction, isSelected) {
    // Handle selection
  },
  allowSelect: true,

  // Styling
  containerColor: Colors.white,
  useHorizontalPaddingConstrained: true,    // Responsive padding

  // Display options
  showCategory: true,
  showWallet: false,
  showObjectivePercentage: true,
  showDate: false,
)
```

**Visual Structure:**
```
┌─────────────────────────────────────────┐
│ [Icon] Transaction Name        -$50.00  │
│        Category • Note                  │
│        [Progress bar if objective]      │
└─────────────────────────────────────────┘
```

**Key Features:**
- OpenContainer animation on tap
- Swipe actions (delete, edit)
- Multi-select mode
- Category/subcategory display
- Amount with currency
- Optional progress indicators
- Date badges
- Custom colors

**Variants:**
- `TransactionEntries` - Grouped list with sticky date headers
- `TransactionEntryBanner` - Compact banner version

---

### ObjectiveContainer

Display component for goals/loans (can be adapted for investments).

**File:** `/home/user/ContaCashew/budget/lib/widgets/objectiveContainer.dart`

```dart
ObjectiveContainer(
  objective: objective,
  totalAmount: 1500.50,                     // Current progress
  openPage: ObjectivePage(
    objectivePk: objective.objectivePk,
  ),
  selected: false,
  onSelected: (objective, selected) {},
  isPinned: false,
  useHorizontalPaddingConstrained: true,
)
```

**Visual Structure:**
```
┌─────────────────────────────────────────┐
│ [Icon] Objective Name                   │
│                                         │
│ ████████░░░░░░░░ 60%                   │
│ $1,500.50 of $2,500.00                 │
│ 15 days remaining                       │
└─────────────────────────────────────────┘
```

**Features:**
- Circular or linear progress indicator
- Percentage display
- Amount progress (current/target)
- Time remaining
- Custom colors and icons
- OpenContainer animation

---

## Chart Components

### PieChartWrapper

Interactive pie chart for category spending.

**File:** `/home/user/ContaCashew/budget/lib/widgets/pieChart.dart`

```dart
PieChartWrapper(
  data: categoryTotals,                     // List<CategoryWithTotal>
  totalSpent: 1234.56,
  setSelectedCategory: (categoryPk, category) {
    setState(() {
      selectedCategoryPk = categoryPk;
    });
  },
  isPastBudget: false,
  middleColor: Colors.white,                // Center hole color
  numberOfDecimals: 2,
)
```

**Features:**
- Touch interaction (tap to select)
- Automatic color assignment from categories
- Percentage labels
- Center hole (donut chart)
- Legend with amounts
- Smooth animations

**Data Structure:**
```dart
class CategoryWithTotal {
  final TransactionCategory category;
  final double total;
  final int transactionCount;
}
```

---

### LineGraph

Time-series line chart for trends.

**File:** `/home/user/ContaCashew/budget/lib/widgets/lineGraph.dart`

```dart
_LineChart(
  spots: [
    [FlSpot(0, 100), FlSpot(1, 200), FlSpot(2, 150)],  // Series 1
    [FlSpot(0, 50), FlSpot(1, 75), FlSpot(2, 100)],    // Series 2 (optional)
  ],
  maxPair: Pair(x: 2, y: 200),
  minPair: Pair(x: 0, y: 0),
  color: Theme.of(context).colorScheme.primary,
  secondColor: Theme.of(context).colorScheme.secondary,  // Optional
  isCurved: true,
  enableTouch: true,
  showDots: true,
  betweenLinesFillGradient: LinearGradient(...),        // Area between lines
)
```

**Features:**
- Single or dual line series
- Curved or straight lines
- Touch interaction (tooltip)
- Gradient fills
- Grid lines
- Custom X/Y axis labels
- Smooth animations

**Use Cases:**
- Net worth over time
- Budget spending trends
- Investment portfolio value
- Category spending history

---

### BarGraph

Bar chart for comparing values.

**File:** `/home/user/ContaCashew/budget/lib/widgets/barGraph.dart`

```dart
BarGraph(
  data: [
    BarData(x: 0, y: 100, label: "Jan"),
    BarData(x: 1, y: 200, label: "Feb"),
    BarData(x: 2, y: 150, label: "Mar"),
  ],
  maxY: 250,
  color: Colors.blue,
  showLabels: true,
)
```

**Features:**
- Vertical bars
- Custom colors per bar
- Touch interaction
- Value labels
- Grid lines

---

## Amount Display Components

### TransactionsAmountBox

Summary box showing total amount with optional drill-down.

**File:** `/home/user/ContaCashew/budget/lib/widgets/transactionsAmountBox.dart`

```dart
TransactionsAmountBox(
  label: "net-worth",                       // Localized key
  totalWithCountStream: database.watchTotalWithCountOfWallet(
    allWallets: Provider.of<AllWallets>(context),
    searchFilters: SearchFilters(...),
  ),
  textColor: getColor(context, "black"),
  absolute: false,                          // Show +/- sign
  invertSign: false,
  currencyKey: "USD",
  decimals: 2,

  // Navigation
  openPage: WalletDetailsPage(...),
  onLongPress: () => showOptions(),

  // Styling
  getTextColor: (amount) {
    return amount >= 0 ? Colors.green : Colors.red;
  },
  backgroundColor: Colors.white,
)
```

**Visual Structure:**
```
┌─────────────────────────────────────────┐
│ Net Worth                               │
│ $12,345.67                              │
│ 156 transactions                        │
└─────────────────────────────────────────┘
```

**Features:**
- Animated number transitions
- Stream-based reactive updates
- Conditional text colors
- Transaction count display
- Click to navigate
- Long press for actions

---

### CountNumber

Animated number counter with currency formatting.

**File:** `/home/user/ContaCashew/budget/lib/widgets/countNumber.dart`

```dart
CountNumber(
  count: 1234.56,
  duration: Duration(milliseconds: 500),
  initialCount: 0,
  textBuilder: (number) {
    return convertToMoney(
      Provider.of<AllWallets>(context),
      number,
      currencyKey: "USD",
    );
  },
  textStyle: TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
  ),
)
```

**Features:**
- Smooth counting animation
- Custom formatting via textBuilder
- Configurable duration
- Initial value support

---

## Input Components

### TextInput

Standardized text field with validation.

**File:** `/home/user/ContaCashew/budget/lib/widgets/textInput.dart`

```dart
TextInput(
  labelText: "name",
  icon: Icons.label,
  controller: nameController,
  validator: (value) {
    if (value == null || value.isEmpty) {
      return "name-required".tr();
    }
    return null;
  },
  autoFocus: false,
  bubbly: true,                             // Rounded corners
  padding: EdgeInsets.symmetric(horizontal: 16),
)
```

---

### SelectAmount

Amount input with calculator-style interface.

**File:** `/home/user/ContaCashew/budget/lib/widgets/selectAmount.dart`

```dart
SelectAmount(
  onlyShowCurrencyIcon: false,
  amountPassed: "100.00",
  setSelectedAmount: (amount, calculated) {
    setState(() {
      selectedAmount = amount;
    });
  },
  next: () => saveAndContinue(),
  nextLabel: "save",
  currencyKey: "USD",
  enableWalletPicker: true,
  walletPk: selectedWalletPk,
  setSelectedWalletPk: (walletPk) {
    setState(() => selectedWalletPk = walletPk);
  },
)
```

**Features:**
- Calculator interface
- Multi-currency support
- Wallet picker integration
- Decimal place configuration
- Expression evaluation (e.g., "10+5*2")

---

### SelectCategory

Category picker with search and quick add.

**File:** `/home/user/ContaCashew/budget/lib/widgets/selectCategory.dart`

```dart
SelectCategory(
  setSelectedCategory: (category) {
    setState(() => selectedCategory = category);
  },
  selectedCategory: currentCategory,
  income: false,                            // Expense categories
  showIncomeExpenseIcons: true,
)
```

**Features:**
- Icon/emoji display
- Subcategory support
- Search functionality
- Quick add new category
- Income/expense filtering

---

## Progress Components

### AnimatedCircularProgress

Circular progress indicator with animation.

**File:** `/home/user/ContaCashew/budget/lib/widgets/animatedCircularProgress.dart`

```dart
AnimatedCircularProgress(
  percent: 0.65,                            // 0.0 to 1.0
  backgroundColor: Colors.grey[300],
  valueColor: Colors.blue,
  strokeWidth: 8.0,
  animationDuration: Duration(milliseconds: 800),
  child: Center(
    child: Text("65%"),
  ),
)
```

---

### ProgressBar

Linear progress bar with customization.

**File:** `/home/user/ContaCashew/budget/lib/widgets/progressBar.dart`

```dart
ProgressBar(
  progress: 0.75,
  color: Colors.green,
  backgroundColor: Colors.grey[200],
  height: 8,
  borderRadius: BorderRadius.circular(4),
  showPercentage: true,
)
```

---

## Navigation Components

### OpenContainerNavigation

Material motion page transition.

**File:** `/home/user/ContaCashew/budget/lib/widgets/openContainerNavigation.dart`

```dart
OpenContainerNavigation(
  openPage: InvestmentDetailsPage(investmentPk: investment.investmentPk),
  button: (openContainer) {
    return InvestmentCard(
      investment: investment,
      onTap: openContainer,
    );
  },
  borderRadius: 15,
  closedColor: Colors.transparent,
)
```

**Features:**
- Shared element transition
- Configurable animation duration
- Custom border radius
- Closed/open color customization

**Use Cases:**
- List item → Detail page
- Card → Expanded view
- Any element → Full page

---

### BottomNavBar

Custom bottom navigation with badges.

**File:** Custom implementation in pages

```dart
BottomNavigationBar(
  currentIndex: selectedIndex,
  onTap: (index) {
    setState(() => selectedIndex = index);
  },
  items: [
    BottomNavigationBarItem(
      icon: Icon(Icons.receipt),
      label: "transactions".tr(),
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.pie_chart),
      label: "budgets".tr(),
    ),
    // ... more items
  ],
)
```

---

## Utility Components

### Tappable

Standardized tap handling with haptic feedback.

**File:** `/home/user/ContaCashew/budget/lib/widgets/tappable.dart`

```dart
Tappable(
  onTap: () => handleTap(),
  onLongPress: () => handleLongPress(),
  borderRadius: 15,
  color: Colors.white,
  child: MyContent(),
)
```

**Features:**
- Ripple effect
- Haptic feedback
- Long press support
- Custom border radius
- Ink well effect

---

### Button

Standardized button component.

**File:** `/home/user/ContaCashew/budget/lib/widgets/button.dart`

```dart
Button(
  label: "save",
  onTap: () => save(),
  color: Theme.of(context).colorScheme.primary,
  textColor: Colors.white,
  icon: Icons.save,
  loading: isSaving,
  disabled: !isValid,
  expandedLayout: true,                     // Full width
)
```

---

### IconButtonScaled

Icon button with scale animation on press.

**File:** `/home/user/ContaCashew/budget/lib/widgets/iconButtonScaled.dart`

```dart
IconButtonScaled(
  icon: Icons.delete,
  onTap: () => deleteItem(),
  iconColor: Colors.red,
  iconSize: 24,
  scale: 0.9,                               // Scale down to 0.9 when pressed
)
```

---

## Loading States

### LoadingShimmer

Skeleton loading effect.

```dart
if (!snapshot.hasData) {
  return Shimmer.fromColors(
    baseColor: Colors.grey[300]!,
    highlightColor: Colors.grey[100]!,
    child: Container(
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
    ),
  );
}
```

**Package:** `shimmer: ^3.0.0`

---

## Color & Theme

### CustomColorTheme

Apply custom accent color to widget subtree.

**File:** `/home/user/ContaCashew/budget/lib/widgets/framework/customColorTheme.dart`

```dart
CustomColorTheme(
  accentColor: dynamicPastel(
    context,
    colorHexString,
    amount: 0.3,
  ),
  child: MyThemedWidget(),
)
```

---

### Color Functions

**File:** `/home/user/ContaCashew/budget/lib/colors.dart`

```dart
// Get theme-aware color
Color color = getColor(context, "black");
// Returns actual color based on current theme

// Generate dynamic pastel variant
Color pastel = dynamicPastel(
  context,
  "#FF5733",
  amount: 0.3,      // Lightness adjustment
  inverse: false,   // Invert for dark mode
);

// Convert hex to Color
Color color = HexColor("#FF5733");
```

---

## Component Composition Patterns

### Example: Investment Entry Component

Following TransactionEntry pattern:

```dart
class InvestmentEntry extends StatelessWidget {
  final Investment investment;
  final Widget openPage;
  final String? listID;
  final bool selected;
  final Function(Investment, bool)? onSelected;

  const InvestmentEntry({
    required this.investment,
    required this.openPage,
    this.listID,
    this.selected = false,
    this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return OpenContainerNavigation(
      openPage: openPage,
      button: (openContainer) {
        return Tappable(
          onTap: openContainer,
          onLongPress: listID != null
            ? () => onSelected?.call(investment, !selected)
            : null,
          color: selected
            ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
            : Colors.white,
          borderRadius: 15,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: HexColor(investment.colour ?? "#4CAF50"),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    getIconFromName(investment.iconName),
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 12),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        investment.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        investment.symbol ?? "",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 8),
                      _buildProgressBar(),
                    ],
                  ),
                ),

                // Amount
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      convertToMoney(
                        Provider.of<AllWallets>(context),
                        investment.currentValue,
                      ),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    _buildGainLoss(),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressBar() {
    // Progress indicator logic
  }

  Widget _buildGainLoss() {
    // Gain/loss percentage display
  }
}
```

---

## Best Practices

### 1. Reusability
- Extract common patterns into widgets
- Use composition over inheritance
- Keep widgets focused and single-purpose

### 2. Performance
- Use `const` constructors where possible
- Minimize rebuilds with proper widget boundaries
- Use `KeepAlive` for expensive widgets in lists

### 3. Theming
- Always use theme colors, not hardcoded values
- Support dark/light theme variants
- Use `CustomColorTheme` for dynamic accents

### 4. Accessibility
- Add semantic labels for screen readers
- Ensure sufficient color contrast
- Support text scaling

### 5. Consistency
- Follow existing component patterns
- Use standard spacing/padding values
- Maintain visual hierarchy

---

## Common Widget Patterns

### Stream-Based Widget
```dart
StreamBuilder<T>(
  stream: database.watchSomeData(),
  builder: (context, snapshot) {
    if (snapshot.hasError) {
      return ErrorWidget(snapshot.error);
    }
    if (!snapshot.hasData) {
      return LoadingShimmer();
    }
    return DataWidget(snapshot.data!);
  }
)
```

### KeepAlive Widget
```dart
class MyExpensiveWidget extends StatefulWidget {
  @override
  State<MyExpensiveWidget> createState() => _MyExpensiveWidgetState();
}

class _MyExpensiveWidgetState extends State<MyExpensiveWidget>
    with AutomaticKeepAliveClientMixin {

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required!
    return ExpensiveContent();
  }
}
```

### Responsive Padding
```dart
EdgeInsets padding = EdgeInsets.symmetric(
  horizontal: getHorizontalPaddingConstrained(context),
);

// Or use built-in:
Container(
  padding: EdgeInsets.symmetric(
    horizontal: appStateSettings["horizontalPadding"] ?? 16,
  ),
)
```

---

## References

**Key Component Files:**
- `/home/user/ContaCashew/budget/lib/widgets/framework/pageFramework.dart`
- `/home/user/ContaCashew/budget/lib/widgets/transactionEntry/transactionEntry.dart`
- `/home/user/ContaCashew/budget/lib/widgets/objectiveContainer.dart`
- `/home/user/ContaCashew/budget/lib/widgets/pieChart.dart`
- `/home/user/ContaCashew/budget/lib/widgets/lineGraph.dart`
- `/home/user/ContaCashew/budget/lib/widgets/transactionsAmountBox.dart`

**Example Pages:**
- `/home/user/ContaCashew/budget/lib/pages/objectivePage.dart`
- `/home/user/ContaCashew/budget/lib/pages/objectivesListPage.dart`
- `/home/user/ContaCashew/budget/lib/pages/addObjectivePage.dart`
