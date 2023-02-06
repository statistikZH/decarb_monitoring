# decarb_monitoring
Repository für den Bezug der Daten fürs Dekarbonisierungsmonitoring des Kantons Zürich

## Input

Jeder Datensatz ist in der Parameterliste ==[dataset_parameter_list.xlsx](https://github.com/statistikZH/decarb_monitoring/blob/main/dataset_parameter_list.xlsx)== beschrieben.
Die Parameterliste ist die Grundlage für den Import der Daten. Der Import wird in Abhängigkeit von ausgewählten Parametern (über Methoden) definiert und kann somit auch auf andere Datensätze mit den gleichen Parameterangaben angewendet werden.
Basierend auf der 'DATASET_ID', dem 'DATA_FORMAT' und der 'DATA_ORGANIZATION' erfolgt der Datenimport in standardisierter Weise.

Jeder weitere Datensatz wird hinzugefügt und in der Parameterliste beschrieben.

**Inhalte der Parameterliste**

| Parameter     | Beschreibung |
| ---      | ---       |
| DATASET_ID  | ID gem. AWEL |
| DATASET_NAME | NAME gem. AWEL |
| INDICATOR_NAME | Hier kann dem Indikator ein kürzerer, prägnanterer Name gegeben werden, wie er an der Visualisierung verwendet werden kann | 
| DATA_FORMAT | Dateiformat bei der Datenquelle, bspw. px, XLSX, CSV, CSV aus gezipptem Ordner |
| DATA_ORGANIZATION | Organisation, welche die Daten bereitstellt, bspw. BFS, openzh | 
| DATA_URL | URL zu den Daten | 
| DATA_ID | ID eines Datensets, einer Ressource o.ä., bspw. px-x-0103010000_102 |
| DATA_FILE | Wird eine spezifische Datei verwendet? |
| YEAR_COL | Name der Spalte, in der das Erfassungsjahr steht |
| YEAR_START | Jahr, in dem die Zeitreihe beginnt |
| GEBIET_COL | Name der Spalte, in der das Gebiet erfasst ist, bspw. bei BFS pxweb oftmals "Kanton" |
| GEBIET_ID | Frei lassen |
| GEBIET_NAME | Namen der Gebiete, wie an der Quelle |
| DIMENSION_COL | Name der Spalte, in der die Variable erfasst ist, die importiert werden soll, bspw. Treibstoff für die Treibstofftypen Benzin, Diesel etc.|
| DIMENSION_ID | Frei lassen |
| DIMENSION_NAME | Name(n) der Ausprägungen der Variable, bspw. Benzin, Diesel etc. |
| DIMENSION_UNIT | Einheit in Kurzform für die Dimension | 
| DIMENSION_LABEL | Einheit in Langform für die Dimension |
| DATA_SOURCE | Angabe zur Datenquelle |
| COMPUTATION | Welche Berechnungen sollen gemacht werden. Bspw. Pro Einwohner, Anteil etc. |
| UPDATE_DATE | Frei lassen |
| LAST_UPDATED | Frei lassen |
| MODIFY_NEXT | Frei lassen |


