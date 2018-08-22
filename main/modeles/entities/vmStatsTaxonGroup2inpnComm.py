# coding: utf-8
from sqlalchemy import BigInteger, Column, Date, DateTime, Integer, MetaData, String, Table, Text
from geoalchemy2.types import Geometry
from sqlalchemy.sql.sqltypes import NullType
from sqlalchemy.orm import mapper
from sqlalchemy.ext.declarative import declarative_base
from ...utils import engine

metadata = MetaData()
Base = declarative_base()

class VmStatsTaxonGroup2inpnComm(Base):
    __table__ = Table(
    'vm_stats_espece_group2inpn_comm', metadata,
    Column('insee', String, primary_key=True, unique=True),
    Column('acanthocephales', Integer),
    Column('algues_brunes', Integer),
    Column('algues_rouges', Integer),
    Column('algues_vertes', Integer),
    Column('amphibiens', Integer),
    Column('angiospermes', Integer),
    Column('annelides', Integer),
    Column('arachnides', Integer),
    Column('ascidies', Integer),
    Column('autres', Integer),
    Column('bivalves', Integer),
    Column('cephalopodes', Integer),
    Column('crustaces', Integer),
    Column('diatomees', Integer),
    Column('entognathes', Integer),
    Column('fougeres', Integer),
    Column('gasteropodes', Integer),
    Column('gymnospermes', Integer),
    Column('hepatiques_anthocerotes', Integer),
    Column('hydrozoaires', Integer),
    Column('insectes', Integer),
    Column('lichens', Integer),
    Column('mammiferes', Integer),
    Column('mousses', Integer),
    Column('myriapodes', Integer),
    Column('nematodes', Integer),
    Column('nemertes', Integer),
    Column('octocoralliaires', Integer),
    Column('oiseaux', Integer),
    Column('poissons', Integer),
    Column('pycnogonides', Integer),
    Column('reptiles', Integer),
    Column('scleractiniaires', Integer),

    schema='atlas', autoload=True, autoload_with=engine
)


