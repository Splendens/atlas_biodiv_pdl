
# -*- coding:utf-8 -*-

from flask import json, Blueprint
from werkzeug.wrappers import Response
from . import utils
from modeles.repositories import (
    vmSearchTaxonRepository, vmObservationsRepository, vmCommunesRepository,
    vmObservationsMaillesRepository, vmObservationsMaillesRepository, 
    vmObservationsMaillesCommunalesRepository, vmMedias
)
from configuration import config

api = Blueprint('api', __name__)


@api.route('/searchTaxon/', methods=['GET'])
def searchTaxonAPI():
    session = utils.loadSession()
    listeTaxonsSearch = vmSearchTaxonRepository.listeTaxons(session)
    session.close()
    return Response(json.dumps(listeTaxonsSearch), mimetype='application/json')


@api.route('/observationsMailleAndPoint/<int:cd_ref>', methods=['GET'])
def getObservationsMailleAndPointAPI(cd_ref):
    connection = utils.engine.connect()
    observations = {
        'point': vmObservationsRepository.searchObservationsChilds(connection, cd_ref),
        'maille': vmObservationsMaillesRepository.getObservationsMaillesChilds(connection, cd_ref)
    }
    connection.close()
    return Response(json.dumps(observations), mimetype='application/json')


@api.route('/observationsMaille/<int:cd_ref>', methods=['GET'])
def getObservationsMailleAPI(cd_ref):
    connection = utils.engine.connect()
    observations = vmObservationsMaillesRepository.getObservationsMaillesChilds(connection, cd_ref)
    connection.close()
    return Response(json.dumps(observations), mimetype='application/json')


@api.route('/observationsMailleCommunale/<int:cd_ref>', methods=['GET'])
def getObservationsMailleCommunaleAPI(cd_ref):
    connection = utils.engine.connect()
    observations = vmObservationsMaillesCommunalesRepository.getObservationsMaillesCommunalesChilds(connection, cd_ref)
    connection.close()
    return Response(json.dumps(observations), mimetype='application/json')


@api.route('/observationsPoint/<int:cd_ref>', methods=['GET'])
def getObservationsPointAPI(cd_ref):
    connection = utils.engine.connect()
    observations = vmObservationsRepository.searchObservationsChilds(connection, cd_ref)
    connection.close()
    return Response(json.dumps(observations), mimetype='application/json')


@api.route('/pressionProspectionCommune/<insee>', methods=['GET'])
def getpressionProspectionCommuneAPI(insee):
    connection = utils.engine.connect()
    observations = vmObservationsMaillesRepository.pressionProspectionCommune(connection, insee)
    connection.close()
    return Response(json.dumps(observations), mimetype='application/json')

@api.route('/pressionProspectionEpci/<nom_epci_simple>', methods=['GET'])
def getpressionProspectionEpciAPI(nom_epci_simple):
    connection = utils.engine.connect()
    observations = vmObservationsMaillesRepository.pressionProspectionEpci(connection, nom_epci_simple)
    connection.close()
    return Response(json.dumps(observations), mimetype='application/json')

@api.route('/pressionProspectionEpciMaillesCommunales/<nom_epci_simple>', methods=['GET'])
def getpressionProspectionEpciMaillesCommunalesAPI(nom_epci_simple):
    connection = utils.engine.connect()
    observations = vmObservationsMaillesCommunalesRepository.getpressionProspectionEpciMaillesCommunalesChilds(connection, nom_epci_simple)
    connection.close()
    return Response(json.dumps(observations), mimetype='application/json')

@api.route('/pressionProspectionDpt/<num_dpt>', methods=['GET'])
def getpressionProspectionDptAPI(num_dpt):
    connection = utils.engine.connect()
    observations = vmObservationsMaillesRepository.pressionProspectionDpt(connection, num_dpt)
    connection.close()
    return Response(json.dumps(observations), mimetype='application/json')

@api.route('/pressionProspectionDpt10/<num_dpt>', methods=['GET'])
def getpressionProspectionDpt10API(num_dpt):
    connection = utils.engine.connect()
    observations = vmObservationsMaillesRepository.pressionProspectionDpt10(connection, num_dpt)
    connection.close()
    return Response(json.dumps(observations), mimetype='application/json')


@api.route('/pressionProspectionDptMaillesCommunales/<num_dpt>', methods=['GET'])
def getpressionProspectionDptMaillesCommunalesAPI(num_dpt):
    connection = utils.engine.connect()
    observations = vmObservationsMaillesCommunalesRepository.getpressionProspectionDptMaillesCommunalesChilds(connection, num_dpt)
    connection.close()
    return Response(json.dumps(observations), mimetype='application/json')

@api.route('/observations/<insee>/<int:cd_ref>', methods=['GET'])
def getObservationsCommuneTaxonAPI(insee, cd_ref):
    connection = utils.engine.connect()
    observations = vmObservationsRepository.getObservationTaxonCommune(connection, insee, cd_ref)
    connection.close()
    return Response(json.dumps(observations), mimetype='application/json')


@api.route('/observationsMaille/<insee>/<int:cd_ref>', methods=['GET'])
def getObservationsCommuneTaxonMailleAPI(insee, cd_ref):
    connection = utils.engine.connect()
    observations = vmObservationsMaillesRepository.getObservationsTaxonCommuneMaille(connection, insee, cd_ref)
    connection.close()
    return Response(json.dumps(observations), mimetype='application/json')


@api.route('/photoGroup/<group>', methods=['GET'])
def getPhotosGroup(group):
    connection = utils.engine.connect()
    photos = vmMedias.getPhotosGalleryByGroup(connection, config.ATTR_MAIN_PHOTO, config.ATTR_OTHER_PHOTO, group)
    connection.close()
    return Response(json.dumps(photos), mimetype='application/json')


@api.route('/photosGallery', methods=['GET'])
def getPhotosGallery():
    connection = utils.engine.connect()
    photos = vmMedias.getPhotosGallery(connection, config.ATTR_MAIN_PHOTO, config.ATTR_OTHER_PHOTO)
    connection.close()
    return Response(json.dumps(photos), mimetype='application/json')
