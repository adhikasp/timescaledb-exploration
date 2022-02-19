set -e
set -x

date
mysql -h 192.168.0.103 -P 3308 -u root -ppassword < mysql.sql
# date
# python3 generate-data.py
date
mysqlimport  -h 192.168.0.103 -P 3308 -u root -ppassword --local exploration --use-threads=2 --fields-terminated-by=, --verbose transactions.csv