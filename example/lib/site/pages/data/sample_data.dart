import 'package:desen_ui/desen_ui.dart';

/// The state of an [Invoice], with the badge color that shows it.
enum InvoiceStatus {
  paid('Paid', DsStatus.success),
  pending('Pending', DsStatus.warning),
  overdue('Overdue', DsStatus.danger);

  const InvoiceStatus(this.label, this.tone);

  final String label;
  final DsStatus tone;
}

/// One invoice of the table examples.
class Invoice {
  const Invoice(this.id, this.customer, this.status, this.amount, this.due);

  final int id;
  final String customer;
  final InvoiceStatus status;

  /// In cents, so sums stay exact.
  final int amount;
  final DateTime due;

  String get number => 'INV-$id';
}

const _customers = [
  'Northwind Logistics', 'Atlas Software', 'Blue Harbor Design', //
  'Evergreen Foods', 'Summit Textiles', 'Bosphorus Consulting',
  'Cedar Architecture', 'Coastal Travel', 'Harvest Farms',
  'Riverside Energy', 'Sunrise Media', 'Keystone Builders', 'Lumen Optics',
  'Marble Freight', 'Orchard Café', 'Pinewood Furniture',
  'Juniper Pharmacy', 'Westwind Sports', 'Quill Publishing',
  'Taurus Motors', 'Skyline Aviation', 'Valley Gardens',
  'Starlight Jewelers', 'Olive Branch Catering',
];

/// 236 invoices, the same on every run.
final List<Invoice> invoices = () {
  final start = DateTime(2026, 11, 30);
  return [
    for (var i = 0; i < 236; i++)
      Invoice(
        1000 + i,
        _customers[(i * 7) % _customers.length],
        InvoiceStatus.values[(i * 5 + i ~/ 3) % 3],
        // $150.00 to $24,999.00, uneven so sorting shows.
        ((i * 7919) % 2485000) + 15000,
        start.subtract(Duration(days: (i * 3) % 120)),
      ),
  ];
}();

/// [cents] as dollars: `$12,480.00`.
String money(int cents) {
  final dollars = (cents ~/ 100).toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  return '\$$dollars.${(cents % 100).toString().padLeft(2, '0')}';
}

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// [d] as `Oct 5, 2026`.
String shortDate(DateTime d) => '${_months[d.month - 1]} ${d.day}, ${d.year}';

/// A teammate in the sorting example.
typedef Person = ({String name, String city});

/// Names whose order differs between English and Turkish dictionary order.
const List<Person> team = [
  (name: 'Şahin Kaya', city: 'İzmir'),
  (name: 'Çelik Aras', city: 'Bursa'),
  (name: 'İpek Doğan', city: 'Ankara'),
  (name: 'Ozan Er', city: 'Eskişehir'),
  (name: 'Cem Yıldız', city: 'İstanbul'),
  (name: 'Irmak Su', city: 'Çanakkale'),
  (name: 'Öykü Tan', city: 'Antalya'),
  (name: 'Selin Ak', city: 'Ordu'),
  (name: 'Ilgaz Ün', city: 'Kastamonu'),
  (name: 'Ceylan Ok', city: 'Şanlıurfa'),
];
