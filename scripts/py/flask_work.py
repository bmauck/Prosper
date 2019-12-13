# -*- coding: utf-8 -*-
"""
Created on Wed Apr 17 09:13:58 2019

@author: bmauck
"""
from flask import Flask
app = Flask(__name__)


@app.route('/')
def hello_world():
    return 'Hello, World!'

if __name__ == '__main__':
    app.run()
