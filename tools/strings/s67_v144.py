from s1_ui import add

# v144 (App Review 2.1(b)): every in-app purchase reachable from the first minute. Settings has a "Shop" row at the
# top that opens the bazaar's screen from day one; the shop lists the Grand Tour and the Supporter Edition on top, and
# says so when the App Store's prices couldn't be loaded instead of hiding anything.

add("shop.title", "Shop", "Mağaza", "Shop", "Tienda", "ショップ", "상점")
add("shop.tour.hint",
    "Cappadocia is free. The Grand Tour opens Albuquerque, Luxor, Bristol and the Maasai Mara; each region still opens when you become baron of the one before it.",
    "Kapadokya ücretsiz. Dünya Turu Albuquerque, Luksor, Bristol ve Maasai Mara'yı açar; her bölge yine bir öncekinin baronu olunca açılır.",
    "Kappadokien ist kostenlos. Die Weltreise öffnet Albuquerque, Luxor, Bristol und die Maasai Mara; jede Region öffnet sich weiterhin, sobald du Baron der vorherigen bist.",
    "Capadocia es gratis. El Gran Tour abre Albuquerque, Luxor, Bristol y el Maasai Mara; cada región se sigue abriendo cuando eres barón de la anterior.",
    "カッパドキアは無料。グランドツアーでアルバカーキ、ルクソール、ブリストル、マサイマラが開きます。各地域は、これまでどおり前の地域の男爵になると開きます。",
    "카파도키아는 무료입니다. 그랜드 투어로 앨버커키, 룩소르, 브리스틀, 마사이 마라가 열리며, 각 지역은 여전히 이전 지역의 남작이 되면 열립니다.")
add("shop.noPrice", "Price unavailable", "Fiyat alınamadı", "Preis nicht verfügbar", "Precio no disponible", "価格を取得できません", "가격을 불러올 수 없음")
add("shop.pricesFailed",
    "The App Store's prices couldn't be loaded. Check your connection and try again.",
    "App Store fiyatları yüklenemedi. Bağlantını kontrol edip yeniden dene.",
    "Die Preise aus dem App Store konnten nicht geladen werden. Prüfe deine Verbindung und versuche es noch einmal.",
    "No se pudieron cargar los precios de la App Store. Revisa tu conexión e inténtalo de nuevo.",
    "App Storeの価格を読み込めませんでした。接続を確認して、もう一度お試しください。",
    "App Store 가격을 불러오지 못했습니다. 연결을 확인하고 다시 시도해 주세요.")
add("shop.retry", "Try again", "Yeniden dene", "Erneut versuchen", "Reintentar", "再試行", "다시 시도")
add("shop.buyRetry", "Price unavailable, try again", "Fiyat alınamadı, yeniden dene", "Preis nicht verfügbar, erneut versuchen",
    "Precio no disponible, reintentar", "価格を取得できません。再試行", "가격을 불러올 수 없음, 다시 시도")
