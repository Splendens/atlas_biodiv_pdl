# coding: utf-8
from sqlalchemy import BigInteger, Column, Date, DateTime, Integer, MetaData, String, Table, Text
from geoalchemy2.types import Geometry
from sqlalchemy.sql.sqltypes import NullType
from sqlalchemy.orm import mapper
from sqlalchemy.ext.declarative import declarative_base
from ...utils import engine

metadata = MetaData()
Base = declarative_base()

class VmStatsOrgaComm(Base):
    __table__ = Table(
    'vm_stats_orga_comm', metadata,
    Column('insee', String, primary_key=True, unique=True),
    Column('_03', Integer),
    Column('_04', Integer),
    Column('_05', Integer),
    Column('_06', Integer),
    Column('_09', Integer),
    Column('_70', Integer),
    Column('_80', Integer),
    Column('_81', Integer),
    Column('_82', Integer),
    Column('_83', Integer),
    Column('_84', Integer),
    schema='atlas', autoload=True, autoload_with=engine
)


