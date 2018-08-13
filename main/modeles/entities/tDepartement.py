# coding: utf-8
from sqlalchemy import BigInteger, Boolean, Column, ForeignKey, Integer, String
from geoalchemy2 import Geometry
from sqlalchemy.orm import relationship
from sqlalchemy.ext.declarative import declarative_base



Base = declarative_base()
metadata = Base.metadata


class tDepartement(Base):
    __tablename__ = 'dpt_simpli_pdl'
    __table_args__ = {u'schema': 'layers'}

    id_0 = Column(Integer, primary_key=True)
    num_dpt = Column(String(5))
    nom_dpt = Column(String(254))
    geojson_dpt = Column(String)
    geom = Column(Geometry)

