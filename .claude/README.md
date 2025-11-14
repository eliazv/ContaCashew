# ContaCashew - Claude Project Memory

Questa directory contiene la documentazione di memoria del progetto ContaCashew per Claude Code. I documenti forniscono una comprensione completa dell'architettura, dei pattern e delle convenzioni utilizzate nell'applicazione.

## Struttura della Documentazione

### 📋 [project-overview.md](memory/project-overview.md)
**Inizia da qui!** Una panoramica completa del progetto:
- Descrizione del progetto e funzionalità principali
- Stack tecnologico (Flutter, Drift, Firebase, ecc.)
- Struttura del progetto e organizzazione delle directory
- Principi di design e filosofia dell'app
- Linee guida per lo sviluppo

### 🏗️ [architecture-patterns.md](memory/architecture-patterns.md)
Pattern architetturali e best practices:
- Architettura reattiva basata su Stream
- Pattern PageFramework per le pagine
- Composizione dei widget
- Gestione dello stato (Provider, Stream, GlobalKey)
- Pattern di navigazione
- Gestione dei form
- Ottimizzazioni delle performance
- Anti-pattern da evitare

### 🗄️ [database-schema.md](memory/database-schema.md)
Schema completo del database e query pattern:
- Tabelle principali (Transactions, Categories, Wallets, Budgets, Objectives)
- Struttura delle colonne e relazioni
- Query pattern con Drift ORM
- Calcoli e aggregazioni
- Gestione delle migrazioni
- Ottimizzazione delle query
- Integrità dei dati

### 🎨 [ui-components.md](memory/ui-components.md)
Libreria completa dei componenti UI:
- Framework components (PageFramework, PopupFramework)
- List components (TransactionEntry, ObjectiveContainer)
- Chart components (PieChart, LineGraph, BarGraph)
- Input components (TextInput, SelectAmount, SelectCategory)
- Progress components
- Navigation components
- Utility components
- Loading states e animazioni

### 💰 [investments-feature.md](memory/investments-feature.md)
**Design completo della funzionalità investimenti:**
- Schema database (Investments, InvestmentPriceHistory)
- Calcoli per valori, guadagni/perdite, performance
- Struttura delle pagine (List, Detail, Add/Edit)
- Widget personalizzati (InvestmentEntry, PortfolioSummaryCard)
- Query e stream per dati reattivi
- Integrazione con navigazione e home page
- Localizzazione
- Checklist implementazione
- Miglioramenti futuri

## Come Usare Questa Documentazione

### Per Nuove Funzionalità
1. Leggi `project-overview.md` per comprendere il contesto generale
2. Studia `architecture-patterns.md` per i pattern da seguire
3. Consulta `database-schema.md` se serve modificare il database
4. Usa `ui-components.md` per scegliere i componenti giusti
5. Segui `investments-feature.md` come esempio di design completo

### Per Bug Fix o Modifiche
1. Identifica l'area interessata (database, UI, business logic)
2. Consulta la documentazione corrispondente
3. Segui i pattern esistenti
4. Mantieni la coerenza con il codice esistente

### Per Comprendere il Codice
1. Inizia da `project-overview.md` per il quadro generale
2. Usa i riferimenti ai file per navigare nel codice
3. Consulta i pattern in `architecture-patterns.md` per capire le scelte architetturali
4. Usa `database-schema.md` per comprendere le relazioni tra i dati

## Principi Chiave

### 🎯 Reattività
- Usa **StreamBuilder** per UI guidata dai dati
- Database queries ritornano **Stream** per aggiornamenti automatici
- Evita setState eccessivo, preferisci approccio reattivo

### 🧩 Modularità
- **PageFramework** per tutte le pagine
- Widget riutilizzabili e componibili
- Separazione chiara tra dati, logica e UI

### 🎨 Consistenza
- Segui i pattern esistenti
- Usa il sistema di colori del tema
- Localizzazione per tutti i testi
- Supporta dark/light theme

### ⚡ Performance
- KeepAlive per widget costosi
- Lazy loading con visibility detection
- Animazioni controllabili (battery saver)
- Query ottimizzate con limit/offset

## Tech Stack Rapido

```yaml
Framework: Flutter 3.0+
Database: Drift (SQLite)
State: Provider + Streams
Charts: fl_chart
Navigation: Material + Custom
Backend: Firebase (auth, firestore)
i18n: easy_localization
```

## Pattern Comuni

### Nuova Pagina
```dart
PageFramework(
  title: "page-title",
  dragDownToDismiss: true,
  slivers: [
    SliverToBoxAdapter(child: Header()),
    SliverList(...),
  ],
  floatingActionButton: FAB(...),
)
```

### Query Database
```dart
StreamBuilder<List<T>>(
  stream: database.watchData(),
  builder: (context, snapshot) {
    if (!snapshot.hasData) return LoadingShimmer();
    return DataWidget(snapshot.data!);
  }
)
```

### Navigazione
```dart
pushRoute(context, DetailPage());
OpenContainerNavigation(
  openPage: DetailPage(),
  button: (open) => Button(onTap: open),
)
```

## File Chiave

### Core
- `/budget/lib/main.dart` - Entry point
- `/budget/lib/database/tables.dart` - Schema DB
- `/budget/lib/struct/settings.dart` - Stato globale
- `/budget/lib/functions.dart` - Utility

### Framework
- `/budget/lib/widgets/framework/pageFramework.dart`
- `/budget/lib/widgets/framework/popupFramework.dart`
- `/budget/lib/colors.dart`

### Esempi
- `/budget/lib/pages/objectivePage.dart` - Pagina dettaglio
- `/budget/lib/pages/objectivesListPage.dart` - Pagina lista
- `/budget/lib/pages/addObjectivePage.dart` - Pagina form

## Prossimi Passi

### Implementare Feature Investimenti
Segui la guida completa in `investments-feature.md`:

1. ✅ Documentazione completata
2. ⏭️ Aggiungere tabelle al database
3. ⏭️ Creare le pagine (List, Detail, Add)
4. ⏭️ Implementare i widget personalizzati
5. ⏭️ Aggiungere localizzazione
6. ⏭️ Integrare con navigazione
7. ⏭️ Testing multi-valuta e temi

## Convenzioni Codice

### Naming
- Pages: `CamelCasePage`
- Widgets: `CamelCaseWidget`
- Private: `_CamelCase`
- Variables: `camelCase`
- Constants: `UPPER_SNAKE_CASE`

### Organizzazione
- Un widget principale per file
- Helper privati nello stesso file
- Widget correlati in subdirectory
- Chiara separazione pages/widgets

### Best Practices
- Sempre localizzazione per stringhe
- Colori dal tema, mai hardcoded
- Dispose dei controller
- Null safety
- Error handling in StreamBuilder
- Performance optimization dove serve

## Risorse Aggiuntive

### Flutter/Dart
- [Flutter Documentation](https://flutter.dev/docs)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)

### Drift (Database)
- [Drift Documentation](https://drift.simonbinder.eu/)
- [Drift Examples](https://drift.simonbinder.eu/docs/examples/)

### FL Chart
- [FL Chart Documentation](https://github.com/imaNNeo/fl_chart)

## Contribuire

Quando aggiungi nuove funzionalità:
1. Segui i pattern esistenti
2. Documenta le modifiche al database
3. Aggiungi localizzazione
4. Testa su dark/light theme
5. Considera multi-valuta
6. Ottimizza per performance
7. Aggiorna questa documentazione se necessario

## Supporto

Per domande o chiarimenti:
1. Consulta questa documentazione
2. Esamina file di esempio simili
3. Verifica pattern in `architecture-patterns.md`
4. Cerca nel codice esistente per pattern simili

---

**Ultima modifica:** 2025-11-14
**Versione app:** 5.4.3+416
**Flutter SDK:** >= 3.0.0
