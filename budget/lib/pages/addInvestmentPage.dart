import 'package:budget/colors.dart';
import 'package:budget/database/tables.dart';
import 'package:budget/functions.dart';
import 'package:budget/struct/databaseGlobal.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/widgets/button.dart';
import 'package:budget/widgets/framework/pageFramework.dart';
import 'package:budget/widgets/selectCategory.dart';
import 'package:budget/widgets/selectColor.dart';
import 'package:budget/widgets/selectIcon.dart';
import 'package:budget/widgets/textInput.dart';
import 'package:budget/widgets/tappable.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart' hide SliverToBoxAdapter;
import 'package:budget/modified/sliver_to_box_adapter.dart';
import 'package:provider/provider.dart';

class AddInvestmentPage extends StatefulWidget {
  const AddInvestmentPage({
    Key? key,
    this.investment,
  }) : super(key: key);

  final Investment? investment;

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
    } else {
      _selectedWalletPk = "0";
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
      title: _isEditing ? "edit-investment".tr() : "add-investment".tr(),
      dragDownToDismiss: true,
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                TextInput(
                  labelText: "name".tr(),
                  icon: Icons.label,
                  controller: _nameController,
                  autoFocus: !_isEditing,
                  bubbly: false,
                ),
                SizedBox(height: 16),
                TextInput(
                  labelText: "symbol".tr(),
                  icon: Icons.tag,
                  controller: _symbolController,
                  placeholder: "AAPL, BTC, etc.",
                  bubbly: false,
                ),
                SizedBox(height: 16),
                TextInput(
                  labelText: "shares".tr(),
                  icon: Icons.pie_chart,
                  controller: _sharesController,
                  keyboardType: TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  bubbly: false,
                ),
                SizedBox(height: 16),
                TextInput(
                  labelText: "purchase-price".tr(),
                  icon: Icons.attach_money,
                  controller: _purchasePriceController,
                  keyboardType: TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  bubbly: false,
                ),
                SizedBox(height: 16),
                TextInput(
                  labelText: "current-price".tr(),
                  icon: Icons.trending_up,
                  controller: _currentPriceController,
                  keyboardType: TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  bubbly: false,
                ),
                SizedBox(height: 16),
                Tappable(
                  onTap: () => _selectPurchaseDate(),
                  borderRadius: 15,
                  color: getColor(context, "lightDarkAccentHeavyLight"),
                  child: Container(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.calendar_today),
                            SizedBox(width: 12),
                            Text(getWordedDate(context, _purchaseDate)),
                          ],
                        ),
                        Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),
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
                      child: SelectIconButton(
                        selectedIconName: _selectedIcon,
                        setSelectedIconName: (icon) {
                          setState(() => _selectedIcon = icon);
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 32),
                Button(
                  label: _isEditing ? "save".tr() : "create".tr(),
                  onTap: _saveInvestment,
                  expandedLayout: true,
                ),
                if (_isEditing) ...[
                  SizedBox(height: 16),
                  Button(
                    label: "delete".tr(),
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

  Future<void> _saveInvestment() async {
    if (_nameController.text.isEmpty) {
      openSnackbar(
        SnackbarMessage(
          title: "name-required".tr(),
          icon: Icons.warning,
        ),
      );
      return;
    }

    final shares = double.tryParse(_sharesController.text);
    if (shares == null || shares <= 0) {
      openSnackbar(
        SnackbarMessage(
          title: "invalid-shares".tr(),
          icon: Icons.warning,
        ),
      );
      return;
    }

    final purchasePrice = double.tryParse(_purchasePriceController.text);
    if (purchasePrice == null || purchasePrice < 0) {
      openSnackbar(
        SnackbarMessage(
          title: "invalid-purchase-price".tr(),
          icon: Icons.warning,
        ),
      );
      return;
    }

    final currentPrice = double.tryParse(_currentPriceController.text);
    if (currentPrice == null || currentPrice < 0) {
      openSnackbar(
        SnackbarMessage(
          title: "invalid-current-price".tr(),
          icon: Icons.warning,
        ),
      );
      return;
    }

    final companion = InvestmentsCompanion(
      investmentPk: Value(
        _isEditing ? widget.investment!.investmentPk : uuid.v4()
      ),
      name: Value(_nameController.text),
      symbol: Value(_symbolController.text.isNotEmpty
        ? _symbolController.text
        : null),
      shares: Value(shares),
      purchasePrice: Value(purchasePrice),
      currentPrice: Value(currentPrice),
      purchaseDate: Value(_purchaseDate),
      walletFk: Value(_selectedWalletPk ?? "0"),
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

    await database.createOrUpdateInvestment(
      companion,
      insert: !_isEditing,
    );

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

    openSnackbar(
      SnackbarMessage(
        title: _isEditing ? "investment-updated".tr() : "investment-created".tr(),
        icon: Icons.check,
      ),
    );

    Navigator.pop(context);
  }

  Future<void> _deleteInvestment() async {
    final confirm = await openPopup(
      context,
      title: "delete-investment".tr(),
      description: "delete-investment-confirmation".tr(),
      icon: Icons.warning,
      onSubmit: () async {
        Navigator.pop(context, true);
      },
      onSubmitLabel: "delete".tr(),
      onCancelLabel: "cancel".tr(),
      onCancel: () {
        Navigator.pop(context, false);
      },
    );

    if (confirm == true) {
      await database.deleteInvestment(widget.investment!.investmentPk);
      openSnackbar(
        SnackbarMessage(
          title: "investment-deleted".tr(),
          icon: Icons.check,
        ),
      );
      Navigator.pop(context);
    }
  }
}
