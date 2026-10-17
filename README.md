# PvP-Kompass für WoW Forever

Dieses Repository enthält das Addon und den Datenfeed für den externen Updater.

## Addon-Installation

Den heruntergeladenen Addon-Ordner in `World of Warcraft\_classic_\Interface\AddOns\PvPKompass` ablegen. Falls du das Repository direkt herunterlädst, den entpackten Ordner `pvp-kompass-wow-forever` in `PvPKompass` umbenennen. Im Spiel öffnet `/pvpkompass` das Fenster. Das Minimap-Symbol lässt sich ziehen und öffnet das Fenster per Klick.

## Daten aktualisieren

Im Addon auf **Daten aktualisieren** klicken, WoW vollständig schließen und `Update-PvPKompass.ps1` ausführen:

```powershell
.\Update-PvPKompass.ps1 -WowRoot "C:\Pfad\zu\World of Warcraft\_classic_"
```

Die Adresse des öffentlichen GitHub-Feeds ist im Updater hinterlegt. Der Updater prüft den SHA-256-Wert und legt vor dem Austausch ein Backup der vorhandenen Datei an.

Wenn `Data.lua` oder die Addon-Version geändert wird, aktualisiert GitHub Actions das Manifest samt Prüfsumme. Die Empfehlungen müssen weiterhin anhand der verlinkten Guides gepflegt werden; dieser Workflow aktualisiert die Veröffentlichung der Daten und liest die Guides nicht automatisch aus.
