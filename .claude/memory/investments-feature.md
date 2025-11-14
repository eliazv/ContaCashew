# ContaCashew - Investments Feature Design

## Feature Overview

The Investments feature will add comprehensive investment portfolio tracking to ContaCashew, allowing users to:

- Track multiple investments (stocks, ETFs, crypto, etc.)
- Monitor portfolio value over time
- Record price history and updates
- Visualize performance with charts
- Calculate gains/losses
- Link investments to wallets
- Categorize investments
- Set investment goals

**Design Philosophy:** Follow the existing Objectives system pattern, adapting it for investment-specific needs.

---

## Database Schema

### Primary Table: Investments

```dart
@DataClassName('Investment')
class Investments extends Table {
  // Primary Key
  TextColumn get investmentPk => text().clientDefault(() => uuid.v4())();

  // Basic Information
  TextColumn get name => text().withLength(max: 250)();
  TextColumn get symbol => text().nullable()(); // Ticker symbol (AAPL, BTC, etc.)
  TextColumn get investmentType => text().nullable()(); // stock, crypto, etf, bond, etc.

  // Holdings
  RealColumn get shares => real()(); // Number of shares/units
  RealColumn get purchasePrice => real()(); // Initial purchase price per share
  RealColumn get currentPrice => real()(); // Current price per share
  DateTimeColumn get purchaseDate => dateTime()();

  // Display & Organization
  TextColumn get colour => text().nullable()();
  TextColumn get iconName => text().nullable()();
  TextColumn get emojiIconName => text().nullable()();
  BoolColumn get pinned => boolean().withDefault(const Constant(false))();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  IntColumn get order => integer()();

  // Relationships
  TextColumn get walletFk => text().references(Wallets, #walletPk)();
  TextColumn get categoryFk => text().nullable()
    .references(Categories, #categoryPk)();

  // Notes
  TextColumn get note => text().nullable().withLength(max: 500)();

  // Metadata
  DateTimeColumn get dateCreated => dateTime()();
  DateTimeColumn get dateTimeModified => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {investmentPk};
}
```

### Supporting Table: InvestmentPriceHistory

Track price changes over time for performance graphs.

```dart
@DataClassName('InvestmentPriceHistory')
class InvestmentPriceHistories extends Table {
  // Primary Key
  TextColumn get priceHistoryPk => text().clientDefault(() => uuid.v4())();

  // Relationships
  TextColumn get investmentFk => text()
    .references(Investments, #investmentPk)();

  // Price Data
  RealColumn get price => real()(); // Price per share at this point
  DateTimeColumn get date => dateTime()();

  // Optional: Additional data points
  RealColumn get shares => real().nullable()(); // Share quantity at this time
  TextColumn get note => text().nullable()(); // Transaction note (buy/sell)

  // Metadata
  DateTimeColumn get dateCreated => dateTime()();

  @override
  Set<Column> get primaryKey => {priceHistoryPk};
}
```

### Investment Types Enum

```dart
enum InvestmentType {
  stock,
  etf,
  mutualFund,
  crypto,
  bond,
  realEstate,
  commodities,
  other,
}
```

---

## Calculated Fields

### Investment Value Calculations

```dart
class InvestmentWithCalculations {
  final Investment investment;
  final List<InvestmentPriceHistory> priceHistory;

  // Current total value
  double get currentValue => investment.shares * investment.currentPrice;

  // Initial investment amount
  double get initialValue => investment.shares * investment.purchasePrice;

  // Absolute gain/loss
  double get gainLoss => currentValue - initialValue;

  // Percentage gain/loss
  double get gainLossPercentage =>
    (gainLoss / initialValue) * 100;

  // Is profitable?
  bool get isProfitable => gainLoss >= 0;

  // Days held
  int get daysHeld =>
    DateTime.now().difference(investment.purchaseDate).inDays;

  // Annualized return (simple)
  double get annualizedReturn {
    if (daysHeld == 0) return 0;
    double years = daysHeld / 365.25;
    return (gainLossPercentage / years);
  }
}
```

### Portfolio Calculations

```dart
class PortfolioSummary {
  final List<Investment> investments;

  double get totalValue =>
    investments.fold(0, (sum, inv) =>
      sum + (inv.shares * inv.currentPrice));

  double get totalCost =>
    investments.fold(0, (sum, inv) =>
      sum + (inv.shares * inv.purchasePrice));

  double get totalGainLoss => totalValue - totalCost;

  double get totalGainLossPercentage =>
    (totalGainLoss / totalCost) * 100;

  Map<String, double> get allocationByType {
    // Calculate % allocation by investment type
  }

  Map<String, double> get allocationByCategory {
    // Calculate % allocation by category
  }
}
```

---

## Database Queries

```dart
// Watch all investments
Stream<List<Investment>> watchAllInvestments({
  String? walletFk,
  String? categoryFk,
  bool hideArchived = true,
  String? searchFor,
}) {
  var query = select(investments);

  if (walletFk != null) {
    query.where((i) => i.walletFk.equals(walletFk));
  }

  if (hideArchived) {
    query.where((i) => i.archived.equals(false));
  }

  if (searchFor != null && searchFor.isNotEmpty) {
    query.where((i) =>
      i.name.contains(searchFor) |
      i.symbol.contains(searchFor)
    );
  }

  query.orderBy([
    (i) => OrderingTerm(expression: i.pinned, mode: OrderingMode.desc),
    (i) => OrderingTerm(expression: i.order, mode: OrderingMode.asc),
  ]);

  return query.watch();
}

// Get single investment with price history
Future<InvestmentWithHistory> getInvestmentWithHistory(
  String investmentPk
) async {
  final investment = await (select(investments)
    ..where((i) => i.investmentPk.equals(investmentPk)))
    .getSingle();

  final priceHistory = await (select(investmentPriceHistories)
    ..where((p) => p.investmentFk.equals(investmentPk))
    ..orderBy([(p) => OrderingTerm.asc(p.date)]))
    .get();

  return InvestmentWithHistory(investment, priceHistory);
}

// Watch portfolio total value
Stream<double> watchPortfolioTotalValue({
  String? walletFk,
  bool hideArchived = true,
}) {
  return watchAllInvestments(
    walletFk: walletFk,
    hideArchived: hideArchived,
  ).map((investments) {
    return investments.fold(
      0.0,
      (sum, inv) => sum + (inv.shares * inv.currentPrice),
    );
  });
}

// Watch portfolio gain/loss
Stream<PortfolioGainLoss> watchPortfolioGainLoss({
  String? walletFk,
}) {
  return watchAllInvestments(walletFk: walletFk).map((investments) {
    double totalValue = 0;
    double totalCost = 0;

    for (var inv in investments) {
      totalValue += inv.shares * inv.currentPrice;
      totalCost += inv.shares * inv.purchasePrice;
    }

    return PortfolioGainLoss(
      totalValue: totalValue,
      totalCost: totalCost,
      gainLoss: totalValue - totalCost,
      gainLossPercentage: ((totalValue - totalCost) / totalCost) * 100,
    );
  });
}

// Create or update investment
Future<Investment> createOrUpdateInvestment(
  InvestmentsCompanion investment, {
  bool insert = false,
}) async {
  if (insert) {
    return await into(investments).insertReturning(investment);
  } else {
    await (update(investments)
      ..where((i) => i.investmentPk.equals(
        investment.investmentPk.value
      )))
      .write(investment);
    return await getInvestment(investment.investmentPk.value);
  }
}

// Add price history entry
Future<InvestmentPriceHistory> addPriceHistory(
  InvestmentPriceHistoriesCompanion priceHistory
) async {
  return await into(investmentPriceHistories)
    .insertReturning(priceHistory);
}

// Update investment price (and add to history)
Future<void> updateInvestmentPrice({
  required String investmentPk,
  required double newPrice,
  DateTime? date,
  String? note,
}) async {
  final now = date ?? DateTime.now();

  // Update current price in investment
  await (update(investments)
    ..where((i) => i.investmentPk.equals(investmentPk)))
    .write(InvestmentsCompanion(
      currentPrice: Value(newPrice),
      dateTimeModified: Value(now),
    ));

  // Add to price history
  await into(investmentPriceHistories).insert(
    InvestmentPriceHistoriesCompanion.insert(
      investmentFk: investmentPk,
      price: newPrice,
      date: now,
      note: Value(note),
    )
  );
}

// Delete investment
Future<void> deleteInvestment(String investmentPk) async {
  // Delete price history first
  await (delete(investmentPriceHistories)
    ..where((p) => p.investmentFk.equals(investmentPk)))
    .go();

  // Delete investment
  await (delete(investments)
    ..where((i) => i.investmentPk.equals(investmentPk)))
    .go();
}
```

---

## Page Structure

### 1. InvestmentsListPage

Main page showing all investments (similar to ObjectivesListPage).

**File:** `/home/user/ContaCashew/budget/lib/pages/investmentsListPage.dart`

**Structure:**
```dart
class InvestmentsListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return PageFramework(
      title: "investments",
      dragDownToDismiss: true,
      actions: [
        IconButton(
          icon: Icon(Icons.search),
          onPressed: () => showSearchSheet(),
        ),
      ],
      slivers: [
        // Portfolio Summary Card
        SliverToBoxAdapter(
          child: PortfolioSummaryCard(),
        ),

        // Filter Tabs (All, Stocks, Crypto, etc.)
        SliverToBoxAdapter(
          child: InvestmentTypeTabs(),
        ),

        // Investments List
        StreamBuilder<List<Investment>>(
          stream: database.watchAllInvestments(
            hideArchived: true,
          ),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return SliverToBoxAdapter(
                child: LoadingShimmer(),
              );
            }

            return SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final investment = snapshot.data![index];
                  return InvestmentEntry(
                    investment: investment,
                    openPage: InvestmentPage(
                      investmentPk: investment.investmentPk,
                    ),
                    listID: "investments-list",
                  );
                },
                childCount: snapshot.data!.length,
              ),
            );
          },
        ),
      ],
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          pushRoute(context, AddInvestmentPage());
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
```

**Key Features:**
- Portfolio summary at top
- Filter by investment type
- Search functionality
- Multi-select for batch operations
- Pull to refresh

---

### 2. InvestmentPage

Detail page for a single investment (similar to ObjectivePage).

**File:** `/home/user/ContaCashew/budget/lib/pages/investmentPage.dart`

**Structure:**
```dart
class InvestmentPage extends StatelessWidget {
  final String investmentPk;

  const InvestmentPage({required this.investmentPk});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Investment>(
      stream: database.getInvestment(investmentPk),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return SizedBox.shrink();
        }

        final investment = snapshot.data!;

        return CustomColorTheme(
          accentColor: dynamicPastel(
            context,
            investment.colour,
            amount: 0.3,
          ),
          child: _InvestmentPageContent(
            investment: investment,
          ),
        );
      },
    );
  }
}

class _InvestmentPageContent extends StatefulWidget {
  final Investment investment;

  const _InvestmentPageContent({required this.investment});

  @override
  State<_InvestmentPageContent> createState() =>
    _InvestmentPageContentState();
}

class _InvestmentPageContentState extends State<_InvestmentPageContent> {
  @override
  Widget build(BuildContext context) {
    return PageFramework(
      title: widget.investment.name,
      dragDownToDismiss: true,
      actions: [
        IconButton(
          icon: Icon(Icons.edit),
          onPressed: () {
            pushRoute(
              context,
              AddInvestmentPage(
                investment: widget.investment,
              ),
            );
          },
        ),
      ],
      slivers: [
        // Header with icon and name
        SliverToBoxAdapter(
          child: _buildHeader(),
        ),

        // Current value and gain/loss
        SliverToBoxAdapter(
          child: _buildValueSection(),
        ),

        // Performance chart
        SliverToBoxAdapter(
          child: _buildPerformanceChart(),
        ),

        // Holdings details
        SliverToBoxAdapter(
          child: _buildHoldingsSection(),
        ),

        // Price history list
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "price-history".tr(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Button(
                  label: "update-price",
                  onTap: () => _showUpdatePriceSheet(),
                  compact: true,
                ),
              ],
            ),
          ),
        ),

        StreamBuilder<List<InvestmentPriceHistory>>(
          stream: database.watchInvestmentPriceHistory(
            widget.investment.investmentPk,
          ),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return SliverToBoxAdapter(
                child: EmptyState(
                  message: "no-price-history".tr(),
                ),
              );
            }

            return SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final priceEntry = snapshot.data![index];
                  return PriceHistoryEntry(
                    priceHistory: priceEntry,
                  );
                },
                childCount: snapshot.data!.length,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: HexColor(widget.investment.colour ?? "#4CAF50"),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              getIconFromName(widget.investment.iconName),
              color: Colors.white,
              size: 40,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.investment.name,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.investment.symbol != null)
                  Text(
                    widget.investment.symbol!,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValueSection() {
    final currentValue =
      widget.investment.shares * widget.investment.currentPrice;
    final initialValue =
      widget.investment.shares * widget.investment.purchasePrice;
    final gainLoss = currentValue - initialValue;
    final gainLossPercentage =
      (gainLoss / initialValue) * 100;

    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // Current value
          Text(
            "current-value".tr(),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          CountNumber(
            count: currentValue,
            duration: Duration(milliseconds: 500),
            textBuilder: (value) {
              return convertToMoney(
                Provider.of<AllWallets>(context),
                value,
                currencyKey: widget.investment.walletFk,
              );
            },
            textStyle: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),

          // Gain/Loss
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: gainLoss >= 0
                ? Colors.green.withOpacity(0.1)
                : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  gainLoss >= 0
                    ? Icons.trending_up
                    : Icons.trending_down,
                  color: gainLoss >= 0
                    ? Colors.green
                    : Colors.red,
                ),
                SizedBox(width: 8),
                Text(
                  "${gainLoss >= 0 ? '+' : ''}${convertToMoney(Provider.of<AllWallets>(context), gainLoss)}",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: gainLoss >= 0
                      ? Colors.green
                      : Colors.red,
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  "(${gainLoss >= 0 ? '+' : ''}${gainLossPercentage.toStringAsFixed(2)}%)",
                  style: TextStyle(
                    fontSize: 16,
                    color: gainLoss >= 0
                      ? Colors.green
                      : Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceChart() {
    return StreamBuilder<List<InvestmentPriceHistory>>(
      stream: database.watchInvestmentPriceHistory(
        widget.investment.investmentPk,
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.length < 2) {
          return SizedBox.shrink();
        }

        // Convert price history to FlSpot data points
        final spots = snapshot.data!.asMap().entries.map((entry) {
          return FlSpot(
            entry.key.toDouble(),
            entry.value.price * widget.investment.shares,
          );
        }).toList();

        final maxValue = spots.map((s) => s.y).reduce(max);
        final minValue = spots.map((s) => s.y).reduce(min);

        return Container(
          height: 200,
          margin: EdgeInsets.all(16),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(15),
          ),
          child: _LineChart(
            spots: [spots],
            maxPair: Pair(
              x: (spots.length - 1).toDouble(),
              y: maxValue * 1.1,
            ),
            minPair: Pair(x: 0, y: minValue * 0.9),
            color: Theme.of(context).colorScheme.primary,
            isCurved: true,
            enableTouch: true,
          ),
        );
      },
    );
  }

  Widget _buildHoldingsSection() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "holdings-details".tr(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            _buildDetailRow(
              "shares".tr(),
              widget.investment.shares.toString(),
            ),
            _buildDetailRow(
              "purchase-price".tr(),
              convertToMoney(
                Provider.of<AllWallets>(context),
                widget.investment.purchasePrice,
              ),
            ),
            _buildDetailRow(
              "current-price".tr(),
              convertToMoney(
                Provider.of<AllWallets>(context),
                widget.investment.currentPrice,
              ),
            ),
            _buildDetailRow(
              "purchase-date".tr(),
              getWordedDate(widget.investment.purchaseDate),
            ),
            if (widget.investment.investmentType != null)
              _buildDetailRow(
                "type".tr(),
                widget.investment.investmentType!,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showUpdatePriceSheet() async {
    await openBottomSheet(
      context,
      UpdateInvestmentPriceSheet(
        investment: widget.investment,
        onUpdate: () {
          setState(() {}); // Refresh data
        },
      ),
    );
  }
}
```

**Key Features:**
- Header with icon and symbol
- Current value with animated counter
- Gain/loss display with color coding
- Performance line chart
- Holdings details card
- Price history timeline
- Update price functionality

---

### 3. AddInvestmentPage

Form for creating/editing investments (similar to AddObjectivePage).

**File:** `/home/user/ContaCashew/budget/lib/pages/addInvestmentPage.dart`

**Structure:**
```dart
class AddInvestmentPage extends StatefulWidget {
  final Investment? investment; // null for new, populated for edit

  const AddInvestmentPage({this.investment});

  @override
  State<AddInvestmentPage> createState() => _AddInvestmentPageState();
}

class _AddInvestmentPageState extends State<AddInvestmentPage> {
  late TextEditingController _nameController;
  late TextEditingController _symbolController;
  late TextEditingController _sharesController;
  late TextEditingController _purchasePriceController;
  late TextEditingController _currentPriceController;
  late TextEditingController _noteController;

  DateTime _purchaseDate = DateTime.now();
  String? _selectedWalletPk;
  String? _selectedCategoryPk;
  String? _selectedColor;
  String? _selectedIcon;
  String? _selectedInvestmentType;

  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.investment != null;

    _nameController = TextEditingController(
      text: widget.investment?.name ?? "",
    );
    _symbolController = TextEditingController(
      text: widget.investment?.symbol ?? "",
    );
    _sharesController = TextEditingController(
      text: widget.investment?.shares.toString() ?? "",
    );
    _purchasePriceController = TextEditingController(
      text: widget.investment?.purchasePrice.toString() ?? "",
    );
    _currentPriceController = TextEditingController(
      text: widget.investment?.currentPrice.toString() ?? "",
    );
    _noteController = TextEditingController(
      text: widget.investment?.note ?? "",
    );

    if (_isEditing) {
      _purchaseDate = widget.investment!.purchaseDate;
      _selectedWalletPk = widget.investment!.walletFk;
      _selectedCategoryPk = widget.investment!.categoryFk;
      _selectedColor = widget.investment!.colour;
      _selectedIcon = widget.investment!.iconName;
      _selectedInvestmentType = widget.investment!.investmentType;
    } else {
      _selectedWalletPk =
        Provider.of<SelectedWalletPk>(context, listen: false).walletPk;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _symbolController.dispose();
    _sharesController.dispose();
    _purchasePriceController.dispose();
    _currentPriceController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageFramework(
      title: _isEditing ? "edit-investment" : "add-investment",
      dragDownToDismiss: true,
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                // Name
                TextInput(
                  labelText: "name",
                  icon: Icons.label,
                  controller: _nameController,
                  autoFocus: !_isEditing,
                ),

                SizedBox(height: 16),

                // Symbol
                TextInput(
                  labelText: "symbol",
                  icon: Icons.tag,
                  controller: _symbolController,
                  placeholder: "AAPL, BTC, etc.",
                ),

                SizedBox(height: 16),

                // Investment Type
                Tappable(
                  onTap: () => _showInvestmentTypePicker(),
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.category),
                            SizedBox(width: 12),
                            Text(
                              _selectedInvestmentType ?? "select-type".tr(),
                            ),
                          ],
                        ),
                        Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 16),

                // Shares
                TextInput(
                  labelText: "shares",
                  icon: Icons.pie_chart,
                  controller: _sharesController,
                  keyboardType: TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),

                SizedBox(height: 16),

                // Purchase Price
                TextInput(
                  labelText: "purchase-price",
                  icon: Icons.attach_money,
                  controller: _purchasePriceController,
                  keyboardType: TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),

                SizedBox(height: 16),

                // Current Price
                TextInput(
                  labelText: "current-price",
                  icon: Icons.trending_up,
                  controller: _currentPriceController,
                  keyboardType: TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),

                SizedBox(height: 16),

                // Purchase Date
                Tappable(
                  onTap: () => _selectPurchaseDate(),
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.calendar_today),
                            SizedBox(width: 12),
                            Text(getWordedDate(_purchaseDate)),
                          ],
                        ),
                        Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 16),

                // Wallet
                SelectWallet(
                  selectedWalletPk: _selectedWalletPk,
                  setSelectedWalletPk: (walletPk) {
                    setState(() => _selectedWalletPk = walletPk);
                  },
                ),

                SizedBox(height: 16),

                // Category (optional)
                SelectCategory(
                  selectedCategory: _selectedCategoryPk,
                  setSelectedCategory: (categoryPk) {
                    setState(() => _selectedCategoryPk = categoryPk);
                  },
                  income: null, // Allow any category
                ),

                SizedBox(height: 16),

                // Color & Icon
                Row(
                  children: [
                    Expanded(
                      child: SelectColor(
                        selectedColor: _selectedColor,
                        setSelectedColor: (color) {
                          setState(() => _selectedColor = color);
                        },
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: SelectIcon(
                        selectedIcon: _selectedIcon,
                        setSelectedIcon: (icon) {
                          setState(() => _selectedIcon = icon);
                        },
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 16),

                // Note
                TextInput(
                  labelText: "note",
                  icon: Icons.note,
                  controller: _noteController,
                  maxLines: 3,
                ),

                SizedBox(height: 32),

                // Save Button
                Button(
                  label: _isEditing ? "save" : "create",
                  onTap: _saveInvestment,
                  expandedLayout: true,
                ),

                if (_isEditing) ...[
                  SizedBox(height: 16),
                  Button(
                    label: "delete",
                    onTap: _deleteInvestment,
                    color: Colors.red,
                    expandedLayout: true,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectPurchaseDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _purchaseDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() => _purchaseDate = picked);
    }
  }

  Future<void> _showInvestmentTypePicker() async {
    final types = [
      "stock",
      "etf",
      "mutual-fund",
      "crypto",
      "bond",
      "real-estate",
      "commodities",
      "other",
    ];

    final selected = await openBottomSheet(
      context,
      PopupFramework(
        title: "select-investment-type",
        child: Column(
          children: types.map((type) {
            return Tappable(
              onTap: () => Navigator.pop(context, type),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(_getIconForType(type)),
                    SizedBox(width: 12),
                    Text(type.tr()),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );

    if (selected != null) {
      setState(() => _selectedInvestmentType = selected);
    }
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case "stock":
        return Icons.show_chart;
      case "crypto":
        return Icons.currency_bitcoin;
      case "bond":
        return Icons.account_balance;
      case "real-estate":
        return Icons.house;
      default:
        return Icons.attach_money;
    }
  }

  Future<void> _saveInvestment() async {
    // Validation
    if (_nameController.text.isEmpty) {
      showSnackbar(context, "name-required".tr());
      return;
    }

    final shares = double.tryParse(_sharesController.text);
    if (shares == null || shares <= 0) {
      showSnackbar(context, "invalid-shares".tr());
      return;
    }

    final purchasePrice = double.tryParse(_purchasePriceController.text);
    if (purchasePrice == null || purchasePrice < 0) {
      showSnackbar(context, "invalid-purchase-price".tr());
      return;
    }

    final currentPrice = double.tryParse(_currentPriceController.text);
    if (currentPrice == null || currentPrice < 0) {
      showSnackbar(context, "invalid-current-price".tr());
      return;
    }

    if (_selectedWalletPk == null) {
      showSnackbar(context, "wallet-required".tr());
      return;
    }

    // Create investment companion
    final companion = InvestmentsCompanion(
      investmentPk: Value(
        _isEditing ? widget.investment!.investmentPk : uuid.v4()
      ),
      name: Value(_nameController.text),
      symbol: Value(_symbolController.text.isNotEmpty
        ? _symbolController.text
        : null),
      investmentType: Value(_selectedInvestmentType),
      shares: Value(shares),
      purchasePrice: Value(purchasePrice),
      currentPrice: Value(currentPrice),
      purchaseDate: Value(_purchaseDate),
      walletFk: Value(_selectedWalletPk!),
      categoryFk: Value(_selectedCategoryPk),
      colour: Value(_selectedColor),
      iconName: Value(_selectedIcon),
      note: Value(_noteController.text.isNotEmpty
        ? _noteController.text
        : null),
      dateTimeModified: Value(DateTime.now()),
      dateCreated: Value(
        _isEditing
          ? widget.investment!.dateCreated
          : DateTime.now()
      ),
    );

    // Save to database
    await database.createOrUpdateInvestment(
      companion,
      insert: !_isEditing,
    );

    // If creating new, add initial price history
    if (!_isEditing) {
      await database.addPriceHistory(
        InvestmentPriceHistoriesCompanion.insert(
          investmentFk: companion.investmentPk.value,
          price: currentPrice,
          date: _purchaseDate,
          note: Value("initial-purchase".tr()),
        ),
      );
    }

    // Show success and pop
    showSnackbar(
      context,
      _isEditing ? "investment-updated".tr() : "investment-created".tr(),
    );

    Navigator.pop(context);
  }

  Future<void> _deleteInvestment() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("delete-investment".tr()),
        content: Text("delete-investment-confirmation".tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("cancel".tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              "delete".tr(),
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await database.deleteInvestment(widget.investment!.investmentPk);
      showSnackbar(context, "investment-deleted".tr());
      Navigator.pop(context);
    }
  }
}
```

**Key Features:**
- Form validation
- Investment type picker
- Date picker for purchase date
- Wallet and category selection
- Color and icon customization
- Note field
- Delete functionality (edit mode)
- Initial price history entry

---

## Custom Widgets

### InvestmentEntry

List item for displaying investments (similar to TransactionEntry).

**File:** `/home/user/ContaCashew/budget/lib/widgets/investmentEntry.dart`

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
    final currentValue =
      investment.shares * investment.currentPrice;
    final initialValue =
      investment.shares * investment.purchasePrice;
    final gainLoss = currentValue - initialValue;
    final gainLossPercentage =
      (gainLoss / initialValue) * 100;

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
            : Colors.transparent,
          borderRadius: 15,
          child: Container(
            margin: EdgeInsets.symmetric(
              horizontal: getHorizontalPaddingConstrained(context),
              vertical: 8,
            ),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: HexColor(
                      investment.colour ?? "#4CAF50"
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    getIconFromName(investment.iconName),
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                SizedBox(width: 12),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name
                      Text(
                        investment.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),

                      // Symbol and shares
                      Row(
                        children: [
                          if (investment.symbol != null) ...[
                            Text(
                              investment.symbol!,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              " • ",
                              style: TextStyle(
                                color: Colors.grey[400],
                              ),
                            ),
                          ],
                          Text(
                            "${investment.shares} " + "shares".tr(),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),

                      // Gain/Loss indicator
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: gainLoss >= 0
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              gainLoss >= 0
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                              size: 12,
                              color: gainLoss >= 0
                                ? Colors.green
                                : Colors.red,
                            ),
                            SizedBox(width: 4),
                            Text(
                              "${gainLoss >= 0 ? '+' : ''}${gainLossPercentage.toStringAsFixed(2)}%",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: gainLoss >= 0
                                  ? Colors.green
                                  : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Value
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      convertToMoney(
                        Provider.of<AllWallets>(context),
                        currentValue,
                      ),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "${gainLoss >= 0 ? '+' : ''}${convertToMoney(Provider.of<AllWallets>(context), gainLoss)}",
                      style: TextStyle(
                        fontSize: 14,
                        color: gainLoss >= 0
                          ? Colors.green
                          : Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
```

---

### PortfolioSummaryCard

Summary widget showing total portfolio value and performance.

**File:** `/home/user/ContaCashew/budget/lib/widgets/portfolioSummaryCard.dart`

```dart
class PortfolioSummaryCard extends StatelessWidget {
  final String? walletPk;

  const PortfolioSummaryCard({this.walletPk});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PortfolioGainLoss>(
      stream: database.watchPortfolioGainLoss(walletPk: walletPk),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return LoadingShimmer();
        }

        final portfolio = snapshot.data!;

        return Container(
          margin: EdgeInsets.all(16),
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primary.withOpacity(0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context)
                  .colorScheme
                  .primary
                  .withOpacity(0.3),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "total-portfolio-value".tr(),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              SizedBox(height: 8),
              CountNumber(
                count: portfolio.totalValue,
                duration: Duration(milliseconds: 500),
                textBuilder: (value) {
                  return convertToMoney(
                    Provider.of<AllWallets>(context),
                    value,
                  );
                },
                textStyle: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    portfolio.gainLoss >= 0
                      ? Icons.trending_up
                      : Icons.trending_down,
                    color: Colors.white,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    "${portfolio.gainLoss >= 0 ? '+' : ''}${convertToMoney(Provider.of<AllWallets>(context), portfolio.gainLoss)}",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    "(${portfolio.gainLoss >= 0 ? '+' : ''}${portfolio.gainLossPercentage.toStringAsFixed(2)}%)",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
```

---

### PriceHistoryEntry

Display component for price history entries.

**File:** `/home/user/ContaCashew/budget/lib/widgets/priceHistoryEntry.dart`

```dart
class PriceHistoryEntry extends StatelessWidget {
  final InvestmentPriceHistory priceHistory;

  const PriceHistoryEntry({required this.priceHistory});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: getHorizontalPaddingConstrained(context),
        vertical: 4,
      ),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  getWordedDate(priceHistory.date),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (priceHistory.note != null) ...[
                  SizedBox(height: 4),
                  Text(
                    priceHistory.note!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Price
          Text(
            convertToMoney(
              Provider.of<AllWallets>(context),
              priceHistory.price,
            ),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
```

---

### UpdateInvestmentPriceSheet

Bottom sheet for updating investment price.

**File:** `/home/user/ContaCashew/budget/lib/widgets/updateInvestmentPriceSheet.dart`

```dart
class UpdateInvestmentPriceSheet extends StatefulWidget {
  final Investment investment;
  final VoidCallback onUpdate;

  const UpdateInvestmentPriceSheet({
    required this.investment,
    required this.onUpdate,
  });

  @override
  State<UpdateInvestmentPriceSheet> createState() =>
    _UpdateInvestmentPriceSheetState();
}

class _UpdateInvestmentPriceSheetState
    extends State<UpdateInvestmentPriceSheet> {

  late TextEditingController _priceController;
  late TextEditingController _noteController;
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    _priceController = TextEditingController(
      text: widget.investment.currentPrice.toString(),
    );
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _priceController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopupFramework(
      title: "update-price",
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Current info
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "current-price".tr(),
                    style: TextStyle(fontSize: 14),
                  ),
                  Text(
                    convertToMoney(
                      Provider.of<AllWallets>(context),
                      widget.investment.currentPrice,
                    ),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),

            // New price
            TextInput(
              labelText: "new-price",
              icon: Icons.attach_money,
              controller: _priceController,
              keyboardType: TextInputType.numberWithOptions(
                decimal: true,
              ),
              autoFocus: true,
            ),
            SizedBox(height: 16),

            // Date
            Tappable(
              onTap: _selectDate,
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.calendar_today),
                        SizedBox(width: 12),
                        Text(getWordedDate(_date)),
                      ],
                    ),
                    Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),

            // Note
            TextInput(
              labelText: "note",
              icon: Icons.note,
              controller: _noteController,
              placeholder: "price-update-note".tr(),
            ),
            SizedBox(height: 24),

            // Save button
            Button(
              label: "update",
              onTap: _updatePrice,
              expandedLayout: true,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: widget.investment.purchaseDate,
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  Future<void> _updatePrice() async {
    final newPrice = double.tryParse(_priceController.text);

    if (newPrice == null || newPrice < 0) {
      showSnackbar(context, "invalid-price".tr());
      return;
    }

    await database.updateInvestmentPrice(
      investmentPk: widget.investment.investmentPk,
      newPrice: newPrice,
      date: _date,
      note: _noteController.text.isNotEmpty
        ? _noteController.text
        : null,
    );

    showSnackbar(context, "price-updated".tr());
    widget.onUpdate();
    Navigator.pop(context);
  }
}
```

---

## Home Page Integration

Add investments widget to home page (similar to objectives).

**File:** `/home/user/ContaCashew/budget/lib/pages/homePage/homePageInvestments.dart`

```dart
class HomePageInvestments extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PortfolioGainLoss>(
      stream: database.watchPortfolioGainLoss(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return SizedBox.shrink();
        }

        return Tappable(
          onTap: () {
            pushRoute(context, InvestmentsListPage());
          },
          child: Container(
            margin: EdgeInsets.all(16),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "investments".tr(),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(Icons.chevron_right),
                  ],
                ),
                SizedBox(height: 12),
                TransactionsAmountBox(
                  label: "portfolio-value",
                  totalWithCountStream: /* portfolio value stream */,
                  absolute: true,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
```

---

## Localization Keys

Add to `/home/user/ContaCashew/budget/assets/translations/*.json`:

```json
{
  "investments": "Investments",
  "investment": "Investment",
  "add-investment": "Add Investment",
  "edit-investment": "Edit Investment",
  "delete-investment": "Delete Investment",
  "delete-investment-confirmation": "Are you sure you want to delete this investment?",
  "investment-created": "Investment created successfully",
  "investment-updated": "Investment updated successfully",
  "investment-deleted": "Investment deleted successfully",

  "symbol": "Symbol",
  "shares": "Shares",
  "purchase-price": "Purchase Price",
  "current-price": "Current Price",
  "purchase-date": "Purchase Date",
  "current-value": "Current Value",
  "initial-value": "Initial Value",
  "gain-loss": "Gain/Loss",
  "portfolio-value": "Portfolio Value",
  "total-portfolio-value": "Total Portfolio Value",

  "investment-type": "Investment Type",
  "select-type": "Select Type",
  "stock": "Stock",
  "etf": "ETF",
  "mutual-fund": "Mutual Fund",
  "crypto": "Cryptocurrency",
  "bond": "Bond",
  "real-estate": "Real Estate",
  "commodities": "Commodities",
  "other": "Other",

  "price-history": "Price History",
  "update-price": "Update Price",
  "new-price": "New Price",
  "price-updated": "Price updated successfully",
  "no-price-history": "No price history available",
  "price-update-note": "e.g., Market update, Dividend, etc.",
  "initial-purchase": "Initial Purchase",

  "holdings-details": "Holdings Details",
  "performance": "Performance",

  "invalid-shares": "Please enter a valid number of shares",
  "invalid-purchase-price": "Please enter a valid purchase price",
  "invalid-current-price": "Please enter a valid current price",
  "invalid-price": "Please enter a valid price"
}
```

---

## Navigation Integration

Add investments tab/section to main navigation.

**File:** `/home/user/ContaCashew/budget/lib/pages/morePage.dart`

Add to "More" tab:

```dart
SettingsContainerOpenPage(
  title: "investments",
  icon: Icons.trending_up,
  openPage: InvestmentsListPage(),
),
```

Or create dedicated bottom tab (requires modifying HomePage):

```dart
BottomNavigationBarItem(
  icon: Icon(Icons.trending_up),
  label: "investments".tr(),
),
```

---

## Implementation Checklist

- [ ] Add database tables (Investments, InvestmentPriceHistories)
- [ ] Create database migration
- [ ] Implement database queries
- [ ] Create InvestmentsListPage
- [ ] Create InvestmentPage (detail view)
- [ ] Create AddInvestmentPage (form)
- [ ] Create InvestmentEntry widget
- [ ] Create PortfolioSummaryCard widget
- [ ] Create PriceHistoryEntry widget
- [ ] Create UpdateInvestmentPriceSheet widget
- [ ] Add localization strings
- [ ] Integrate with navigation
- [ ] Add home page widget (optional)
- [ ] Test with multiple currencies
- [ ] Test dark/light themes
- [ ] Add export/import support
- [ ] Performance testing with large datasets

---

## Future Enhancements

- Automatic price fetching from APIs (Yahoo Finance, CoinGecko, etc.)
- Dividend tracking
- Transaction history (buy/sell events)
- Portfolio rebalancing suggestions
- Asset allocation pie chart
- Benchmark comparison (S&P 500, etc.)
- Tax reports (capital gains)
- Multiple portfolios
- Stock splits handling
- Currency conversion for international investments
- Notifications for price targets
- Investment goals linked to objectives

---

## References

**Similar Features:**
- `/home/user/ContaCashew/budget/lib/pages/objectivePage.dart`
- `/home/user/ContaCashew/budget/lib/pages/objectivesListPage.dart`
- `/home/user/ContaCashew/budget/lib/pages/addObjectivePage.dart`
- `/home/user/ContaCashew/budget/lib/widgets/objectiveContainer.dart`

**Components to Reuse:**
- PageFramework
- PopupFramework
- TransactionsAmountBox
- LineGraph (for price charts)
- CountNumber
- OpenContainerNavigation
- All input widgets (TextInput, SelectAmount, etc.)

**Utility Functions:**
- `convertToMoney()` - Money formatting
- `getWordedDate()` - Date formatting
- `dynamicPastel()` - Color generation
- `getIconFromName()` - Icon mapping
