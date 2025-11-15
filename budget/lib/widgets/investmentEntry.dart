import 'package:budget/colors.dart';
import 'package:budget/database/tables.dart';
import 'package:budget/functions.dart';
import 'package:budget/pages/investmentPage.dart';
import 'package:budget/widgets/openContainerNavigation.dart';
import 'package:budget/widgets/tappable.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class InvestmentEntry extends StatelessWidget {
  const InvestmentEntry({
    Key? key,
    required this.investment,
    this.listID,
    this.selected = false,
    this.onSelected,
  }) : super(key: key);

  final Investment investment;
  final String? listID;
  final bool selected;
  final Function(Investment, bool)? onSelected;

  @override
  Widget build(BuildContext context) {
    final currentValue = investment.shares * investment.currentPrice;
    final initialValue = investment.shares * investment.purchasePrice;
    final gainLoss = currentValue - initialValue;
    final gainLossPercentage =
        initialValue > 0 ? (gainLoss / initialValue) * 100 : 0;

    return OpenContainerNavigation(
      borderRadius: 15,
      closedColor: Colors.transparent,
      openPage: InvestmentPage(investmentPk: investment.investmentPk),
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
              vertical: 4,
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
                    color: HexColor(investment.colour ?? "#4CAF50"),
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
                        color:
                            gainLoss >= 0 ? Colors.green : Colors.red,
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
