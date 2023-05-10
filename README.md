
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

## Setup

Um den Prozess für einen neuen Indikator zu initialiseren sind die
folgenden Vorbereitungen notwendig. Schritte 1. und 2. sind dabei nur
beim erstmaligen aufsetzen notwendig.

1.  Dieses Code-Repo clonen. Entweder über den [klassischen download des
    Repos](https://github.com/statistikZH/decarb_monitoring/archive/refs/heads/main.zip)
    oder einen [direkten Download in der R-Studio
    Benutzeroberfläche.](https://happygitwithr.com/rstudio-git-github.html#clone-the-test-github-repository-to-your-computer-via-rstudio)

2.  Installation notwendiger Pakete innerhalb des R-Projekts:

``` r
install.packages("devtools")
#> Installing devtools [2.4.5] ...
#>  OK [copied cache]
devtools::load_all()
#> ℹ Loading decarbmonitoring
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
#> ℹ Loading decarbmonitoring
```

Die Bestätigung erfolgt:

    ℹ Loading decarbmonitoring

4.  Um einen neuen Indikator anzulegen kann nun mittels der Funktion
    `decarbmonitoring::indicator_init()` ein neuer Indikator angelegt
    werden:

``` r
#Achtung: Code unten wird einen Fehler ergeben, da schon ein Skript für den Indikator M1 exisitert.
decarbmonitoring::indicator_init("M1")
```

## Import

Jeder Datensatz ist in der Parameter-Liste [2773
Monitoring.xlsx](https://github.com/statistikZH/decarb_monitoring/blob/main/2773%20Monitoring.xlsx)
beschrieben. Die Parameter-Liste ist die Grundlage für den Import der
Daten. Der Import wird in Abhängigkeit von ausgewählten Parametern (über
Methoden) definiert und kann somit auch auf andere Datensätze mit den
gleichen Parameterangaben angewendet werden. Basierend auf der
`DATASET_ID`, dem `DATA_FORMAT` und der `DATA_ORGANIZATION` erfolgt der
Datenimport in standardisierter Weise.

**Inhalte der Parameterliste**

| Parameter         | Beschreibung                                                                                                                               |
|-------------------|--------------------------------------------------------------------------------------------------------------------------------------------|
| DATASET_ID        | ID gem. AWEL                                                                                                                               |
| DATASET_NAME      | NAME gem. AWEL                                                                                                                             |
| INDICATOR_NAME    | Hier kann dem Indikator ein kürzerer, prägnanterer Name gegeben werden, wie er an der Visualisierung verwendet werden kann                 |
| DATA_FORMAT       | Dateiformat bei der Datenquelle, bspw. px, XLSX, CSV, CSV aus gezipptem Ordner                                                             |
| DATA_ORGANIZATION | Organisation, welche die Daten bereitstellt, bspw. BFS, openzh                                                                             |
| DATA_URL          | URL zu den Daten                                                                                                                           |
| DATA_ID           | ID eines Datensets, einer Ressource o.ä., bspw. px-x-0103010000_102                                                                        |
| DATA_FILE         | Wird eine spezifische Datei verwendet?                                                                                                     |
| YEAR_COL          | Name der Spalte, in der das Erfassungsjahr steht                                                                                           |
| YEAR_START        | Jahr, in dem die Zeitreihe beginnt                                                                                                         |
| GEBIET_COL        | Name der Spalte, in der das Gebiet erfasst ist, bspw. bei BFS pxweb oftmals “Kanton”                                                       |
| GEBIET_ID         | Frei lassen                                                                                                                                |
| GEBIET_NAME       | Namen der Gebiete, wie an der Quelle                                                                                                       |
| DIMENSION_COL     | Name der Spalte, in der die Variable erfasst ist, die importiert werden soll, bspw. Treibstoff für die Treibstofftypen Benzin, Diesel etc. |
| DIMENSION_ID      | Frei lassen                                                                                                                                |
| DIMENSION_NAME    | Name(n) der Ausprägungen der Variable, bspw. Benzin, Diesel etc.                                                                           |
| DIMENSION_UNIT    | Einheit in Kurzform für die Dimension                                                                                                      |
| DIMENSION_LABEL   | Einheit in Langform für die Dimension                                                                                                      |
| DATA_SOURCE       | Angabe zur Datenquelle                                                                                                                     |
| COMPUTATION       | Welche Berechnungen sollen gemacht werden. Bspw. Pro Einwohner, Anteil etc.                                                                |
| UPDATE_DATE       | Frei lassen                                                                                                                                |
| LAST_UPDATED      | Frei lassen                                                                                                                                |
| MODIFY_NEXT       | Frei lassen                                                                                                                                |

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
