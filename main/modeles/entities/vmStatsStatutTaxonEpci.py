# coding: utf-8
from sqlalchemy import BigInteger, Column, Date, DateTime, Integer, MetaData, String, Table, Text
from geoalchemy2.types import Geometry
from sqlalchemy.sql.sqltypes import NullType
from sqlalchemy.orm import mapper
from sqlalchemy.ext.declarative import declarative_base
from ...utils import engine

metadata = MetaData()
Base = declarative_base()

class vmStatsStatutTaxonEpci(Base):
    __table__ = Table(
    'vm_stats_statut_taxon_epci', metadata,
    Column('nom_epci_simple', String, primary_key=True, unique=True),
    Column('nb_taxon_pro', Integer),
    Column('nb_taxon_patri', Integer),
    Column('nb_taxon_que_pro', Integer),
    Column('nb_taxon_que_patri', Integer),
    Column('nb_taxon_pro_et_patri', Integer),
    Column('nb_taxon_sans_statut', Integer)
    schema='atlas', autoload=True, autoload_with=engine
)


