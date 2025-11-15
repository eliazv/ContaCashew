import 'package:budget/colors.dart';
import 'package:budget/database/tables.dart';
import 'package:budget/functions.dart';
import 'package:budget/pages/addInvestmentPage.dart';
import 'package:budget/pages/transactionFilters.dart';
import 'package:budget/struct/databaseGlobal.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/widgets/fab.dart';
import 'package:budget/widgets/fadeIn.dart';
import 'package:budget/widgets/framework/pageFramework.dart';
import 'package:budget/widgets/framework/popupFramework.dart';
import 'package:budget/widgets/investmentEntry.dart';
import 'package:budget/widgets/openBottomSheet.dart';
import 'package:budget/widgets/openPopup.dart';
import 'package:budget/widgets/transactionsAmountBox.dart';
import 'package:budget/widgets/walletEntry.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:budget/widgets/util/keepAliveClientMixin.dart';
import 'package:provider/provider.dart';

class InvestmentsListPage extends StatefulWidget {
  const InvestmentsListPage({
    Key? key,
    this.backButton = true,
  }) : super(key: key);

  final bool backButton;

  @override
  InvestmentsListPageState createState() => InvestmentsListPageState();
}

class InvestmentsListPageState extends State<InvestmentsListPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  void scrollToTop() {}

  void refreshState() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return WillPopScope(
      onWillPop: () async {
        return true;
      },
      child: PageFramework(
        key: Key("investments-list-page"),
        title: "investments".tr(),
        backButton: widget.backButton,
        horizontalPaddingConstrained: true,
        listID: "investments",
        dragDownToDismiss: true,
        slivers: [
          // Portfolio Summary
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(
                left: getHorizontalPaddingConstrained(context),
                right: getHorizontalPaddingConstrained(context),
                top: 15,
                bottom: 5,
              ),
              child: StreamBuilder<Map<String, double>>(
                stream: database.watchPortfolioSummary(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return SizedBox.shrink();
                  }
                  final summary = snapshot.data!;
                  final totalValue = summary['totalValue'] ?? 0;
                  final gainLoss = summary['gainLoss'] ?? 0;
                  final gainLossPercentage =
                      summary['gainLossPercentage'] ?? 0;

                  return Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.7),
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
                        Text(
                          convertToMoney(
                            Provider.of<AllWallets>(context),
                            totalValue,
                          ),
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            Icon(
                              gainLoss >= 0
                                  ? Icons.trending_up
                                  : Icons.trending_down,
                              color: Colors.white,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              "${gainLoss >= 0 ? '+' : ''}${convertToMoney(Provider.of<AllWallets>(context), gainLoss)}",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              "(${gainLoss >= 0 ? '+' : ''}${gainLossPercentage.toStringAsFixed(2)}%)",
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
              ),
            ),
          ),

          // Wallets Section (as investments)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: getHorizontalPaddingConstrained(context),
                vertical: 10,
              ),
              child: Text(
                "accounts".tr(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          StreamBuilder<List<TransactionWallet>>(
            stream: database.watchAllWallets(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return SliverToBoxAdapter(child: SizedBox.shrink());
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final wallet = snapshot.data![index];
                    return StreamBuilder<TotalWithCount?>(
                      stream: database.watchTotalWithCountOfWallet(
                        allWallets: Provider.of<AllWallets>(context),
                        followCustomPeriodCycle: false,
                        cycleSettingsExtension: "_allSpending",
                        searchFilters: SearchFilters(
                          walletPks: [wallet.walletPk],
                        ),
                      ),
                      builder: (context, totalSnapshot) {
                        final total = totalSnapshot.data?.total ?? 0;
                        return Container(
                          margin: EdgeInsets.symmetric(
                            horizontal: getHorizontalPaddingConstrained(context),
                            vertical: 4,
                          ),
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: HexColor(
                                      wallet.colour ?? "#4CAF50"),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  getIconFromName(wallet.iconName),
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      wallet.name,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      wallet.currency ?? "",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                convertToMoney(
                                  Provider.of<AllWallets>(context),
                                  total,
                                  currencyKey: wallet.currency,
                                ),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  childCount: snapshot.data!.length,
                ),
              );
            },
          ),

          // Investments Section
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: getHorizontalPaddingConstrained(context),
                vertical: 10,
              ),
              child: Text(
                "investments".tr(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          StreamBuilder<List<Investment>>(
            stream: database.watchAllInvestments(
              hideArchived: true,
            ),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return SliverToBoxAdapter(
                  child: Container(
                    padding: EdgeInsets.all(20),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                );
              }

              if (snapshot.data!.isEmpty) {
                return SliverToBoxAdapter(
                  child: Container(
                    padding: EdgeInsets.all(40),
                    child: Center(
                      child: Text(
                        "no-investments".tr(),
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final investment = snapshot.data![index];
                    return InvestmentEntry(
                      investment: investment,
                      listID: "investments",
                    );
                  },
                  childCount: snapshot.data!.length,
                ),
              );
            },
          ),
        ],
        floatingActionButton: AnimateFABDelayed(
          fab: AddFAB(
            tooltip: "add-investment".tr(),
            openPage: AddInvestmentPage(),
          ),
        ),
      ),
    );
  }
}
