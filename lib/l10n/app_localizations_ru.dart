// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class LRu extends L {
  LRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Komero';

  @override
  String get cancel => 'Отмена';

  @override
  String get save => 'Сохранить';

  @override
  String get retry => 'Повторить';

  @override
  String get close => 'Закрыть';

  @override
  String get search => 'Поиск';

  @override
  String get apply => 'Применить';

  @override
  String get done => 'Готово';

  @override
  String get all => 'Все';

  @override
  String get today => 'Сегодня';

  @override
  String get thisWeek => 'За неделю';

  @override
  String get thisMonth => 'За месяц';

  @override
  String get loading => 'Загрузка…';

  @override
  String get somethingWentWrong => 'Что-то пошло не так';

  @override
  String get noResults => 'Пока ничего нет';

  @override
  String get permissionDenied => 'У вас нет прав на это действие';

  @override
  String get loginTitle => 'Войдите в свой магазин';

  @override
  String get loginSubtitle => 'Заказы, склад и товары — с телефона';

  @override
  String get storeDomain => 'Адрес магазина';

  @override
  String get storeDomainHint => 'mystore.ge';

  @override
  String get storeDomainHelp =>
      'Домен, на котором работает ваш магазин. По нему Komero определяет, какой магазин открыть.';

  @override
  String get email => 'Эл. почта';

  @override
  String get password => 'Пароль';

  @override
  String get signIn => 'Войти';

  @override
  String get signOut => 'Выйти';

  @override
  String get forgotPassword => 'Забыли пароль?';

  @override
  String get resetLinkSent =>
      'Проверьте почту — мы отправили ссылку для сброса';

  @override
  String get enterStoreDomain => 'Укажите адрес магазина';

  @override
  String get enterEmail => 'Укажите эл. почту';

  @override
  String get enterPassword => 'Введите пароль';

  @override
  String get invalidCredentials => 'Неверная почта или пароль';

  @override
  String get storeNotFound => 'По этому адресу магазин не найден';

  @override
  String get notAMember => 'У этого аккаунта нет доступа к магазину';

  @override
  String get navHome => 'Главная';

  @override
  String get navOrders => 'Заказы';

  @override
  String get navInventory => 'Склад';

  @override
  String get navProducts => 'Товары';

  @override
  String get navSettings => 'Настройки';

  @override
  String get dashboard => 'Показатели';

  @override
  String get liveNow => 'Сейчас';

  @override
  String visitorsNow(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Сейчас $count посетителей',
      many: 'Сейчас $count посетителей',
      few: 'Сейчас $count посетителя',
      one: 'Сейчас 1 посетитель',
      zero: 'Сейчас посетителей нет',
    );
    return '$_temp0';
  }

  @override
  String get revenue => 'Выручка';

  @override
  String get orders => 'Заказы';

  @override
  String get customers => 'Клиенты';

  @override
  String get products => 'Товары';

  @override
  String get conversionRate => 'Конверсия';

  @override
  String get averageOrderValue => 'Средний чек';

  @override
  String get sessions => 'Сессии';

  @override
  String get salesOverTime => 'Продажи по дням';

  @override
  String get topProducts => 'Топ товаров';

  @override
  String unitsSold(int count) {
    return 'продано $count';
  }

  @override
  String get channels => 'Каналы';

  @override
  String get funnel => 'Воронка покупки';

  @override
  String get funnelViewed => 'Смотрели товар';

  @override
  String get funnelCart => 'Добавили в корзину';

  @override
  String get funnelCheckout => 'Начали оформление';

  @override
  String get funnelPurchased => 'Купили';

  @override
  String get vsLastMonth => 'к прошлому месяцу';

  @override
  String get needsAttention => 'Требует внимания';

  @override
  String lowStockCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count товаров заканчиваются',
      many: '$count товаров заканчиваются',
      few: '$count товара заканчиваются',
      one: '1 товар заканчивается',
    );
    return '$_temp0';
  }

  @override
  String outOfStockCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count товаров закончились',
      many: '$count товаров закончились',
      few: '$count товара закончились',
      one: '1 товар закончился',
    );
    return '$_temp0';
  }

  @override
  String orderNumber(String number) {
    return 'Заказ №$number';
  }

  @override
  String itemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count позиций',
      many: '$count позиций',
      few: '$count позиции',
      one: '1 позиция',
    );
    return '$_temp0';
  }

  @override
  String get statusPending => 'Ожидает';

  @override
  String get statusPaid => 'Оплачен';

  @override
  String get statusProcessing => 'В обработке';

  @override
  String get statusShipped => 'Отправлен';

  @override
  String get statusDelivered => 'Доставлен';

  @override
  String get statusCancelled => 'Отменён';

  @override
  String get statusRefunded => 'Возвращён';

  @override
  String get channelWebShop => 'Интернет-магазин';

  @override
  String get channelB2B => 'B2B';

  @override
  String get channelPos => 'Касса';

  @override
  String get orderDetails => 'Детали заказа';

  @override
  String get items => 'Позиции';

  @override
  String get customer => 'Клиент';

  @override
  String get shippingAddress => 'Адрес доставки';

  @override
  String get payment => 'Оплата';

  @override
  String get paymentMethod => 'Способ оплаты';

  @override
  String get paymentStatus => 'Статус оплаты';

  @override
  String get subtotal => 'Сумма';

  @override
  String get tax => 'Налог';

  @override
  String get shipping => 'Доставка';

  @override
  String get discount => 'Скидка';

  @override
  String get total => 'Итого';

  @override
  String get markAsFulfilled => 'Отметить выполненным';

  @override
  String get fulfillOrder => 'Выполнить заказ';

  @override
  String get trackingNumber => 'Трек-номер';

  @override
  String get trackingNumberHint => 'Код отслеживания курьера';

  @override
  String get estimatedDelivery => 'Ожидаемая доставка';

  @override
  String get updateStatus => 'Обновить статус';

  @override
  String get statusUpdated => 'Заказ обновлён';

  @override
  String get addNote => 'Примечание для клиента';

  @override
  String get cancelOrder => 'Отменить заказ';

  @override
  String get cancelReason => 'Причина отмены';

  @override
  String get orderCancelled => 'Заказ отменён';

  @override
  String get callCustomer => 'Позвонить';

  @override
  String get emailCustomer => 'Написать';

  @override
  String get posOrderReadOnly =>
      'Продажа на кассе меняется только возвратом на кассе';

  @override
  String get markRefunded => 'Отметить возвратом';

  @override
  String get refundWarning =>
      'Это запишется в Komero. Деньги верните отдельно в платёжной системе.';

  @override
  String get guestOrder => 'Заказ без аккаунта';

  @override
  String get inventory => 'Склад';

  @override
  String get scanBarcode => 'Сканировать штрихкод';

  @override
  String get scanToFind => 'Отсканируйте штрихкод, чтобы найти товар';

  @override
  String get scanning => 'Сканирование…';

  @override
  String get cameraPermissionNeeded => 'Для сканирования нужен доступ к камере';

  @override
  String get productNotFound => 'Товар с таким кодом не найден';

  @override
  String get matchedBySku => 'Найдено по SKU';

  @override
  String get onHand => 'На складе';

  @override
  String get reserved => 'Зарезервировано';

  @override
  String get available => 'Доступно';

  @override
  String get lowStock => 'Заканчивается';

  @override
  String get outOfStock => 'Нет в наличии';

  @override
  String get inStock => 'В наличии';

  @override
  String get allStock => 'Весь склад';

  @override
  String get adjustStock => 'Изменить остаток';

  @override
  String get receiveStock => 'Приёмка товара';

  @override
  String get countStock => 'Инвентаризация';

  @override
  String get newQuantity => 'Новое количество';

  @override
  String get addQuantity => 'Добавить';

  @override
  String get removeQuantity => 'Списать';

  @override
  String get setQuantity => 'Установить';

  @override
  String get adjustmentReason => 'Причина';

  @override
  String get reasonRestocked => 'Поступление';

  @override
  String get reasonDamaged => 'Повреждено';

  @override
  String get reasonReturned => 'Возврат';

  @override
  String get reasonTheft => 'Утеря или кража';

  @override
  String get reasonCorrection => 'Корректировка учёта';

  @override
  String get stockUpdated => 'Остаток обновлён';

  @override
  String packQuantityNote(int count) {
    return 'Одно сканирование = $count шт.';
  }

  @override
  String get locations => 'Склады';

  @override
  String get location => 'Склад';

  @override
  String get allLocations => 'Все склады';

  @override
  String get webSource => 'Продаёт онлайн';

  @override
  String get transferStock => 'Переместить товар';

  @override
  String get transferFrom => 'Откуда';

  @override
  String get transferTo => 'Куда';

  @override
  String get transferNote => 'Примечание';

  @override
  String get transferQuantity => 'Количество';

  @override
  String get transferCreated => 'Товар перемещён';

  @override
  String get sameLocationError => 'Выберите два разных склада';

  @override
  String get productCatalog => 'Товары';

  @override
  String get addProduct => 'Добавить товар';

  @override
  String get editProduct => 'Изменить товар';

  @override
  String get productName => 'Название';

  @override
  String get sku => 'SKU';

  @override
  String get price => 'Цена';

  @override
  String get salePrice => 'Цена со скидкой';

  @override
  String get description => 'Описание';

  @override
  String get shortDescription => 'Краткое описание';

  @override
  String get category => 'Категория';

  @override
  String get brand => 'Бренд';

  @override
  String get condition => 'Состояние';

  @override
  String get conditionNew => 'Новый';

  @override
  String get conditionUsed => 'Б/у';

  @override
  String get conditionLikeNew => 'Как новый';

  @override
  String get photos => 'Фото';

  @override
  String get takePhoto => 'Сделать фото';

  @override
  String get chooseFromLibrary => 'Выбрать из галереи';

  @override
  String get setAsCover => 'Сделать главным';

  @override
  String get initialStock => 'Начальный остаток';

  @override
  String get visibility => 'Видимость';

  @override
  String get publishedOnline => 'Виден в интернет-магазине';

  @override
  String get markNewArrival => 'Показывать как новинку';

  @override
  String get markLiquidated => 'Показывать как распродажу';

  @override
  String get markComingSoon => 'Показывать как ожидается';

  @override
  String get productSaved => 'Товар сохранён';

  @override
  String get productCreated => 'Товар создан';

  @override
  String get uploadingPhotos => 'Загрузка фото…';

  @override
  String get requiredField => 'Обязательное поле';

  @override
  String get invalidPrice => 'Введите корректную цену';

  @override
  String get pickCategory => 'Выберите категорию';

  @override
  String get pickBrand => 'Выберите бренд';

  @override
  String get settings => 'Настройки';

  @override
  String get appearance => 'Оформление';

  @override
  String get themeSystem => 'Системная';

  @override
  String get themeLight => 'Светлая';

  @override
  String get themeDark => 'Тёмная';

  @override
  String get language => 'Язык';

  @override
  String get notifications => 'Уведомления';

  @override
  String get notifyNewOrders => 'Новые заказы';

  @override
  String get notifyLowStock => 'Предупреждения об остатках';

  @override
  String get pushUnavailable =>
      'Фоновые уведомления в этой сборке не настроены. Оповещения приходят, пока приложение открыто.';

  @override
  String get account => 'Аккаунт';

  @override
  String get store => 'Магазин';

  @override
  String get role => 'Роль';

  @override
  String get roleOwner => 'Владелец';

  @override
  String get roleMember => 'Сотрудник';

  @override
  String get signOutConfirm => 'Выйти из этого магазина?';

  @override
  String get about => 'О приложении';

  @override
  String get filters => 'Фильтры';

  @override
  String get filter => 'Фильтр';

  @override
  String get clearAll => 'Сбросить';

  @override
  String get showResults => 'Показать результаты';

  @override
  String get sortBy => 'Сортировка';

  @override
  String get sortNameAsc => 'Название А-Я';

  @override
  String get sortPriceLow => 'Цена: по возрастанию';

  @override
  String get sortPriceHigh => 'Цена: по убыванию';

  @override
  String get sortNewest => 'Сначала новые';

  @override
  String get allCategories => 'Все категории';

  @override
  String get allBrands => 'Все бренды';

  @override
  String get stockStatus => 'Наличие';

  @override
  String get promoFlags => 'Метки';

  @override
  String get onlyNewArrivals => 'Новинки';

  @override
  String get onlyDiscounted => 'Со скидкой';

  @override
  String get onlyLiquidated => 'Распродажа';

  @override
  String get priceRange => 'Диапазон цен';

  @override
  String get priceFrom => 'От';

  @override
  String get priceTo => 'До';

  @override
  String activeFilters(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count фильтров',
      many: '$count фильтров',
      few: '$count фильтра',
      one: '1 фильтр',
    );
    return '$_temp0';
  }

  @override
  String resultCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count товаров',
      many: '$count товаров',
      few: '$count товара',
      one: '1 товар',
      zero: 'Нет товаров',
    );
    return '$_temp0';
  }

  @override
  String get filterSearchNote =>
      'Текстовый поиск применяется к отфильтрованным результатам.';

  @override
  String get deliveryLocation => 'Место доставки';

  @override
  String get openInMaps => 'Открыть в Google Maps';

  @override
  String get noMapPin => 'Для этого заказа точка на карте не указана';

  @override
  String get coordinatesCopied => 'Координаты скопированы';

  @override
  String get orderFilters => 'Фильтр заказов';

  @override
  String get status => 'Статус';

  @override
  String get dateRange => 'Дата';

  @override
  String get anyDate => 'Любая';

  @override
  String get last7Days => 'Последние 7 дней';

  @override
  String get last30Days => 'Последние 30 дней';

  @override
  String get channel => 'Канал';

  @override
  String get orderFilterNote =>
      'Статус и дата применяются к загруженным заказам.';
}
