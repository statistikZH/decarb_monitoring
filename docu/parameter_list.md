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
