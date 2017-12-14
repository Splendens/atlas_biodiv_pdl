# coding: utf-8
from sqlalchemy import BigInteger, Boolean, Column, ForeignKey, Integer, String
from geoalchemy2 import Geometry
from sqlalchemy.orm import relationship
from sqlalchemy.ext.declarative import declarative_base



Base = declarative_base()
metadata = Base.metadata


class TPages(Base):
    __tablename__ = 't_pages'

    id_page = Column(Integer, primary_key=True)
    titre = Column(Text)
    route = Column(route)
    picto = Column(Text)
    ordre = Column(Integer)