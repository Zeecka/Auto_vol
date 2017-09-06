#!/usr/bin/python2

from bs4 import BeautifulSoup
from urllib2 import urlopen
from sys import argv

fp = urlopen("https://app.vagrantup.com/boxes/search?sort=downloads&provider=virtualbox&q="+argv[1])
html = fp.read()
fp.close

parsed_html = BeautifulSoup(html, "lxml")

# If a profil is find, then display it, otherwise print "Nop"
try:
	print parsed_html.find("h4").find(text=True).strip()
except AttributeError:
	print "Nop"