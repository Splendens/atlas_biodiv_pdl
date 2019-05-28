
# -*- coding:utf-8 -*-

from flask import jsonify, Blueprint, request
from werkzeug.wrappers import Response
from . import utils
from modeles.repositories import (
    vmSearchTaxonRepository, vmObservationsRepository, vmCommunesRepository,
    vmObservationsMaillesRepository, vmObservationsMaillesRepository, 
    vmObservationsMaillesCommunalesRepository, vmMedias, vmCommunesRepository, vmEpciRepository, vmDepartementRepository
)
from configuration import config

api = Blueprint('api', __name__)


@api.route('/searchTaxon', methods=['GET'])
def searchTaxonAPI():
    session = utils.loadSession()
    search = request.args.get('search', '')
    limit = request.args.get('limit', 50)
    results = vmSearchTaxonRepository.listeTaxonsSearch(session, search, limit)
    session.close()
    return jsonify(results)


@api.route('/searchCommune', methods=['GET'])
def searchCommuneAPI():
    session = utils.loadSession()
    search = request.args.get('search', '')
    limit = request.args.get('limit', 50)
    results = vmCommunesRepository.getCommunesSearch(session, search, limit)
    return jsonify(results)


@api.route('/searchEpci', methods=['GET'])
def searchEpciAPI():
    session = utils.loadSession()
    search = request.args.get('search', '')
    limit = request.args.get('limit', 50)
    results = vmEpciRepository.getEpciSearch(session, search, limit)
    return jsonify(results)


@api.route('/searchDepartement', methods=['GET'])
def searchDepartementAPI():
    session = utils.loadSession()
    search = request.args.get('search', '')
    limit = request.args.get('limit', 50)
    results = vmDepartementRepository.getDepartementSearch(session, search, limit)
    return jsonify(results)


@api.route('/observationsMailleAndPoint/<int:cd_ref>', methods=['GET'])
def getObservationsMailleAndPointAPI(cd_ref):
    connection = utils.engine.connect()
    observations = {
        'point': vmObservationsRepository.searchObservationsChilds(connection, cd_ref),
        'maille': vmObservationsMaillesRepository.getObservationsMaillesChilds(connection, cd_ref)
    }
    connection.close()
    return jsonify(observations)

@api.route('/observationsMaille/<int:cd_ref>', methods=['GET'])
def getObservationsMailleAPI(cd_ref):
    connection = utils.engine.connect()
    observations = vmObservationsMaillesRepository.getObservationsMaillesChilds(connection, cd_ref)
    connection.close()
    return jsonify(observations)


@api.route('/observationsMailleCommunale/<int:cd_ref>', methods=['GET'])
def getObservationsMailleCommunaleAPI(cd_ref):
    connection = utils.engine.connect()
    observations = vmObservationsMaillesCommunalesRepository.getObservationsMaillesCommunalesChilds(connection, cd_ref)
    connection.close()
    return jsonify(observations)


@api.route('/observationsPoint/<int:cd_ref>', methods=['GET'])
def getObservationsPointAPI(cd_ref):
    connection = utils.engine.connect()
    observations = vmObservationsRepository.searchObservationsChilds(connection, cd_ref)
    connection.close()
    return jsonify(observations)


@api.route('/pressionProspectionCommune/<insee>', methods=['GET'])
def getpressionProspectionCommuneAPI(insee):
    connection = utils.engine.connect()
    observations = vmObservationsMaillesRepository.pressionProspectionCommune(connection, insee)
    connection.close()
    return jsonify(observations)

@api.route('/pressionProspectionEpci/<nom_epci_simple>', methods=['GET'])
def getpressionProspectionEpciAPI(nom_epci_simple):
    connection = utils.engine.connect()
    observations = vmObservationsMaillesRepository.pressionProspectionEpci(connection, nom_epci_simple)
    connection.close()
    return jsonify(observations)

@api.route('/pressionProspectionEpciMaillesCommunales/<nom_epci_simple>', methods=['GET'])
def getpressionProspectionEpciMaillesCommunalesAPI(nom_epci_simple):
    connection = utils.engine.connect()
    observations = vmObservationsMaillesCommunalesRepository.getpressionProspectionEpciMaillesCommunalesChilds(connection, nom_epci_simple)
    connection.close()
    return jsonify(observations)

@api.route('/pressionProspectionDpt/<num_dpt>', methods=['GET'])
def getpressionProspectionDptAPI(num_dpt):
    connection = utils.engine.connect()
    observations = vmObservationsMaillesRepository.pressionProspectionDpt(connection, num_dpt)
    connection.close()
    return jsonify(observations)

@api.route('/pressionProspectionDptMaillesCommunales/<num_dpt>', methods=['GET'])
def getpressionProspectionDptMaillesCommunalesAPI(num_dpt):
    connection = utils.engine.connect()
    observations = vmObservationsMaillesCommunalesRepository.getpressionProspectionDptMaillesCommunalesChilds(connection, num_dpt)
    connection.close()
    return jsonify(observations)

@api.route('/observations/<insee>/<int:cd_ref>', methods=['GET'])
def getObservationsCommuneTaxonAPI(insee, cd_ref):
    connection = utils.engine.connect()
    observations = vmObservationsRepository.getObservationTaxonCommune(connection, insee, cd_ref)
    connection.close()
    return jsonify(observations)


@api.route('/observationsMaille/<insee>/<int:cd_ref>', methods=['GET'])
def getObservationsCommuneTaxonMailleAPI(insee, cd_ref):
    connection = utils.engine.connect()
    observations = vmObservationsMaillesRepository.getObservationsTaxonCommuneMaille(connection, insee, cd_ref)
    connection.close()
    return jsonify(observations)


@api.route('/photoGroup/<group>', methods=['GET'])
def getPhotosGroup(group):
    connection = utils.engine.connect()
    photos = vmMedias.getPhotosGalleryByGroup(
        connection, 
        current_app.config['ATTR_MAIN_PHOTO'], 
        current_app.config['ATTR_OTHER_PHOTO'], 
        group
    )
    connection.close()
    return jsonify(photos)


@api.route('/photosGallery', methods=['GET'])
def getPhotosGallery():
    connection = utils.engine.connect()
    photos = vmMedias.getPhotosGallery(
        connection, 
        current_app.config['ATTR_MAIN_PHOTO'], 
        current_app.config['ATTR_OTHER_PHOTO']
    )
    connection.close()
    return jsonify(photos)
