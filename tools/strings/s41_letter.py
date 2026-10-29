"""v123: the family's letter on day 50 (envelope, letter, buttons). Reviewed by language agents in all six languages.
letter.addrTo has two lines: the one with %@ is the company name, drawn big; the other is the "to the founder" line. The
stamp (NEVŞEHİR) and the postmark's place (GÖREME) stay Turkish in every language, like a real stamp; only the day word
of the postmark is localized (letter.postmarkDay)."""
from s1_ui import add

add("letter.hint", "There's a letter for you · tap", "Sana bir mektup var · dokun", "Ein Brief für dich · tippen", "Tienes una carta · toca", "あなたに手紙が届いています · タップ", "편지가 도착했어요 · 탭하세요")
add("letter.addrTo", "To the founder of\n%@", "%@\nkurucusuna", "An den klugen Kopf hinter\n%@", "%@\nPara quien la fundó", "%@\n創業者様", "%@\n창업자님께")
add("letter.addrPlace", "Göreme, Nevşehir", "Göreme, Nevşehir", "Göreme, Nevşehir", "Göreme, Nevşehir", "ネヴシェヒル県 ギョレメ", "네브셰히르 괴레메")
add("letter.greeting", "Dear founder of %@,", "Sevgili %@ kurucusu,", "Hallo, du kluger Kopf hinter %@,", "Hola a quien fundó %@:", "%@の創業者さまへ", "%@ 창업자님께")
add("letter.p1", "Your company is %@ days old today. You've come so far, sending your balloons up into the sky every morning, and that makes us truly happy.", "Bugün şirketinin %@. günü. Bu kadar yol gelmen, balonlarını her sabah yeniden göğe salman bizi gerçekten çok mutlu etti.", "Heute ist der %@. Tag deiner Firma. Dass du so weit gekommen bist und deine Ballone jeden Morgen wieder in den Himmel schickst, hat uns wirklich glücklich gemacht.", "Hoy es el día %@ de tu empresa. Que hayas llegado hasta aquí y sigas soltando tus globos al cielo cada mañana nos ha hecho muy felices, de verdad.", "今日で、あなたの会社は%@日目を迎えました。ここまで続けてくれたこと、毎朝気球をまた空へ送り出してくれていることが、私たちには本当にうれしいです。", "오늘로 회사가 %@일째를 맞았어요. 여기까지 함께 와 주시고, 매일 아침 열기구를 다시 하늘로 띄워 주셔서 저희는 정말 행복했어요.")
add("letter.p2", "We made this game for our daughter. If you've enjoyed it, would you write a few lines on the App Store? It's words like yours that help other players find Cappadocia.", "Kızımız için yaptığımız oyunu sevdiysen App Store'a birkaç cümle yazar mısın? Başka oyuncuların Kapadokya'yı bulmasını senin sözlerin sağlıyor.", "Wenn dir das Spiel gefällt, das wir für unsere Tochter gemacht haben: Schreibst du ein paar Sätze im App Store? Gerade deine Worte sorgen dafür, dass andere Kappadokien finden.", "Si te ha gustado el juego que hicimos para nuestra hija, ¿nos escribirías unas líneas en la App Store? Son tus palabras las que ayudan a otros a descubrir Capadocia.", "娘のために作ったこのゲームを気に入ってもらえたなら、App Storeに少しだけ感想を書いてもらえませんか？ ほかのプレイヤーがカッパドキアに出会えるのは、あなたの言葉のおかげなんです。", "딸아이를 위해 만든 게임인데, 즐겁게 하셨다면 App Store에 몇 줄 남겨 주시겠어요? 다른 플레이어들이 카파도키아를 찾게 되는 건 바로 창업자님의 한마디 덕분이에요.")
add("letter.signOff", "With love,", "Sevgiler,", "Alles Liebe", "Con cariño,", "心をこめて", "사랑을 담아,")
add("letter.signature", "S. & U.", "S. & U.", "S. & U.", "S. & U.", "S. & U. より", "S. & U. 드림")
add("letter.rate", "Write a review on the App Store", "App Store'da yorum yaz", "Rezension im App Store schreiben", "Escribir una reseña en la App Store", "App Storeでレビューを書く", "App Store에서 리뷰 작성")
add("letter.later", "Not now", "Şimdi değil", "Nicht jetzt", "Ahora no", "今はしない", "나중에")
add("letter.close", "Close", "Kapat", "Schließen", "Cerrar", "閉じる", "닫기")
add("letter.thanks", "Thank you!", "Teşekkür ederiz!", "Danke dir!", "¡Muchas gracias!", "ありがとうございます！", "고맙습니다!")
add("letter.photoAlt", "The family who made the game, under the balloons in Cappadocia", "Oyunu yapan aile, Kapadokya'da balonların altında", "Die Familie, die das Spiel gemacht hat, unter den Ballonen in Kappadokien", "La familia que hizo el juego, bajo los globos de Capadocia", "このゲームを作った家族。カッパドキアの気球の下で", "이 게임을 만든 가족, 카파도키아의 열기구 아래에서")
add("letter.postmarkDay", "DAY %@", "GÜN %@", "TAG %@", "DÍA %@", "%@日目", "%@일째")
