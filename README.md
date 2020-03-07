# tools-and-scripts

## Brikkekontroll

### Setup

1. Last ned og installer emiTagCheck fra http://195.159.103.189:1379/software/
2. Plugg inn emit USB-leser (driver skal installeres automatisk)

### Import av startliste
1. Last ned rapport fra eqtiming: Fil for import i eTiming
2. ```bash
cat eTiming_Stafett_Import_2020.csv | tr -d ',' | awk -F';' '{printf"%i,%s,%s,%s,%s,%i,,%i\n", NR, $1, $2, $3, $4, $8, $7}' > emiTagCheck_Stafett_Import_2020.csv
```
3. Start emiTagCheck
4. Importer fil via File -> Open
