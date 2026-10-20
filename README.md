# PvP-Kompass für WoW Forever

Dieses Repository enthält das Addon und den Datenfeed für den externen Updater.

## PvP-Händler

Der Reiter **PvP-Händler** bietet Fraktionsfilter, Händlerliste und Suche nach Namen, Ort und Item-ID. Gegenstände werden mit Client-Icons, Qualitätsfarben und originalen Item-Tooltips angezeigt. Shift-Klick öffnet die Anprobe. Kosten stehen pro Kauf neben Rufanforderungen; PvP-Rang, Stufe und Klassenbeschränkungen bleiben zusätzlich im Tooltip sichtbar.

Der Online-Teilbestand vom 20.10.2026 enthält 42 in Wowheads Forever-PvP-Übersicht aufgeführte Rufbelohnungen von Bryanna Embreeze und Creeg Bothunk. Weitere bekannte Händler und Händlerstandorte sind als Verzeichnis hinterlegt. Das ist noch kein vollständiges, verifiziertes Sortiment aller PvP-Händler. Unbekannte Kosten werden ausdrücklich als nicht bestätigt angezeigt; Classic-Preise werden nicht übernommen. Exalted-Wappenröcke sind wegen der laut Blizzard erforderlichen Questreihe nicht als bestätigte Händlerkäufe enthalten.

Beim Öffnen eines bekannten PvP-Händlers speichert das Addon dessen vom Client geliefertes Sortiment lokal in `PvPKompassDB.vendors`. Weitere Händler lassen sich bei geöffnetem Handelsfenster mit **Händler vor Ort erfassen** hinzufügen. Gespeichert werden Gegenstände, Stückzahl pro Kauf, Goldpreis, zusätzliche Währungen/Marken und die vom Client gelieferten Anforderungen, Datum und Build. Ein vollständiger Scan mit nachweislich aktiviertem „Alle“-Händlerfilter ersetzt das alte Sortiment; bei noch nicht geladenen Einträgen oder unbekanntem/eingeschränktem Filter bleiben bisher bekannte Items erhalten. Preise sind der persönlich angezeigte Preis einschließlich möglicher Rabatte. Nicht vom Client gelieferte Anforderungen gelten weiterhin als unbekannt. Die Daten bleiben nach `/reload` oder normalem Beenden erhalten und werden nicht hochgeladen.

Quellen: [Wowhead Forever PvP](https://www.wowhead.com/forever/guide/pvp-overview-ranking-rewards), [Dalaran-Händler](https://www.wowhead.com/news/what-to-do-in-dalaran-in-wow-forever-383146), [Forever-Händlerübersicht](https://wowhonor.com/guides/rewards-and-vendors/). Quellen können in der Beta noch unvollständig oder veraltet sein.

## Addon-Installation

Den heruntergeladenen Addon-Ordner in `World of Warcraft\_classic_\Interface\AddOns\PvPKompass` ablegen. Falls du das Repository direkt herunterlädst, den entpackten Ordner `pvp-kompass-wow-forever` in `PvPKompass` umbenennen. Im Spiel öffnet `/pvpkompass` das Fenster. Das Minimap-Symbol lässt sich ziehen und öffnet das Fenster per Klick.

## Daten aktualisieren

Wie beim Dungeon-Helper gibt es einen Client-Updater mit Menü. `start_updater.bat` per Doppelklick starten und einmalig den installierten Addon-Ordner sowie optional die SavedVariables-Datei `WTF\Account\ACCOUNT\SavedVariables\PvPKompass.lua` eintragen. Die Pfade bleiben unter `%APPDATA%\PvPKompass\updater_config.json` erhalten, auch nach dem Entpacken einer neuen Version. Menüpunkt 2 aktualisiert sofort; Menüpunkt 3 überwacht den Ingame-Button und wartet vor der Installation auf das vollständige Beenden von WoW. Mit M geht es zurück ins Menü. Python wird nicht benötigt.

Der aktuelle Updater lädt alle im Manifest hinterlegten Addon-Dateien, prüft jede Prüfsumme vor dem Installieren und sichert geänderte Dateien in einem `Backup-*`-Unterordner. Bei einem Fehler während der Installation werden bereits ersetzte Dateien zurückgesetzt. Eigene Einstellungen und lokal erfasste Händlerdaten bleiben erhalten. Ein zweiter Updater kann nicht gleichzeitig in denselben Addon-Ordner schreiben. Der Updater aktualisiert die Addon-Dateien, seine eigenen Skripte werden über ein neues Download-Paket verteilt.

Im Addon auf **Daten aktualisieren** klicken, WoW vollständig schließen und `Update-PvPKompass.ps1` ausführen:

```powershell
.\Update-PvPKompass.ps1 -WowRoot "C:\Pfad\zu\World of Warcraft\_classic_"
```

Die Adresse des öffentlichen GitHub-Feeds ist im Updater hinterlegt. Der Updater prüft den SHA-256-Wert und legt vor dem Austausch ein Backup der vorhandenen Datei an.

Wenn `Data.lua` oder die Addon-Version geändert wird, aktualisiert GitHub Actions das Manifest samt Prüfsumme. Die Empfehlungen müssen weiterhin anhand der verlinkten Guides gepflegt werden; dieser Workflow aktualisiert die Veröffentlichung der Daten und liest die Guides nicht automatisch aus.
