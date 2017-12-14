#! /usr/bin/python
# -*- coding:utf-8 -*-

#from modele import utils
from .. import utils
from ...configuration import config

from sqlalchemy.sql import text

def getPages(connection):
    sql = "SELECT * \
    FROM atlas.t_pages \
    ORDER BY ordre"
    req = connection.execute(text(sql))
    tabPages = list()
    for r in req:
        temp = {
        'id_page': r.id_page, 
        'titre': r.titre, 
        'route':r.route, 
        'picto': r.picto, 
        'ordre': r.ordre
        }
        tabPages.append(temp)
    return tabPages