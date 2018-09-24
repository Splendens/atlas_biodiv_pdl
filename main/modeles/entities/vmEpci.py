# coding: utf-8
from sqlalchemy import Boolean, Column, Date, DateTime, Integer, MetaData, String, Table, Text
from geoalchemy2.types import Geometry
from sqlalchemy.sql.sqltypes import NullType
from sqlalchemy.orm import mapper
from sqlalchemy.ext.declarative import declarative_base
from ...utils import engine

metadata = MetaData()
Base = declarative_base()

class VmEpci(Base):
    __table__ = Table(
    'vm_epci', metadata,
    Column('id', String(5),primary_key=True, unique=True),
    Column('nom_epci', String(50)),
    Column('nom_epci_simple', String(50)),
    Column('the_geom', Geometry(u'MULTIPOLYGON', 2154), index=True),
    schema='atlas', autoload=True, autoload_with=engine
)

