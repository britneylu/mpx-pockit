// define supported currencies and their decimal places
enum Currency {
  usd('USD', 'US Dollar', 2),
  eur('EUR', 'Euro', 2),
  gbp('GBP', 'British Pound', 2),
  jpy('JPY', 'Japanese Yen', 0),
  krw('KRW', 'South Korean Won', 0),
  cad('CAD', 'Canadian Dollar', 2),
  aud('AUD', 'Australian Dollar', 2),
  cny('CNY', 'Chinese Yuan', 2);

  const Currency(this.code, this.label, this.decimals);
  final String code;
  final String label;
  final int decimals;
}
