#!/usr/bin/env python

from flask import Flask, escape, redirect, render_template, request, session, url_for
from flask_sqlalchemy import SQLAlchemy
from werkzeug.exceptions import NotFound as WerkzeugNotFound

import os
import sqlite3

app = Flask(__name__, static_folder='images')
app.secret_key = "[\xf4'\n\xe3o\xfb\x86e\xf6TB\xc2\x92\xa3b\xfd\xa96|o\xd7\xfe["
app.SQLALCHEMY_DATABASE_URI = 'sqlite:////tmp/ffffound-blech.db'

db = SQLAlchemy(app)

class Image(db.Model):
    __tablename__ = 'images'
    id = db.Column(db.String, primary_key=True)
    url = db.Column(db.String)
    src = db.Column(db.String)
    orig_url = db.Column(db.String)
    orig_src = db.Column(db.String)
    date = db.Column(db.DateTime)
    count = db.Column(db.Integer)
    related = db.Column(db.String)
    posted = db.Column(db.Boolean)

@app.route("/")
def index():
    offset = request.args.get('offset', 0)
    print offset
    images = Image.query.order_by(Image.date.desc()).limit(10).offset(offset)
    return render_template("index.html", images=images, offset=offset)

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

if __name__ == "__main__":
    app.run(debug = True, port=7790)

url_for('static', filename='images')
