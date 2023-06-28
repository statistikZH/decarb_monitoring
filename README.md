
# decarbmonitoring 🌳📉

<!-- badges: start -->
<!-- badges: end -->

Repository für den Bezug der Daten fürs Dekarbonisierungsmonitoring des
Kantons Zürich.

Für jeden Datensatz im Monitoring werden drei Prozessschritte
durchlaufen:

Import ➡️ Processing ➡️ Export

Diese drei Prozessschritte werden für jeden Indikator in einem separaten
Skript definiert und ausgeführt.

## Setup 📁

Um den Prozess für einen neuen Indikator zu initialiseren sind die
folgenden Vorbereitungen notwendig. 
Schritte 1. und 2. sind dabei nur beim erstmaligen Aufsetzen notwendig.

1.  Dieses Code-Repo clonen. Entweder über den [klassischen download des
    Repos](https://github.com/statistikZH/decarb_monitoring/archive/refs/heads/main.zip)
    oder einen [direkten Download in der R-Studio
    Benutzeroberfläche.](https://happygitwithr.com/rstudio-git-github.html#clone-the-test-github-repository-to-your-computer-via-rstudio)

2.  Installation notwendiger Pakete innerhalb des R-Projekts:

``` r
install.packages("devtools")
devtools::load_all()
```

Beim erstmaligen ausführen müssen nun zusätzliche Pakete installiert
werden. Dazu erscheint folgender Dialog:

    ℹ The packages "data.table", "dplyr", "lubridate", "pxweb", "readxl", "rio", "rvest", and "tidyr" are required.
    ✖ Would you like to install them?

    1: Yes
    2: No

Hier mit `1` bestätigen.

3.  Nun kann die komplette Funktionalität des Pakets/Repos genutzt
    werden. Dazu einfach noch einmal folgenden Code ausführen:

``` r
devtools::load_all()
```

Die Bestätigung erfolgt:

    ℹ Loading decarbmonitoring

4.  Ein neuer Indikator kann nun mittels der Funktion `decarbmonitoring::indicator_init()` angelegt werden.

``` r
#Achtung: Code unten wird einen Fehler ergeben, da schon ein Skript für den Indikator M1 exisitert.
decarbmonitoring::indicator_init("M1")
```
Exisitert der Indikator in der Parameter-Liste [2773
Monitoring.xlsx](https://github.com/statistikZH/decarb_monitoring/blob/main/2773%20Monitoring.xlsx) und es gibt noch **KEIN** Aufbereitungsskript, wird nun ein neues Aufbereitungsskript im Ordner [scripts](scripts) erstellt.


## Import 📥

Jeder Datensatz ist in der Parameter-Liste [2773
Monitoring.xlsx](https://github.com/statistikZH/decarb_monitoring/blob/main/2773%20Monitoring.xlsx)
beschrieben. Die Parameter-Liste ist die Grundlage für den Import der
Daten. Der Import wird in Abhängigkeit von ausgewählten Parametern (über
Methoden) definiert und kann somit auch auf andere Datensätze mit den
gleichen Parameterangaben angewendet werden. Basierend auf der
`DATASET_ID`, dem `DATA_FORMAT` und der `DATA_ORGANIZATION` erfolgt der
Datenimport in standardisierter Weise. Eine nähere Beschreibung der Parameter-Liste findet sich auch [hier](docu/parameter_list.md).

Nach erfolgreichem Aufruf von `decarbmonitoring::indicator_init()` für einen neuen Indikator sind im jeweils neu erstellten Template schon die richtigen Parameter für den Import 
eines Datensatzes hinterlegt. 

Hier ein Beispiel für den Indikator `LF1` (Anzahl Rindvieh):

``` r
# LF1 - Anzahl Rindvieh ----------------------------------------------------


# Import data -------------------------------------------------------------
# Schritt 1 : hier werden die Daten eingelesen

ds <- create_dataset('LF1')
ds <- download_data(ds)

# Dieses Objekt dient als Grundlage zur Weiterverarbeitung

LF1_data <- ds$data

```


## Processing ⚙️

Die Datenaufbereitung variiert von Datensatz zu Datensatz
(`DATASET_ID`). Insbesondere was die Berechnungen anbelangt. Die
Berechnung werden spezifisch für jeden Datensatz gemacht. Falls in der Berechnung eines Indikators Bevölkerungszahlen (Schweiz/Kanton Zürich) benötigt werden, können diese einfach 
mit der Funktion `download_per_capita()` eingelesen werden. Diese lädt im Hintergrund den Indikator `Q1` herunter.

Beispiel anhand Indikator `LF1`

```r
# Einlesen von Populationsdaten für per_capita
LF1_pop <- decarbmonitoring::download_per_capita()
```

Für die weiteren Berechnungsschritte sind im Aufbereitungstemplate jeweils Hinweise gegeben. Es wird empfohlen, Code von schon erstellten Indikatoren wiederzuverwenden.

## Export 💾

Die verarbeiteten Daten werden in einer harmonisierten Datenstruktur
exportiert, die für alle Datensätze identisch ist. Die exportierten
Daten bilden die Grundlage für die Visualisierungen.



**Datenstruktur**

| Jahr                    | Gebiet                  | Indikator_ID            | Indikator_Name          | Variable                | Datenquelle             | Einheit                 | Wert   |
|-------------------------|-------------------------|-------------------------|-------------------------|-------------------------|-------------------------|-------------------------|--------|
| *dimension attributes* | *dimension attributes* | *dimension attributes* | *dimension attributes* | *dimension attributes* | *dimension attributes* | *dimension attributes* | *fact* |

**Logik hinter der Datenstruktur**

Die Tabelle besteht aus *dimension attributes* und *facts*. Wobei die
*facts* durch die *dimension attributes* beschrieben werden.

- *dimension attributes* liefern strukturierte
  Beschreibungsinformationen. Die Hauptfunktionen der *dimension
  attributes* sind: Filtern, Gruppieren und Bezeichnen.

- *facts* stellen die messbaren Werte dar.

In unserer Tabelle entspricht alles links der `Wert`-Spalte den
*dimension attributes* und die `Wert`-Spalte ist der *fact*.

> Sometimes (…), it is unclear whether a numeric data field from a data
> source is a measured fact or an attribute. Generally, if the numeric
> data field is a measurement that changes each time you sample it, the
> field is a fact. If field is a discretely valued description of
> something that is more or less constant, it is a dimension
> attribute.[^1]

Sind die Daten nach der Verarbeitung in der richtigen Struktur, können Sie ganz einfach im Template in die Export-Funktionen gegeben werden. Hier wieder beispielhaft für den Indikator `LF1`

```r
# Harmonisierung Datenstruktur / Bezeichnungen  ----------------------------------------------------------

# Schritt 3 : Hier werden die Daten in die finale Form gebracht

# - Angleichung der Spaltennamen / Kategorien und Einheitslabels an die Konvention
# - Anreicherung mit Metadaten aus der Datensatzliste

LF1_export_data <- LF1_computed %>%
  dplyr::mutate(Indikator_ID = ds$dataset_id,
                Indikator_Name = ds$indicator_name,
                Datenquelle = ds$data_source,
                Variable = ds$dataset_name) %>%
  dplyr::select(Jahr, Gebiet, Indikator_ID, Indikator_Name, Variable, Wert, Einheit, Datenquelle)

# assign data to be exported back to the initial ds object -> ready to export
ds$export_data <- LF1_export_data

# Export CSV --------------------------------------------------------------

# Daten werden in den /output - Ordner geschrieben

export_data(ds)

```

Die Funktion `export_data(ds)` prüft dabei, ob der Datensatz schon einmal aufbereitet wurde. Wenn dies der Fall ist, muss aktiv bestätigt werden, dass man den Datensatz überschreiben möchte.
Ausserdem wirft die Funktion einen Fehler, wenn Variablen fehlen/überflüssig sind im Export-Datensatz.

## Troubleshooting
Der Code läuft Stand Juli 2023 stabil auf einer Linux-Umgebung sowie der Windows-Umgebung des "Digitalen Arbeitsplatzes" (DAP). Da jeder Indikator externe Daten lädt und transfomiert, kann keine Garantie für das Funktionieren der Pipeline in Zukunft übernommen werden. Auch bei Aufnahmen eines neuen Indikators in der [Excel-Liste](https://github.com/statistikZH/decarb_monitoring/blob/main/2773%20Monitoring.xlsx) können sich Fehler einschleichen. Deshalb findet sich [hier](docu/Troubleshooting.md) eine Sammlung an Hinweisen, wie mögliche Probleme entstehen und behoben werden können. 

Um zu überprüfen ob alle Indikatoren eingelesen und heruntergeladen werden können, kann man die Hilfsfunktion `test_pipeline()` nutzen. Diese spielt eine Liste zurück, welche für jeden Indikator einen Eintrag samt Daten enthält. Bei einem Fehler empfiehlt es sich, zu überprüfen an welcher Stelle/welchem Indikator die Funktion stoppt. Dies erleichtert die Fehlersuche und somit Behebung.

```r
list_of_indicators <- decarbmonitoring::test_pipeline()

```
 
## Kontakte 📧

### AWEL

**Amt für Abfall, Wasser, Energie und Luft** Luft, Klima und Strahlung
Klima und Mobilität

| Name            | E-Mail                   |
|-----------------|--------------------------|
| Gian-Marco Alt  | gian-marco.alt@bd.zh.ch  |
| Nathalie Hutter | nathalie.hutter@bd.zh.ch |
| Cuno Bieler     | cuno.bieler@bd.zh.ch     |

### STAT

| Name            | E-Mail                            |
|-----------------|-----------------------------------|
| Corinna Grobe   | corinna.grobe@statistik.ji.zh.ch  |
| Philipp Bosch   | philipp.bosch@statistik.ji.zh.ch  |
| Thomas Lo Russo | thomas.lorusso@statistik.ji.zh.ch |

[^1]: Dimension attributes. (o.D.). © Copyright IBM Corporation 2016.
    <https://www.ibm.com/docs/en/informix-servers/12.10?topic=model-dimension-attributes>
