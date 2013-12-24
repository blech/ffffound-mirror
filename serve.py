#!/usr/bin/env python

from flask import Flask, escape, redirect, render_template, request, session, url_for
from werkzeug.exceptions import NotFound as WerkzeugNotFound

import os
import sqlite3

from datetime import datetime

app = Flask(__name__, static_folder='images')
app.secret_key = "[\xf4'\n\xe3o\xfb\x86e\xf6TB\xc2\x92\xa3b\xfd\xa96|o\xd7\xfe["

def iso_date(value, format='medium'):
    dt = datetime.utcfromtimestamp(value)
    return dt.isoformat()
app.jinja_env.filters['iso_date'] = iso_date

@app.route("/")
def index():
    offset = request.args.get('offset', 0)
    print offset
    images = default_images(offset)
    return render_template("index.html", images=images, site='', offset=offset)

@app.route("/filter/<site>")
def filter(site):
    offset = request.args.get('offset', 0)
    images = site_filter(site, offset)
    return render_template("index.html", images=images, site=site, offset=offset)

### db queries

def get_connection():
    conn = sqlite3.connect('db/ffffound-blech.db')
    c = conn.cursor()
    
    return c

def default_images(offset=0):
    c = get_connection()
    c.execute("SELECT * FROM images ORDER BY date DESC LIMIT 10 OFFSET ?", (int(offset),))
    images = c.fetchall()
    return images

def site_filter(site, offset=0):
    site = '%'+site+'%'
    
    c = get_connection()
    c.execute("SELECT * FROM images WHERE orig_url LIKE ? ORDER BY date DESC LIMIT 10 OFFSET ?", (site, int(offset),))
    images = c.fetchall()
    return images
    

if __name__ == "__main__":
    app.run(debug = True, port=7790)

url_for('static', filename='images')