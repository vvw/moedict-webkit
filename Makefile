run ::
	node ./static-here.js 8888 | lsc -cw main.ls server.ls | jade -Pw index.jade | compass watch

upload ::
	rsync -avzP main.* styles.css index.html js moe0:code/
	rsync -avzP main.* styles.css index.html js moe1:code/

deps ::
	npm install webworker-threads

checkout ::
	-git clone --depth 1 https://github.com/g0v/moedict-data.git
	-git clone --depth 1 https://github.com/g0v/moedict-data-twblg.git
	-git clone --depth 1 https://github.com/g0v/moedict-data-hakka.git
	-git clone --depth 1 https://github.com/g0v/moedict-data-csld.git
	-git clone https://github.com/g0v/moedict-epub.git

moedict-data :: checkout

offline :: moedict-data deps translation
	ln -fs ../moedict-data/dict-revised-translated.json moedict-epub/dict-revised.json
	cd moedict-epub && perl json2unicode.pl             > dict-revised.unicode.json
	cd moedict-epub && perl json2unicode.pl sym-pua.txt > dict-revised.pua.json
	ln -fs moedict-epub/dict-revised.unicode.json          dict-revised.unicode.json
	ln -fs moedict-epub/dict-revised.pua.json              dict-revised.pua.json
	ln -fs moedict-data-twblg/dict-twblg.json              dict-twblg.json
	ln -fs moedict-data-twblg/dict-twblg-ext.json          dict-twblg-ext.json
	ln -fs moedict-data-hakka/dict-hakka.json              dict-hakka.json
	ln -fs moedict-data-csld/dict-csld.json                dict-csld.json
	lsc json2prefix.ls a
	lsc autolink.ls a > a.txt
	perl link2pack.pl a < a.txt
	lsc json2prefix.ls t
	lsc autolink.ls t > t.txt
	perl link2pack.pl t < t.txt
	lsc json2prefix.ls h
	lsc autolink.ls h > h.txt
	perl link2pack.pl h < h.txt
	-lsc json2prefix.ls c
	-lsc autolink.ls c > c.txt
	-perl link2pack.pl c < c.txt
	perl special2pack.pl

csld ::
	python translation-data/csld2json.py
	cp translation-data/csld-translation.json dict-csld.json
	lsc json2prefix.ls c
	lsc autolink.ls c > c.txt
	perl link2pack.pl c < c.txt
	cp moedict-data-csld/index.json c/

hakka ::
	cp ../hakka/dict-hakka.json .
	lsc json2prefix.ls h
	lsc autolink.ls h > h.txt
	perl link2pack.pl h < h.txt

twblg ::
	lsc json2prefix.ls t
	lsc autolink.ls t > t.txt
	perl link2pack.pl t < t.txt

translation :: moedict-data
	cd translation-data && curl http://www.mdbg.net/chindict/export/cedict/cedict_1_0_ts_utf-8_mdbg.txt.gz | gunzip > cedict.txt
	cd translation-data && curl http://www.handedict.de/handedict/handedict-20110528.tar.bz2 | tar -Oxvj -f - handedict-20110528/handedict_nb.u8 > handedict.txt
	cd translation-data && curl -O 'http://www.chine-informations.com/chinois/open/CFDICT/cfdict_xml.zip' && unzip cfdict_xml.zip && rm cfdict_xml.zip
	python translation-data/xml2txt.py
	python translation-data/txt2json.py
	cp translation-data/moe-translation.json moedict-data/dict-revised-translated.json

all :: data/0/100.html
	tar jxf data.tar.bz2
