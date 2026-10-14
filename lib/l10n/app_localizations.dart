import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ka.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of L
/// returned by `L.of(context)`.
///
/// Applications need to include `L.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: L.localizationsDelegates,
///   supportedLocales: L.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the L.supportedLocales
/// property.
abstract class L {
  L(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static L of(BuildContext context) {
    return Localizations.of<L>(context, L)!;
  }

  static const LocalizationsDelegate<L> delegate = _LDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ka'),
    Locale('ru'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Komero'**
  String get appTitle;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get thisWeek;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get thisMonth;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get noResults;

  /// No description provided for @permissionDenied.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission for this'**
  String get permissionDenied;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Run your store from your pocket'**
  String get welcomeTitle;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Orders, stock and products — wherever you are'**
  String get welcomeSubtitle;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to your store'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage orders, stock and products on the go'**
  String get loginSubtitle;

  /// No description provided for @storeDomain.
  ///
  /// In en, this message translates to:
  /// **'Store address'**
  String get storeDomain;

  /// No description provided for @storeDomainHint.
  ///
  /// In en, this message translates to:
  /// **'mystore.ge'**
  String get storeDomainHint;

  /// No description provided for @storeDomainHelp.
  ///
  /// In en, this message translates to:
  /// **'The domain your store runs on. It tells Komero which store to open.'**
  String get storeDomainHelp;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @rememberMe.
  ///
  /// In en, this message translates to:
  /// **'Remember me'**
  String get rememberMe;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @resetLinkSent.
  ///
  /// In en, this message translates to:
  /// **'Check your email for a reset link'**
  String get resetLinkSent;

  /// No description provided for @enterStoreDomain.
  ///
  /// In en, this message translates to:
  /// **'Enter your store address'**
  String get enterStoreDomain;

  /// No description provided for @enterEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get enterEmail;

  /// No description provided for @enterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get enterPassword;

  /// No description provided for @invalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Wrong email or password'**
  String get invalidCredentials;

  /// No description provided for @storeNotFound.
  ///
  /// In en, this message translates to:
  /// **'No store found at that address'**
  String get storeNotFound;

  /// No description provided for @notAMember.
  ///
  /// In en, this message translates to:
  /// **'This account cannot manage that store'**
  String get notAMember;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navOrders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get navOrders;

  /// No description provided for @navInventory.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get navInventory;

  /// No description provided for @navProducts.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get navProducts;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @liveNow.
  ///
  /// In en, this message translates to:
  /// **'Live now'**
  String get liveNow;

  /// No description provided for @visitorsNow.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No visitors right now} =1{1 visitor right now} other{{count} visitors right now}}'**
  String visitorsNow(int count);

  /// No description provided for @revenue.
  ///
  /// In en, this message translates to:
  /// **'Revenue'**
  String get revenue;

  /// No description provided for @orders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get orders;

  /// No description provided for @customers.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get customers;

  /// No description provided for @products.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get products;

  /// No description provided for @conversionRate.
  ///
  /// In en, this message translates to:
  /// **'Conversion rate'**
  String get conversionRate;

  /// No description provided for @averageOrderValue.
  ///
  /// In en, this message translates to:
  /// **'Average order value'**
  String get averageOrderValue;

  /// No description provided for @sessions.
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get sessions;

  /// No description provided for @salesOverTime.
  ///
  /// In en, this message translates to:
  /// **'Sales over time'**
  String get salesOverTime;

  /// No description provided for @topProducts.
  ///
  /// In en, this message translates to:
  /// **'Top products'**
  String get topProducts;

  /// No description provided for @unitsSold.
  ///
  /// In en, this message translates to:
  /// **'{count} sold'**
  String unitsSold(int count);

  /// No description provided for @channels.
  ///
  /// In en, this message translates to:
  /// **'Channels'**
  String get channels;

  /// No description provided for @funnel.
  ///
  /// In en, this message translates to:
  /// **'Shopping funnel'**
  String get funnel;

  /// No description provided for @funnelViewed.
  ///
  /// In en, this message translates to:
  /// **'Viewed a product'**
  String get funnelViewed;

  /// No description provided for @funnelCart.
  ///
  /// In en, this message translates to:
  /// **'Added to cart'**
  String get funnelCart;

  /// No description provided for @funnelCheckout.
  ///
  /// In en, this message translates to:
  /// **'Started checkout'**
  String get funnelCheckout;

  /// No description provided for @funnelPurchased.
  ///
  /// In en, this message translates to:
  /// **'Purchased'**
  String get funnelPurchased;

  /// No description provided for @vsLastMonth.
  ///
  /// In en, this message translates to:
  /// **'vs last month'**
  String get vsLastMonth;

  /// No description provided for @ordersToFulfil.
  ///
  /// In en, this message translates to:
  /// **'Orders to fulfil'**
  String get ordersToFulfil;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get viewAll;

  /// No description provided for @needsAttention.
  ///
  /// In en, this message translates to:
  /// **'Needs attention'**
  String get needsAttention;

  /// No description provided for @lowStockCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 product low on stock} other{{count} products low on stock}}'**
  String lowStockCount(int count);

  /// No description provided for @outOfStockCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 product out of stock} other{{count} products out of stock}}'**
  String outOfStockCount(int count);

  /// No description provided for @orderNumber.
  ///
  /// In en, this message translates to:
  /// **'Order #{number}'**
  String orderNumber(String number);

  /// No description provided for @itemCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item} other{{count} items}}'**
  String itemCount(int count);

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statusPending;

  /// No description provided for @statusPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get statusPaid;

  /// No description provided for @statusProcessing.
  ///
  /// In en, this message translates to:
  /// **'Processing'**
  String get statusProcessing;

  /// No description provided for @statusShipped.
  ///
  /// In en, this message translates to:
  /// **'Shipped'**
  String get statusShipped;

  /// No description provided for @statusDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get statusDelivered;

  /// No description provided for @statusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// No description provided for @statusRefunded.
  ///
  /// In en, this message translates to:
  /// **'Refunded'**
  String get statusRefunded;

  /// No description provided for @channelWebShop.
  ///
  /// In en, this message translates to:
  /// **'Online store'**
  String get channelWebShop;

  /// No description provided for @channelB2B.
  ///
  /// In en, this message translates to:
  /// **'B2B'**
  String get channelB2B;

  /// No description provided for @channelPos.
  ///
  /// In en, this message translates to:
  /// **'Point of sale'**
  String get channelPos;

  /// No description provided for @orderDetails.
  ///
  /// In en, this message translates to:
  /// **'Order details'**
  String get orderDetails;

  /// No description provided for @items.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get items;

  /// No description provided for @customer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get customer;

  /// No description provided for @shippingAddress.
  ///
  /// In en, this message translates to:
  /// **'Shipping address'**
  String get shippingAddress;

  /// No description provided for @payment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get payment;

  /// No description provided for @paymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment method'**
  String get paymentMethod;

  /// No description provided for @paymentStatus.
  ///
  /// In en, this message translates to:
  /// **'Payment status'**
  String get paymentStatus;

  /// No description provided for @subtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get subtotal;

  /// No description provided for @tax.
  ///
  /// In en, this message translates to:
  /// **'Tax'**
  String get tax;

  /// No description provided for @shipping.
  ///
  /// In en, this message translates to:
  /// **'Shipping'**
  String get shipping;

  /// No description provided for @discount.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get discount;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @markAsFulfilled.
  ///
  /// In en, this message translates to:
  /// **'Mark as fulfilled'**
  String get markAsFulfilled;

  /// No description provided for @fulfillOrder.
  ///
  /// In en, this message translates to:
  /// **'Fulfil order'**
  String get fulfillOrder;

  /// No description provided for @trackingNumber.
  ///
  /// In en, this message translates to:
  /// **'Tracking number'**
  String get trackingNumber;

  /// No description provided for @trackingNumberHint.
  ///
  /// In en, this message translates to:
  /// **'Carrier tracking code'**
  String get trackingNumberHint;

  /// No description provided for @estimatedDelivery.
  ///
  /// In en, this message translates to:
  /// **'Estimated delivery'**
  String get estimatedDelivery;

  /// No description provided for @updateStatus.
  ///
  /// In en, this message translates to:
  /// **'Update status'**
  String get updateStatus;

  /// No description provided for @statusUpdated.
  ///
  /// In en, this message translates to:
  /// **'Order updated'**
  String get statusUpdated;

  /// No description provided for @addNote.
  ///
  /// In en, this message translates to:
  /// **'Note for the customer'**
  String get addNote;

  /// No description provided for @cancelOrder.
  ///
  /// In en, this message translates to:
  /// **'Cancel order'**
  String get cancelOrder;

  /// No description provided for @cancelReason.
  ///
  /// In en, this message translates to:
  /// **'Reason for cancelling'**
  String get cancelReason;

  /// No description provided for @orderCancelled.
  ///
  /// In en, this message translates to:
  /// **'Order cancelled'**
  String get orderCancelled;

  /// No description provided for @callCustomer.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get callCustomer;

  /// No description provided for @emailCustomer.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailCustomer;

  /// No description provided for @posOrderReadOnly.
  ///
  /// In en, this message translates to:
  /// **'Till sales change only through a return at the till'**
  String get posOrderReadOnly;

  /// No description provided for @markRefunded.
  ///
  /// In en, this message translates to:
  /// **'Mark as refunded'**
  String get markRefunded;

  /// No description provided for @refundWarning.
  ///
  /// In en, this message translates to:
  /// **'This records the refund in Komero. Move the money in your payment provider separately.'**
  String get refundWarning;

  /// No description provided for @guestOrder.
  ///
  /// In en, this message translates to:
  /// **'Guest order'**
  String get guestOrder;

  /// No description provided for @inventory.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get inventory;

  /// No description provided for @scanBarcode.
  ///
  /// In en, this message translates to:
  /// **'Scan barcode'**
  String get scanBarcode;

  /// No description provided for @scanToFind.
  ///
  /// In en, this message translates to:
  /// **'Scan a barcode to find a product'**
  String get scanToFind;

  /// No description provided for @scanning.
  ///
  /// In en, this message translates to:
  /// **'Scanning…'**
  String get scanning;

  /// No description provided for @cameraPermissionNeeded.
  ///
  /// In en, this message translates to:
  /// **'Camera access is needed to scan barcodes'**
  String get cameraPermissionNeeded;

  /// No description provided for @productNotFound.
  ///
  /// In en, this message translates to:
  /// **'No product matches that code'**
  String get productNotFound;

  /// No description provided for @matchedBySku.
  ///
  /// In en, this message translates to:
  /// **'Matched by SKU'**
  String get matchedBySku;

  /// No description provided for @onHand.
  ///
  /// In en, this message translates to:
  /// **'On hand'**
  String get onHand;

  /// No description provided for @reserved.
  ///
  /// In en, this message translates to:
  /// **'Reserved'**
  String get reserved;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// No description provided for @lowStock.
  ///
  /// In en, this message translates to:
  /// **'Low stock'**
  String get lowStock;

  /// No description provided for @outOfStock.
  ///
  /// In en, this message translates to:
  /// **'Out of stock'**
  String get outOfStock;

  /// No description provided for @inStock.
  ///
  /// In en, this message translates to:
  /// **'In stock'**
  String get inStock;

  /// No description provided for @allStock.
  ///
  /// In en, this message translates to:
  /// **'All stock'**
  String get allStock;

  /// No description provided for @adjustStock.
  ///
  /// In en, this message translates to:
  /// **'Adjust stock'**
  String get adjustStock;

  /// No description provided for @receiveStock.
  ///
  /// In en, this message translates to:
  /// **'Receive stock'**
  String get receiveStock;

  /// No description provided for @countStock.
  ///
  /// In en, this message translates to:
  /// **'Count stock'**
  String get countStock;

  /// No description provided for @newQuantity.
  ///
  /// In en, this message translates to:
  /// **'New quantity'**
  String get newQuantity;

  /// No description provided for @addQuantity.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addQuantity;

  /// No description provided for @removeQuantity.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeQuantity;

  /// No description provided for @setQuantity.
  ///
  /// In en, this message translates to:
  /// **'Set to'**
  String get setQuantity;

  /// No description provided for @adjustmentReason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get adjustmentReason;

  /// No description provided for @reasonRestocked.
  ///
  /// In en, this message translates to:
  /// **'Restocked'**
  String get reasonRestocked;

  /// No description provided for @reasonDamaged.
  ///
  /// In en, this message translates to:
  /// **'Damaged'**
  String get reasonDamaged;

  /// No description provided for @reasonReturned.
  ///
  /// In en, this message translates to:
  /// **'Returned'**
  String get reasonReturned;

  /// No description provided for @reasonTheft.
  ///
  /// In en, this message translates to:
  /// **'Theft or loss'**
  String get reasonTheft;

  /// No description provided for @reasonCorrection.
  ///
  /// In en, this message translates to:
  /// **'Count correction'**
  String get reasonCorrection;

  /// No description provided for @stockUpdated.
  ///
  /// In en, this message translates to:
  /// **'Stock updated'**
  String get stockUpdated;

  /// No description provided for @packQuantityNote.
  ///
  /// In en, this message translates to:
  /// **'One scan counts {count} units'**
  String packQuantityNote(int count);

  /// No description provided for @locations.
  ///
  /// In en, this message translates to:
  /// **'Locations'**
  String get locations;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @allLocations.
  ///
  /// In en, this message translates to:
  /// **'All locations'**
  String get allLocations;

  /// No description provided for @webSource.
  ///
  /// In en, this message translates to:
  /// **'Sells online'**
  String get webSource;

  /// No description provided for @transferStock.
  ///
  /// In en, this message translates to:
  /// **'Move stock'**
  String get transferStock;

  /// No description provided for @transferFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get transferFrom;

  /// No description provided for @transferTo.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get transferTo;

  /// No description provided for @transferNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get transferNote;

  /// No description provided for @transferQuantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get transferQuantity;

  /// No description provided for @transferCreated.
  ///
  /// In en, this message translates to:
  /// **'Stock moved'**
  String get transferCreated;

  /// No description provided for @sameLocationError.
  ///
  /// In en, this message translates to:
  /// **'Pick two different locations'**
  String get sameLocationError;

  /// No description provided for @productCatalog.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get productCatalog;

  /// No description provided for @addProduct.
  ///
  /// In en, this message translates to:
  /// **'Add product'**
  String get addProduct;

  /// No description provided for @editProduct.
  ///
  /// In en, this message translates to:
  /// **'Edit product'**
  String get editProduct;

  /// No description provided for @productName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get productName;

  /// No description provided for @sku.
  ///
  /// In en, this message translates to:
  /// **'SKU'**
  String get sku;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @salePrice.
  ///
  /// In en, this message translates to:
  /// **'Sale price'**
  String get salePrice;

  /// No description provided for @addPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get addPhoto;

  /// No description provided for @addValue.
  ///
  /// In en, this message translates to:
  /// **'Add {field}'**
  String addValue(String field);

  /// No description provided for @selectValue.
  ///
  /// In en, this message translates to:
  /// **'Select {field}'**
  String selectValue(String field);

  /// No description provided for @noneSelected.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get noneSelected;

  /// No description provided for @catalog.
  ///
  /// In en, this message translates to:
  /// **'Catalog'**
  String get catalog;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @brands.
  ///
  /// In en, this message translates to:
  /// **'Brands'**
  String get brands;

  /// No description provided for @productGroups.
  ///
  /// In en, this message translates to:
  /// **'Product groups'**
  String get productGroups;

  /// No description provided for @addNew.
  ///
  /// In en, this message translates to:
  /// **'Add new'**
  String get addNew;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @deleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get deleted;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @deleteItem.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}?'**
  String deleteItem(String name);

  /// No description provided for @deleteCatalogWarning.
  ///
  /// In en, this message translates to:
  /// **'Products using it keep their other details, but lose this one.'**
  String get deleteCatalogWarning;

  /// No description provided for @storeContent.
  ///
  /// In en, this message translates to:
  /// **'Store content'**
  String get storeContent;

  /// No description provided for @promotions.
  ///
  /// In en, this message translates to:
  /// **'Discounts'**
  String get promotions;

  /// No description provided for @newDiscount.
  ///
  /// In en, this message translates to:
  /// **'New discount'**
  String get newDiscount;

  /// No description provided for @percentOff.
  ///
  /// In en, this message translates to:
  /// **'% off'**
  String get percentOff;

  /// No description provided for @amountOff.
  ///
  /// In en, this message translates to:
  /// **'Amount off'**
  String get amountOff;

  /// No description provided for @couponCode.
  ///
  /// In en, this message translates to:
  /// **'Promo code'**
  String get couponCode;

  /// No description provided for @couponCodeHelp.
  ///
  /// In en, this message translates to:
  /// **'Leave empty to apply the discount automatically.'**
  String get couponCodeHelp;

  /// No description provided for @automaticDiscount.
  ///
  /// In en, this message translates to:
  /// **'Applies automatically'**
  String get automaticDiscount;

  /// No description provided for @couponCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No codes} =1{1 code} other{{count} codes}}'**
  String couponCount(int count);

  /// No description provided for @statusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get statusActive;

  /// No description provided for @statusPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get statusPaused;

  /// No description provided for @statusScheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get statusScheduled;

  /// No description provided for @statusDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get statusDraft;

  /// No description provided for @statusEnded.
  ///
  /// In en, this message translates to:
  /// **'Ended'**
  String get statusEnded;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @activate.
  ///
  /// In en, this message translates to:
  /// **'Activate'**
  String get activate;

  /// No description provided for @archive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get archive;

  /// No description provided for @blog.
  ///
  /// In en, this message translates to:
  /// **'Blog'**
  String get blog;

  /// No description provided for @postBody.
  ///
  /// In en, this message translates to:
  /// **'Post text'**
  String get postBody;

  /// No description provided for @published.
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get published;

  /// No description provided for @publish.
  ///
  /// In en, this message translates to:
  /// **'Publish'**
  String get publish;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @faqs.
  ///
  /// In en, this message translates to:
  /// **'FAQ'**
  String get faqs;

  /// No description provided for @question.
  ///
  /// In en, this message translates to:
  /// **'Question'**
  String get question;

  /// No description provided for @answer.
  ///
  /// In en, this message translates to:
  /// **'Answer'**
  String get answer;

  /// No description provided for @addVideo.
  ///
  /// In en, this message translates to:
  /// **'Add video'**
  String get addVideo;

  /// No description provided for @videoLink.
  ///
  /// In en, this message translates to:
  /// **'Video link'**
  String get videoLink;

  /// No description provided for @videoLinkHint.
  ///
  /// In en, this message translates to:
  /// **'YouTube link, or an embed link'**
  String get videoLinkHint;

  /// No description provided for @invalidVideoLink.
  ///
  /// In en, this message translates to:
  /// **'That does not look like a video link'**
  String get invalidVideoLink;

  /// No description provided for @moveUp.
  ///
  /// In en, this message translates to:
  /// **'Move up'**
  String get moveUp;

  /// No description provided for @moveDown.
  ///
  /// In en, this message translates to:
  /// **'Move down'**
  String get moveDown;

  /// No description provided for @formatBold.
  ///
  /// In en, this message translates to:
  /// **'Bold'**
  String get formatBold;

  /// No description provided for @formatItalic.
  ///
  /// In en, this message translates to:
  /// **'Italic'**
  String get formatItalic;

  /// No description provided for @formatBulletList.
  ///
  /// In en, this message translates to:
  /// **'Bulleted list'**
  String get formatBulletList;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @shortDescription.
  ///
  /// In en, this message translates to:
  /// **'Short description'**
  String get shortDescription;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @brand.
  ///
  /// In en, this message translates to:
  /// **'Brand'**
  String get brand;

  /// No description provided for @condition.
  ///
  /// In en, this message translates to:
  /// **'Condition'**
  String get condition;

  /// No description provided for @conditionNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get conditionNew;

  /// No description provided for @conditionUsed.
  ///
  /// In en, this message translates to:
  /// **'Used'**
  String get conditionUsed;

  /// No description provided for @conditionLikeNew.
  ///
  /// In en, this message translates to:
  /// **'Like new'**
  String get conditionLikeNew;

  /// No description provided for @photos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get photos;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get takePhoto;

  /// No description provided for @chooseFromLibrary.
  ///
  /// In en, this message translates to:
  /// **'Choose from library'**
  String get chooseFromLibrary;

  /// No description provided for @setAsCover.
  ///
  /// In en, this message translates to:
  /// **'Set as cover'**
  String get setAsCover;

  /// No description provided for @initialStock.
  ///
  /// In en, this message translates to:
  /// **'Starting stock'**
  String get initialStock;

  /// No description provided for @visibility.
  ///
  /// In en, this message translates to:
  /// **'Visibility'**
  String get visibility;

  /// No description provided for @publishedOnline.
  ///
  /// In en, this message translates to:
  /// **'Visible in the online store'**
  String get publishedOnline;

  /// No description provided for @markNewArrival.
  ///
  /// In en, this message translates to:
  /// **'Show as new arrival'**
  String get markNewArrival;

  /// No description provided for @markLiquidated.
  ///
  /// In en, this message translates to:
  /// **'Show as clearance'**
  String get markLiquidated;

  /// No description provided for @markComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Show as coming soon'**
  String get markComingSoon;

  /// No description provided for @productSaved.
  ///
  /// In en, this message translates to:
  /// **'Product saved'**
  String get productSaved;

  /// No description provided for @productCreated.
  ///
  /// In en, this message translates to:
  /// **'Product created'**
  String get productCreated;

  /// No description provided for @uploadingPhotos.
  ///
  /// In en, this message translates to:
  /// **'Uploading photos…'**
  String get uploadingPhotos;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get requiredField;

  /// No description provided for @invalidPrice.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid price'**
  String get invalidPrice;

  /// No description provided for @pickCategory.
  ///
  /// In en, this message translates to:
  /// **'Pick a category'**
  String get pickCategory;

  /// No description provided for @pickBrand.
  ///
  /// In en, this message translates to:
  /// **'Pick a brand'**
  String get pickBrand;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @notifyNewOrders.
  ///
  /// In en, this message translates to:
  /// **'New orders'**
  String get notifyNewOrders;

  /// No description provided for @notifyLowStock.
  ///
  /// In en, this message translates to:
  /// **'Low stock warnings'**
  String get notifyLowStock;

  /// No description provided for @pushUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Background push is not set up for this build. Alerts arrive while the app is open.'**
  String get pushUnavailable;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @store.
  ///
  /// In en, this message translates to:
  /// **'Store'**
  String get store;

  /// No description provided for @role.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get role;

  /// No description provided for @roleOwner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get roleOwner;

  /// No description provided for @roleMember.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get roleMember;

  /// No description provided for @signOutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Sign out of this store?'**
  String get signOutConfirm;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @filters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get clearAll;

  /// No description provided for @showResults.
  ///
  /// In en, this message translates to:
  /// **'Show results'**
  String get showResults;

  /// No description provided for @sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get sortBy;

  /// No description provided for @sortNameAsc.
  ///
  /// In en, this message translates to:
  /// **'Name A-Z'**
  String get sortNameAsc;

  /// No description provided for @sortPriceLow.
  ///
  /// In en, this message translates to:
  /// **'Price: low to high'**
  String get sortPriceLow;

  /// No description provided for @sortPriceHigh.
  ///
  /// In en, this message translates to:
  /// **'Price: high to low'**
  String get sortPriceHigh;

  /// No description provided for @sortNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest first'**
  String get sortNewest;

  /// No description provided for @allCategories.
  ///
  /// In en, this message translates to:
  /// **'All categories'**
  String get allCategories;

  /// No description provided for @allBrands.
  ///
  /// In en, this message translates to:
  /// **'All brands'**
  String get allBrands;

  /// No description provided for @stockStatus.
  ///
  /// In en, this message translates to:
  /// **'Availability'**
  String get stockStatus;

  /// No description provided for @promoFlags.
  ///
  /// In en, this message translates to:
  /// **'Labels'**
  String get promoFlags;

  /// No description provided for @onlyNewArrivals.
  ///
  /// In en, this message translates to:
  /// **'New arrivals'**
  String get onlyNewArrivals;

  /// No description provided for @onlyDiscounted.
  ///
  /// In en, this message translates to:
  /// **'On sale'**
  String get onlyDiscounted;

  /// No description provided for @onlyLiquidated.
  ///
  /// In en, this message translates to:
  /// **'Clearance'**
  String get onlyLiquidated;

  /// No description provided for @priceRange.
  ///
  /// In en, this message translates to:
  /// **'Price range'**
  String get priceRange;

  /// No description provided for @priceFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get priceFrom;

  /// No description provided for @priceTo.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get priceTo;

  /// No description provided for @activeFilters.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 filter} other{{count} filters}}'**
  String activeFilters(int count);

  /// No description provided for @resultCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No products} =1{1 product} other{{count} products}}'**
  String resultCount(int count);

  /// No description provided for @filterSearchNote.
  ///
  /// In en, this message translates to:
  /// **'Text search is applied to the filtered results.'**
  String get filterSearchNote;

  /// No description provided for @deliveryLocation.
  ///
  /// In en, this message translates to:
  /// **'Delivery location'**
  String get deliveryLocation;

  /// No description provided for @openInMaps.
  ///
  /// In en, this message translates to:
  /// **'Open in Google Maps'**
  String get openInMaps;

  /// No description provided for @noMapPin.
  ///
  /// In en, this message translates to:
  /// **'No pin was dropped for this order'**
  String get noMapPin;

  /// No description provided for @coordinatesCopied.
  ///
  /// In en, this message translates to:
  /// **'Coordinates copied'**
  String get coordinatesCopied;

  /// No description provided for @orderFilters.
  ///
  /// In en, this message translates to:
  /// **'Filter orders'**
  String get orderFilters;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @dateRange.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get dateRange;

  /// No description provided for @anyDate.
  ///
  /// In en, this message translates to:
  /// **'Any time'**
  String get anyDate;

  /// No description provided for @last7Days.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get last7Days;

  /// No description provided for @last30Days.
  ///
  /// In en, this message translates to:
  /// **'Last 30 days'**
  String get last30Days;

  /// No description provided for @channel.
  ///
  /// In en, this message translates to:
  /// **'Channel'**
  String get channel;

  /// No description provided for @orderFilterNote.
  ///
  /// In en, this message translates to:
  /// **'Status and date are applied to the loaded orders.'**
  String get orderFilterNote;

  /// No description provided for @notifNewOrderTitle.
  ///
  /// In en, this message translates to:
  /// **'New order'**
  String get notifNewOrderTitle;

  /// No description provided for @notifPaymentTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment received'**
  String get notifPaymentTitle;

  /// No description provided for @notifOrderBody.
  ///
  /// In en, this message translates to:
  /// **'#{number} · {total}'**
  String notifOrderBody(String number, String total);

  /// No description provided for @notifOrderBodyNamed.
  ///
  /// In en, this message translates to:
  /// **'#{number} · {total} · {customer}'**
  String notifOrderBodyNamed(String number, String total, String customer);

  /// No description provided for @notifOrderGroup.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 new order} other{{count} new orders}}'**
  String notifOrderGroup(int count);

  /// No description provided for @notifLowStockOne.
  ///
  /// In en, this message translates to:
  /// **'{product} is down to {count}'**
  String notifLowStockOne(String product, int count);

  /// No description provided for @notifLowStockMany.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 product is running low} other{{count} products are running low}}'**
  String notifLowStockMany(int count);

  /// No description provided for @pullToPreview.
  ///
  /// In en, this message translates to:
  /// **'Pull to preview'**
  String get pullToPreview;

  /// No description provided for @preview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get preview;

  /// No description provided for @seo.
  ///
  /// In en, this message translates to:
  /// **'Search engine listing'**
  String get seo;

  /// No description provided for @urlHandle.
  ///
  /// In en, this message translates to:
  /// **'URL handle'**
  String get urlHandle;

  /// No description provided for @metaTitle.
  ///
  /// In en, this message translates to:
  /// **'Page title'**
  String get metaTitle;

  /// No description provided for @metaDescription.
  ///
  /// In en, this message translates to:
  /// **'Meta description'**
  String get metaDescription;

  /// No description provided for @metaKeywords.
  ///
  /// In en, this message translates to:
  /// **'Keywords'**
  String get metaKeywords;

  /// No description provided for @gtin.
  ///
  /// In en, this message translates to:
  /// **'GTIN / barcode'**
  String get gtin;

  /// No description provided for @mpn.
  ///
  /// In en, this message translates to:
  /// **'MPN'**
  String get mpn;

  /// No description provided for @allowIndexing.
  ///
  /// In en, this message translates to:
  /// **'Allow search engines to index'**
  String get allowIndexing;

  /// No description provided for @canonicalUrl.
  ///
  /// In en, this message translates to:
  /// **'Canonical URL'**
  String get canonicalUrl;

  /// No description provided for @seoHint.
  ///
  /// In en, this message translates to:
  /// **'How this product appears on Google and in your sitemap.'**
  String get seoHint;
}

class _LDelegate extends LocalizationsDelegate<L> {
  const _LDelegate();

  @override
  Future<L> load(Locale locale) {
    return SynchronousFuture<L>(lookupL(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ka', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_LDelegate old) => false;
}

L lookupL(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return LEn();
    case 'ka':
      return LKa();
    case 'ru':
      return LRu();
  }

  throw FlutterError(
    'L.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
