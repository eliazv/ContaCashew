# ContaCashew - Project Overview

## Project Description

ContaCashew is a comprehensive personal finance management application built with Flutter. It provides users with tools to track transactions, manage budgets, set financial goals, and monitor their net worth across multiple accounts and currencies.

**Current Version:** 5.4.3+416
**Framework:** Flutter (Dart)
**Min SDK:** >= 3.0.0
**Target Platforms:** iOS, Android, Web

## Core Features

### 1. **Transaction Management**
- Track income and expenses
- Categorize transactions with custom categories
- Support for notes, attachments, and titles
- Multi-currency support with automatic conversion
- Transaction types: regular, upcoming, subscription, credit/debt
- Shared transactions between wallets

### 2. **Wallet/Account Management**
- Multiple wallets with different currencies
- Custom wallet colors and icons
- Balance tracking and history
- Net worth calculation across all accounts
- Custom decimal precision per wallet
- Home page widget display customization

### 3. **Budget System**
- Time-based budgets (daily, weekly, monthly, yearly, custom)
- Category-based spending limits
- Budget income/expense tracking
- Recurring budget periods
- Visual progress indicators
- Budget wallets with addons/exclusions

### 4. **Goals & Loans (Objectives)**
- Savings goals with target amounts
- Loan tracking (money lent/borrowed)
- Progress visualization
- Transaction linking
- Pinnable to home page
- Archive functionality

### 5. **Data Visualization**
- Pie charts for category spending
- Line graphs for trends over time
- Bar graphs for budget comparisons
- Net worth tracking graphs
- Customizable time periods
- Interactive chart elements

### 6. **Advanced Features**
- Cloud sync via Firebase
- Multi-device support
- Data import/export (CSV, JSON)
- Material You theming
- Dark/light/OLED themes
- Extensive localization support
- Accessibility features
- Battery saver mode
- Custom animation speeds

## Technology Stack

### Core Framework
- **Flutter/Dart** - Cross-platform UI framework
- **provider** (^6.1.2) - State management

### Database & Persistence
- **drift** (^2.14.0) - SQL ORM (formerly Moor)
- **sqlite3_flutter_libs** (^0.5.0) - SQLite database
- **path_provider** (^2.1.3) - File system access

### UI Components
- **fl_chart** (^0.68.0) - Charts and graphs (Line, Pie, Bar)
- **animations** (^2.0.11) - Page transitions
- **simple_animations** (^5.0.2) - Widget animations
- **carousel_slider** (^5.1.1) - Carousel components
- **shimmer** (^3.0.0) - Loading skeleton screens

### Backend Services
- **firebase_core** (^3.2.0) - Firebase initialization
- **firebase_auth** (^5.1.2) - User authentication
- **cloud_firestore** (^5.1.0) - Cloud database

### Utilities
- **easy_localization** (^3.0.7) - Internationalization
- **share_plus** (^10.0.0) - Native sharing
- **url_launcher** (^6.2.6) - URL handling
- **device_info_plus** (^10.1.0) - Device information

## Project Structure

```
budget/
├── lib/
│   ├── main.dart                 # App entry point
│   ├── colors.dart              # Theme and color system
│   ├── functions.dart           # Global utility functions
│   ├── database/
│   │   ├── tables.dart          # Database schema (Drift)
│   │   ├── generatePreviewData.dart
│   │   └── initializeDefaultDatabase.dart
│   ├── pages/                   # 54+ screen components
│   │   ├── homePage/
│   │   ├── addBudgetPage.dart
│   │   ├── addObjectivePage.dart
│   │   ├── addTransactionPage.dart
│   │   ├── objectivePage.dart
│   │   ├── objectivesListPage.dart
│   │   └── ... (many more)
│   ├── widgets/                 # 115+ reusable components
│   │   ├── framework/           # Base page/popup frameworks
│   │   ├── transactionEntry/    # Transaction list items
│   │   ├── pieChart.dart
│   │   ├── lineGraph.dart
│   │   ├── barGraph.dart
│   │   └── ... (many more)
│   ├── struct/                  # Data structures & utilities
│   │   ├── settings.dart        # Global app state
│   │   ├── databaseGlobal.dart  # Database instance
│   │   └── ... (helpers)
│   ├── modified/                # Modified third-party packages
│   └── packages/                # Custom package modifications
├── assets/
│   ├── categories/              # Category icons (PNG)
│   ├── fonts/                   # Custom fonts (Avenir, Inter, DMSans)
│   └── translations/            # i18n JSON files
└── packages/
    ├── sliding_sheet/           # Modified sliding sheet package
    └── reorderable_list/        # Modified reorderable list
```

## Key Design Principles

### 1. **Reactive Data Flow**
- StreamBuilder-based UI updates
- Database queries return reactive streams
- Provider for global state management
- Automatic UI refresh on data changes

### 2. **Modular Architecture**
- Reusable widget components
- Separation of concerns (data/UI/logic)
- Page framework standardization
- Component composition over inheritance

### 3. **Performance Optimization**
- Lazy loading with indexed stacks
- KeepAlive for expensive widgets
- Visibility-based content loading
- Shimmer loading states
- Battery saver mode
- Animation speed controls

### 4. **Customization First**
- User-definable colors and icons
- Flexible theming system
- Customizable home page widgets
- Extensive settings options
- Multi-currency support

### 5. **Data Integrity**
- UUID primary keys
- Foreign key constraints
- Transaction history preservation
- Soft deletes (archive)
- Cloud backup support

## Navigation Structure

```
HomePage (bottom tabs)
├── Transactions
│   ├── Add Transaction
│   ├── Transaction Details
│   └── Edit Transaction
├── Budgets
│   ├── Add Budget
│   ├── Budget Details
│   └── Edit Budget
├── Subscriptions
│   ├── Add Subscription
│   └── Subscription Details
└── More
    ├── All Spending
    ├── Wallets
    ├── Categories
    ├── Objectives
    ├── Settings
    └── About
```

## State Management Strategy

### Global State (appStateSettings)
- Map-based configuration storage
- Persistent via shared preferences
- Accessed globally throughout app
- Examples: theme, language, selected wallet

### Provider State
- Reactive data for cross-widget communication
- Examples: AllWallets, SelectedWalletPk
- Minimal usage, preference for streams

### Stream-based State
- Primary pattern for database-driven UI
- Automatic rebuild on data changes
- Efficient query optimization via Drift

### Local State (StatefulWidget)
- Form inputs and temporary UI state
- Page-specific interactions
- Controlled via setState()

## Code Style Conventions

### Naming
- **Pages:** `CamelCasePage` (e.g., AddBudgetPage)
- **Widgets:** `CamelCaseWidget` (e.g., TransactionEntry)
- **Private classes:** `_CamelCase` (prefixed with underscore)
- **Database classes:** PascalCase with @DataClassName
- **Variables:** camelCase
- **Constants:** UPPER_SNAKE_CASE

### File Organization
- One main class per file
- Related private classes in same file
- Group related widgets in subdirectories
- Clear separation of pages vs widgets

### Documentation
- Inline comments for complex logic
- Function/class documentation where needed
- Clear variable naming as self-documentation

## Development Guidelines

1. **Always use PageFramework** for new pages
2. **Use StreamBuilder** for database-driven UI
3. **Follow existing widget patterns** (TransactionEntry, etc.)
4. **Maintain consistent theming** via CustomColorTheme
5. **Use existing utility functions** (convertToMoney, etc.)
6. **Test with multiple currencies** and edge cases
7. **Support dark/light themes** in all new UI
8. **Use proper localization** for all user-facing strings
9. **Optimize for performance** (lazy loading, visibility detection)
10. **Follow database migration patterns** when adding tables

## Future Expansion Areas

- Investment tracking (planned)
- Advanced reporting and analytics
- Bill reminders
- Receipt scanning
- Multi-user/family accounts
- Advanced budgeting rules
- Cashflow forecasting
- Tax categorization

## Related Documentation

- `architecture-patterns.md` - Detailed architecture patterns
- `database-schema.md` - Complete database schema
- `ui-components.md` - UI component library guide
- `state-management.md` - State management patterns
- `investments-feature.md` - Investments tracking feature design
