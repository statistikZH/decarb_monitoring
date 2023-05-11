
<!-- README.md is generated from README.Rmd. Please edit that file -->

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
Datenimport in standardisierter Weise.

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

**Inhalte der Parameterliste**

| Parameter         | Beschreibung                                                                                                                               |
|-------------------|--------------------------------------------------------------------------------------------------------------------------------------------|
| DATASET_ID        | ID gem. AWEL                                                                                                                               |
| DATASET_NAME      | NAME gem. AWEL                                                                                                                             |
| INDICATOR_NAME    | Hier kann dem Indikator ein kürzerer, prägnanterer Name gegeben werden, wie er an der Visualisierung verwendet werden kann                 |
| DOWNLOAD_FORMAT   | Dateiformat bei der Datenquelle, bspw. px, XLSX, CSV, CSV aus gezipptem Ordner. Wichtig für Wahl der download-Methode                      |
| DATA_ORGANIZATION | Organisation, welche die Daten bereitstellt, bspw. BFS, openzh                                                                             |
| DATA_URL          | URL zu den Daten                                                                                                                           |
| DATA_ID           | ID eines Datensets, einer Ressource o.ä., bspw. px-x-0103010000_102                                                                        |
| WHICH_DATA        | Wird eine spezifische Datei verwendet? Name der csv aus zip oder Blattname in Excel                                                        |
| YEAR_COL          | Name der Spalte, in der das Erfassungsjahr steht                                                                                           |
| YEAR_START        | Jahr, in dem die Zeitreihe beginnt                                                                                                         |
| GEBIET_COL        | Name der Spalte, in der das Gebiet erfasst ist, bspw. bei BFS pxweb oftmals “Kanton”                                                       |
| GEBIET_ID         | Wichtig bei px-Tabellen des BFS. Wie ist Gebiet numerisch kodiert? Bsp.: Schweiz = 0, Zürich = 1                                           |
| GEBIET_NAME       | Namen der Gebiete, wie an der Quelle                                                                                                       |
| DIMENSION1_COL    | Name der Spalte, in der die Variable erfasst ist, die importiert werden soll, bspw. Treibstoff für die Treibstofftypen Benzin, Diesel etc. |
| DIMENSION1_ID     | Frei lassen                                                                                                                                |
| DIMENSION1_NAME   | Name(n) der Ausprägungen der Variable, bspw. Benzin, Diesel etc.                                                                           |
| DIMENSION2_COL    | Name der Spalte, in der eine weitere Variable erfasst ist, die importiert werden soll. Diese Variable ist eigentlich nur für einzelne px Tabellen relevant. |
| DIMENSION2_ID     | Frei lassen                                                                                                                                |
| DIMENSION2_NAME   | Name(n) der Ausprägungen der weiteren Variable, bspw. Benzin, Diesel etc.                                                                           |
| DIMENSION_UNIT    | Einheit in Kurzform für die Dimension                                                                                                      |
| DIMENSION_LABEL   | Einheit in Langform für die Dimension                                                                                                      |
| DIMENSION_AGGREGATION | Wie werden Dimensionen zusammengefasst?                                                                                                |
| DATA_SOURCE       | Angabe zur Datenquelle                                                                                                                     |
| DIAGRAMM          | Angabe zur gewünschten Visualisierung. Hilft bei Aufbereitung                                                                              |
| COMPUTATION_DEF   | Formalisierung der gewünschten Berechnungen.                                                                                               |
| COMPUTATION       | Welche Berechnungen sollen gemacht werden. Bspw. Pro Einwohner, Anteil etc.                                                                |
| UPDATE_DATE       | Frei lassen                                                                                                                                |
| LAST_UPDATED      | Frei lassen                                                                                                                                |
| MODIFY_NEXT       | Frei lassen                                                                                                                                |
| DEPENDENCY        | ID eines anderen Indikators welcher zur Berechnung benötigt wird. Wird beim erstellen automatisch miteingelsen                             |

## Processing

Die Datenaufbereitung variiert von Datensatz zu Datensatz
(`DATASET_ID`). Insbesondere was die Berechnungen anbelangt. Die
Berechnung werden vorerst spezifisch für jeden Datensatz gemacht. Wo
sich wiederkehrende Berechnungen in Funktionen auslagern lassen, wird
das gemacht.

**Übersicht der Berechnungs-Funktionen**

| Function                | Title                    | Description                                                                                                 |
|-------------------------|--------------------------|-------------------------------------------------------------------------------------------------------------|
| `download_per_capita()` | Pro Einwohner-Berechnung | Lädt die Bevölkerungsdaten aus DATASET_ID ‘Q1’ und lässt sich dann in der Berechnung pro Einwohner aufrufen |
| …                       | …                        | …                                                                                                           |

## Export

Die verarbeiteten Daten werden in einer harmonisierten Datenstruktur
exportiert, die für alle Datensätze identisch ist. Die exportierten
Daten bilden die Grundlage für die Visualisierungen.

**Datenstruktur**

| Jahr                    | Gebiet                  | Indikator_ID            | Indikator_Name          | Variable                | Datenquelle             | Einheit                 | Wert   |
|-------------------------|-------------------------|-------------------------|-------------------------|-------------------------|-------------------------|-------------------------|--------|
| *dimsension attributes* | *dimsension attributes* | *dimsension attributes* | *dimsension attributes* | *dimsension attributes* | *dimsension attributes* | *dimsension attributes* | *fact* |

**Logik hinter der Datenstruktur**

Die Tabelle besteht aus *dimsension attributes* und *facts*. Wobei die
*facts* durch die *dimension attributes* beschrieben werden.

- *dimsension attributes* liefern strukturierte
  Beschreibungsinformationen. Die Hauptfunktionen der *dimsension
  attributes* sind: Filtern, Gruppieren und Bezeichnen.

- *facts* stellen die messbaren Werte dar.

In unserer Tabelle entspricht alles links der `Wert`-Spalte den
*dimsension attributes* und die `Wert`-Spalte ist der *fact*.

> Sometimes (…), it is unclear whether a numeric data field from a data
> source is a measured fact or an attribute. Generally, if the numeric
> data field is a measurement that changes each time you sample it, the
> field is a fact. If field is a discretely valued description of
> something that is more or less constant, it is a dimension
> attribute.[^1]

## Kontakte

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
