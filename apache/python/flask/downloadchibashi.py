import logging
from logging.handlers import RotatingFileHandler

from flask import Flask
from flask import send_from_directory
import urllib
import urllib2
#from BeautifulSoup import BeautifulSoup
import re

app = Flask(__name__, static_folder='static')

@app.route('/')
def root():
    return ':D :) Hello World! FUCK' 


@app.route('/uploads/<path:filename>')
def download_file(filename):
    #return send_from_directory(app.config['UPLOAD_FOLDER'],filename, as_attachment=True)
    print app.static_folder
    return send_from_directory(app.static_folder,filename, as_attachment=True)

if __name__ == '__main__':
    handler = RotatingFileHandler('foo.log', maxBytes=10000, backupCount=1)
    handler.setLevel(logging.INFO)
    app.logger.addHandler(handler)
    app.run(debug=True)

