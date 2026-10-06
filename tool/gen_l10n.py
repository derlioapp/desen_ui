"""Generates lib/src/l10n/strings/*.dart: every string Desen shows or
announces, in 13 languages and their regional variants.

English is the complete base; every other language extends it, so a key a
language does not translate falls back to English instead of failing.
A regional variant (VARIANTS: 'zh_Hant', 'pt_PT') extends its language and
overrides only the keys whose wording differs.
To add a key: add it to KEYS (with its English text) and, where known, to
the other languages and to every complete variant; then run
`python3 tool/gen_l10n.py` (it runs `dart format` on the output).

Most texts come from the earlier desen_ui project's translations.
"""
import os
import subprocess

OUT = os.path.join(os.path.dirname(__file__), '..', 'lib', 'src', 'l10n', 'strings')

# key: (doc, english). Keys with parameters ("name(int a, int b)"; a bare
# "()" means `int count`) hold a Dart expression instead of a plain string.
KEYS = {
    'close': ('Closes a dialog, panel or popover.', 'Close'),
    'cancel': ('Dismisses a dialog without acting.', 'Cancel'),
    'confirm': ('Confirms a dialog.', 'Confirm'),
    'dismiss': ('Removes a notification.', 'Dismiss'),
    'previousPage': ('Pagination: the previous page.', 'Previous page'),
    'nextPage': ('Pagination: the next page.', 'Next page'),
    'selectPlaceholder': ('A select with nothing chosen.', 'Select'),
    'selectNoResults': ('A search that matches no option.', 'No results'),
    'selectResultCount()': (
        'Announces how many options match a search.',
        "count == 1 ? '1 result' : '$count results'",
    ),
    'loading': ('Announces that content or an action is loading.', 'Loading'),
    'percent(int value)': (
        'A percentage, written the local way ("40%", "%40", "40 %").',
        "'$value%'",
    ),
    'moreCount()': (
        'Announces items hidden behind a "+N" overflow, e.g. in an avatar group.',
        "'$count more'",
    ),
    'overflowCount()': ('The visible "+N" of hidden items.', "'+$count'"),
    'countOverflow(int max)': (
        'A count capped at max, e.g. "99+" on a badge.',
        "'$max+'",
    ),
    'page(int page)': ('Pagination: a page button.', "'Page $page'"),
    'pageOf(int page, int count)': (
        'Pagination: the current position.',
        "'Page $page of $count'",
    ),
    'currentPage': ('Pagination: marks the current page.', 'Current page'),
    'pagination': ('Names a pagination control.', 'Pagination'),
    'breadcrumb': ('Names a breadcrumb trail.', 'Breadcrumb'),
    'error': ('A field or status in error.', 'Error'),
    'warning': ('A warning status.', 'Warning'),
    'success': ('A success status.', 'Success'),
    'info': ('An informational status.', 'Information'),
    'selected': ('Announces a selected item.', 'Selected'),
    'notification': ('Names a notification (toast).', 'Notification'),
    'dismissNotification': ('Closes a notification.', 'Dismiss notification'),
    'dialog': ('Names a dialog that has no title.', 'Dialog'),
    'more': ('Opens more actions, e.g. an overflow menu.', 'More'),
    'required': ('Marks a required field.', 'Required'),
    'increase': ('Increases a value, e.g. a stepper.', 'Increase'),
    'decrease': ('Decreases a value, e.g. a stepper.', 'Decrease'),
    'clear': ('Clears a field or a selection.', 'Clear'),
    'search': ('Names a search field or action.', 'Search'),
    'cut': ('Edit menu: cuts the selected text.', 'Cut'),
    'copy': ('Edit menu: copies the selected text.', 'Copy'),
    'paste': ('Edit menu: pastes the clipboard.', 'Paste'),
    'selectAll': ('Edit menu: selects all text.', 'Select all'),
    'lookUp': ('Edit menu: looks the selected word up.', 'Look up'),
    'share': ('Edit menu: shares the selected text.', 'Share'),
    'searchWeb': ('Edit menu: searches the web for the selected text.', 'Search the web'),
    'showPassword': ('Reveals a password field\'s text.', 'Show password'),
    'hidePassword': ('Hides a revealed password again.', 'Hide password'),
    'characterCount(int count, int max)': (
        'A text field\'s visible counter, e.g. "12 / 100".',
        "'$count / $max'",
    ),
    'characterCountLabel(int count, int max)': (
        'The counter as screen readers hear it, e.g. "12 of 100 characters".',
        "'$count of $max characters'",
    ),
    'charactersRemaining(int count)': (
        'Announces how many characters can still be typed.',
        "count == 1 ? '1 character left' : '$count characters left'",
    ),
    'charactersOver(int count)': (
        'How many characters are over a soft limit, e.g. "14 characters too many".',
        "count == 1 ? '1 character too many' : '$count characters too many'",
    ),
    'remove(String label)': (
        'Removes one chosen value, e.g. the remove button of a tag ("Remove Ayşe").',
        "'Remove $label'",
    ),
    'removed(String label)': (
        'Announces that a chosen value was removed, e.g. a tag by Backspace.',
        "'$label removed'",
    ),
    # 8c file/submenu
    'fileUploadPrompt(String browse)': (
        'A file drop zone\'s prompt; browse is fileUploadBrowse, shown as a link.',
        "'Drop files here or $browse'",
    ),
    'fileUploadBrowse': ('The "browse" word inside fileUploadPrompt.', 'browse'),
    'fileUploadDrop': ('A file drop zone while files are dragged over it.', 'Drop files to upload'),
    'uploading': ('A file that is uploading.', 'Uploading'),
    'uploaded(String name)': ('Announces a finished upload.', "'$name uploaded'"),
    'uploadFailed(String name)': ('Announces a failed upload.', "'$name could not be uploaded'"),
    'uploadError': ('A failed upload\'s message when the app gives none.', 'Upload failed'),
    'cancelUpload(String name)': ('Stops one file\'s upload.', "'Cancel upload of $name'"),
    'retry': ('Tries a failed action again, e.g. an upload.', 'Retry'),
    'fileProgress(String loaded, String total)': (
        'How much of a file is uploaded, e.g. "2,4 / 3,1 MB".',
        "'$loaded / $total'",
    ),
    'fileSizeUnit(int power)': (
        'The unit of a file size: power 0 is bytes, 1 kilobytes (1000 bytes), up to 4 terabytes.',
        "const ['B', 'KB', 'MB', 'GB', 'TB'][power]",
    ),
    # 8a table
    'tableSelectRow': ('Table: the checkbox that selects one row.', 'Select row'),
    'tableSelectAll': (
        'Table: the header checkbox that selects every row.',
        'Select all rows',
    ),
    'sortedAscending': (
        'Table: a column header sorted from low to high.',
        'Sorted ascending',
    ),
    'sortedDescending': (
        'Table: a column header sorted from high to low.',
        'Sorted descending',
    ),
    'tableNoResults': ('Table: there are no rows to show.', 'No results'),
    'rowCount()': (
        'Table: how many rows it holds, also those scrolled out of view.',
        "count == 1 ? '1 row' : '$count rows'",
    ),
    # Table row names
    'selectRowNamed(String name)': (
        'Table: the checkbox that selects one row, named by the row\'s first cell ("Select Kuzey Lojistik").',
        "'Select $name'",
    ),
    'sortBy': (
        'Table in the card layout: the label before the sort buttons.',
        'Sort by',
    ),
}

LANGS = {
    'ar': dict(close='إغلاق', cancel='إلغاء', confirm='تأكيد', dismiss='إغلاق',
               previousPage='الصفحة السابقة', nextPage='الصفحة التالية',
               selectPlaceholder='اختر', selectNoResults='لا توجد نتائج',
               selectResultCount="'عدد النتائج: $count'"),
    'de': dict(close='Schließen', cancel='Abbrechen', confirm='Bestätigen',
               dismiss='Schließen', previousPage='Vorherige Seite',
               nextPage='Nächste Seite', selectPlaceholder='Auswählen',
               selectNoResults='Keine Ergebnisse',
               selectResultCount="count == 1 ? '1 Ergebnis' : '$count Ergebnisse'"),
    'es': dict(close='Cerrar', cancel='Cancelar', confirm='Confirmar',
               dismiss='Descartar', previousPage='Página anterior',
               nextPage='Página siguiente', selectPlaceholder='Seleccionar',
               selectNoResults='Sin resultados',
               selectResultCount="count == 1 ? '1 resultado' : '$count resultados'"),
    'fr': dict(close='Fermer', cancel='Annuler', confirm='Confirmer',
               dismiss='Fermer', previousPage='Page précédente',
               nextPage='Page suivante', selectPlaceholder='Sélectionner',
               selectNoResults='Aucun résultat',
               selectResultCount="count <= 1 ? '$count résultat' : '$count résultats'"),
    'hi': dict(close='बंद करें', cancel='रद्द करें', confirm='पुष्टि करें',
               dismiss='खारिज करें', previousPage='पिछला पृष्ठ',
               nextPage='अगला पृष्ठ', selectPlaceholder='चुनें',
               selectNoResults='कोई परिणाम नहीं',
               selectResultCount="'$count परिणाम'"),
    'it': dict(close='Chiudi', cancel='Annulla', confirm='Conferma',
               dismiss='Chiudi', previousPage='Pagina precedente',
               nextPage='Pagina successiva', selectPlaceholder='Seleziona',
               selectNoResults='Nessun risultato',
               selectResultCount="count == 1 ? '1 risultato' : '$count risultati'"),
    'ja': dict(close='閉じる', cancel='キャンセル', confirm='確認',
               dismiss='閉じる', previousPage='前のページ', nextPage='次のページ',
               selectPlaceholder='選択', selectNoResults='結果なし',
               selectResultCount="'$count 件の結果'"),
    'ko': dict(close='닫기', cancel='취소', confirm='확인', dismiss='닫기',
               previousPage='이전 페이지', nextPage='다음 페이지',
               selectPlaceholder='선택', selectNoResults='결과 없음',
               selectResultCount="'결과 $count개'"),
    'pt': dict(close='Fechar', cancel='Cancelar', confirm='Confirmar',
               dismiss='Dispensar', previousPage='Página anterior',
               nextPage='Próxima página', selectPlaceholder='Selecionar',
               selectNoResults='Nenhum resultado',
               selectResultCount="count == 1 ? '1 resultado' : '$count resultados'"),
    'ru': dict(close='Закрыть', cancel='Отмена', confirm='Подтвердить',
               dismiss='Закрыть', previousPage='Предыдущая страница',
               nextPage='Следующая страница', selectPlaceholder='Выберите',
               selectNoResults='Нет результатов',
               # One, few, many: 1 результат, 2 результата, 5 результатов.
               selectResultCount="'$count ${count % 10 == 1 && count % 100 != 11 ? 'результат' : count % 10 >= 2 && count % 10 <= 4 && (count % 100 < 12 || count % 100 > 14) ? 'результата' : 'результатов'}'"),
    'tr': dict(close='Kapat', cancel='Vazgeç', confirm='Onayla', dismiss='Kapat',
               previousPage='Önceki sayfa', nextPage='Sonraki sayfa',
               selectPlaceholder='Seçin', selectNoResults='Sonuç yok',
               selectResultCount="'$count sonuç'"),
    'zh': dict(close='关闭', cancel='取消', confirm='确认', dismiss='关闭',
               previousPage='上一页', nextPage='下一页',
               selectPlaceholder='请选择', selectNoResults='无结果',
               selectResultCount="'$count 个结果'"),
}

# Status names, loading, paging and other announced texts. Dart
# expressions for keys with
# parameters, plain text otherwise.
NEW = {
    'ar': dict(loading='جارٍ التحميل', percent="'$value٪'",
               moreCount="'$count أخرى'", page="'الصفحة $page'",
               pageOf="'الصفحة $page من $count'", currentPage='الصفحة الحالية',
               pagination='ترقيم الصفحات', breadcrumb='مسار التنقل',
               error='خطأ', warning='تحذير', success='نجاح', info='معلومات',
               selected='محدد', notification='إشعار',
               dismissNotification='إغلاق الإشعار', dialog='مربع حوار',
               more='المزيد', required='مطلوب', increase='زيادة',
               decrease='إنقاص', clear='مسح', search='بحث'),
    'de': dict(loading='Wird geladen', percent="'$value\\u00A0%'",
               moreCount="'$count weitere'", page="'Seite $page'",
               pageOf="'Seite $page von $count'", currentPage='Aktuelle Seite',
               pagination='Seitennavigation', breadcrumb='Brotkrümelnavigation',
               error='Fehler', warning='Warnung', success='Erfolg',
               info='Information', selected='Ausgewählt',
               notification='Benachrichtigung',
               dismissNotification='Benachrichtigung schließen',
               dialog='Dialogfeld', more='Mehr', required='Erforderlich',
               increase='Erhöhen', decrease='Verringern', clear='Löschen',
               search='Suchen'),
    'es': dict(loading='Cargando', percent="'$value\\u00A0%'",
               moreCount="'$count más'", page="'Página $page'",
               pageOf="'Página $page de $count'", currentPage='Página actual',
               pagination='Paginación', breadcrumb='Ruta de navegación',
               error='Error', warning='Advertencia', success='Éxito',
               info='Información', selected='Seleccionado',
               notification='Notificación',
               dismissNotification='Descartar notificación',
               dialog='Cuadro de diálogo', more='Más', required='Obligatorio',
               increase='Aumentar', decrease='Disminuir', clear='Borrar',
               search='Buscar'),
    'fr': dict(loading='Chargement', percent="'$value\\u202F%'",
               moreCount="'$count de plus'", page="'Page $page'",
               pageOf="'Page $page sur $count'", currentPage='Page actuelle',
               pagination='Pagination', breadcrumb='Fil d’Ariane',
               error='Erreur', warning='Avertissement', success='Succès',
               info='Information', selected='Sélectionné',
               notification='Notification',
               dismissNotification='Fermer la notification',
               dialog='Boîte de dialogue', more='Plus', required='Obligatoire',
               increase='Augmenter', decrease='Diminuer', clear='Effacer',
               search='Rechercher'),
    'hi': dict(loading='लोड हो रहा है', moreCount="'$count और'",
               page="'पृष्ठ $page'", pageOf="'$count में से पृष्ठ $page'",
               currentPage='वर्तमान पृष्ठ', pagination='पृष्ठांकन',
               breadcrumb='नेविगेशन पथ', error='त्रुटि', warning='चेतावनी',
               success='सफल', info='जानकारी', selected='चयनित',
               notification='सूचना', dismissNotification='सूचना खारिज करें',
               dialog='संवाद', more='और', required='आवश्यक',
               increase='बढ़ाएँ', decrease='घटाएँ', clear='साफ़ करें',
               search='खोजें'),
    'it': dict(loading='Caricamento', moreCount="'altri $count'",
               page="'Pagina $page'", pageOf="'Pagina $page di $count'",
               currentPage='Pagina corrente', pagination='Paginazione',
               breadcrumb='Percorso di navigazione', error='Errore',
               warning='Avviso', success='Operazione riuscita',
               info='Informazioni', selected='Selezionato',
               notification='Notifica', dismissNotification='Chiudi notifica',
               dialog='Finestra di dialogo', more='Altro',
               required='Obbligatorio', increase='Aumenta',
               decrease='Diminuisci', clear='Cancella', search='Cerca'),
    'ja': dict(loading='読み込み中', moreCount="'他 $count 件'",
               page="'$page ページ'", pageOf="'$count ページ中 $page ページ'",
               currentPage='現在のページ', pagination='ページ送り',
               breadcrumb='パンくずリスト', error='エラー', warning='警告',
               success='成功', info='情報', selected='選択済み',
               notification='通知', dismissNotification='通知を閉じる',
               dialog='ダイアログ', more='その他', required='必須',
               increase='増やす', decrease='減らす', clear='クリア',
               search='検索'),
    'ko': dict(loading='로드 중', moreCount="'$count개 더'",
               page="'$page페이지'", pageOf="'$count페이지 중 $page페이지'",
               currentPage='현재 페이지', pagination='페이지 매기기',
               breadcrumb='탐색 경로', error='오류', warning='경고',
               success='성공', info='정보', selected='선택됨',
               notification='알림', dismissNotification='알림 닫기',
               dialog='대화상자', more='더보기', required='필수',
               increase='증가', decrease='감소', clear='지우기',
               search='검색'),
    'pt': dict(loading='Carregando', moreCount="'mais $count'",
               page="'Página $page'", pageOf="'Página $page de $count'",
               currentPage='Página atual', pagination='Paginação',
               breadcrumb='Trilha de navegação', error='Erro', warning='Aviso',
               success='Sucesso', info='Informação', selected='Selecionado',
               notification='Notificação',
               dismissNotification='Dispensar notificação',
               dialog='Caixa de diálogo', more='Mais', required='Obrigatório',
               increase='Aumentar', decrease='Diminuir', clear='Limpar',
               search='Pesquisar'),
    'ru': dict(loading='Загрузка', percent="'$value\\u00A0%'",
               moreCount="'ещё $count'", page="'Страница $page'",
               pageOf="'Страница $page из $count'",
               currentPage='Текущая страница', pagination='Нумерация страниц',
               breadcrumb='Навигационная цепочка', error='Ошибка',
               warning='Предупреждение', success='Успешно',
               info='Информация', selected='Выбрано',
               notification='Уведомление',
               dismissNotification='Закрыть уведомление',
               dialog='Диалоговое окно', more='Ещё', required='Обязательно',
               increase='Увеличить', decrease='Уменьшить', clear='Очистить',
               search='Поиск'),
    # Turkish puts the sign first (%40); "3. sayfa, toplam 10" reads more
    # naturally aloud than "Sayfa 3 / 10".
    'tr': dict(loading='Yükleniyor', percent="'%$value'",
               moreCount="'$count tane daha'", page="'Sayfa $page'",
               pageOf="'$page. sayfa, toplam $count'",
               currentPage='Geçerli sayfa', pagination='Sayfalama',
               breadcrumb='Gezinme yolu', error='Hata', warning='Uyarı',
               success='Başarılı', info='Bilgi', selected='Seçili',
               notification='Bildirim', dismissNotification='Bildirimi kapat',
               dialog='İletişim kutusu', more='Daha fazla',
               required='Zorunlu', increase='Artır', decrease='Azalt',
               clear='Temizle', search='Ara'),
    'zh': dict(loading='正在加载', moreCount="'还有 $count 个'",
               page="'第 $page 页'", pageOf="'第 $page 页，共 $count 页'",
               currentPage='当前页', pagination='分页',
               breadcrumb='面包屑导航', error='错误', warning='警告',
               success='成功', info='信息', selected='已选择',
               notification='通知', dismissNotification='关闭通知',
               dialog='对话框', more='更多', required='必填',
               increase='增加', decrease='减少', clear='清除',
               search='搜索'),
}
for _lang, _values in NEW.items():
    LANGS[_lang].update(_values)

# The edit menu and the text field. The visible counter
# ("12 / 100") is the same everywhere and inherited from English.
EDITING = {
    'ar': dict(cut='قص', copy='نسخ', paste='لصق', selectAll='تحديد الكل',
               lookUp='بحث عن', share='مشاركة', searchWeb='البحث في الويب',
               showPassword='إظهار كلمة المرور',
               hidePassword='إخفاء كلمة المرور',
               characterCountLabel="'عدد الأحرف: $count من $max'",
               charactersRemaining="'الأحرف المتبقية: $count'",
               charactersOver="'عدد الأحرف الزائدة: $count'"),
    'de': dict(cut='Ausschneiden', copy='Kopieren', paste='Einfügen',
               selectAll='Alles auswählen', lookUp='Nachschlagen',
               share='Teilen', searchWeb='Im Web suchen',
               showPassword='Passwort anzeigen',
               hidePassword='Passwort ausblenden',
               characterCountLabel="'$count von $max Zeichen'",
               charactersRemaining="count == 1 ? 'Noch 1 Zeichen' : 'Noch $count Zeichen'",
               charactersOver="count == 1 ? '1 Zeichen zu viel' : '$count Zeichen zu viel'"),
    'es': dict(cut='Cortar', copy='Copiar', paste='Pegar',
               selectAll='Seleccionar todo', lookUp='Consultar',
               share='Compartir', searchWeb='Buscar en la Web',
               showPassword='Mostrar contraseña',
               hidePassword='Ocultar contraseña',
               characterCountLabel="'$count de $max caracteres'",
               charactersRemaining="count == 1 ? 'Queda 1 carácter' : 'Quedan $count caracteres'",
               charactersOver="count == 1 ? '1 carácter de más' : '$count caracteres de más'"),
    'fr': dict(cut='Couper', copy='Copier', paste='Coller',
               selectAll='Tout sélectionner', lookUp='Définir',
               share='Partager', searchWeb='Rechercher sur le Web',
               showPassword='Afficher le mot de passe',
               hidePassword='Masquer le mot de passe',
               characterCountLabel="'$count caractères sur $max'",
               charactersRemaining="count <= 1 ? '$count caractère restant' : '$count caractères restants'",
               charactersOver="count <= 1 ? '$count caractère en trop' : '$count caractères en trop'"),
    'hi': dict(cut='काटें', copy='कॉपी करें', paste='चिपकाएँ',
               selectAll='सभी चुनें', lookUp='लुक अप करें', share='शेयर करें',
               searchWeb='वेब पर खोजें', showPassword='पासवर्ड दिखाएँ',
               hidePassword='पासवर्ड छिपाएँ',
               characterCountLabel="'$max में से $count वर्ण'",
               charactersRemaining="'$count वर्ण शेष'",
               charactersOver="'$count वर्ण अधिक'"),
    'it': dict(cut='Taglia', copy='Copia', paste='Incolla',
               selectAll='Seleziona tutto', lookUp='Cerca',
               share='Condividi', searchWeb='Cerca sul web',
               showPassword='Mostra password',
               hidePassword='Nascondi password',
               characterCountLabel="'$count di $max caratteri'",
               charactersRemaining="count == 1 ? '1 carattere rimanente' : '$count caratteri rimanenti'",
               charactersOver="count == 1 ? '1 carattere di troppo' : '$count caratteri di troppo'"),
    'ja': dict(cut='切り取り', copy='コピー', paste='ペースト',
               selectAll='すべてを選択', lookUp='調べる', share='共有',
               searchWeb='Web を検索', showPassword='パスワードを表示',
               hidePassword='パスワードを非表示',
               characterCountLabel="'$max 文字中 $count 文字'",
               charactersRemaining="'残り $count 文字'",
               charactersOver="'$count 文字超過'"),
    'ko': dict(cut='잘라내기', copy='복사', paste='붙여넣기',
               selectAll='전체 선택', lookUp='찾아보기', share='공유',
               searchWeb='웹 검색', showPassword='비밀번호 표시',
               hidePassword='비밀번호 숨기기',
               characterCountLabel="'$max자 중 $count자'",
               charactersRemaining="'$count자 남음'",
               charactersOver="'$count자 초과'"),
    'pt': dict(cut='Recortar', copy='Copiar', paste='Colar',
               selectAll='Selecionar tudo', lookUp='Pesquisar',
               share='Compartilhar', searchWeb='Pesquisar na Web',
               showPassword='Mostrar senha', hidePassword='Ocultar senha',
               characterCountLabel="'$count de $max caracteres'",
               charactersRemaining="count == 1 ? '1 caractere restante' : '$count caracteres restantes'",
               charactersOver="count == 1 ? '1 caractere a mais' : '$count caracteres a mais'"),
    'ru': dict(cut='Вырезать', copy='Копировать', paste='Вставить',
               selectAll='Выбрать все', lookUp='Найти', share='Поделиться',
               searchWeb='Искать в интернете',
               showPassword='Показать пароль', hidePassword='Скрыть пароль',
               # "из N": genitive singular after 1, 21, 31 ..., else plural.
               characterCountLabel="'$count из $max ${max % 10 == 1 && max % 100 != 11 ? 'символа' : 'символов'}'",
               # One, few, many: остался 1 символ, осталось 2 символа, 5 символов.
               charactersRemaining="count % 10 == 1 && count % 100 != 11 ? 'Остался $count символ' : count % 10 >= 2 && count % 10 <= 4 && (count % 100 < 12 || count % 100 > 14) ? 'Осталось $count символа' : 'Осталось $count символов'",
               charactersOver="'Лишних символов: $count'"),
    'tr': dict(cut='Kes', copy='Kopyala', paste='Yapıştır',
               selectAll='Tümünü seç', lookUp='Araştır', share='Paylaş',
               searchWeb="Web'de ara", showPassword='Parolayı göster',
               hidePassword='Parolayı gizle',
               characterCountLabel="'$count karakter, en fazla $max'",
               charactersRemaining="'$count karakter kaldı'",
               charactersOver="'$count karakter fazla'"),
    'zh': dict(cut='剪切', copy='复制', paste='粘贴', selectAll='全选',
               lookUp='查询', share='分享', searchWeb='网页搜索',
               showPassword='显示密码', hidePassword='隐藏密码',
               characterCountLabel="'已输入 $count 个字符，最多 $max 个'",
               charactersRemaining="'还可输入 $count 个字符'",
               charactersOver="'超出 $count 个字符'"),
}
for _lang, _values in EDITING.items():
    LANGS[_lang].update(_values)

# Tags of a multi-select (DsMultiSelect).
TAGS = {
    'ar': dict(remove="'إزالة $label'", removed="'تمت إزالة $label'"),
    'de': dict(remove="'$label entfernen'", removed="'$label entfernt'"),
    'es': dict(remove="'Quitar $label'", removed="'Se quitó $label'"),
    'fr': dict(remove="'Retirer $label'", removed="'Retiré : $label'"),
    'hi': dict(remove="'$label हटाएँ'", removed="'$label हटाया गया'"),
    'it': dict(remove="'Rimuovi $label'", removed="'Rimosso: $label'"),
    'ja': dict(remove="'$label を削除'", removed="'$label を削除しました'"),
    'ko': dict(remove="'$label 삭제'", removed="'$label 삭제됨'"),
    'pt': dict(remove="'Remover $label'", removed="'Removido: $label'"),
    'ru': dict(remove="'Удалить: $label'", removed="'Удалено: $label'"),
    'tr': dict(remove="'Kaldır: $label'", removed="'$label kaldırıldı'"),
    'zh': dict(remove="'移除 $label'", removed="'已移除 $label'"),
}
for _lang, _values in TAGS.items():
    LANGS[_lang].update(_values)

# Regional variants, keyed like Locale.toString() ('zh_Hant', 'pt_PT').
# Each extends `base` and overrides only what differs from it. A `complete`
# variant must list every key its base translates (the generator checks), so
# a missed key can never show the base's wording; e.g. Traditional Chinese
# must not fall back to Simplified characters. Lookup order: see
# DsLocalizations.resolve.
VARIANTS = {
    # Traditional Chinese, Taiwan usage (also chosen for zh_TW, zh_HK and
    # zh_MO without a script). Full list; keys identical to zh (取消, 警告,
    # 成功, 通知, 更多, 必填, 增加, 清除) are inherited, not repeated.
    'zh_Hant': dict(
        base='zh', name='Traditional Chinese', complete=True,
        values=dict(close='關閉', cancel='取消', confirm='確認', dismiss='關閉',
                    previousPage='上一頁', nextPage='下一頁',
                    selectPlaceholder='請選擇', selectNoResults='沒有結果',
                    selectResultCount="'$count 項結果'",
                    loading='載入中', moreCount="'還有 $count 個'",
                    page="'第 $page 頁'", pageOf="'第 $page 頁，共 $count 頁'",
                    currentPage='目前頁面', pagination='分頁',
                    breadcrumb='導覽路徑', error='錯誤', warning='警告',
                    success='成功', info='資訊', selected='已選取',
                    notification='通知', dismissNotification='關閉通知',
                    dialog='對話方塊', more='更多', required='必填',
                    increase='增加', decrease='減少', clear='清除',
                    search='搜尋', cut='剪下', copy='拷貝', paste='貼上',
                    selectAll='全選', lookUp='查詢', share='分享',
                    searchWeb='搜尋網頁', showPassword='顯示密碼',
                    hidePassword='隱藏密碼',
                    characterCountLabel="'已輸入 $count 個字元，上限 $max 個'",
                    charactersRemaining="'還可輸入 $count 個字元'",
                    charactersOver="'超出 $count 個字元'",
                    remove="'移除 $label'", removed="'已移除 $label'")),
    # `pt` is Brazilian (as in Flutter's own localizations): Carregando,
    # Próxima página, Dispensar, Trilha. European Portuguese differs in these
    # keys only; the rest is shared.
    'pt_PT': dict(
        base='pt', name='European Portuguese', complete=False,
        values=dict(dismiss='Ignorar', dismissNotification='Ignorar notificação',
                    loading='A carregar', nextPage='Página seguinte',
                    breadcrumb='Trilho de navegação', cut='Cortar',
                    lookUp='Procurar', share='Partilhar',
                    showPassword='Mostrar palavra-passe',
                    hidePassword='Ocultar palavra-passe',
                    characterCountLabel="'$count de $max carateres'",
                    charactersRemaining="count == 1 ? 'Resta 1 caráter' : 'Restam $count carateres'",
                    charactersOver="count == 1 ? '1 caráter a mais' : '$count carateres a mais'")),
}

# The file upload. The progress text
# ("2,4 / 3,1 MB") is inherited from English everywhere.
FILES = {
    'ar': dict(fileUploadPrompt="'أفلت الملفات هنا أو $browse'",
               fileUploadBrowse='تصفّح', fileUploadDrop='أفلت الملفات لرفعها',
               uploading='جارٍ الرفع', uploaded="'تم رفع $name'",
               uploadFailed="'تعذّر رفع $name'", uploadError='تعذّر الرفع',
               cancelUpload="'إلغاء رفع $name'", retry='إعادة المحاولة'),
    'de': dict(fileUploadPrompt="'Dateien hierher ziehen oder $browse'",
               fileUploadBrowse='auswählen',
               fileUploadDrop='Zum Hochladen loslassen',
               uploading='Wird hochgeladen', uploaded="'$name hochgeladen'",
               uploadFailed="'$name konnte nicht hochgeladen werden'",
               uploadError='Hochladen fehlgeschlagen',
               cancelUpload="'Hochladen von $name abbrechen'",
               retry='Erneut versuchen'),
    'es': dict(fileUploadPrompt="'Suelta archivos aquí o $browse'",
               fileUploadBrowse='selecciónalos',
               fileUploadDrop='Suelta para subir', uploading='Subiendo',
               uploaded="'$name subido'", uploadFailed="'No se pudo subir $name'",
               uploadError='Error al subir',
               cancelUpload="'Cancelar la subida de $name'", retry='Reintentar'),
    'fr': dict(fileUploadPrompt="'Déposez des fichiers ici ou $browse'",
               fileUploadBrowse='parcourez',
               fileUploadDrop='Déposez pour importer', uploading='Importation',
               uploaded="'$name importé'",
               uploadFailed='"Impossible d\'importer $name"',
               uploadError="Échec de l'importation",
               cancelUpload='"Annuler l\'importation de $name"',
               retry='Réessayer',
               # French writes bytes as octets.
               fileSizeUnit="const ['o', 'ko', 'Mo', 'Go', 'To'][power]"),
    'hi': dict(fileUploadPrompt="'फ़ाइलें यहाँ छोड़ें या $browse'",
               fileUploadBrowse='ब्राउज़ करें',
               fileUploadDrop='अपलोड करने के लिए छोड़ें',
               uploading='अपलोड हो रहा है', uploaded="'$name अपलोड हो गई'",
               uploadFailed="'$name अपलोड नहीं हो सकी'", uploadError='अपलोड विफल',
               cancelUpload="'$name का अपलोड रद्द करें'",
               retry='फिर से कोशिश करें'),
    'it': dict(fileUploadPrompt="'Trascina qui i file o $browse'",
               fileUploadBrowse='sfoglia',
               fileUploadDrop='Rilascia per caricare', uploading='Caricamento',
               uploaded="'$name caricato'",
               uploadFailed="'Impossibile caricare $name'",
               uploadError='Caricamento non riuscito',
               cancelUpload="'Annulla il caricamento di $name'", retry='Riprova'),
    'ja': dict(fileUploadPrompt="'ここにファイルをドロップするか、$browse'",
               fileUploadBrowse='ファイルを選択',
               fileUploadDrop='ドロップしてアップロード', uploading='アップロード中',
               uploaded="'$name をアップロードしました'",
               uploadFailed="'$name をアップロードできませんでした'",
               uploadError='アップロードに失敗しました',
               cancelUpload="'$name のアップロードをキャンセル'", retry='再試行'),
    'ko': dict(fileUploadPrompt="'파일을 여기에 놓거나 $browse'",
               fileUploadBrowse='찾아보기', fileUploadDrop='놓아서 업로드',
               uploading='업로드 중', uploaded="'$name 업로드됨'",
               uploadFailed="'$name 업로드할 수 없음'", uploadError='업로드 실패',
               cancelUpload="'$name 업로드 취소'", retry='다시 시도'),
    'pt': dict(fileUploadPrompt="'Solte arquivos aqui ou $browse'",
               fileUploadBrowse='procure', fileUploadDrop='Solte para enviar',
               uploading='Enviando', uploaded="'$name enviado'",
               uploadFailed="'Não foi possível enviar $name'",
               uploadError='Falha no envio',
               cancelUpload="'Cancelar o envio de $name'",
               retry='Tentar novamente'),
    'ru': dict(fileUploadPrompt="'Перетащите файлы сюда или $browse'",
               fileUploadBrowse='выберите',
               fileUploadDrop='Отпустите, чтобы загрузить', uploading='Загрузка',
               uploaded="'Файл $name загружен'",
               uploadFailed="'Не удалось загрузить $name'",
               uploadError='Ошибка загрузки',
               cancelUpload="'Отменить загрузку $name'", retry='Повторить',
               fileSizeUnit="const ['Б', 'КБ', 'МБ', 'ГБ', 'ТБ'][power]"),
    'tr': dict(fileUploadPrompt="'Dosyaları buraya bırakın ya da $browse'",
               fileUploadBrowse='seçin',
               fileUploadDrop='Yüklemek için bırakın', uploading='Yükleniyor',
               uploaded="'$name yüklendi'", uploadFailed="'$name yüklenemedi'",
               uploadError='Yüklenemedi',
               cancelUpload="'$name yüklemesini iptal et'",
               retry='Yeniden dene'),
    'zh': dict(fileUploadPrompt="'将文件拖放到此处，或$browse'",
               fileUploadBrowse='浏览', fileUploadDrop='松开即可上传',
               uploading='正在上传', uploaded="'已上传 $name'",
               uploadFailed="'无法上传 $name'", uploadError='上传失败',
               cancelUpload="'取消上传 $name'", retry='重试'),
}
for _lang, _values in FILES.items():
    LANGS[_lang].update(_values)
VARIANTS['zh_Hant']['values'].update(
    fileUploadPrompt="'將檔案拖放到此處，或$browse'", fileUploadBrowse='瀏覽',
    fileUploadDrop='放開即可上傳', uploading='正在上傳',
    uploaded="'已上傳 $name'", uploadFailed="'無法上傳 $name'",
    uploadError='上傳失敗', cancelUpload="'取消上傳 $name'", retry='重試')
VARIANTS['pt_PT']['values'].update(
    fileUploadPrompt="'Largue ficheiros aqui ou $browse'",
    fileUploadDrop='Largue para carregar', uploading='A carregar',
    uploaded="'$name carregado'",
    uploadFailed="'Não foi possível carregar $name'",
    uploadError='Falha no carregamento',
    cancelUpload="'Cancelar o carregamento de $name'")

# 8a table: DsTable.
TABLE = {
    'ar': dict(tableSelectRow='تحديد الصف', tableSelectAll='تحديد كل الصفوف',
               sortedAscending='مرتب تصاعديًا', sortedDescending='مرتب تنازليًا',
               tableNoResults='لا توجد نتائج', rowCount="'عدد الصفوف: $count'"),
    'de': dict(tableSelectRow='Zeile auswählen', tableSelectAll='Alle Zeilen auswählen',
               sortedAscending='Aufsteigend sortiert',
               sortedDescending='Absteigend sortiert',
               tableNoResults='Keine Ergebnisse',
               rowCount="count == 1 ? '1 Zeile' : '$count Zeilen'"),
    'es': dict(tableSelectRow='Seleccionar fila',
               tableSelectAll='Seleccionar todas las filas',
               sortedAscending='Orden ascendente', sortedDescending='Orden descendente',
               tableNoResults='Sin resultados',
               rowCount="count == 1 ? '1 fila' : '$count filas'"),
    'fr': dict(tableSelectRow='Sélectionner la ligne',
               tableSelectAll='Sélectionner toutes les lignes',
               sortedAscending='Tri croissant', sortedDescending='Tri décroissant',
               tableNoResults='Aucun résultat',
               rowCount="count <= 1 ? '$count ligne' : '$count lignes'"),
    'hi': dict(tableSelectRow='पंक्ति चुनें', tableSelectAll='सभी पंक्तियाँ चुनें',
               sortedAscending='आरोही क्रम में', sortedDescending='अवरोही क्रम में',
               tableNoResults='कोई परिणाम नहीं', rowCount="'$count पंक्तियाँ'"),
    'it': dict(tableSelectRow='Seleziona riga', tableSelectAll='Seleziona tutte le righe',
               sortedAscending='Ordine crescente', sortedDescending='Ordine decrescente',
               tableNoResults='Nessun risultato',
               rowCount="count == 1 ? '1 riga' : '$count righe'"),
    'ja': dict(tableSelectRow='行を選択', tableSelectAll='すべての行を選択',
               sortedAscending='昇順で並べ替え済み', sortedDescending='降順で並べ替え済み',
               tableNoResults='結果なし', rowCount="'$count 行'"),
    'ko': dict(tableSelectRow='행 선택', tableSelectAll='모든 행 선택',
               sortedAscending='오름차순 정렬됨', sortedDescending='내림차순 정렬됨',
               tableNoResults='결과 없음', rowCount="'$count개 행'"),
    'pt': dict(tableSelectRow='Selecionar linha',
               tableSelectAll='Selecionar todas as linhas',
               sortedAscending='Ordem crescente', sortedDescending='Ordem decrescente',
               tableNoResults='Nenhum resultado',
               rowCount="count == 1 ? '1 linha' : '$count linhas'"),
    'ru': dict(tableSelectRow='Выбрать строку', tableSelectAll='Выбрать все строки',
               sortedAscending='Сортировка по возрастанию',
               sortedDescending='Сортировка по убыванию',
               tableNoResults='Нет результатов',
               # One, few, many: 1 строка, 2 строки, 5 строк.
               rowCount="'$count ${count % 10 == 1 && count % 100 != 11 ? 'строка' : count % 10 >= 2 && count % 10 <= 4 && (count % 100 < 12 || count % 100 > 14) ? 'строки' : 'строк'}'"),
    'tr': dict(tableSelectRow='Satırı seç', tableSelectAll='Tüm satırları seç',
               sortedAscending='Artan sıralı', sortedDescending='Azalan sıralı',
               tableNoResults='Sonuç bulunamadı', rowCount="'$count satır'"),
    'zh': dict(tableSelectRow='选择行', tableSelectAll='选择所有行',
               sortedAscending='升序排列', sortedDescending='降序排列',
               tableNoResults='无结果', rowCount="'$count 行'"),
}
for _lang, _values in TABLE.items():
    LANGS[_lang].update(_values)
VARIANTS['zh_Hant']['values'].update(
    tableSelectRow='選取列', tableSelectAll='選取所有列',
    sortedAscending='遞增排序', sortedDescending='遞減排序',
    tableNoResults='沒有結果', rowCount="'$count 列'")

# 8b date/time: calendar and clock words for DsCalendar, DsDatePicker,
# DsDateRangePicker and DsTimePicker (CLDR). Month and weekday names are
# Dart list lookups (month 1-12; weekday 1 = Monday ... 7 = Sunday, as
# DateTime.weekday). Patterns use the CLDR letters DsDateFormat reads:
# y, M/MM (number), MMM (short name), MMMM (name in a date), LLLL (name on
# its own), d/dd, EEEE (weekday), H/HH, h, mm, a, and 'quoted' literals.
# The week's first day and the 12/24-hour default follow the region
# (dsFirstDayOfWeek, dsUses24HourClock), not these strings.
def _dl(values):
    q = ["'" + v.replace('\\', '\\\\').replace("'", "\\'") + "'" for v in values]
    return 'const [' + ', '.join(q) + ']'


def _dt_keys(month, month_in_date, month_abbr, weekday, weekday_abbr, **plain):
    return dict(monthName=_dl(month) + '[month - 1]',
                monthNameInDate=_dl(month_in_date or month) + '[month - 1]',
                monthAbbr=_dl(month_abbr) + '[month - 1]',
                weekdayName=_dl(weekday) + '[weekday - 1]',
                weekdayAbbr=_dl(weekday_abbr) + '[weekday - 1]',
                **plain)


def _num_months(unit):
    return [f'{m}{unit}' for m in range(1, 13)]


_EN_DT = _dt_keys(
    ['January', 'February', 'March', 'April', 'May', 'June', 'July',
     'August', 'September', 'October', 'November', 'December'], None,
    ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct',
     'Nov', 'Dec'],
    ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday',
     'Sunday'],
    ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'])
KEYS.update({
    'monthName(int month)': (
        'A month on its own, e.g. a calendar header ("October"); month is 1-12.',
        _EN_DT['monthName']),
    'monthNameInDate(int month)': (
        'A month inside a date ("5 October 2026"): Russian takes the genitive, French and Spanish lowercase.',
        _EN_DT['monthNameInDate']),
    'monthAbbr(int month)': ('A short month inside a date ("Oct").', _EN_DT['monthAbbr']),
    'weekdayName(int weekday)': (
        'A weekday ("Monday"); weekday is 1 (Monday) to 7 (Sunday), as DateTime.weekday.',
        _EN_DT['weekdayName']),
    'weekdayAbbr(int weekday)': ('A calendar column header ("Mo").', _EN_DT['weekdayAbbr']),
    'datePattern': ('The numeric date a date field shows and reads, in DsDateFormat letters.', 'M/d/y'),
    'dateMediumPattern': ('A date with a short month name ("Oct 5, 2026").', 'MMM d, y'),
    'dateFullPattern': ('A date as screen readers hear it ("Monday, October 5, 2026").', 'EEEE, MMMM d, y'),
    'monthYearPattern': ('A calendar header ("October 2026").', 'LLLL y'),
    'dateHint': ('The placeholder of an empty date field, showing the order to type.', 'MM/DD/YYYY'),
    'timePattern12': ('A 12-hour time ("3:05 PM"); 24-hour time is HH:mm everywhere.', 'h:mm a'),
    'am': ('Before noon in a 12-hour time.', 'AM'),
    'pm': ('After noon in a 12-hour time.', 'PM'),
    'previousMonth': ('Calendar: shows the previous month.', 'Previous month'),
    'nextMonth': ('Calendar: shows the next month.', 'Next month'),
    'chooseDate': ('Opens a calendar to choose a date.', 'Choose date'),
    'chooseTime': ('Opens a list to choose a time.', 'Choose time'),
    'today': ('Marks today in a calendar.', 'Today'),
    'hours': ('Names the hour column of a time picker.', 'Hours'),
    'minutes': ('Names the minute column of a time picker.', 'Minutes'),
    'dayPeriod': ('Names the AM/PM column of a time picker.', 'AM/PM'),
    'rangeStart': ('Marks the first day of a chosen date range.', 'Start date'),
    'rangeEnd': ('Marks the last day of a chosen date range.', 'End date'),
    'inRange': ('Marks a day inside a chosen date range.', 'In range'),
})

_ZH_MONTHS = ['一月', '二月', '三月', '四月', '五月', '六月', '七月', '八月',
              '九月', '十月', '十一月', '十二月']
_ZH_WEEKDAYS = ['星期一', '星期二', '星期三', '星期四', '星期五', '星期六', '星期日']
_ZH_WEEKDAY_ABBR = ['一', '二', '三', '四', '五', '六', '日']
_AR_MONTHS = ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو',
              'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر']

DATE_TIME = {
    'ar': _dt_keys(
        _AR_MONTHS, None, _AR_MONTHS,
        ['الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'],
        ['ن', 'ث', 'ر', 'خ', 'ج', 'س', 'ح'],
        datePattern='d‏/M‏/y', dateMediumPattern='d MMM y',
        dateFullPattern='EEEE، d MMMM y', monthYearPattern='LLLL y',
        dateHint='يوم/شهر/سنة', timePattern12='h:mm a', am='ص', pm='م',
        previousMonth='الشهر السابق', nextMonth='الشهر التالي',
        chooseDate='اختيار التاريخ', chooseTime='اختيار الوقت', today='اليوم',
        hours='الساعات', minutes='الدقائق', dayPeriod='ص/م',
        rangeStart='تاريخ البدء', rangeEnd='تاريخ الانتهاء', inRange='ضمن النطاق'),
    'de': _dt_keys(
        ['Januar', 'Februar', 'März', 'April', 'Mai', 'Juni', 'Juli',
         'August', 'September', 'Oktober', 'November', 'Dezember'], None,
        ['Jan.', 'Feb.', 'März', 'Apr.', 'Mai', 'Juni', 'Juli', 'Aug.',
         'Sept.', 'Okt.', 'Nov.', 'Dez.'],
        ['Montag', 'Dienstag', 'Mittwoch', 'Donnerstag', 'Freitag', 'Samstag',
         'Sonntag'],
        ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'],
        datePattern='dd.MM.y', dateMediumPattern='d. MMM y',
        dateFullPattern='EEEE, d. MMMM y', monthYearPattern='LLLL y',
        dateHint='TT.MM.JJJJ', timePattern12='h:mm a',
        previousMonth='Vorheriger Monat', nextMonth='Nächster Monat',
        chooseDate='Datum auswählen', chooseTime='Uhrzeit auswählen',
        today='Heute', hours='Stunden', minutes='Minuten',
        rangeStart='Startdatum', rangeEnd='Enddatum', inRange='Im Zeitraum'),
    'es': _dt_keys(
        ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio',
         'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'],
        ['enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio',
         'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'],
        ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sept',
         'oct', 'nov', 'dic'],
        ['lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado',
         'domingo'],
        ['lu', 'ma', 'mi', 'ju', 'vi', 'sá', 'do'],
        datePattern='d/M/y', dateMediumPattern='d MMM y',
        dateFullPattern="EEEE, d 'de' MMMM 'de' y",
        monthYearPattern="LLLL 'de' y", dateHint='DD/MM/AAAA',
        timePattern12='h:mm a', am='a. m.', pm='p. m.',
        previousMonth='Mes anterior', nextMonth='Mes siguiente',
        chooseDate='Elegir fecha', chooseTime='Elegir hora', today='Hoy',
        hours='Horas', minutes='Minutos', dayPeriod='a. m./p. m.',
        rangeStart='Fecha de inicio', rangeEnd='Fecha de fin',
        inRange='En el intervalo'),
    'fr': _dt_keys(
        ['Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin', 'Juillet',
         'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'],
        ['janvier', 'février', 'mars', 'avril', 'mai', 'juin', 'juillet',
         'août', 'septembre', 'octobre', 'novembre', 'décembre'],
        ['janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin', 'juil.', 'août',
         'sept.', 'oct.', 'nov.', 'déc.'],
        ['lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi',
         'dimanche'],
        ['lu', 'ma', 'me', 'je', 've', 'sa', 'di'],
        datePattern='dd/MM/y', dateMediumPattern='d MMM y',
        dateFullPattern='EEEE d MMMM y', monthYearPattern='LLLL y',
        dateHint='JJ/MM/AAAA', timePattern12='h:mm a',
        previousMonth='Mois précédent', nextMonth='Mois suivant',
        chooseDate='Choisir une date', chooseTime='Choisir une heure',
        today='Aujourd’hui', hours='Heures', minutes='Minutes',
        rangeStart='Date de début', rangeEnd='Date de fin',
        inRange='Dans la période'),
    'hi': _dt_keys(
        ['जनवरी', 'फ़रवरी', 'मार्च', 'अप्रैल', 'मई', 'जून', 'जुलाई', 'अगस्त',
         'सितंबर', 'अक्तूबर', 'नवंबर', 'दिसंबर'], None,
        ['जन॰', 'फ़र॰', 'मार्च', 'अप्रैल', 'मई', 'जून', 'जुल॰', 'अग॰', 'सित॰',
         'अक्तू॰', 'नव॰', 'दिस॰'],
        ['सोमवार', 'मंगलवार', 'बुधवार', 'गुरुवार', 'शुक्रवार', 'शनिवार', 'रविवार'],
        ['सो', 'मं', 'बु', 'गु', 'शु', 'श', 'र'],
        datePattern='d/M/y', dateMediumPattern='d MMM y',
        dateFullPattern='EEEE, d MMMM y', monthYearPattern='LLLL y',
        dateHint='DD/MM/YYYY', timePattern12='h:mm a', am='am', pm='pm',
        previousMonth='पिछला महीना', nextMonth='अगला महीना',
        chooseDate='तारीख चुनें', chooseTime='समय चुनें', today='आज',
        hours='घंटे', minutes='मिनट', dayPeriod='am/pm',
        rangeStart='आरंभ तिथि', rangeEnd='समाप्ति तिथि', inRange='सीमा में'),
    'it': _dt_keys(
        ['Gennaio', 'Febbraio', 'Marzo', 'Aprile', 'Maggio', 'Giugno',
         'Luglio', 'Agosto', 'Settembre', 'Ottobre', 'Novembre', 'Dicembre'],
        ['gennaio', 'febbraio', 'marzo', 'aprile', 'maggio', 'giugno',
         'luglio', 'agosto', 'settembre', 'ottobre', 'novembre', 'dicembre'],
        ['gen', 'feb', 'mar', 'apr', 'mag', 'giu', 'lug', 'ago', 'set', 'ott',
         'nov', 'dic'],
        ['lunedì', 'martedì', 'mercoledì', 'giovedì', 'venerdì', 'sabato',
         'domenica'],
        ['lu', 'ma', 'me', 'gi', 've', 'sa', 'do'],
        datePattern='dd/MM/y', dateMediumPattern='d MMM y',
        dateFullPattern='EEEE d MMMM y', monthYearPattern='LLLL y',
        dateHint='GG/MM/AAAA', timePattern12='h:mm a',
        previousMonth='Mese precedente', nextMonth='Mese successivo',
        chooseDate='Scegli data', chooseTime='Scegli ora', today='Oggi',
        hours='Ore', minutes='Minuti', rangeStart='Data di inizio',
        rangeEnd='Data di fine', inRange='Nell’intervallo'),
    'ja': _dt_keys(
        _num_months('月'), None, _num_months('月'),
        ['月曜日', '火曜日', '水曜日', '木曜日', '金曜日', '土曜日', '日曜日'],
        ['月', '火', '水', '木', '金', '土', '日'],
        datePattern='y/MM/dd', dateMediumPattern='y年M月d日',
        dateFullPattern='y年M月d日EEEE', monthYearPattern='y年M月',
        dateHint='YYYY/MM/DD', timePattern12='ah:mm', am='午前', pm='午後',
        previousMonth='前の月', nextMonth='次の月', chooseDate='日付を選択',
        chooseTime='時刻を選択', today='今日', hours='時', minutes='分',
        dayPeriod='午前/午後', rangeStart='開始日', rangeEnd='終了日',
        inRange='期間内'),
    'ko': _dt_keys(
        _num_months('월'), None, _num_months('월'),
        ['월요일', '화요일', '수요일', '목요일', '금요일', '토요일', '일요일'],
        ['월', '화', '수', '목', '금', '토', '일'],
        datePattern='y. M. d.', dateMediumPattern='y년 M월 d일',
        dateFullPattern='y년 M월 d일 EEEE', monthYearPattern='y년 M월',
        dateHint='YYYY. MM. DD.', timePattern12='a h:mm', am='오전', pm='오후',
        previousMonth='이전 달', nextMonth='다음 달', chooseDate='날짜 선택',
        chooseTime='시간 선택', today='오늘', hours='시', minutes='분',
        dayPeriod='오전/오후', rangeStart='시작일', rangeEnd='종료일',
        inRange='기간 내'),
    'pt': _dt_keys(
        ['Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho', 'Julho',
         'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'],
        ['janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho', 'julho',
         'agosto', 'setembro', 'outubro', 'novembro', 'dezembro'],
        ['jan.', 'fev.', 'mar.', 'abr.', 'mai.', 'jun.', 'jul.', 'ago.',
         'set.', 'out.', 'nov.', 'dez.'],
        ['segunda-feira', 'terça-feira', 'quarta-feira', 'quinta-feira',
         'sexta-feira', 'sábado', 'domingo'],
        ['seg', 'ter', 'qua', 'qui', 'sex', 'sáb', 'dom'],
        datePattern='dd/MM/y', dateMediumPattern="d 'de' MMM 'de' y",
        dateFullPattern="EEEE, d 'de' MMMM 'de' y",
        monthYearPattern="LLLL 'de' y", dateHint='DD/MM/AAAA',
        timePattern12='h:mm a', previousMonth='Mês anterior',
        nextMonth='Próximo mês', chooseDate='Escolher data',
        chooseTime='Escolher horário', today='Hoje', hours='Horas',
        minutes='Minutos', rangeStart='Data de início',
        rangeEnd='Data de término', inRange='No intervalo'),
    'ru': _dt_keys(
        ['Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь', 'Июль',
         'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь'],
        ['января', 'февраля', 'марта', 'апреля', 'мая', 'июня', 'июля',
         'августа', 'сентября', 'октября', 'ноября', 'декабря'],
        ['янв.', 'февр.', 'мар.', 'апр.', 'мая', 'июн.', 'июл.', 'авг.',
         'сент.', 'окт.', 'нояб.', 'дек.'],
        ['понедельник', 'вторник', 'среда', 'четверг', 'пятница', 'суббота',
         'воскресенье'],
        ['пн', 'вт', 'ср', 'чт', 'пт', 'сб', 'вс'],
        datePattern='dd.MM.y', dateMediumPattern="d MMM y 'г'.",
        dateFullPattern="EEEE, d MMMM y 'г'.", monthYearPattern='LLLL y',
        dateHint='ДД.ММ.ГГГГ', timePattern12='h:mm a',
        previousMonth='Предыдущий месяц', nextMonth='Следующий месяц',
        chooseDate='Выбрать дату', chooseTime='Выбрать время',
        today='Сегодня', hours='Часы', minutes='Минуты',
        rangeStart='Дата начала', rangeEnd='Дата окончания',
        inRange='В диапазоне'),
    'tr': _dt_keys(
        ['Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran', 'Temmuz',
         'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'], None,
        ['Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 'Tem', 'Ağu', 'Eyl', 'Eki',
         'Kas', 'Ara'],
        ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi',
         'Pazar'],
        ['Pt', 'Sa', 'Ça', 'Pe', 'Cu', 'Ct', 'Pz'],
        datePattern='dd.MM.y', dateMediumPattern='d MMM y',
        dateFullPattern='d MMMM y EEEE', monthYearPattern='LLLL y',
        dateHint='GG.AA.YYYY', timePattern12='a h:mm', am='ÖÖ', pm='ÖS',
        previousMonth='Önceki ay', nextMonth='Sonraki ay',
        chooseDate='Tarih seç', chooseTime='Saat seç', today='Bugün',
        hours='Saat', minutes='Dakika', dayPeriod='ÖÖ/ÖS',
        rangeStart='Başlangıç tarihi', rangeEnd='Bitiş tarihi',
        inRange='Aralıkta'),
    'zh': _dt_keys(
        _ZH_MONTHS, _num_months('月'), _num_months('月'), _ZH_WEEKDAYS,
        _ZH_WEEKDAY_ABBR,
        datePattern='y/M/d', dateMediumPattern='y年M月d日',
        dateFullPattern='y年M月d日EEEE', monthYearPattern='y年M月',
        dateHint='YYYY/MM/DD', timePattern12='ah:mm', am='上午', pm='下午',
        previousMonth='上个月', nextMonth='下个月', chooseDate='选择日期',
        chooseTime='选择时间', today='今天', hours='小时', minutes='分钟',
        dayPeriod='上午/下午', rangeStart='开始日期', rangeEnd='结束日期',
        inRange='范围内'),
}
for _lang, _values in DATE_TIME.items():
    LANGS[_lang].update(_values)
# Traditional Chinese is a complete variant: every key, identical or not.
VARIANTS['zh_Hant']['values'].update(dict(
    DATE_TIME['zh'], dateFullPattern='y年M月d日 EEEE',
    previousMonth='上個月', nextMonth='下個月', chooseDate='選擇日期',
    chooseTime='選擇時間', hours='小時', minutes='分鐘',
    rangeStart='開始日期', rangeEnd='結束日期', inRange='範圍內'))
# European Portuguese: the same calendar words, a few different nouns.
VARIANTS['pt_PT']['values'].update(dict(
    nextMonth='Mês seguinte', chooseTime='Escolher hora',
    rangeEnd='Data de fim'))

# Table: a row checkbox named by its first cell, and the card layout's
# sort label. The name cannot be inflected, so languages with cases put it
# after a colon or as a compound ("… satırını seç").
D2_TABLE = {
    'ar': dict(selectRowNamed="'تحديد $name'", sortBy='ترتيب حسب'),
    'de': dict(selectRowNamed="'$name auswählen'", sortBy='Sortieren nach'),
    'es': dict(selectRowNamed="'Seleccionar $name'", sortBy='Ordenar por'),
    'fr': dict(selectRowNamed="'Sélectionner $name'", sortBy='Trier par'),
    'hi': dict(selectRowNamed="'$name चुनें'", sortBy='इसके अनुसार क्रमबद्ध करें'),
    'it': dict(selectRowNamed="'Seleziona $name'", sortBy='Ordina per'),
    'ja': dict(selectRowNamed="'$name を選択'", sortBy='並べ替え'),
    'ko': dict(selectRowNamed="'$name 선택'", sortBy='정렬 기준'),
    'pt': dict(selectRowNamed="'Selecionar $name'", sortBy='Ordenar por'),
    'ru': dict(selectRowNamed="'Выбрать: $name'", sortBy='Сортировать по'),
    'tr': dict(selectRowNamed="'$name satırını seç'", sortBy='Sırala'),
    'zh': dict(selectRowNamed="'选择 $name'", sortBy='排序方式'),
}
for _lang, _values in D2_TABLE.items():
    LANGS[_lang].update(_values)
VARIANTS['zh_Hant']['values'].update(
    selectRowNamed="'選取 $name'", sortBy='排序方式')


# Typed fields: the messages of a date, time or number field whose typed text
# is not a value (DsInputIssue; WCAG 3.3.1 and 3.3.3). `format` is the
# field's hint ("DD.MM.YYYY"), `example` a time in the field's clock
# ("14:30", "2:30 PM"), `date`, `min` and `max` are already formatted.
KEYS.update({
    'invalidDate(String format)': (
        'A date field holds text that is not a date; format is its hint ("MM/DD/YYYY").',
        "'Enter a date as $format.'"),
    'invalidTime(String example)': (
        'A time field holds text that is not a time; example is a time in its clock ("2:30 PM").',
        "'Enter a time such as $example.'"),
    'invalidNumber': ('A number field holds text that is not a number.', 'Enter a number.'),
    'dateTooEarly(String date)': (
        'A typed date is before the first one that can be chosen.',
        "'Enter a date on or after $date.'"),
    'dateTooLate(String date)': (
        'A typed date is after the last one that can be chosen.',
        "'Enter a date on or before $date.'"),
    'dateUnavailable': ('A typed date is in range but cannot be chosen.', 'This date can’t be chosen.'),
    'numberTooSmall(String min)': (
        'A typed number is under the minimum.', "'Enter $min or more.'"),
    'numberTooLarge(String max)': (
        'A typed number is over the maximum.', "'Enter $max or less.'"),
})
D2_FIELDS = {
    'ar': dict(invalidDate="'أدخل تاريخًا بالتنسيق $format.'",
               invalidTime="'أدخل وقتًا مثل $example.'",
               invalidNumber='أدخل رقمًا.',
               dateTooEarly="'أدخل تاريخ $date أو تاريخًا بعده.'",
               dateTooLate="'أدخل تاريخ $date أو تاريخًا قبله.'",
               dateUnavailable='لا يمكن اختيار هذا التاريخ.',
               numberTooSmall="'أدخل $min أو أكثر.'",
               numberTooLarge="'أدخل $max أو أقل.'"),
    'de': dict(invalidDate="'Geben Sie ein Datum im Format $format ein.'",
               invalidTime="'Geben Sie eine Uhrzeit wie $example ein.'",
               invalidNumber='Geben Sie eine Zahl ein.',
               dateTooEarly="'Geben Sie den $date oder ein späteres Datum ein.'",
               dateTooLate="'Geben Sie den $date oder ein früheres Datum ein.'",
               dateUnavailable='Dieses Datum kann nicht gewählt werden.',
               numberTooSmall="'Geben Sie $min oder mehr ein.'",
               numberTooLarge="'Geben Sie $max oder weniger ein.'"),
    'es': dict(invalidDate="'Introduce una fecha con el formato $format.'",
               invalidTime="'Introduce una hora como $example.'",
               invalidNumber='Introduce un número.',
               dateTooEarly="'Introduce el $date o una fecha posterior.'",
               dateTooLate="'Introduce el $date o una fecha anterior.'",
               dateUnavailable='No se puede elegir esta fecha.',
               numberTooSmall="'Introduce $min o más.'",
               numberTooLarge="'Introduce $max o menos.'"),
    'fr': dict(invalidDate="'Saisissez une date au format $format.'",
               invalidTime="'Saisissez une heure comme $example.'",
               invalidNumber='Saisissez un nombre.',
               dateTooEarly="'Saisissez le $date ou une date ultérieure.'",
               dateTooLate="'Saisissez le $date ou une date antérieure.'",
               dateUnavailable='Cette date ne peut pas être choisie.',
               numberTooSmall="'Saisissez $min ou plus.'",
               numberTooLarge="'Saisissez $max ou moins.'"),
    'hi': dict(invalidDate="'तारीख $format प्रारूप में दर्ज करें।'",
               invalidTime="'समय $example की तरह दर्ज करें।'",
               invalidNumber='कोई संख्या दर्ज करें।',
               dateTooEarly="'$date या उसके बाद की तारीख दर्ज करें।'",
               dateTooLate="'$date या उससे पहले की तारीख दर्ज करें।'",
               dateUnavailable='यह तारीख नहीं चुनी जा सकती।',
               numberTooSmall="'$min या उससे अधिक दर्ज करें।'",
               numberTooLarge="'$max या उससे कम दर्ज करें।'"),
    'it': dict(invalidDate="'Inserisci una data nel formato $format.'",
               invalidTime="'Inserisci un orario come $example.'",
               invalidNumber='Inserisci un numero.',
               dateTooEarly="'Inserisci il $date o una data successiva.'",
               dateTooLate="'Inserisci il $date o una data precedente.'",
               dateUnavailable='Questa data non può essere scelta.',
               numberTooSmall="'Inserisci $min o più.'",
               numberTooLarge="'Inserisci $max o meno.'"),
    'ja': dict(invalidDate="'日付を $format の形式で入力してください。'",
               invalidTime="'時刻を $example のように入力してください。'",
               invalidNumber='数値を入力してください。',
               dateTooEarly="'$date 以降の日付を入力してください。'",
               dateTooLate="'$date 以前の日付を入力してください。'",
               dateUnavailable='この日付は選択できません。',
               numberTooSmall="'$min 以上の数値を入力してください。'",
               numberTooLarge="'$max 以下の数値を入力してください。'"),
    'ko': dict(invalidDate="'날짜를 $format 형식으로 입력하세요.'",
               invalidTime="'시간을 $example 형식으로 입력하세요.'",
               invalidNumber='숫자를 입력하세요.',
               dateTooEarly="'$date 이후의 날짜를 입력하세요.'",
               dateTooLate="'$date 이전의 날짜를 입력하세요.'",
               dateUnavailable='이 날짜는 선택할 수 없습니다.',
               numberTooSmall="'$min 이상의 숫자를 입력하세요.'",
               numberTooLarge="'$max 이하의 숫자를 입력하세요.'"),
    'pt': dict(invalidDate="'Digite uma data no formato $format.'",
               invalidTime="'Digite um horário como $example.'",
               invalidNumber='Digite um número.',
               dateTooEarly="'Digite $date ou uma data posterior.'",
               dateTooLate="'Digite $date ou uma data anterior.'",
               dateUnavailable='Esta data não pode ser escolhida.',
               numberTooSmall="'Digite $min ou mais.'",
               numberTooLarge="'Digite $max ou menos.'"),
    'ru': dict(invalidDate="'Введите дату в формате $format.'",
               invalidTime="'Введите время, например $example.'",
               invalidNumber='Введите число.',
               dateTooEarly="'Введите дату не раньше $date.'",
               dateTooLate="'Введите дату не позже $date.'",
               dateUnavailable='Эту дату нельзя выбрать.',
               numberTooSmall="'Введите число не меньше $min.'",
               numberTooLarge="'Введите число не больше $max.'"),
    'tr': dict(invalidDate="'Tarihi $format biçiminde girin.'",
               invalidTime="'Saati $example gibi girin.'",
               invalidNumber='Bir sayı girin.',
               dateTooEarly="'$date ya da sonraki bir tarih girin.'",
               dateTooLate="'$date ya da önceki bir tarih girin.'",
               dateUnavailable='Bu tarih seçilemez.',
               numberTooSmall="'$min ya da daha büyük bir sayı girin.'",
               numberTooLarge="'$max ya da daha küçük bir sayı girin.'"),
    'zh': dict(invalidDate="'请按 $format 格式输入日期。'",
               invalidTime="'请输入时间，例如 $example。'",
               invalidNumber='请输入数字。',
               dateTooEarly="'请输入 $date 或之后的日期。'",
               dateTooLate="'请输入 $date 或之前的日期。'",
               dateUnavailable='无法选择此日期。',
               numberTooSmall="'请输入不小于 $min 的数字。'",
               numberTooLarge="'请输入不大于 $max 的数字。'"),
}
for _lang, _values in D2_FIELDS.items():
    LANGS[_lang].update(_values)
VARIANTS['zh_Hant']['values'].update(
    invalidDate="'請按 $format 格式輸入日期。'",
    invalidTime="'請輸入時間，例如 $example。'",
    invalidNumber='請輸入數字。',
    dateTooEarly="'請輸入 $date 或之後的日期。'",
    dateTooLate="'請輸入 $date 或之前的日期。'",
    dateUnavailable='無法選擇此日期。',
    numberTooSmall="'請輸入不小於 $min 的數字。'",
    numberTooLarge="'請輸入不大於 $max 的數字。'")
# European Portuguese: "introduza" where Brazil says "digite"; "hora" for
# a time of day.
VARIANTS['pt_PT']['values'].update(
    invalidDate="'Introduza uma data no formato $format.'",
    invalidTime="'Introduza uma hora como $example.'",
    invalidNumber='Introduza um número.',
    dateTooEarly="'Introduza $date ou uma data posterior.'",
    dateTooLate="'Introduza $date ou uma data anterior.'",
    numberTooSmall="'Introduza $min ou mais.'",
    numberTooLarge="'Introduza $max ou menos.'")

# Forms: the messages of DsValidators (DsFormField). They say how to fix
# the value (WCAG 3.3.3), as the typed field messages do. Counts are
# characters as people count them (grapheme clusters); languages without
# a plural form, or with cases (ar, ru), avoid inflecting the noun or
# pick the genitive the phrase needs.
KEYS.update({
    'fieldRequired': ('A required form field is empty (DsValidators.required).',
                      'This field is required.'),
    'textTooShort(int min)': (
        'A text is shorter than its minimum length, in characters.',
        "min == 1 ? 'Enter at least 1 character.' : 'Enter at least $min characters.'"),
    'textTooLong(int max)': (
        'A text is longer than its maximum length, in characters.',
        "max == 1 ? 'Enter at most 1 character.' : 'Enter at most $max characters.'"),
    'invalidEmail': ('A text is not an email address (DsValidators.email).',
                     'Enter an email address such as name@example.com.'),
})
FORMS = {
    'ar': dict(fieldRequired='هذا الحقل مطلوب.',
               textTooShort="'الحد الأدنى لعدد الأحرف: $min.'",
               textTooLong="'الحد الأقصى لعدد الأحرف: $max.'",
               invalidEmail='أدخل عنوان بريد إلكتروني مثل name@example.com.'),
    'de': dict(fieldRequired='Dieses Feld ist erforderlich.',
               textTooShort="'Geben Sie mindestens $min Zeichen ein.'",
               textTooLong="'Geben Sie höchstens $max Zeichen ein.'",
               invalidEmail='Geben Sie eine E-Mail-Adresse wie name@example.com ein.'),
    'es': dict(fieldRequired='Este campo es obligatorio.',
               textTooShort="min == 1 ? 'Introduce al menos 1 carácter.' : 'Introduce al menos $min caracteres.'",
               textTooLong="max == 1 ? 'Introduce como máximo 1 carácter.' : 'Introduce como máximo $max caracteres.'",
               invalidEmail='Introduce una dirección de correo como name@example.com.'),
    'fr': dict(fieldRequired='Ce champ est obligatoire.',
               textTooShort="min <= 1 ? 'Saisissez au moins $min caractère.' : 'Saisissez au moins $min caractères.'",
               textTooLong="max <= 1 ? 'Saisissez au plus $max caractère.' : 'Saisissez au plus $max caractères.'",
               invalidEmail='Saisissez une adresse e-mail comme name@example.com.'),
    'hi': dict(fieldRequired='यह फ़ील्ड आवश्यक है।',
               textTooShort="'कम से कम $min वर्ण दर्ज करें।'",
               textTooLong="'अधिकतम $max वर्ण दर्ज करें।'",
               invalidEmail='name@example.com जैसा ईमेल पता दर्ज करें।'),
    'it': dict(fieldRequired='Questo campo è obbligatorio.',
               textTooShort="min == 1 ? 'Inserisci almeno 1 carattere.' : 'Inserisci almeno $min caratteri.'",
               textTooLong="max == 1 ? 'Inserisci al massimo 1 carattere.' : 'Inserisci al massimo $max caratteri.'",
               invalidEmail='Inserisci un indirizzo email come name@example.com.'),
    'ja': dict(fieldRequired='この項目は必須です。',
               textTooShort="'$min 文字以上で入力してください。'",
               textTooLong="'$max 文字以内で入力してください。'",
               invalidEmail='name@example.com のようなメールアドレスを入力してください。'),
    'ko': dict(fieldRequired='필수 항목입니다.',
               textTooShort="'$min자 이상 입력하세요.'",
               textTooLong="'$max자 이하로 입력하세요.'",
               invalidEmail='name@example.com 형식의 이메일 주소를 입력하세요.'),
    'pt': dict(fieldRequired='Este campo é obrigatório.',
               textTooShort="min == 1 ? 'Digite pelo menos 1 caractere.' : 'Digite pelo menos $min caracteres.'",
               textTooLong="max == 1 ? 'Digite no máximo 1 caractere.' : 'Digite no máximo $max caracteres.'",
               invalidEmail='Digite um endereço de e-mail como name@example.com.'),
    # "Не меньше / не больше N" takes the genitive: 1 символа (21, 31 ...),
    # else символов.
    'ru': dict(fieldRequired='Это поле обязательно.',
               textTooShort="'Введите не меньше $min ${min % 10 == 1 && min % 100 != 11 ? 'символа' : 'символов'}.'",
               textTooLong="'Введите не больше $max ${max % 10 == 1 && max % 100 != 11 ? 'символа' : 'символов'}.'",
               invalidEmail='Введите адрес электронной почты, например name@example.com.'),
    'tr': dict(fieldRequired='Bu alan zorunludur.',
               textTooShort="'En az $min karakter girin.'",
               textTooLong="'En fazla $max karakter girin.'",
               invalidEmail='name@example.com gibi bir e-posta adresi girin.'),
    'zh': dict(fieldRequired='此字段为必填项。',
               textTooShort="'请至少输入 $min 个字符。'",
               textTooLong="'最多可输入 $max 个字符。'",
               invalidEmail='请输入电子邮件地址，例如 name@example.com。'),
}
for _lang, _values in FORMS.items():
    LANGS[_lang].update(_values)
VARIANTS['zh_Hant']['values'].update(
    fieldRequired='此欄位為必填。',
    textTooShort="'請至少輸入 $min 個字元。'",
    textTooLong="'最多可輸入 $max 個字元。'",
    invalidEmail='請輸入電子郵件地址，例如 name@example.com。')
# European Portuguese: "introduza", "caráter"/"carateres" (AO 1990).
VARIANTS['pt_PT']['values'].update(
    textTooShort="min == 1 ? 'Introduza pelo menos 1 caráter.' : 'Introduza pelo menos $min carateres.'",
    textTooLong="max == 1 ? 'Introduza no máximo 1 caráter.' : 'Introduza no máximo $max carateres.'",
    invalidEmail='Introduza um endereço de email como name@example.com.')

# Autocomplete with free text (onCustom): the popup row that offers the
# typed text as the value when no option matches. Each language quotes it
# its own way.
KEYS.update({
    'useCustom(String text)': (
        'Offers typed text that matches no option as the value, in an autocomplete that takes free text.',
        "'Use “$text”'"),
})
CUSTOM = {
    'ar': "'استخدام «$text»'",
    'de': "'„$text“ verwenden'",
    'es': "'Usar «$text»'",
    'fr': "'Utiliser « $text »'",
    'hi': "'“$text” का उपयोग करें'",
    'it': "'Usa “$text”'",
    'ja': "'「$text」を使用'",
    'ko': "'“$text” 사용'",
    'pt': "'Usar “$text”'",
    'ru': "'Использовать «$text»'",
    'tr': "'“$text” kullan'",
    'zh': "'使用“$text”'",
}
for _lang, _value in CUSTOM.items():
    LANGS[_lang].update(useCustom=_value)
VARIANTS['zh_Hant']['values'].update(useCustom="'使用「$text」'")
# LIB-2: the file item's retry button named with the file, avatar presence
# (announced with the name, e.g. "Ayşe Kaya, Online"), the breadcrumb's
# collapsed-levels button, and the table's row actions column.
KEYS.update({
    'retryUpload(String name)': ('Uploads one failed file again.', "'Retry upload of $name'"),
    'presenceOnline': ('An avatar status: the person is online.', 'Online'),
    'presenceAway': ('An avatar status: the person is away.', 'Away'),
    'presenceBusy': ('An avatar status: the person is busy (do not disturb).', 'Busy'),
    'presenceOffline': ('An avatar status: the person is offline.', 'Offline'),
    'breadcrumbMore': ('Breadcrumb: the "…" button listing the levels collapsed to fit.', 'More levels'),
    'rowActions': ('Table: names the column of row action buttons.', 'Actions'),
    'rowActionsFor(String name)': ('Table: a row\'s actions button, with the row\'s name.', "'Actions for $name'"),
})
LIB2 = {
    'ar': dict(retryUpload="'إعادة رفع $name'", presenceOnline='متصل',
               presenceAway='بعيد', presenceBusy='مشغول', presenceOffline='غير متصل',
               breadcrumbMore='مستويات أخرى', rowActions='الإجراءات',
               rowActionsFor="'إجراءات $name'"),
    'de': dict(retryUpload="'Hochladen von $name wiederholen'", presenceOnline='Online',
               presenceAway='Abwesend', presenceBusy='Beschäftigt', presenceOffline='Offline',
               breadcrumbMore='Weitere Ebenen', rowActions='Aktionen',
               rowActionsFor="'Aktionen für $name'"),
    'es': dict(retryUpload="'Reintentar la subida de $name'", presenceOnline='En línea',
               presenceAway='Ausente', presenceBusy='Ocupado', presenceOffline='Desconectado',
               breadcrumbMore='Más niveles', rowActions='Acciones',
               rowActionsFor="'Acciones de $name'"),
    'fr': dict(retryUpload='"Réessayer l\'importation de $name"', presenceOnline='En ligne',
               presenceAway='Absent', presenceBusy='Occupé', presenceOffline='Hors ligne',
               breadcrumbMore='Autres niveaux', rowActions='Actions',
               rowActionsFor="'Actions pour $name'"),
    'hi': dict(retryUpload="'$name को फिर से अपलोड करें'", presenceOnline='ऑनलाइन',
               presenceAway='दूर', presenceBusy='व्यस्त', presenceOffline='ऑफ़लाइन',
               breadcrumbMore='और स्तर', rowActions='कार्रवाइयाँ',
               rowActionsFor="'$name के लिए कार्रवाइयाँ'"),
    'it': dict(retryUpload="'Riprova il caricamento di $name'", presenceOnline='Online',
               presenceAway='Assente', presenceBusy='Occupato', presenceOffline='Offline',
               breadcrumbMore='Altri livelli', rowActions='Azioni',
               rowActionsFor="'Azioni per $name'"),
    'ja': dict(retryUpload="'$name のアップロードを再試行'", presenceOnline='オンライン',
               presenceAway='退席中', presenceBusy='取り込み中', presenceOffline='オフライン',
               breadcrumbMore='その他の階層', rowActions='操作',
               rowActionsFor="'$name の操作'"),
    'ko': dict(retryUpload="'$name 업로드 다시 시도'", presenceOnline='온라인',
               presenceAway='자리 비움', presenceBusy='다른 용무 중', presenceOffline='오프라인',
               breadcrumbMore='상위 경로 더보기', rowActions='작업',
               rowActionsFor="'$name 작업'"),
    'pt': dict(retryUpload="'Tentar enviar $name novamente'", presenceOnline='Online',
               presenceAway='Ausente', presenceBusy='Ocupado', presenceOffline='Offline',
               breadcrumbMore='Mais níveis', rowActions='Ações',
               rowActionsFor="'Ações de $name'"),
    'ru': dict(retryUpload="'Повторить загрузку $name'", presenceOnline='В сети',
               presenceAway='Отошёл', presenceBusy='Занят', presenceOffline='Не в сети',
               breadcrumbMore='Другие уровни', rowActions='Действия',
               rowActionsFor="'Действия: $name'"),
    'tr': dict(retryUpload="'$name yüklemesini yeniden dene'", presenceOnline='Çevrimiçi',
               presenceAway='Uzakta', presenceBusy='Meşgul', presenceOffline='Çevrimdışı',
               breadcrumbMore='Diğer düzeyler', rowActions='İşlemler',
               rowActionsFor="'$name işlemleri'"),
    'zh': dict(retryUpload="'重试上传 $name'", presenceOnline='在线',
               presenceAway='离开', presenceBusy='忙碌', presenceOffline='离线',
               breadcrumbMore='更多层级', rowActions='操作',
               rowActionsFor="'$name 的操作'"),
}
for _lang, _values in LIB2.items():
    LANGS[_lang].update(_values)
VARIANTS['zh_Hant']['values'].update(
    retryUpload="'重試上傳 $name'", presenceOnline='線上', presenceAway='離開',
    presenceBusy='忙碌', presenceOffline='離線', breadcrumbMore='更多層級',
    rowActions='操作', rowActionsFor="'$name 的操作'")
VARIANTS['pt_PT']['values'].update(
    retryUpload="'Tentar carregar $name novamente'")

# The compact pager's visible position ("3 / 10"), like the text field's
# counter: the same everywhere and inherited from English. Screen readers
# hear pageOf instead.
KEYS.update({
    'pageCounter(int page, int count)': (
        'Pagination: the compact pager\'s visible position, e.g. "3 / 10".',
        "'$page / $count'",
    ),
})

# The edit menu's other platform actions: Delete (Android, macOS) and Live
# Text (iOS "Scan Text", Android "Scan text"), worded as Apple and Android
# do in each language. editAction names an app's own menu item that came
# without a label, so its button is never blank.
KEYS.update({
    'delete': ('Edit menu: deletes the selected text.', 'Delete'),
    'scanText': ('Edit menu: Live Text, types in text the camera reads.', 'Scan text'),
    'editAction': ("Edit menu: an app's own action that came without a label.", 'Action'),
})
EDIT_MORE = {
    'ar': dict(delete='حذف', scanText='مسح النص ضوئيًا', editAction='إجراء'),
    'de': dict(delete='Löschen', scanText='Text scannen', editAction='Aktion'),
    'es': dict(delete='Eliminar', scanText='Escanear texto', editAction='Acción'),
    'fr': dict(delete='Supprimer', scanText='Scanner du texte', editAction='Action'),
    'hi': dict(delete='मिटाएँ', scanText='टेक्स्ट स्कैन करें', editAction='कार्रवाई'),
    'it': dict(delete='Elimina', scanText='Scansiona testo', editAction='Azione'),
    'ja': dict(delete='削除', scanText='テキストをスキャン', editAction='操作'),
    'ko': dict(delete='삭제', scanText='텍스트 스캔', editAction='작업'),
    'pt': dict(delete='Excluir', scanText='Escanear texto', editAction='Ação'),
    'ru': dict(delete='Удалить', scanText='Сканировать текст', editAction='Действие'),
    'tr': dict(delete='Sil', scanText='Metni tara', editAction='İşlem'),
    'zh': dict(delete='删除', scanText='扫描文本', editAction='操作'),
}
for _lang, _values in EDIT_MORE.items():
    LANGS[_lang].update(_values)
VARIANTS['zh_Hant']['values'].update(delete='刪除', scanText='掃描文字', editAction='操作')
VARIANTS['pt_PT']['values'].update(delete='Eliminar', scanText='Digitalizar texto')

# DsImage: names a picture that could not be loaded, in place of the
# picture's own label.
KEYS.update({
    'imageUnavailable': ('An image that could not be loaded.', 'Image unavailable'),
})
IMAGE = {
    'ar': dict(imageUnavailable='الصورة غير متوفرة'),
    'de': dict(imageUnavailable='Bild nicht verfügbar'),
    'es': dict(imageUnavailable='Imagen no disponible'),
    'fr': dict(imageUnavailable='Image indisponible'),
    'hi': dict(imageUnavailable='छवि उपलब्ध नहीं'),
    'it': dict(imageUnavailable='Immagine non disponibile'),
    'ja': dict(imageUnavailable='画像を読み込めません'),
    'ko': dict(imageUnavailable='이미지를 불러올 수 없음'),
    'pt': dict(imageUnavailable='Imagem indisponível'),
    'ru': dict(imageUnavailable='Изображение недоступно'),
    'tr': dict(imageUnavailable='Görsel yüklenemedi'),
    'zh': dict(imageUnavailable='图片无法加载'),
}
for _lang, _values in IMAGE.items():
    LANGS[_lang].update(_values)
VARIANTS['zh_Hant']['values'].update(imageUnavailable='圖片無法載入')

# A tab's place among its siblings, announced after its name on iOS and
# Android, where nothing else says it (on the web the tab role does): the
# tabs of a tab bar. Bottom navigation destinations are buttons and use
# the neutral positionOf instead.
KEYS.update({
    'tabOf(int index, int count)': (
        'A tab\'s position, announced after its name ("Home, Tab 2 of 4"); index counts from 1.',
        "'Tab $index of $count'",
    ),
})
TABS = {
    'ar': dict(tabOf="'علامة التبويب $index من $count'"),
    'de': dict(tabOf="'Tab $index von $count'"),
    'es': dict(tabOf="'Pestaña $index de $count'"),
    'fr': dict(tabOf="'Onglet $index sur $count'"),
    'hi': dict(tabOf="'$count में से टैब $index'"),
    'it': dict(tabOf="'Scheda $index di $count'"),
    'ja': dict(tabOf="'タブ: $index/$count'"),
    'ko': dict(tabOf="'탭 $count개 중 $index번째'"),
    'pt': dict(tabOf="'Guia $index de $count'"),
    'ru': dict(tabOf="'Вкладка $index из $count'"),
    'tr': dict(tabOf="'$index. sekme, toplam $count'"),
    'zh': dict(tabOf="'第 $index 个标签，共 $count 个'"),
}
for _lang, _values in TABS.items():
    LANGS[_lang].update(_values)
VARIANTS['zh_Hant']['values'].update(tabOf="'第 $index 個分頁，共 $count 個'")
VARIANTS['pt_PT']['values'].update(tabOf="'Separador $index de $count'")

# Names a navigation landmark that the app leaves unnamed: the bottom
# navigation.
KEYS.update({
    'navigation': ('Names a navigation bar, e.g. the bottom navigation.', 'Navigation'),
})
NAVIGATION = {
    'ar': dict(navigation='التنقل'),
    'de': dict(navigation='Navigation'),
    'es': dict(navigation='Navegación'),
    'fr': dict(navigation='Navigation'),
    'hi': dict(navigation='नेविगेशन'),
    'it': dict(navigation='Navigazione'),
    'ja': dict(navigation='ナビゲーション'),
    'ko': dict(navigation='탐색'),
    'pt': dict(navigation='Navegação'),
    'ru': dict(navigation='Навигация'),
    'tr': dict(navigation='Gezinme'),
    'zh': dict(navigation='导航'),
}
for _lang, _values in NAVIGATION.items():
    LANGS[_lang].update(_values)
VARIANTS['zh_Hant']['values'].update(navigation='導覽')

# A number field's text that reads two ways: "1.234" in German with three
# fraction digits is a thousand or a decimal. `grouped` and `decimal` are
# the two readings, written in the field's format so each reads one way
# ("1.234,000", "1,234").
KEYS.update({
    'numberAmbiguous(String grouped, String decimal)': (
        'A typed number reads two ways; grouped and decimal are both readings, already formatted.',
        "'Enter $grouped or $decimal.'"),
})
NUMBER_AMBIGUOUS = {
    'ar': "'أدخل $grouped أو $decimal.'",
    'de': "'Geben Sie $grouped oder $decimal ein.'",
    'es': "'Introduce $grouped o $decimal.'",
    'fr': "'Saisissez $grouped ou $decimal.'",
    'hi': "'$grouped या $decimal दर्ज करें।'",
    'it': "'Inserisci $grouped o $decimal.'",
    'ja': "'$grouped または $decimal と入力してください。'",
    'ko': "'$grouped 또는 $decimal 중 하나를 입력하세요.'",
    'pt': "'Digite $grouped ou $decimal.'",
    'ru': "'Введите $grouped или $decimal.'",
    'tr': "'$grouped ya da $decimal girin.'",
    'zh': "'请输入 $grouped 或 $decimal。'",
}
for _lang, _value in NUMBER_AMBIGUOUS.items():
    LANGS[_lang].update(numberAmbiguous=_value)
VARIANTS['zh_Hant']['values'].update(numberAmbiguous="'請輸入 $grouped 或 $decimal。'")
VARIANTS['pt_PT']['values'].update(numberAmbiguous="'Introduza $grouped ou $decimal.'")

# Key names for shortcut hints ("⌘E" is read "Command E"): the symbols
# a hint draws as icons, plus ⌃.
KEYS.update({
    'keyCommand': ('A shortcut\'s ⌘ key, as screen readers hear it.', 'Command'),
    'keyOption': ('A shortcut\'s ⌥ key, as screen readers hear it.', 'Option'),
    'keyShift': ('A shortcut\'s ⇧ key, as screen readers hear it.', 'Shift'),
    'keyControl': ('A shortcut\'s ⌃ key, as screen readers hear it.', 'Control'),
    'keyBackspace': ('A shortcut\'s ⌫ key, as screen readers hear it.', 'Backspace'),
    'keyEnter': ('A shortcut\'s ⏎ key, as screen readers hear it.', 'Enter'),
})
SHORTCUT_KEYS = {
    'ar': dict(keyCommand='الأوامر', keyOption='الخيارات', keyShift='العالي',
               keyControl='التحكم', keyBackspace='مسافة للخلف', keyEnter='إدخال'),
    'de': dict(keyCommand='Befehl', keyOption='Wahl', keyShift='Umschalt',
               keyControl='Steuerung', keyBackspace='Rücktaste', keyEnter='Eingabe'),
    'es': dict(keyCommand='Comando', keyOption='Opción', keyShift='Mayúsculas',
               keyControl='Control', keyBackspace='Retroceso', keyEnter='Intro'),
    'fr': dict(keyCommand='Commande', keyOption='Option', keyShift='Maj',
               keyControl='Contrôle', keyBackspace='Retour arrière', keyEnter='Entrée'),
    'hi': dict(keyCommand='कमांड', keyOption='ऑप्शन', keyShift='शिफ़्ट',
               keyControl='कंट्रोल', keyBackspace='बैकस्पेस', keyEnter='एंटर'),
    'it': dict(keyCommand='Comando', keyOption='Opzione', keyShift='Maiuscole',
               keyControl='Controllo', keyBackspace='Backspace', keyEnter='Invio'),
    'ja': dict(keyCommand='コマンド', keyOption='オプション', keyShift='シフト',
               keyControl='コントロール', keyBackspace='バックスペース', keyEnter='エンター'),
    'ko': dict(keyCommand='커맨드', keyOption='옵션', keyShift='시프트',
               keyControl='컨트롤', keyBackspace='백스페이스', keyEnter='엔터'),
    'pt': dict(keyCommand='Comando', keyOption='Opção', keyShift='Shift',
               keyControl='Control', keyBackspace='Backspace', keyEnter='Enter'),
    'ru': dict(keyCommand='Command', keyOption='Option', keyShift='Shift',
               keyControl='Control', keyBackspace='Backspace', keyEnter='Ввод'),
    'tr': dict(keyCommand='Komut', keyOption='Seçenek', keyShift='Üst Karakter',
               keyControl='Kontrol', keyBackspace='Geri Silme', keyEnter='Enter'),
    'zh': dict(keyCommand='命令', keyOption='选项', keyShift='上档',
               keyControl='控制', keyBackspace='退格', keyEnter='回车'),
}
for _lang, _values in SHORTCUT_KEYS.items():
    LANGS[_lang].update(_values)
VARIANTS['zh_Hant']['values'].update(
    keyCommand='命令', keyOption='選項', keyShift='Shift', keyControl='控制',
    keyBackspace='退格', keyEnter='輸入')

# A place among siblings where no role says it, read after the name: a
# bottom navigation destination (a button, not a tab).
KEYS.update({
    'positionOf(int index, int count)': (
        'An item\'s position among its siblings, read after its name ("Home, 2 of 4"); index counts from 1.',
        "'$index of $count'",
    ),
})
POSITION = {
    'ar': dict(positionOf="'$index من $count'"),
    'de': dict(positionOf="'$index von $count'"),
    'es': dict(positionOf="'$index de $count'"),
    'fr': dict(positionOf="'$index sur $count'"),
    'hi': dict(positionOf="'$count में से $index'"),
    'it': dict(positionOf="'$index di $count'"),
    'ja': dict(positionOf="'$index/$count'"),
    'ko': dict(positionOf="'$count개 중 $index번째'"),
    'pt': dict(positionOf="'$index de $count'"),
    'ru': dict(positionOf="'$index из $count'"),
    'tr': dict(positionOf="'$index, toplam $count'"),
    'zh': dict(positionOf="'第 $index 个，共 $count 个'"),
}
for _lang, _values in POSITION.items():
    LANGS[_lang].update(_values)
VARIANTS['zh_Hant']['values'].update(positionOf="'第 $index 個，共 $count 個'")

NAMES = dict(ar='Arabic', de='German', en='English', es='Spanish', fr='French',
             hi='Hindi', it='Italian', ja='Japanese', ko='Korean',
             pt='Portuguese (Brazilian)', ru='Russian', tr='Turkish',
             zh='Chinese (Simplified)')
for _code, _variant in VARIANTS.items():
    NAMES[_code] = _variant['name']


def dart_string(s):
    return "'" + s.replace('\\', '\\\\').replace("'", "\\'") + "'"


def signature(key):
    """(name, params) for a key; "()" is the legacy `(int count)`."""
    if '(' not in key:
        return key, None
    name, params = key[:-1].split('(', 1)
    return name, params or 'int count'


def member(key, value, override):
    out = ['  @override'] if override else []
    name, params = signature(key)
    if params is None:
        out.append(f"  String get {name} => {dart_string(value)};")
    else:
        out.append(f"  String {name}({params}) => {value};")
    return out


def class_name(code):
    """'zh_Hant' -> DsLocalizationsZhHant, 'pt_PT' -> DsLocalizationsPtPt."""
    return 'DsLocalizations' + ''.join(p.capitalize() for p in code.split('_'))


def file_name(code):
    return code.lower() + '.dart'


def write(lang, cls, base, values, base_file):
    lines = ['// GENERATED by tool/gen_l10n.py. Do not edit by hand.', '']
    lines.append(f"import '{base_file}';")
    lines += ['', f'/// {NAMES[lang]} strings.',
              f'class {cls} extends {base} {{', f'  /// Creates the {NAMES[lang]} strings.',
              f'  const {cls}();', '', '  @override',
              f"  String get localeName => '{lang}';"]
    for key in KEYS:
        name, _ = signature(key)
        if name in values:
            lines.append('')
            lines += member(key, values[name], True)
    lines.append('}')
    open(os.path.join(OUT, file_name(lang)), 'w').write('\n'.join(lines) + '\n')


os.makedirs(OUT, exist_ok=True)
english = {signature(k)[0]: v[1] for k, v in KEYS.items()}
names = {signature(k)[0] for k in KEYS}
write('en', 'DsLocalizationsEn', 'DsLocalizations', english, '../localizations.dart')
for lang, values in LANGS.items():
    assert set(values) <= names, f'{lang}: unknown keys {set(values) - names}'
    write(lang, class_name(lang), 'DsLocalizationsEn', values, 'en.dart')

for code, variant in VARIANTS.items():
    base = variant['base']
    inherited = LANGS[base]
    values = variant['values']
    assert code.split('_')[0] == base, f'{code} must extend its language'
    assert set(values) <= names, f'{code}: unknown keys {set(values) - names}'
    if variant['complete']:
        missing = set(inherited) - set(values)
        assert not missing, f'{code} is complete but lacks {sorted(missing)}'
    # Only the wording that differs from the base is generated.
    differs = {k: v for k, v in values.items() if inherited.get(k) != v}
    write(code, class_name(code), class_name(base), differs, file_name(base))

# The registry and the abstract member list.
langs = ['en'] + sorted(list(LANGS) + list(VARIANTS))
reg = ['// GENERATED by tool/gen_l10n.py. Do not edit by hand.', '',
       "import '../localizations.dart';"]
reg += [f"import '{file_name(l)}';" for l in langs]
reg += [''] + [f"export '{file_name(l)}';" for l in langs]
reg += ['', '/// The bundled strings, keyed like `Locale.toString()`: a language',
        "/// ('pt') or a language with a script or region ('zh_Hant', 'pt_PT').",
        '/// [DsLocalizations.resolve] picks the most specific match.',
        'const Map<String, DsLocalizations> dsBundledLocalizations = {']
reg += [f"  '{l}': {class_name(l)}()," for l in langs]
reg += ['};']
open(os.path.join(OUT, 'all.dart'), 'w').write('\n'.join(reg) + '\n')

api = ['// GENERATED by tool/gen_l10n.py. Do not edit by hand.', '',
       "part of '../localizations.dart';", '',
       '/// The strings every language provides.',
       'mixin _DsStrings {']
for key, (doc, _) in KEYS.items():
    api.append(f'  /// {doc}')
    name, params = signature(key)
    if params is None:
        api.append(f'  String get {name};')
    else:
        api.append(f'  String {name}({params});')
    api.append('')
api[-1] = '}'
open(os.path.join(OUT, 'keys.dart'), 'w').write('\n'.join(api) + '\n')
try:
    subprocess.run(['dart', 'format', OUT], check=True, capture_output=True)
except (OSError, subprocess.CalledProcessError) as e:
    print(f'dart format failed ({e}); run it on {OUT} by hand')
print(f'{len(LANGS) + 1} languages, {len(VARIANTS)} variants, {len(KEYS)} keys')
