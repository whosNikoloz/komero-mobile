// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Georgian (`ka`).
class LKa extends L {
  LKa([String locale = 'ka']) : super(locale);

  @override
  String get appTitle => 'Komero';

  @override
  String get cancel => 'გაუქმება';

  @override
  String get save => 'შენახვა';

  @override
  String get retry => 'ხელახლა';

  @override
  String get close => 'დახურვა';

  @override
  String get search => 'ძიება';

  @override
  String get apply => 'გამოყენება';

  @override
  String get done => 'მზადაა';

  @override
  String get all => 'ყველა';

  @override
  String get today => 'დღეს';

  @override
  String get thisWeek => 'ამ კვირაში';

  @override
  String get thisMonth => 'ამ თვეში';

  @override
  String get loading => 'იტვირთება…';

  @override
  String get somethingWentWrong => 'რამე ვერ გამოვიდა';

  @override
  String get noResults => 'ჯერ არაფერია';

  @override
  String get permissionDenied => 'ამისთვის უფლება არ გაქვთ';

  @override
  String get loginTitle => 'შედით თქვენს მაღაზიაში';

  @override
  String get loginSubtitle =>
      'მართეთ შეკვეთები, მარაგი და პროდუქტები ნებისმიერი ადგილიდან';

  @override
  String get storeDomain => 'მაღაზიის მისამართი';

  @override
  String get storeDomainHint => 'mystore.ge';

  @override
  String get storeDomainHelp =>
      'დომენი, რომელზეც თქვენი მაღაზია მუშაობს. ის განსაზღვრავს რომელი მაღაზია გაიხსნას.';

  @override
  String get email => 'ელფოსტა';

  @override
  String get password => 'პაროლი';

  @override
  String get signIn => 'შესვლა';

  @override
  String get signOut => 'გასვლა';

  @override
  String get forgotPassword => 'დაგავიწყდათ პაროლი?';

  @override
  String get resetLinkSent => 'შეამოწმეთ ელფოსტა პაროლის აღდგენის ბმულისთვის';

  @override
  String get enterStoreDomain => 'შეიყვანეთ მაღაზიის მისამართი';

  @override
  String get enterEmail => 'შეიყვანეთ ელფოსტა';

  @override
  String get enterPassword => 'შეიყვანეთ პაროლი';

  @override
  String get invalidCredentials => 'ელფოსტა ან პაროლი არასწორია';

  @override
  String get storeNotFound => 'ამ მისამართზე მაღაზია ვერ მოიძებნა';

  @override
  String get notAMember => 'ამ ანგარიშს ამ მაღაზიის მართვის უფლება არ აქვს';

  @override
  String get navHome => 'მთავარი';

  @override
  String get navOrders => 'შეკვეთები';

  @override
  String get navInventory => 'მარაგი';

  @override
  String get navProducts => 'პროდუქტები';

  @override
  String get navSettings => 'პარამეტრები';

  @override
  String get dashboard => 'მაჩვენებლები';

  @override
  String get liveNow => 'ახლა';

  @override
  String visitorsNow(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ამჟამად $count ვიზიტორი',
      one: 'ამჟამად 1 ვიზიტორი',
      zero: 'ამჟამად ვიზიტორი არ არის',
    );
    return '$_temp0';
  }

  @override
  String get revenue => 'შემოსავალი';

  @override
  String get orders => 'შეკვეთები';

  @override
  String get customers => 'მომხმარებლები';

  @override
  String get products => 'პროდუქტები';

  @override
  String get conversionRate => 'კონვერსია';

  @override
  String get averageOrderValue => 'შეკვეთის საშუალო თანხა';

  @override
  String get sessions => 'სესიები';

  @override
  String get salesOverTime => 'გაყიდვები დროში';

  @override
  String get topProducts => 'საუკეთესო პროდუქტები';

  @override
  String unitsSold(int count) {
    return 'გაიყიდა $count';
  }

  @override
  String get channels => 'არხები';

  @override
  String get funnel => 'შესყიდვის ძაბრი';

  @override
  String get funnelViewed => 'ნახეს პროდუქტი';

  @override
  String get funnelCart => 'დაამატეს კალათაში';

  @override
  String get funnelCheckout => 'დაიწყეს შეკვეთა';

  @override
  String get funnelPurchased => 'შეიძინეს';

  @override
  String get vsLastMonth => 'გასულ თვესთან';

  @override
  String get needsAttention => 'საჭიროებს ყურადღებას';

  @override
  String lowStockCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count პროდუქტს მარაგი დაუწია',
      one: '1 პროდუქტს მარაგი დაუწია',
    );
    return '$_temp0';
  }

  @override
  String outOfStockCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count პროდუქტი ამოიწურა',
      one: '1 პროდუქტი ამოიწურა',
    );
    return '$_temp0';
  }

  @override
  String orderNumber(String number) {
    return 'შეკვეთა #$number';
  }

  @override
  String itemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ნივთი',
      one: '1 ნივთი',
    );
    return '$_temp0';
  }

  @override
  String get statusPending => 'მოლოდინში';

  @override
  String get statusPaid => 'გადახდილი';

  @override
  String get statusProcessing => 'მუშავდება';

  @override
  String get statusShipped => 'გაგზავნილი';

  @override
  String get statusDelivered => 'მიტანილი';

  @override
  String get statusCancelled => 'გაუქმებული';

  @override
  String get statusRefunded => 'თანხა დაბრუნდა';

  @override
  String get channelWebShop => 'ონლაინ მაღაზია';

  @override
  String get channelB2B => 'B2B';

  @override
  String get channelPos => 'სალარო';

  @override
  String get orderDetails => 'შეკვეთის დეტალები';

  @override
  String get items => 'ნივთები';

  @override
  String get customer => 'მომხმარებელი';

  @override
  String get shippingAddress => 'მიტანის მისამართი';

  @override
  String get payment => 'გადახდა';

  @override
  String get paymentMethod => 'გადახდის მეთოდი';

  @override
  String get paymentStatus => 'გადახდის სტატუსი';

  @override
  String get subtotal => 'ჯამი';

  @override
  String get tax => 'დღგ';

  @override
  String get shipping => 'მიტანა';

  @override
  String get discount => 'ფასდაკლება';

  @override
  String get total => 'სულ';

  @override
  String get markAsFulfilled => 'მონიშნე შესრულებულად';

  @override
  String get fulfillOrder => 'შეკვეთის შესრულება';

  @override
  String get trackingNumber => 'თრექინგის ნომერი';

  @override
  String get trackingNumberHint => 'კურიერის თრექინგ კოდი';

  @override
  String get estimatedDelivery => 'სავარაუდო მიტანა';

  @override
  String get updateStatus => 'სტატუსის განახლება';

  @override
  String get statusUpdated => 'შეკვეთა განახლდა';

  @override
  String get addNote => 'შენიშვნა მომხმარებლისთვის';

  @override
  String get cancelOrder => 'შეკვეთის გაუქმება';

  @override
  String get cancelReason => 'გაუქმების მიზეზი';

  @override
  String get orderCancelled => 'შეკვეთა გაუქმდა';

  @override
  String get callCustomer => 'დარეკვა';

  @override
  String get emailCustomer => 'ელფოსტა';

  @override
  String get posOrderReadOnly =>
      'სალაროს გაყიდვა იცვლება მხოლოდ სალაროში დაბრუნებით';

  @override
  String get markRefunded => 'მონიშნე დაბრუნებულად';

  @override
  String get refundWarning =>
      'ეს ჩაიწერება Komero-ში. თანხა ცალკე დააბრუნეთ გადახდის სისტემაში.';

  @override
  String get guestOrder => 'სტუმრის შეკვეთა';

  @override
  String get inventory => 'მარაგი';

  @override
  String get scanBarcode => 'ბარკოდის სკანირება';

  @override
  String get scanToFind => 'დასკანერეთ ბარკოდი პროდუქტის მოსაძებნად';

  @override
  String get scanning => 'სკანირდება…';

  @override
  String get cameraPermissionNeeded => 'ბარკოდის სკანირებისთვის საჭიროა კამერა';

  @override
  String get productNotFound => 'ამ კოდით პროდუქტი ვერ მოიძებნა';

  @override
  String get matchedBySku => 'მოიძებნა SKU-ით';

  @override
  String get onHand => 'ნაშთი';

  @override
  String get reserved => 'დაჯავშნული';

  @override
  String get available => 'ხელმისაწვდომი';

  @override
  String get lowStock => 'მცირე მარაგი';

  @override
  String get outOfStock => 'ამოიწურა';

  @override
  String get inStock => 'მარაგშია';

  @override
  String get allStock => 'მთელი მარაგი';

  @override
  String get adjustStock => 'მარაგის კორექტირება';

  @override
  String get receiveStock => 'მარაგის მიღება';

  @override
  String get countStock => 'მარაგის აღრიცხვა';

  @override
  String get newQuantity => 'ახალი რაოდენობა';

  @override
  String get addQuantity => 'დამატება';

  @override
  String get removeQuantity => 'მოკლება';

  @override
  String get setQuantity => 'დააყენე';

  @override
  String get adjustmentReason => 'მიზეზი';

  @override
  String get reasonRestocked => 'შემოვიდა';

  @override
  String get reasonDamaged => 'დაზიანდა';

  @override
  String get reasonReturned => 'დაბრუნდა';

  @override
  String get reasonTheft => 'დაიკარგა ან მოიპარეს';

  @override
  String get reasonCorrection => 'აღრიცხვის შესწორება';

  @override
  String get stockUpdated => 'მარაგი განახლდა';

  @override
  String packQuantityNote(int count) {
    return 'ერთი სკანირება = $count ერთეული';
  }

  @override
  String get locations => 'ლოკაციები';

  @override
  String get location => 'ლოკაცია';

  @override
  String get allLocations => 'ყველა ლოკაცია';

  @override
  String get webSource => 'ყიდის ონლაინ';

  @override
  String get transferStock => 'მარაგის გადატანა';

  @override
  String get transferFrom => 'საიდან';

  @override
  String get transferTo => 'სად';

  @override
  String get transferNote => 'შენიშვნა';

  @override
  String get transferQuantity => 'რაოდენობა';

  @override
  String get transferCreated => 'მარაგი გადავიდა';

  @override
  String get sameLocationError => 'აირჩიეთ ორი განსხვავებული ლოკაცია';

  @override
  String get productCatalog => 'პროდუქტები';

  @override
  String get addProduct => 'პროდუქტის დამატება';

  @override
  String get editProduct => 'პროდუქტის რედაქტირება';

  @override
  String get productName => 'დასახელება';

  @override
  String get sku => 'SKU';

  @override
  String get price => 'ფასი';

  @override
  String get salePrice => 'ფასდაკლებული ფასი';

  @override
  String get description => 'აღწერა';

  @override
  String get shortDescription => 'მოკლე აღწერა';

  @override
  String get category => 'კატეგორია';

  @override
  String get brand => 'ბრენდი';

  @override
  String get condition => 'მდგომარეობა';

  @override
  String get conditionNew => 'ახალი';

  @override
  String get conditionUsed => 'მეორადი';

  @override
  String get conditionLikeNew => 'როგორც ახალი';

  @override
  String get photos => 'ფოტოები';

  @override
  String get takePhoto => 'ფოტოს გადაღება';

  @override
  String get chooseFromLibrary => 'აირჩიე გალერეიდან';

  @override
  String get setAsCover => 'მთავარ ფოტოდ';

  @override
  String get initialStock => 'საწყისი მარაგი';

  @override
  String get visibility => 'ხილვადობა';

  @override
  String get publishedOnline => 'ჩანს ონლაინ მაღაზიაში';

  @override
  String get markNewArrival => 'აჩვენე როგორც სიახლე';

  @override
  String get markLiquidated => 'აჩვენე როგორც ლიკვიდაცია';

  @override
  String get markComingSoon => 'აჩვენე როგორც მოსალოდნელი';

  @override
  String get productSaved => 'პროდუქტი შეინახა';

  @override
  String get productCreated => 'პროდუქტი შეიქმნა';

  @override
  String get uploadingPhotos => 'ფოტოები იტვირთება…';

  @override
  String get requiredField => 'სავალდებულოა';

  @override
  String get invalidPrice => 'შეიყვანეთ სწორი ფასი';

  @override
  String get pickCategory => 'აირჩიეთ კატეგორია';

  @override
  String get pickBrand => 'აირჩიეთ ბრენდი';

  @override
  String get settings => 'პარამეტრები';

  @override
  String get appearance => 'იერსახე';

  @override
  String get themeSystem => 'სისტემის';

  @override
  String get themeLight => 'ნათელი';

  @override
  String get themeDark => 'მუქი';

  @override
  String get language => 'ენა';

  @override
  String get notifications => 'შეტყობინებები';

  @override
  String get notifyNewOrders => 'ახალი შეკვეთები';

  @override
  String get notifyLowStock => 'მცირე მარაგის გაფრთხილება';

  @override
  String get pushUnavailable =>
      'ფონური შეტყობინებები ამ ბილდში არ არის კონფიგურირებული. გაფრთხილებები მოვა აპის გახსნისას.';

  @override
  String get account => 'ანგარიში';

  @override
  String get store => 'მაღაზია';

  @override
  String get role => 'როლი';

  @override
  String get roleOwner => 'მფლობელი';

  @override
  String get roleMember => 'წევრი';

  @override
  String get signOutConfirm => 'გსურთ ამ მაღაზიიდან გასვლა?';

  @override
  String get about => 'აპის შესახებ';

  @override
  String get filters => 'ფილტრები';

  @override
  String get filter => 'ფილტრი';

  @override
  String get clearAll => 'გასუფთავება';

  @override
  String get showResults => 'შედეგების ჩვენება';

  @override
  String get sortBy => 'დალაგება';

  @override
  String get sortNameAsc => 'სახელი ა-ჰ';

  @override
  String get sortPriceLow => 'ფასი: ზრდადობით';

  @override
  String get sortPriceHigh => 'ფასი: კლებადობით';

  @override
  String get sortNewest => 'ჯერ ახლები';

  @override
  String get allCategories => 'ყველა კატეგორია';

  @override
  String get allBrands => 'ყველა ბრენდი';

  @override
  String get stockStatus => 'ხელმისაწვდომობა';

  @override
  String get promoFlags => 'ნიშნულები';

  @override
  String get onlyNewArrivals => 'სიახლეები';

  @override
  String get onlyDiscounted => 'ფასდაკლებით';

  @override
  String get onlyLiquidated => 'ლიკვიდაცია';

  @override
  String get priceRange => 'ფასის დიაპაზონი';

  @override
  String get priceFrom => 'დან';

  @override
  String get priceTo => 'მდე';

  @override
  String activeFilters(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ფილტრი',
      one: '1 ფილტრი',
    );
    return '$_temp0';
  }

  @override
  String resultCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count პროდუქტი',
      one: '1 პროდუქტი',
      zero: 'პროდუქტი არ არის',
    );
    return '$_temp0';
  }

  @override
  String get filterSearchNote => 'ტექსტით ძიება გაფილტრულ შედეგებზე მოქმედებს.';

  @override
  String get deliveryLocation => 'მიტანის ადგილი';

  @override
  String get openInMaps => 'Google Maps-ში გახსნა';

  @override
  String get noMapPin => 'ამ შეკვეთას რუკაზე აღნიშნული ადგილი არ აქვს';

  @override
  String get coordinatesCopied => 'კოორდინატები დაკოპირდა';

  @override
  String get orderFilters => 'შეკვეთების ფილტრი';

  @override
  String get status => 'სტატუსი';

  @override
  String get dateRange => 'თარიღი';

  @override
  String get anyDate => 'ნებისმიერი';

  @override
  String get last7Days => 'ბოლო 7 დღე';

  @override
  String get last30Days => 'ბოლო 30 დღე';

  @override
  String get channel => 'არხი';

  @override
  String get orderFilterNote =>
      'სტატუსი და თარიღი ჩატვირთულ შეკვეთებზე მოქმედებს.';
}
