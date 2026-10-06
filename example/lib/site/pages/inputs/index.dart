import '../../registry.dart';
import 'autocomplete_page.dart';
import 'date_picker_page.dart';
import 'field_page.dart';
import 'file_upload_page.dart';
import 'forms_page.dart';
import 'multi_select_page.dart';
import 'number_field_page.dart';
import 'search_field_page.dart';
import 'select_page.dart';
import 'text_field_page.dart';
import 'time_picker_page.dart';

/// The "Inputs" pages, in sidebar order.
final inputPages = <SitePage>[
  SitePage(
    path: '/components/field',
    title: 'Field',
    builder: (_) => const FieldPage(),
    keywords: ['DsField', 'label', 'error', 'required', 'description'],
  ),
  SitePage(
    path: '/components/text-field',
    title: 'Text field',
    builder: (_) => const TextFieldPage(),
    keywords: [
      'DsTextField',
      'input',
      'textarea',
      'password',
      'multiline',
      'magnifier',
      'loupe',
    ],
  ),
  SitePage(
    path: '/components/search-field',
    title: 'Search field',
    builder: (_) => const SearchFieldPage(),
    keywords: ['DsSearchField', 'filter', 'query', 'shortcut'],
  ),
  SitePage(
    path: '/components/number-field',
    title: 'Number field',
    builder: (_) => const NumberFieldPage(),
    keywords: ['DsNumberField', 'stepper', 'spinbutton', 'quantity'],
  ),
  SitePage(
    path: '/components/select',
    title: 'Select',
    builder: (_) => const SelectPage(),
    keywords: ['DsSelect', 'dropdown', 'picker', 'combobox'],
  ),
  SitePage(
    path: '/components/autocomplete',
    title: 'Autocomplete',
    builder: (_) => const AutocompletePage(),
    keywords: ['DsAutocomplete', 'combobox', 'typeahead', 'suggestions'],
  ),
  SitePage(
    path: '/components/multi-select',
    title: 'Multi-select',
    builder: (_) => const MultiSelectPage(),
    keywords: ['DsMultiSelect', 'tags', 'chips', 'multiple'],
  ),
  SitePage(
    path: '/components/date-picker',
    title: 'Date picker',
    builder: (_) => const DatePickerPage(),
    keywords: ['DsDatePicker', 'DsDateRangePicker', 'calendar', 'date'],
  ),
  SitePage(
    path: '/components/time-picker',
    title: 'Time picker',
    builder: (_) => const TimePickerPage(),
    keywords: ['DsTimePicker', 'time', 'clock', 'hour'],
  ),
  SitePage(
    path: '/components/file-upload',
    title: 'File upload',
    builder: (_) => const FileUploadPage(),
    keywords: ['DsFileUpload', 'drop zone', 'attachment', 'drag and drop'],
  ),
  SitePage(
    path: '/components/forms',
    title: 'Forms',
    builder: (_) => const FormsPage(),
    keywords: ['Form', 'DsFormField', 'DsValidators', 'validation'],
  ),
];
