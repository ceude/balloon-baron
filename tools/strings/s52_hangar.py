from s1_ui import add

# v127: the hangar's capacity (levels up to 8), the balloons outside it and the warnings; the localized default balloon
# name; the crew page's "waiting for a pilot" callout leads to the candidates.

add("balloon.default", "Balloon %@", "Balon %@", "Ballon %@", "Globo %@", "気球 %@", "열기구 %@")

add("building.hangar.4", "Second hangar", "İkinci hangar", "Zweiter Hangar", "Segundo hangar", "第二格納庫", "제2 격납고")
add("building.hangar.5", "Big hangar", "Büyük hangar", "Großer Hangar", "Hangar grande", "大型格納庫", "대형 격납고")
add("building.hangar.6", "Hangar complex", "Hangar kompleksi", "Hangarkomplex", "Complejo de hangares", "格納庫群", "격납고 단지")
add("building.hangar.7", "Balloon base", "Balon üssü", "Ballonbasis", "Base de globos", "気球基地", "열기구 기지")
add("building.hangar.8", "Grand balloon base", "Dev balon üssü", "Riesige Ballonbasis", "Gran base de globos", "巨大気球基地", "초대형 열기구 기지")
add("hangar.capacity", "Capacity: %@ balloons", "Kapasite: %@ balon", "Kapazität: %@ Ballone", "Capacidad: %@ globos", "収容数：気球%@機", "수용량: 열기구 %@대")
add("hangar.fleet", "Balloons in your fleet: %@.", "Filonda %@ balon var.", "Ballone in deiner Flotte: %@.", "Globos en tu flota: %@.",
    "保有気球：%@機。", "보유 열기구: %@대.")
add("hangar.fleetOut", "Balloons in your fleet: %1$@. Outside, unable to fly: %2$@.", "Filonda %1$@ balon var; %2$@ tanesi dışarıda, uçamıyor.",
    "Ballone in deiner Flotte: %1$@. Draußen und flugunfähig: %2$@.", "Globos en tu flota: %1$@. Fuera y sin poder volar: %2$@.",
    "保有気球：%1$@機。外にあって飛べない気球：%2$@機。", "보유 열기구: %1$@대. 밖에 있어 뜨지 못하는 열기구: %2$@대.")

add("hangar.full.title", "No room in the hangar", "Hangarda yer yok", "Kein Platz im Hangar", "No hay sitio en el hangar", "格納庫に空きがない", "격납고에 자리가 없어요")
add("hangar.full.body", "Your hangar is full. Balloons left outside: %@. You need to upgrade the hangar.",
    "Hangarın dolu: %@ balon dışarıda kaldı. Hangarı geliştirmen lazım.",
    "Dein Hangar ist voll. Ballone, die draußen bleiben: %@. Du musst den Hangar ausbauen.",
    "Tu hangar está lleno. Globos que se quedan fuera: %@. Tienes que ampliar el hangar.",
    "格納庫がいっぱいだ。外に置かれた気球：%@機。格納庫を拡張しよう。",
    "격납고가 꽉 찼어요. 밖에 남은 열기구: %@대. 격납고를 업그레이드해야 해요.")
add("hangar.full.hint", "Balloons outside can't be maintained: they don't fly and get no pilot. Once the hangar grows they move in by themselves.",
    "Dışarıdaki balonlara bakım yapılamaz: uçamazlar, pilot almazlar. Hangar büyüyünce kendiliğinden içeri girerler.",
    "Ballone draußen können nicht gewartet werden: Sie fliegen nicht und bekommen keinen Piloten. Wächst der Hangar, ziehen sie von selbst ein.",
    "Los globos de fuera no reciben mantenimiento: no vuelan ni tienen piloto. Cuando el hangar crezca, entrarán solos.",
    "外の気球は整備できないので飛べず、パイロットもつかない。格納庫が広がれば自動で中に入る。",
    "밖에 있는 열기구는 정비할 수 없어서 비행도 못 하고 조종사도 배정되지 않아요. 격납고가 커지면 저절로 안으로 들어가요.")
add("hangar.upgrade", "Upgrade the hangar", "Hangarı geliştir", "Hangar ausbauen", "Ampliar el hangar", "格納庫を拡張", "격납고 업그레이드")
add("hangar.ok", "OK", "Tamam", "OK", "Vale", "OK", "확인")

add("fleet.outside.row", "Outside, unable to fly: %@", "Dışarıda %@ balon: uçamıyorlar", "Draußen und flugunfähig: %@", "Fuera y sin poder volar: %@",
    "外にあって飛べない気球：%@機", "밖에 있어 뜨지 못하는 열기구: %@대")
add("fleet.outside.cap", "Hangar capacity: %@", "Hangar kapasitesi: %@ balon", "Hangarkapazität: %@", "Capacidad del hangar: %@",
    "格納庫の収容数：%@機", "격납고 수용량: %@대")
add("fleet.outside.go", "Upgrade hangar ›", "Hangarı geliştir ›", "Hangar ausbauen ›", "Ampliar hangar ›", "格納庫を拡張 ›", "격납고 업그레이드 ›")
add("fleet.f.out", "Outside", "Dışarıda", "Draußen", "Fuera", "屋外", "밖")
add("fleet.row.outside", "No room in the hangar, can't fly", "Hangarda yer yok, uçamaz", "Kein Platz im Hangar, fliegt nicht",
    "Sin sitio en el hangar, no vuela", "格納庫に空きがなく飛べない", "격납고에 자리가 없어 비행 불가")
add("home.fleet.outside", "Outside: %@", "Dışarıda: %@", "Draußen: %@", "Fuera: %@", "屋外：%@", "밖: %@")

add("hez.hangarFull", "Your hangar is full, kid. Balloons left outside: %@. You need to upgrade the hangar.",
    "Hangarın dolu evlat: %@ balon dışarıda kaldı. Hangarı geliştirmen lazım.",
    "Dein Hangar ist voll, Lehrling. Ballone, die draußen bleiben: %@. Du musst den Hangar ausbauen.",
    "Tu hangar está lleno, aprendiz. Globos que se quedan fuera: %@. Tienes que ampliar el hangar.",
    "格納庫がいっぱいだぞ。外に置かれた気球：%@機。格納庫を拡張せねばならん。",
    "격납고가 꽉 찼네. 밖에 남은 열기구: %@대. 격납고를 넓혀야 하네.")
add("hez.hangarOutside", "Balloons standing outside, kid: %@. They can't get into the hangar to be maintained, so they can't fly. Upgrade your hangar.",
    "Dışarıda %@ balonun var evlat; hangara giremeyip bakım yapılamadığı için uçamıyorlar. Hangarın seviyesini yükselt.",
    "Ballone, die draußen stehen, Lehrling: %@. Sie passen nicht in den Hangar, werden nicht gewartet und können deshalb nicht fliegen. Bau deinen Hangar aus.",
    "Globos que están fuera, aprendiz: %@. No caben en el hangar, no reciben mantenimiento y por eso no pueden volar. Amplía tu hangar.",
    "外に置かれた気球：%@機。格納庫に入れず整備できんから、飛べんのだ。格納庫のレベルを上げよ。",
    "밖에 서 있는 열기구: %@대. 격납고에 못 들어가 정비를 못 받으니 뜰 수가 없네. 격납고 레벨을 올리게.")

add("crew.needPilots.go", "See the candidates ›", "Başvuranlara git ›", "Zu den Bewerbern ›", "Ver los candidatos ›", "応募者を見る ›", "지원자 보기 ›")
