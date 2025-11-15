import 'package:budget/colors.dart';
import 'package:budget/database/tables.dart';
import 'package:budget/functions.dart';
import 'package:budget/pages/addInvestmentPage.dart';
import 'package:budget/struct/databaseGlobal.dart';
import 'package:budget/widgets/framework/pageFramework.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class InvestmentPage extends StatelessWidget {
  const InvestmentPage({
    Key? key,
    required this.investmentPk,
  }) : super(key: key);

  final String investmentPk;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Investment>(
      stream: database.getInvestment(investmentPk),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return SizedBox.shrink();
        }

        final investment = snapshot.data!;
        final currentValue = investment.shares * investment.currentPrice;
        final initialValue = investment.shares * investment.purchasePrice;
        final gainLoss = currentValue - initialValue;
        final gainLossPercentage =
            initialValue > 0 ? (gainLoss / initialValue) * 100 : 0;

        return PageFramework(
          title: investment.name,
          dragDownToDismiss: true,
          actions: [
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () {
                pushRoute(
                  context,
                  AddInvestmentPage(
                    investment: investment,
                  ),
                );
              },
            ),
          ],
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: HexColor(investment.colour ?? "#4CAF50"),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        getIconFromName(investment.iconName),
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
                            investment.name,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (investment.symbol != null)
                            Text(
                              investment.symbol!,
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
              ),
            ),

            // Current Value
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      "current-value".tr(),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      convertToMoney(
                        Provider.of<AllWallets>(context),
                        currentValue,
                      ),
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
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
              ),
            ),

            // Holdings Details
            SliverToBoxAdapter(
              child: Padding(
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
                        context,
                        "shares".tr(),
                        investment.shares.toString(),
                      ),
                      _buildDetailRow(
                        context,
                        "purchase-price".tr(),
                        convertToMoney(
                          Provider.of<AllWallets>(context),
                          investment.purchasePrice,
                        ),
                      ),
                      _buildDetailRow(
                        context,
                        "current-price".tr(),
                        convertToMoney(
                          Provider.of<AllWallets>(context),
                          investment.currentPrice,
                        ),
                      ),
                      _buildDetailRow(
                        context,
                        "purchase-date".tr(),
                        getWordedDate(investment.purchaseDate),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
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
}
