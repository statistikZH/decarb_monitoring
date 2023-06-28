# Troubleshooting

Hier sind einige Beispiele aufgeführt, welche in der Entwicklung des Projekts anfällig für Fehler waren. Diese Liste ist nicht erschöpfend und sollte im Betrieb des Projekts ergänzt werden.

## Fehler beim Download von px-Dateien (BFS)

PX-Dateien sind etwas speziell beim download, da diese über die API des BFS bezogen werden. Die API benötigt dabei genaue Angaben, welche Variablen (Indikatoren) aus einem Datensatz eingelesen werden sollen. Ausserdem muss angegeben werden, welche Ausprägungen (Werte) heruntergeladen werden sollen. Diese Angaben werden im Workflow des decarbmonitoring-packages für jeden Indikator in der [Excel-Liste](https://github.com/statistikZH/decarb_monitoring/blob/main/2773%20Monitoring.xlsx) hinterlegt. Hierbei kann es leicht zu Fehlern kommen, wenn sich Tippfehler einschleichen oder Ausprägungen vergessen werden.

Hier ein Beispiel für den Indikator M2 und wie die Einträge in der Excel zustande kommen.

| DATASET_ID | INDICATOR_NAME                                             | DIMENSION1_COL | DIMENSION1_ID                        | DIMENSION1_NAME                                                                                                                                                           |
|---------------|---------------|---------------|---------------|---------------|
| M2         | Antriebsart bei Gütertransportfahrzeugen - Fahrzeugbestand | Treibstoff     | 100,200,300,310,400,500,550,600,9900 | Benzin,Diesel,Benzin-elektrisch: Normal-Hybrid,Benzin-elektrisch: Plug-in-Hybrid,Diesel-elektrisch: Normal-Hybrid,Elektrisch,Wasserstoff,Gas (mono- und bivalent),Anderer |

Die Angaben in den Spalten `DIMENSION1_COL`, `DIMENSION1_ID` und `DIMENSION1_NAME` **MÜSSEN EXAKT** den Ausprägungen/Codierungen der BFS-Tabellen entsprechen. Die Codierungen können online entweder über einen Click auf [JSON-Struktur](https://www.pxweb.bfs.admin.ch/api/v1/de/px-x-1103020100_135/px-x-1103020100_135.px) unter *Weiterführende Links* oder über das [STAT-TAB Tool](https://www.pxweb.bfs.admin.ch/pxweb/de/px-x-1103020100_135/px-x-1103020100_135/px-x-1103020100_135.px) des BFS abgerufen werden.

[![](img/Anmerkung%202023-06-27%20171621.png)](https://www.bfs.admin.ch/asset/de/px-x-1103020100_135)

[![](img/Anmerkung%202023-06-27%20171955.png)](https://www.pxweb.bfs.admin.ch/pxweb/de/px-x-1103020100_135/px-x-1103020100_135/px-x-1103020100_135.px/table/tableViewLayout2/)

Aus dem STAT-TAB Tool lassen sich die Codes über einen Click auf *Über die Tabelle* und *Machen Sie diese Tabelle in Ihrer Applikation verfügbar* abrufen. Dazu einfach vorab die gewünschten Merkmale und Ausprägungen selektieren, als Ausgabe Tabelle wählen und auf den Button `Weiter` am Ende der Seite clicken.

Die Angaben zu Dimensionen und Ausprägungen lassen sich 1:1 auf die räumlichen Einheiten übertragen. Da diese in px-Tabellen auch als Dimensionen gesehen werden, müssen die Einträge in den Spalten `GEBIET_COL` und `GEBIET_ID` den entsprechenden Codes in der PX-Tabelle gleichen. Für den Kanton Zürich und die Schweiz werden oft (leider nicht immer) die Codes `0` und `1` verwendet.

## Falsches Dateiformat in Excel-Liste angegeben

Hier ein Beispiel anhand 3 verschiedener Indikatoren.

| DATASET_ID | DATASET_NAME                  | DOWNLOAD_FORMAT | DATA_ORGANIZATION |
|-----------------|-----------------|---------------------|---------------------|
| G1         | Heizsysteme in Gebäuden       | px              | bfs               |
| KG4        | Treibhausgas-Fussabdruck      | xlsx            | bfs               |
| LF3        | Eingesetzter Stickstoffdünger | csv             | awel              |


Die Funktionalität im Package ist so konzipiert, dass je nach `DATA_ORGANIZATION` und `DOWNLOAD_FORMAT` unterschiedliche Methoden aufgerufen werden. Dies ist insbesondere für px-Dateien vom BFS wichtig. Schleicht sich also ein Schreibfehler bei *bfs* ein, kann die richtige Methode für den Download der Datei nicht gefunden werden. Analog dazu sollte auch beim `DOWNLOAD_FORMAT` darauf geachtet werden, keine Schreibfehler einzubauen.


