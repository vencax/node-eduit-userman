.PHONY: build

duplicate:
	echo "CREATE DATABASE eduit;" | mysql -u root -p
	echo "GRANT ALL PRIVILEGES ON eduit.* TO 'pgina'@'%' WITH GRANT OPTION;" | mysql -u root -p
	mysqldump -u pgina -p pgina > msql.dump
	cat msql.dump | mysql -u pgina -p eduit

backup:
	cp -r /var/lib/mysql/ /tmp/mysql.bck

run:
	# coffee --nodejs --debug-brk mergeDuplicatedTables.coffee
	python merge.py
