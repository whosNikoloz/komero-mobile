// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class LEn extends L {
  LEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Komero';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get retry => 'Retry';

  @override
  String get close => 'Close';

  @override
  String get search => 'Search';

  @override
  String get apply => 'Apply';

  @override
  String get done => 'Done';

  @override
  String get all => 'All';

  @override
  String get today => 'Today';

  @override
  String get thisWeek => 'This week';

  @override
  String get thisMonth => 'This month';

  @override
  String get loading => 'Loading…';

  @override
  String get somethingWentWrong => 'Something went wrong';

  @override
  String get noResults => 'Nothing here yet';

  @override
  String get permissionDenied => 'You do not have permission for this';

  @override
  String get welcomeTitle => 'Run your store from your pocket';

  @override
  String get welcomeSubtitle => 'Orders, stock and products — wherever you are';

  @override
  String get continueLabel => 'Continue';

  @override
  String get loginTitle => 'Sign in to your store';

  @override
  String get loginSubtitle => 'Manage orders, stock and products on the go';

  @override
  String get storeDomain => 'Store address';

  @override
  String get storeDomainHint => 'mystore.ge';

  @override
  String get storeDomainHelp =>
      'The domain your store runs on. It tells Komero which store to open.';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get rememberMe => 'Remember me';

  @override
  String get signIn => 'Sign in';

  @override
  String get signOut => 'Sign out';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get resetLinkSent => 'Check your email for a reset link';

  @override
  String get enterStoreDomain => 'Enter your store address';

  @override
  String get enterEmail => 'Enter your email';

  @override
  String get enterPassword => 'Enter your password';

  @override
  String get invalidCredentials => 'Wrong email or password';

  @override
  String get storeNotFound => 'No store found at that address';

  @override
  String get notAMember => 'This account cannot manage that store';

  @override
  String get navHome => 'Home';

  @override
  String get navOrders => 'Orders';

  @override
  String get navInventory => 'Inventory';

  @override
  String get navProducts => 'Products';

  @override
  String get navSettings => 'Settings';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get liveNow => 'Live now';

  @override
  String visitorsNow(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count visitors right now',
      one: '1 visitor right now',
      zero: 'No visitors right now',
    );
    return '$_temp0';
  }

  @override
  String get revenue => 'Revenue';

  @override
  String get orders => 'Orders';

  @override
  String get customers => 'Customers';

  @override
  String get products => 'Products';

  @override
  String get conversionRate => 'Conversion rate';

  @override
  String get averageOrderValue => 'Average order value';

  @override
  String get sessions => 'Sessions';

  @override
  String get salesOverTime => 'Sales over time';

  @override
  String get topProducts => 'Top products';

  @override
  String unitsSold(int count) {
    return '$count sold';
  }

  @override
  String get channels => 'Channels';

  @override
  String get funnel => 'Shopping funnel';

  @override
  String get funnelViewed => 'Viewed a product';

  @override
  String get funnelCart => 'Added to cart';

  @override
  String get funnelCheckout => 'Started checkout';

  @override
  String get funnelPurchased => 'Purchased';

  @override
  String get vsLastMonth => 'vs last month';

  @override
  String get ordersToFulfil => 'Orders to fulfil';

  @override
  String get viewAll => 'View all';

  @override
  String get needsAttention => 'Needs attention';

  @override
  String lowStockCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count products low on stock',
      one: '1 product low on stock',
    );
    return '$_temp0';
  }

  @override
  String outOfStockCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count products out of stock',
      one: '1 product out of stock',
    );
    return '$_temp0';
  }

  @override
  String orderNumber(String number) {
    return 'Order #$number';
  }

  @override
  String itemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String get statusPending => 'Pending';

  @override
  String get statusPaid => 'Paid';

  @override
  String get statusProcessing => 'Processing';

  @override
  String get statusShipped => 'Shipped';

  @override
  String get statusDelivered => 'Delivered';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String get statusRefunded => 'Refunded';

  @override
  String get channelWebShop => 'Online store';

  @override
  String get channelB2B => 'B2B';

  @override
  String get channelPos => 'Point of sale';

  @override
  String get orderDetails => 'Order details';

  @override
  String get items => 'Items';

  @override
  String get customer => 'Customer';

  @override
  String get shippingAddress => 'Shipping address';

  @override
  String get payment => 'Payment';

  @override
  String get paymentMethod => 'Payment method';

  @override
  String get paymentStatus => 'Payment status';

  @override
  String get subtotal => 'Subtotal';

  @override
  String get tax => 'Tax';

  @override
  String get shipping => 'Shipping';

  @override
  String get discount => 'Discount';

  @override
  String get total => 'Total';

  @override
  String get markAsFulfilled => 'Mark as fulfilled';

  @override
  String get fulfillOrder => 'Fulfil order';

  @override
  String get trackingNumber => 'Tracking number';

  @override
  String get trackingNumberHint => 'Carrier tracking code';

  @override
  String get estimatedDelivery => 'Estimated delivery';

  @override
  String get updateStatus => 'Update status';

  @override
  String get statusUpdated => 'Order updated';

  @override
  String get addNote => 'Note for the customer';

  @override
  String get cancelOrder => 'Cancel order';

  @override
  String get cancelReason => 'Reason for cancelling';

  @override
  String get orderCancelled => 'Order cancelled';

  @override
  String get callCustomer => 'Call';

  @override
  String get emailCustomer => 'Email';

  @override
  String get posOrderReadOnly =>
      'Till sales change only through a return at the till';

  @override
  String get markRefunded => 'Mark as refunded';

  @override
  String get refundWarning =>
      'This records the refund in Komero. Move the money in your payment provider separately.';

  @override
  String get guestOrder => 'Guest order';

  @override
  String get inventory => 'Inventory';

  @override
  String get scanBarcode => 'Scan barcode';

  @override
  String get scanToFind => 'Scan a barcode to find a product';

  @override
  String get scanning => 'Scanning…';

  @override
  String get cameraPermissionNeeded =>
      'Camera access is needed to scan barcodes';

  @override
  String get productNotFound => 'No product matches that code';

  @override
  String get matchedBySku => 'Matched by SKU';

  @override
  String get onHand => 'On hand';

  @override
  String get reserved => 'Reserved';

  @override
  String get available => 'Available';

  @override
  String get lowStock => 'Low stock';

  @override
  String get outOfStock => 'Out of stock';

  @override
  String get inStock => 'In stock';

  @override
  String get allStock => 'All stock';

  @override
  String get adjustStock => 'Adjust stock';

  @override
  String get receiveStock => 'Receive stock';

  @override
  String get countStock => 'Count stock';

  @override
  String get newQuantity => 'New quantity';

  @override
  String get addQuantity => 'Add';

  @override
  String get removeQuantity => 'Remove';

  @override
  String get setQuantity => 'Set to';

  @override
  String get adjustmentReason => 'Reason';

  @override
  String get reasonRestocked => 'Restocked';

  @override
  String get reasonDamaged => 'Damaged';

  @override
  String get reasonReturned => 'Returned';

  @override
  String get reasonTheft => 'Theft or loss';

  @override
  String get reasonCorrection => 'Count correction';

  @override
  String get stockUpdated => 'Stock updated';

  @override
  String packQuantityNote(int count) {
    return 'One scan counts $count units';
  }

  @override
  String get locations => 'Locations';

  @override
  String get location => 'Location';

  @override
  String get allLocations => 'All locations';

  @override
  String get webSource => 'Sells online';

  @override
  String get transferStock => 'Move stock';

  @override
  String get transferFrom => 'From';

  @override
  String get transferTo => 'To';

  @override
  String get transferNote => 'Note';

  @override
  String get transferQuantity => 'Quantity';

  @override
  String get transferCreated => 'Stock moved';

  @override
  String get sameLocationError => 'Pick two different locations';

  @override
  String get productCatalog => 'Products';

  @override
  String get addProduct => 'Add product';

  @override
  String get editProduct => 'Edit product';

  @override
  String get productName => 'Name';

  @override
  String get sku => 'SKU';

  @override
  String get price => 'Price';

  @override
  String get salePrice => 'Sale price';

  @override
  String get addPhoto => 'Add photo';

  @override
  String addValue(String field) {
    return 'Add $field';
  }

  @override
  String selectValue(String field) {
    return 'Select $field';
  }

  @override
  String get noneSelected => 'None';

  @override
  String get catalog => 'Catalog';

  @override
  String get categories => 'Categories';

  @override
  String get brands => 'Brands';

  @override
  String get productGroups => 'Product groups';

  @override
  String get addNew => 'Add new';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get deleted => 'Deleted';

  @override
  String get saved => 'Saved';

  @override
  String get name => 'Name';

  @override
  String deleteItem(String name) {
    return 'Delete $name?';
  }

  @override
  String get deleteCatalogWarning =>
      'Products using it keep their other details, but lose this one.';

  @override
  String get storeContent => 'Store content';

  @override
  String get promotions => 'Discounts';

  @override
  String get newDiscount => 'New discount';

  @override
  String get percentOff => '% off';

  @override
  String get amountOff => 'Amount off';

  @override
  String get couponCode => 'Promo code';

  @override
  String get couponCodeHelp =>
      'Leave empty to apply the discount automatically.';

  @override
  String get automaticDiscount => 'Applies automatically';

  @override
  String couponCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count codes',
      one: '1 code',
      zero: 'No codes',
    );
    return '$_temp0';
  }

  @override
  String get statusActive => 'Active';

  @override
  String get statusPaused => 'Paused';

  @override
  String get statusScheduled => 'Scheduled';

  @override
  String get statusDraft => 'Draft';

  @override
  String get statusEnded => 'Ended';

  @override
  String get pause => 'Pause';

  @override
  String get activate => 'Activate';

  @override
  String get archive => 'Archive';

  @override
  String get blog => 'Blog';

  @override
  String get postBody => 'Post text';

  @override
  String get published => 'Published';

  @override
  String get publish => 'Publish';

  @override
  String get title => 'Title';

  @override
  String get faqs => 'FAQ';

  @override
  String get question => 'Question';

  @override
  String get answer => 'Answer';

  @override
  String get addVideo => 'Add video';

  @override
  String get videoLink => 'Video link';

  @override
  String get videoLinkHint => 'YouTube link, or an embed link';

  @override
  String get invalidVideoLink => 'That does not look like a video link';

  @override
  String get moveUp => 'Move up';

  @override
  String get moveDown => 'Move down';

  @override
  String get formatBold => 'Bold';

  @override
  String get formatItalic => 'Italic';

  @override
  String get formatBulletList => 'Bulleted list';

  @override
  String get description => 'Description';

  @override
  String get shortDescription => 'Short description';

  @override
  String get category => 'Category';

  @override
  String get brand => 'Brand';

  @override
  String get condition => 'Condition';

  @override
  String get conditionNew => 'New';

  @override
  String get conditionUsed => 'Used';

  @override
  String get conditionLikeNew => 'Like new';

  @override
  String get photos => 'Photos';

  @override
  String get takePhoto => 'Take photo';

  @override
  String get chooseFromLibrary => 'Choose from library';

  @override
  String get setAsCover => 'Set as cover';

  @override
  String get initialStock => 'Starting stock';

  @override
  String get visibility => 'Visibility';

  @override
  String get publishedOnline => 'Visible in the online store';

  @override
  String get markNewArrival => 'Show as new arrival';

  @override
  String get markLiquidated => 'Show as clearance';

  @override
  String get markComingSoon => 'Show as coming soon';

  @override
  String get productSaved => 'Product saved';

  @override
  String get productCreated => 'Product created';

  @override
  String get uploadingPhotos => 'Uploading photos…';

  @override
  String get requiredField => 'Required';

  @override
  String get invalidPrice => 'Enter a valid price';

  @override
  String get pickCategory => 'Pick a category';

  @override
  String get pickBrand => 'Pick a brand';

  @override
  String get settings => 'Settings';

  @override
  String get appearance => 'Appearance';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get language => 'Language';

  @override
  String get notifications => 'Notifications';

  @override
  String get notifyNewOrders => 'New orders';

  @override
  String get notifyLowStock => 'Low stock warnings';

  @override
  String get pushUnavailable =>
      'Background push is not set up for this build. Alerts arrive while the app is open.';

  @override
  String get account => 'Account';

  @override
  String get store => 'Store';

  @override
  String get role => 'Role';

  @override
  String get roleOwner => 'Owner';

  @override
  String get roleMember => 'Member';

  @override
  String get signOutConfirm => 'Sign out of this store?';

  @override
  String get about => 'About';

  @override
  String get filters => 'Filters';

  @override
  String get filter => 'Filter';

  @override
  String get clearAll => 'Clear all';

  @override
  String get showResults => 'Show results';

  @override
  String get sortBy => 'Sort by';

  @override
  String get sortNameAsc => 'Name A-Z';

  @override
  String get sortPriceLow => 'Price: low to high';

  @override
  String get sortPriceHigh => 'Price: high to low';

  @override
  String get sortNewest => 'Newest first';

  @override
  String get allCategories => 'All categories';

  @override
  String get allBrands => 'All brands';

  @override
  String get stockStatus => 'Availability';

  @override
  String get promoFlags => 'Labels';

  @override
  String get onlyNewArrivals => 'New arrivals';

  @override
  String get onlyDiscounted => 'On sale';

  @override
  String get onlyLiquidated => 'Clearance';

  @override
  String get priceRange => 'Price range';

  @override
  String get priceFrom => 'From';

  @override
  String get priceTo => 'To';

  @override
  String activeFilters(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count filters',
      one: '1 filter',
    );
    return '$_temp0';
  }

  @override
  String resultCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count products',
      one: '1 product',
      zero: 'No products',
    );
    return '$_temp0';
  }

  @override
  String get filterSearchNote =>
      'Text search is applied to the filtered results.';

  @override
  String get deliveryLocation => 'Delivery location';

  @override
  String get openInMaps => 'Open in Google Maps';

  @override
  String get noMapPin => 'No pin was dropped for this order';

  @override
  String get coordinatesCopied => 'Coordinates copied';

  @override
  String get orderFilters => 'Filter orders';

  @override
  String get status => 'Status';

  @override
  String get dateRange => 'Date';

  @override
  String get anyDate => 'Any time';

  @override
  String get last7Days => 'Last 7 days';

  @override
  String get last30Days => 'Last 30 days';

  @override
  String get channel => 'Channel';

  @override
  String get orderFilterNote =>
      'Status and date are applied to the loaded orders.';

  @override
  String get notifNewOrderTitle => 'New order';

  @override
  String get notifPaymentTitle => 'Payment received';

  @override
  String notifOrderBody(String number, String total) {
    return '#$number · $total';
  }

  @override
  String notifOrderBodyNamed(String number, String total, String customer) {
    return '#$number · $total · $customer';
  }

  @override
  String notifOrderGroup(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count new orders',
      one: '1 new order',
    );
    return '$_temp0';
  }

  @override
  String notifLowStockOne(String product, int count) {
    return '$product is down to $count';
  }

  @override
  String notifLowStockMany(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count products are running low',
      one: '1 product is running low',
    );
    return '$_temp0';
  }

  @override
  String get pullToPreview => 'Pull to preview';

  @override
  String get preview => 'Preview';

  @override
  String get seo => 'Search engine listing';

  @override
  String get urlHandle => 'URL handle';

  @override
  String get metaTitle => 'Page title';

  @override
  String get metaDescription => 'Meta description';

  @override
  String get metaKeywords => 'Keywords';

  @override
  String get gtin => 'GTIN / barcode';

  @override
  String get mpn => 'MPN';

  @override
  String get allowIndexing => 'Allow search engines to index';

  @override
  String get canonicalUrl => 'Canonical URL';

  @override
  String get seoHint =>
      'How this product appears on Google and in your sitemap.';

  @override
  String get recentSearches => 'Recent searches';

  @override
  String get noRecentSearches => 'No recent searches';

  @override
  String get navigation => 'Navigation';

  @override
  String get searchEverything => 'Search products, orders, pages';

  @override
  String get clearRecent => 'Clear';
}
