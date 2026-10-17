# PvP-Kompass für WoW Forever

Dieses Repository enthält das Addon und den Datenfeed für den externen Updater.

## Addon-Installation

Den heruntergeladenen Addon-Ordner in `World of Warcraft\_classic_\Interface\AddOns\PvPKompass` ablegen. Falls du das Repository direkt herunterlädst, den entpackten Ordner `pvp-kompass-wow-forever` in `PvPKompass` umbenennen. Im Spiel öffnet `/pvpkompass` das Fenster. Das Minimap-Symbol lässt sich ziehen und öffnet das Fenster per Klick.

## Daten aktualisieren

Im Addon auf **Daten aktualisieren** klicken, WoW vollständig schließen und `Update-PvPKompass.ps1` ausführen:

```powershell
.\Update-PvPKompass.ps1 -ManifestUrl "https://raw.githubusercontent.com/karachokalle/pvp-kompass-wow-forever/main/update-manifest.json" -WowRoot "C:\Pfad\zu\World of Warcraft\_classic_"
```

Das Repository muss öffentlich sein, damit der Updater Manifest und `Data.lua` ohne GitHub-Anmeldung beziehen kann. Ersetze `OWNER` in der Beispieladresse durch deinen GitHub-Benutzernamen. Der Updater prüft den SHA-256-Wert und legt vor dem Austausch ein Backup der vorhandenen Datei an.

Wenn `Data.lua` oder die Addon-Version geändert wird, aktualisiert GitHub Actions das Manifest samt Prüfsumme. Für den Start das Repository `pvp-kompass-wow-forever` öffentlich mit dem Branch `main` anlegen und den Inhalt dieses Ordners hochladen. In GitHub unter **Settings → Actions → General → Workflow permissions** Schreibzugriff für den Workflow erlauben. Die Empfehlungen müssen weiterhin anhand der verlinkten Guides gepflegt werden; Wowhead stellt dafür keinen direkten Datenfeed im Addon-Format bereit.
