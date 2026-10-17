-- WoW: Forever PvP snapshot. Class and talent-tree data are intentionally
-- separate from the UI so beta and launch recommendations can be updated.
PvPKompassData = {
    game = "World of Warcraft: Forever",
    build = "Beta, Datenstand 17.10.2026",
    betaLevel = 30,
    sources = {
        prep = "https://wowhonor.com/guides/pvp-preparation/",
        gear = "https://wowhonor.com/guides/rewards-and-vendors/",
        rank = "https://worldofwarcraft.blizzard.com/en-us/news/24303316/how-pvp-progression-in-world-of-warcraft-forever-works",
        wowheadPvp = "https://www.wowhead.com/forever/guide/pvp-overview-ranking-rewards",
        wowheadGuides = "https://www.wowhead.com/forever/guides",
    },
    classOrder = { "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "SHAMAN", "MAGE", "WARLOCK", "DRUID" },
    classes = {
        WARRIOR = { name = "Krieger", url = "https://wowhonor.com/guides/classes/warrior/", defaultTree = 1, trees = {
            { name = "Waffen", role = "Nahkampfschaden und Heilungsverringerung", stats = "Kraft und Ausdauer als Basis. Trefferwertung hilft, Angriffe zuverlässig anzubringen; Waffenschaden ist für deine Druckfenster zentral.", talents = "PvP-Kern: Verbesserte Taktikbeherrschung für mehr Wut beim Haltungswechsel. Spearing Strike ist ein früher Forever-Talentpunkt-Meilenstein; Mortal Strike kommt erst ab Stufe 40." },
            { name = "Furor", role = "Zwei Waffen und anhaltender Nahkampfdruck", stats = "Kraft, Trefferwertung und Ausdauer. Für Zweihand- oder Beidhändig-Builds die Ausrüstung passend zum Waffentalent wählen.", talents = "PvP-Kern: Raging Blows auf 16 Punkten senkt die Wutkosten von Spalten und Wirbelwind. Death Wish gibt Druck und Furchtimmunität, erhöht aber den erlittenen Schaden." },
            { name = "Schutz", role = "Defensive Talente als PvP-Beimischung", stats = "Ausdauer und Rüstung für Überleben; Kraft und Trefferwertung halten den Gegenschaden relevant.", talents = "PvP-Kern: Iron Will verkürzt Betäubungen und Furcht. Verbesserte Entwaffnung senkt deren Abklingzeit; Vanguard auf 16 Punkten erlaubt Sturmangriff in Verteidigungshaltung." },
        } },
        PALADIN = { name = "Paladin", url = "https://wowhonor.com/guides/classes/paladin/", defaultTree = 1, trees = {
            { name = "Heilig", role = "Heilung, Segen und Schutz der Gruppe", stats = "Zaubermacht/Heilung und Intelligenz für Heilungen, Ausdauer gegen Fokus. Nutze Plattenrüstung und Schilde für Überleben.", talents = "PvP-Kern: Heilige Zauber und Heilung unterstützen. Segen der Freiheit löst Bewegungsbeeinträchtigungen; Segen des Schutzes und Göttlicher Schutz sind deine großen Antworten auf Nahkampfdruck." },
            { name = "Schutz", role = "Defensive Unterstützung und Kontrolle", stats = "Ausdauer und Rüstung zuerst; Kraft und Zaubermacht je nach Talentmix.", talents = "PvP-Kern: Schild und Schutzfähigkeiten für Überleben, Hammer der Gerechtigkeit als Betäubung. Schutz ist vor allem ein defensiver Nebenbaum; die genaue Forever-Buildempfehlung ist im Beta-Stand noch nicht verlässlich." },
            { name = "Vergeltung", role = "Nahkampfschaden mit Segen und Burst", stats = "Kraft, Trefferwertung und Ausdauer; Zaubermacht verbessert je nach Build Heiligschaden und Unterstützung.", talents = "PvP-Kern: Heilige Schläge, Siegel und Richturteile für Druck. Hammer der Gerechtigkeit setzt Heilern ein Zeitfenster; Segen der Freiheit hilft beim Dranbleiben." },
        } },
        HUNTER = { name = "Jäger", url = "https://wowhonor.com/guides/classes/hunter/", defaultTree = 3, trees = {
            { name = "Tierherrschaft", role = "Druck und Kontrolle über dein Tier", stats = "Beweglichkeit, Trefferwertung und Ausdauer. Das Tier übernimmt einen Teil deiner Ausrüstungswerte.", talents = "PvP-Kern: Intimidation liefert den Tier-Betäubungseffekt; Summon Hawk auf 16 Punkten ergänzt Sofortschaden. Gut, wenn dein Team zusätzliche Kontrolle braucht." },
            { name = "Treffsicherheit", role = "Fernkampf-Burst und Reichweite", stats = "Beweglichkeit, Trefferwertung und Ausdauer; hoher Waffenschaden stärkt gezielte Schüsse.", talents = "PvP-Kern: Lone Wolf auf 11 Punkten erhöht den Schaden ohne aktives Tier. Wähle den Verzicht auf Tierkontrolle, wenn dein Team bereits Kontrolle mitbringt." },
            { name = "Überleben", role = "Fallen, Wurzeln und Antworten auf Nahkämpfer", stats = "Beweglichkeit, Trefferwertung und Ausdauer. Überleben muss im Nahbereich handlungsfähig bleiben.", talents = "PvP-Einstieg für die Beta-Stufe 30: Entrapment wurzelt Gegner in Fallen, Surefooted verkürzt Verlangsamungen, Strider Kick hilft aus der 8-Meter-Totzone. Counterattack kommt auf 16 Punkten." },
        } },
        ROGUE = { name = "Schurke", url = "https://wowhonor.com/guides/classes/rogue/", defaultTree = 3, trees = {
            { name = "Meucheln", role = "Einzelzielschaden und Gifte", stats = "Beweglichkeit, Trefferwertung und Ausdauer. Trefferwertung ist besonders wichtig, wenn Angriffe und Gifte verlässlich treffen sollen.", talents = "PvP-Kern: Gifte und Blutungen für anhaltenden Druck. Nutze Verstümmeln und Kontrollfähigkeiten, um dein Ziel nach dem Eröffnen unter Druck zu halten." },
            { name = "Kampf", role = "Waffenschaden, Tempo und Ausdauer", stats = "Beweglichkeit, Trefferwertung und Ausdauer. Wähle Waffen passend zum Forever-Talent Hack and Slash.", talents = "PvP-Kern: Endurance reduziert Sprint und Entrinnen auf 2 Minuten. Hack and Slash ersetzt Waffenspezialisierungen und belohnt unterschiedliche Waffentypen." },
            { name = "Täuschung", role = "Eröffnungen aus Verstohlenheit und Kontrolle", stats = "Beweglichkeit, Trefferwertung und Ausdauer; nutze den Waffentyp, den deine Talente unterstützen.", talents = "PvP-Kern: Premeditation ist auf 16 Punkte vorgezogen und gibt Kombopunkte. Dirty Tricks senkt Energie für Kopfnuss und Blenden; Initiative belohnt Eröffnungen mit zusätzlichen Kombopunkten." },
        } },
        PRIEST = { name = "Priester", url = "https://wowhonor.com/guides/classes/priest/", defaultTree = 1, trees = {
            { name = "Disziplin", role = "Schilde, Heilung und vielseitiger Druck", stats = "Zaubermacht/Heilung und Intelligenz; Ausdauer schützt dich vor Fokus. Spirit unterstützt Mana-Regeneration.", talents = "PvP-Kern: Soul Warding auf 16 Punkten entfernt die Abklingzeit von Machtwort: Schild. Penance auf 21 Punkten heilt Verbündete oder schädigt Gegner; Mental Agility spart Mana." },
            { name = "Heilig", role = "Direkte Heilung und Gruppenunterstützung", stats = "Heilzaubermacht und Intelligenz für stärkere Heilungen; Ausdauer und Willenskraft helfen beim Überleben und Manahaushalt.", talents = "PvP-Kern: Binding Heal kommt auf 16 Punkten und heilt dich sowie ein Ziel. Twilight Focus schützt Zauber vor Unterbrechung durch erlittenen Schaden." },
            { name = "Schatten", role = "Schattenschaden über Zeit und Kontrolle", stats = "Zaubermacht, Trefferwertung und Ausdauer; Intelligenz und Willenskraft helfen bei Mana und Ausdauer im Kampf.", talents = "PvP-Kern: Schattenzauber und Schaden über Zeit. Furcht, Stille und die in Forever für Priester verfügbaren Volksfähigkeiten sind wichtige Werkzeuge; prüfe die aktuelle Talentverteilung über die Quelle." },
        } },
        SHAMAN = { name = "Schamane", url = "https://wowhonor.com/guides/classes/shaman/", defaultTree = 2, trees = {
            { name = "Elementarkampf", role = "Zauberschaden, Reichweite und Wurzeln", stats = "Zaubermacht, Trefferwertung und Ausdauer; Intelligenz unterstützt deinen Manavorrat.", talents = "PvP-Kern: Elemental Alacrity beschleunigt Blitzschlag und Kettenblitz. Earthbound auf 21 Punkten wurzelt Gegner beim Platzieren des Totems; Lava Burst ist der 31-Punkte-Abschluss." },
            { name = "Verstärkung", role = "Nahkampfschaden und schnelle Zauber", stats = "Beweglichkeit/Kraft, Trefferwertung und Ausdauer; Intelligenz verstärkt über Mental Dexterity deinen Angriffswert.", talents = "PvP-Kern: Stormstrike auf 16 Punkten hat 8 Sekunden Abklingzeit und verstärkt deinen nächsten Blitzschlag, Kettenblitz oder Erdschock. Verbesserter Geisterwolf wird auf Rang 2 sofort gewirkt." },
            { name = "Wiederherstellung", role = "Heilung, Totems und Unterstützung", stats = "Heilzaubermacht, Intelligenz und Ausdauer; Willenskraft unterstützt die Manaregeneration.", talents = "PvP-Kern: Water Shield und Riptide sind Forever-Neuerungen. Totems lassen sich bewegen oder zurückrufen; Erdschild und schnelle Heilungen stabilisieren dein Team." },
        } },
        MAGE = { name = "Magier", url = "https://wowhonor.com/guides/classes/mage/", defaultTree = 3, trees = {
            { name = "Arkan", role = "Zauberschaden, Gegenzauber und Manaeffizienz", stats = "Zaubermacht, Trefferwertung und Ausdauer. Intelligenz erhöht den Manavorrat; Ausdauer ist gegen Nahkampffokus entscheidend.", talents = "PvP-Kern: Verbesserter Gegenzauber erhält eine verlässliche, kürzere Stille. Arkane Explosion und Kontrollzauber helfen gegen Nahkämpfer; Arkanschlag ist ein neuer Forever-Talentzauber." },
            { name = "Feuer", role = "Kritischer Burst und Flächenkontrolle", stats = "Zaubermacht, Trefferwertung und Ausdauer; kritische Treffer unterstützen Feuer-Burst-Talente.", talents = "PvP-Kern: Heating Up verkürzt Pyroschlag nach kritischen Treffern. Impact kann Ziele betäuben; Blast Wave verursacht Schaden und verlangsamt Gegner." },
            { name = "Frost", role = "Verlangsamungen, Wurzeln und defensive Kontrolle", stats = "Zaubermacht, Trefferwertung und Ausdauer; halte Distanz, da Magier sehr verwundbar gegen Nahkampf sind.", talents = "PvP-Einstieg für die Beta-Stufe 30: Ice Lance auf 11 Punkten trifft gefrorene Ziele besonders hart, Ice Block auf 16 Punkten gibt Immunität, Cold Snap auf 21 Punkten setzt Frost-Abklingzeiten zurück." },
        } },
        WARLOCK = { name = "Hexenmeister", url = "https://wowhonor.com/guides/classes/warlock/", defaultTree = 2, trees = {
            { name = "Gebrechen", role = "Schaden über Zeit, Flüche und Entzug", stats = "Zaubermacht, Ausdauer und Trefferwertung. Ausdauer stärkt Life Tap und hilft gegen Fokus.", talents = "PvP-Kern: Curse of Exhaustion auf 16 Punkten verlangsamt dein Ziel. Malediction und Soul Siphon erhöhen den Druck durch Schaden über Zeit und Entzug." },
            { name = "Dämonologie", role = "Dämonenstärke und Schadensumleitung", stats = "Zaubermacht, Ausdauer und Trefferwertung; Dämonen skalieren in Forever mit deinen Werten.", talents = "PvP-Einstieg für die Beta-Stufe 30: Demonic Sacrifice ist auf 11 Punkten, Fel Domination auf 16 und Soul Link auf 21 Punkten erreichbar. Soul Link teilt Schaden mit deinem Dämon." },
            { name = "Zerstörung", role = "Schatten-/Feuer-Burst mit Dämonenunterstützung", stats = "Zaubermacht, Trefferwertung und Ausdauer; priorisiere Überleben, damit du Zauber wirken kannst.", talents = "PvP-Kern: Bane- und Fluchdruck mit direkten Schatten- und Feuerschäden verbinden. Felhunter-Kontrolle ergänzt den Druck, ist aber erst ab Stufe 36 verfügbar." },
        } },
        DRUID = { name = "Druide", url = "https://wowhonor.com/guides/classes/druid/", defaultTree = 2, trees = {
            { name = "Gleichgewicht", role = "Zauberschaden, Wurzeln und Kontrolle", stats = "Zaubermacht, Trefferwertung und Ausdauer. Ausdauer ist wichtig, wenn Nahkämpfer dich erreichen.", talents = "PvP-Kern: Improved Entangling Roots und Overgrowth halten Angreifer auf Abstand. Insect Swarm auf 16 Punkten senkt die Trefferchance des Ziels." },
            { name = "Wildheit", role = "Formwechsel, Nahkampfschaden und Mobilität", stats = "Beweglichkeit und Waffenschaden für Katze; Ausdauer für Überleben. Waffen-DPS wirkt in Katzen- und Bärenform.", talents = "PvP-Einstieg für die Beta-Stufe 30: Feral Charge, Shifting Power auf 16 Punkten und Leader of the Pack auf 21 Punkten. Shifting Power ersetzt Tiger's Fury und gibt Energie sofort zurück." },
            { name = "Wiederherstellung", role = "Heilung über Zeit und Gruppenheilung", stats = "Heilzaubermacht, Intelligenz und Ausdauer; Willenskraft hilft bei längeren Kämpfen.", talents = "PvP-Kern: Gift of the Earthmother auf 11 Punkten verkürzt den globalen Cooldown; Swiftmend auf 16 Punkten ist eine Sofortheilung, ohne den HoT zu verbrauchen." },
        } },
    },
    common = {
        consumables = {
            "PvP-Insignie zuerst besorgen: ab Rang 2; entfernt Bewegungs- und Kontrollverlusteffekte, 5 Min. Abklingzeit.",
            "Heiltrank: Greater Healing Potion ab Stufe 21 (Beta-Stufe 30: 455–585 Leben).",
            "Manatrank: Mana Potion ab Stufe 22 (Beta-Stufe 30: 455–585 Mana).",
            "Free Action Potion: 30 Sek. Immunität gegen Betäubungen und Bewegungseinschränkungen; vor dem Kampf nutzen.",
            "Swiftness Potion: 50% Bewegungstempo für 15 Sek.; Thistle Tea gibt Schurken und Druiden 100 Energie.",
            "Mageweave Bandage heilt 800 Leben über 8 Sek.; nicht verwenden, wenn du während des Kanalisierens angegriffen wirst.",
            "Ab Rang 5 werden Kampftränke freigeschaltet; die stärkeren Kampftränke benötigen höhere Stufen als das Beta-Levelcap.",
        },
        gear = {
            "Forever-Beta, Stufe 30: Es gibt noch keine verlässliche Endgame-BiS-Liste für den Launch auf Stufe 60.",
            "Für PvP die Rangbelohnungen und aktuelle PvP-Händler prüfen; Rang 2 schaltet die PvP-Insignie frei.",
            "Bei Waffen auf den für deinen Build relevanten Waffenschaden und passende Werte achten; für Schurken außerdem die Talent-Synergie mit dem Waffentyp beachten.",
            "Die verlinkte Forever-PvP-Ausrüstungsübersicht enthält aktuelle Rangbelohnungen, Preise und Händler. Beta-Werte können sich bis zum Launch ändern.",
        },
        statsNote = "Forever hat keine einheitliche PvP-Werteliste für alle Talentbäume. Die Baumhinweise nennen die sinnvollen Startwerte; vergleiche Gegenstände auf Stufe 30 und aktualisiere die Empfehlung nach Launch und Level 60.",
        talentNote = "Die Beta endet auf Stufe 30 mit 21 regulären Talentpunkten. Meilenstein-Talente liegen bei 11, 16 und 21 Punkten; der 31-Punkte-Abschluss ist vor Stufe 40 nicht erreichbar. Die Legacy-Fähigkeit Talented kann zusätzliche Punkte vorziehen.",
    },
}
