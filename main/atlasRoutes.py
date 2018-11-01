
# -*- coding:utf-8 -*-

from flask import render_template, redirect, abort, url_for
from configuration import config
from datetime import datetime
from flask_weasyprint import HTML, render_pdf

from modeles.repositories import (
    vmTaxonsRepository, vmObservationsRepository, vmAltitudesRepository, 
    vmMoisRepository, vmTaxrefRepository, vmStatsOrgaTaxonRepository, 
    vmCommunesRepository, vmEpciRepository, vmDepartementRepository,
    vmObservationsMaillesRepository, vmMedias, 
    vmStatsOrgaCommRepository, vmStatsGroup2inpnCommRepository, vmStatsTaxonGroup2inpnCommRepository, 
    vmStatsOrgaEpciRepository, vmStatsGroup2inpnEpciRepository, vmStatsTaxonGroup2inpnEpciRepository,
    vmStatsOrgaDptRepository, vmStatsGroup2inpnDptRepository, vmStatsTaxonGroup2inpnDptRepository,
    vmCorTaxonAttribut, vmTaxonsMostView
)
from . import utils

from flask import Blueprint
main = Blueprint('main', __name__)

base_configuration = {
    'STRUCTURE': config.STRUCTURE,
    'NOM_APPLICATION': config.NOM_APPLICATION,
    'URL_APPLICATION': config.URL_APPLICATION,
    'AFFICHAGE_FOOTER': config.AFFICHAGE_FOOTER,
    'ID_GOOGLE_ANALYTICS': config.ID_GOOGLE_ANALYTICS,
    'STATIC_PAGES': config.STATIC_PAGES,
    'TAXHUB_URL': config.TAXHUB_URL if hasattr(config, 'TAXHUB_URL') else None
}



@main.route(
    '/espece/'+config.REMOTE_MEDIAS_PATH+'<image>',
    methods=['GET', 'POST']
)
def especeMedias(image):
    return redirect(config.REMOTE_MEDIAS_URL+config.REMOTE_MEDIAS_PATH+image)


@main.route(
    '/commune/'+config.REMOTE_MEDIAS_PATH+'<image>',
    methods=['GET', 'POST']
)
def communeMedias(image):
    return redirect(config.REMOTE_MEDIAS_URL+config.REMOTE_MEDIAS_PATH+image)

@main.route(
    '/epci/'+config.REMOTE_MEDIAS_PATH+'<image>',
    methods=['GET', 'POST']
)
def epciMedias(image):
    return redirect(config.REMOTE_MEDIAS_URL+config.REMOTE_MEDIAS_PATH+image)


@main.route(
    '/departement/'+config.REMOTE_MEDIAS_PATH+'<image>',
    methods=['GET', 'POST']
)
def departementMedias(image):
    return redirect(config.REMOTE_MEDIAS_URL+config.REMOTE_MEDIAS_PATH+image)


@main.route(
    '/liste/'+config.REMOTE_MEDIAS_PATH+'<image>',
    methods=['GET', 'POST']
)
def listeMedias(image):
    return redirect(config.REMOTE_MEDIAS_URL+config.REMOTE_MEDIAS_PATH+image)


@main.route(
    '/groupe/'+config.REMOTE_MEDIAS_PATH+'<image>',
    methods=['GET', 'POST']
)
def groupeMedias(image):
    return redirect(config.REMOTE_MEDIAS_URL+config.REMOTE_MEDIAS_PATH+image)


@main.route(
    '/'+config.REMOTE_MEDIAS_PATH+'<image>',
    methods=['GET', 'POST']
)
def indexMedias(image):
    return redirect(config.REMOTE_MEDIAS_URL+config.REMOTE_MEDIAS_PATH+image)


@main.route('/', methods=['GET', 'POST'])
def index():
    session = utils.loadSession()
    connection = utils.engine.connect()

    if config.AFFICHAGE_MAILLE:
        observations = vmObservationsMaillesRepository.lastObservationsMailles(
            connection, config.NB_DAY_LAST_OBS, config.ATTR_MAIN_PHOTO
        )
    else:
        observations = vmObservationsRepository.lastObservations(
            connection, config.NB_DAY_LAST_OBS, config.ATTR_MAIN_PHOTO
        )

    communesSearch = vmCommunesRepository.getAllCommunes(session)
    epciSearch = vmEpciRepository.getAllEpci(session)
    departementSearch = vmDepartementRepository.getAllDepartement(session)
    mostViewTaxon = vmTaxonsMostView.mostViewTaxon(connection)
    stat = vmObservationsRepository.statIndex(connection)
    customStat = vmObservationsRepository.genericStat(
        connection, config.RANG_STAT
    )
    customStatMedias = vmObservationsRepository.genericStatMedias(
        connection, config.RANG_STAT
    )

    configuration = base_configuration.copy()
    configuration.update({
        'HOMEMAP': True,
        'TEXT_LAST_OBS': config.TEXT_LAST_OBS,
        'AFFICHAGE_MAILLE': config.AFFICHAGE_MAILLE,
        'AFFICHAGE_DERNIERES_OBS': config.AFFICHAGE_DERNIERES_OBS,
        'AFFICHAGE_EN_CE_MOMENT': config.AFFICHAGE_EN_CE_MOMENT,
        'AFFICHAGE_STAT_GLOBALES': config.AFFICHAGE_STAT_GLOBALES,
        'AFFICHAGE_RANG_STAT': config.AFFICHAGE_RANG_STAT,
        'COLONNES_RANG_STAT': config.COLONNES_RANG_STAT,
        'RANG_STAT_FR': config.RANG_STAT_FR,
        'MAP': config.MAP,
        'AFFICHAGE_INTRODUCTION': config.AFFICHAGE_INTRODUCTION,
        'AFFICHAGE_LOGOS_ORGAS': config.AFFICHAGE_LOGOS_ORGAS
    })

    connection.close()
    session.close()

    return render_template(
        'templates/index.html',
        observations=observations,
        communesSearch=communesSearch,
        epciSearch=epciSearch,
        departementSearch=departementSearch,
        mostViewTaxon=mostViewTaxon,
        stat=stat,
        customStat=customStat,
        customStatMedias=customStatMedias,
        configuration=configuration
    )


@main.route('/espece/<int:cd_ref>', methods=['GET', 'POST'])
def ficheEspece(cd_ref):
    session = utils.loadSession()
    connection = utils.engine.connect()

    cd_ref = int(cd_ref)
    taxon = vmTaxrefRepository.searchEspece(connection, cd_ref)
    statsorgataxon = vmStatsOrgaTaxonRepository.getStatsOrgaTaxonChilds(connection, cd_ref)
    months = vmMoisRepository.getMonthlyObservationsChilds(connection, cd_ref)
    synonyme = vmTaxrefRepository.getSynonymy(connection, cd_ref)
    communes = vmCommunesRepository.getCommunesObservationsChilds(
        connection, cd_ref
    )
    communesSearch = vmCommunesRepository.getAllCommunes(session)
    epciSearch = vmEpciRepository.getAllEpci(session)
    departementSearch = vmDepartementRepository.getAllDepartement(session)
    taxonomyHierarchy = vmTaxrefRepository.getAllTaxonomy(session, cd_ref)
    firstPhoto = vmMedias.getFirstPhoto(
        connection, cd_ref, config.ATTR_MAIN_PHOTO
    )
    photoCarousel = vmMedias.getPhotoCarousel(
        connection, cd_ref, config.ATTR_OTHER_PHOTO
    )
    videoAudio = vmMedias.getVideo_and_audio(
        connection, cd_ref, config.ATTR_AUDIO, config.ATTR_VIDEO_HEBERGEE,
        config.ATTR_YOUTUBE, config.ATTR_DAILYMOTION, config.ATTR_VIMEO
    )
    articles = vmMedias.getLinks_and_articles(
        connection, cd_ref, config.ATTR_LIEN, config.ATTR_PDF
    )
    taxonDescription = vmCorTaxonAttribut.getAttributesTaxon(
        connection, cd_ref, config.ATTR_DESC, config.ATTR_COMMENTAIRE,
        config.ATTR_MILIEU, config.ATTR_CHOROLOGIE
    )
    orgas = vmObservationsRepository.getOrgasObservations(connection, cd_ref)
    observers = vmObservationsRepository.getObservers(connection, cd_ref)

    configuration = base_configuration.copy()
    configuration.update({
        'LIMIT_FICHE_LISTE_HIERARCHY': config.LIMIT_FICHE_LISTE_HIERARCHY,
        'AFFICHAGE_ORGAS_OBS_FICHEESP': config.AFFICHAGE_ORGAS_OBS_FICHEESP,
        'PATRIMONIALITE': config.PATRIMONIALITE,
        'PROTECTION': config.PROTECTION,
        'GLOSSAIRE': config.GLOSSAIRE,
        'AFFICHAGE_MAILLE': config.AFFICHAGE_MAILLE,       
        'AFFICHAGE_SWITCHER': config.AFFICHAGE_SWITCHER,
        'AFFICHAGE_ATLAS_MAILLE_DEPARTEMENTALE': config.AFFICHAGE_ATLAS_MAILLE_DEPARTEMENTALE,
        'AFFICHAGE_ATLAS_MAILLE_COMMUNALE': config.AFFICHAGE_ATLAS_MAILLE_COMMUNALE,
        'AFFICHAGE_ATLAS_MAILLE_CARREE': config.AFFICHAGE_ATLAS_MAILLE_CARREE,
        'AFFICHAGE_ATLAS_POINT': config.AFFICHAGE_ATLAS_POINT,
        'ZOOM_LEVEL_POINT': config.ZOOM_LEVEL_POINT,
        'LIMIT_CLUSTER_POINT': config.LIMIT_CLUSTER_POINT,
        'FICHE_ESPECE': True,
        'MAP': config.MAP
    })

    connection.close()
    session.close()

    return render_template(
        'templates/ficheEspece.html',
        taxon=taxon,
        listeTaxonsSearch=[],
        observations=[],
        cd_ref=cd_ref,
        statsorgataxon=statsorgataxon,
        months=months,
        synonyme=synonyme,
        communes=communes,
        communesSearch=communesSearch,
        epciSearch=epciSearch,
        departementSearch=departementSearch,
        taxonomyHierarchy=taxonomyHierarchy,
        firstPhoto=firstPhoto,
        photoCarousel=photoCarousel,
        videoAudio=videoAudio,
        articles=articles,
        taxonDescription=taxonDescription,
        orgas=orgas,
        observers=observers,
        configuration=configuration
    )


@main.route('/commune/<insee>', methods=['GET', 'POST'])
def ficheCommune(insee):
    session = utils.loadSession()
    connection = utils.engine.connect()
    listTaxons = vmTaxonsRepository.getTaxonsCommunes(connection, insee)
    listespeces = vmTaxonsRepository.getListeTaxonsCommunes(connection, insee)
    infosCommune = vmCommunesRepository.infosCommune(connection, insee)
    epciCommune = vmCommunesRepository.epciCommune(connection, insee)
    commune = vmCommunesRepository.getCommuneFromInsee(connection, insee)
    statsorgacomm = vmStatsOrgaCommRepository.getStatsOrgaCommChilds(connection, insee)
    statsgroup2inpncomm = vmStatsGroup2inpnCommRepository.getStatsGroup2inpnCommChilds(connection, insee)
    statstaxongroup2inpncomm = vmStatsTaxonGroup2inpnCommRepository.getStatsTaxonGroup2inpnCommChilds(connection, insee)
    communesSearch = vmCommunesRepository.getAllCommunes(session)
    epciSearch = vmEpciRepository.getAllEpci(session)
    departementSearch = vmDepartementRepository.getAllDepartement(session)
    if config.AFFICHAGE_MAILLE:
        observations = vmObservationsMaillesRepository.lastObservationsCommuneMaille(
            connection, config.NB_LAST_OBS, insee
        )
    else:
        observations = vmObservationsRepository.lastObservationsCommune(
            connection, config.NB_LAST_OBS, insee
        )
    orgas = vmObservationsRepository.getOrgasCommunes(connection, insee)
    observers = vmObservationsRepository.getObserversCommunes(connection, insee)

    configuration = base_configuration.copy()
    configuration.update({
        'NB_LAST_OBS': config.NB_LAST_OBS,
        'AFFICHAGE_ORGAS_OBS_FICHECOMM': config.AFFICHAGE_ORGAS_OBS_FICHECOMM,
        'AFFICHAGE_MAILLE': config.AFFICHAGE_MAILLE,
        'MAP': config.MAP,
        'MYTYPE': 0,
        'PRESSION_PROSPECTION': config.PRESSION_PROSPECTION,
        'PATRIMONIALITE': config.PATRIMONIALITE,
        'PROTECTION': config.PROTECTION
    })

    session.close()
    connection.close()

    return render_template(
        'templates/ficheCommune.html',
        insee=insee,
        listTaxons=listTaxons,
        listespeces=listespeces,
        infosCommune=infosCommune,
        epciCommune=epciCommune,
        referenciel=commune,
        statsorgacomm=statsorgacomm,
        statsgroup2inpncomm=statsgroup2inpncomm,
        statstaxongroup2inpncomm=statstaxongroup2inpncomm,
        communesSearch=communesSearch,
        epciSearch=epciSearch,
        departementSearch=departementSearch,
        observations=observations,
        orgas=orgas,
        observers=observers,
        configuration=configuration
    )


@main.route('/epci/<nom_epci_simple>', methods=['GET', 'POST'])
def ficheEpci(nom_epci_simple):
    session = utils.loadSession()
    connection = utils.engine.connect()
    listTaxons = vmTaxonsRepository.getTaxonsEpci(connection, nom_epci_simple)
    listespeces = vmTaxonsRepository.getListeTaxonsEpci(connection, nom_epci_simple)
    infosEpci = vmEpciRepository.infosEpci(connection, nom_epci_simple)
    communesEpci = vmEpciRepository.communesEpciChilds(connection, nom_epci_simple)
    epci = vmEpciRepository.getEpciFromNomsimple(connection, nom_epci_simple)
    epciDpt = vmEpciRepository.getDptFromNEpci(connection, nom_epci_simple)
    statsorgaepci = vmStatsOrgaEpciRepository.getStatsOrgaEpciChilds(connection, nom_epci_simple)
    statsgroup2inpnepci = vmStatsGroup2inpnEpciRepository.getStatsGroup2inpnEpciChilds(connection, nom_epci_simple)
    statstaxongroup2inpnepci = vmStatsTaxonGroup2inpnEpciRepository.getStatsTaxonGroup2inpnEpciChilds(connection, nom_epci_simple)
    communesSearch = vmCommunesRepository.getAllCommunes(session)
    epciSearch = vmEpciRepository.getAllEpci(session)
    departementSearch = vmDepartementRepository.getAllDepartement(session)
    if config.AFFICHAGE_MAILLE:
        observations = vmObservationsMaillesRepository.lastObservationsEpciMaille(
            connection, config.NB_LAST_OBS, nom_epci_simple
        )
    else:
        observations = vmObservationsRepository.lastObservationsEpci(
            connection, config.NB_LAST_OBS, nom_epci_simple
        )
    orgas = vmObservationsRepository.getOrgasEpci(connection, nom_epci_simple)
    observers = vmObservationsRepository.getObserversEpci(connection, nom_epci_simple)

    configuration = base_configuration.copy()
    configuration.update({
        'NB_LAST_OBS': config.NB_LAST_OBS,
        'AFFICHAGE_ORGAS_OBS_FICHECOMM': config.AFFICHAGE_ORGAS_OBS_FICHECOMM,
        'AFFICHAGE_MAILLE': config.AFFICHAGE_MAILLE,
        'MAP': config.MAP,
        'MYTYPE': 0,
        'PRESSION_PROSPECTION': config.PRESSION_PROSPECTION,
        'PATRIMONIALITE': config.PATRIMONIALITE,
        'PROTECTION': config.PROTECTION
    })

    session.close()
    connection.close()

    return render_template(
        'templates/ficheEpci.html',
        nom_epci_simple=nom_epci_simple,
        listTaxons=listTaxons,
        listespeces=listespeces,
        infosEpci=infosEpci,
        communesEpci=communesEpci,
        referenciel=epci,
        epciDpt=epciDpt,
        statsorgaepci=statsorgaepci,
        statsgroup2inpnepci=statsgroup2inpnepci,
        statstaxongroup2inpnepci=statstaxongroup2inpnepci,
        communesSearch=communesSearch,
        epciSearch=epciSearch,
        departementSearch=departementSearch,
        observations=observations,
        orgas=orgas,
        observers=observers,
        configuration=configuration
    )


@main.route('/departement/<num_dpt>', methods=['GET', 'POST'])
def ficheDepartement(num_dpt):
    session = utils.loadSession()
    connection = utils.engine.connect()
    listTaxons = vmTaxonsRepository.getTaxonsDpt(connection, num_dpt)
    listespeces = vmTaxonsRepository.getListeTaxonsDpt(connection, num_dpt)
    infosDpt = vmDepartementRepository.infosDpt(connection, num_dpt)
    communesDpt = vmDepartementRepository.communesDptChilds(connection, num_dpt)
    epciDpt = vmDepartementRepository.epciDptChilds(connection, num_dpt)
    dpt = vmDepartementRepository.getDepartementFromNumdpt(connection, num_dpt)
    statsorgadpt = vmStatsOrgaDptRepository.getStatsOrgaDptChilds(connection, num_dpt)
    statsgroup2inpndpt = vmStatsGroup2inpnDptRepository.getStatsGroup2inpnDptChilds(connection, num_dpt)
    statstaxongroup2inpndpt = vmStatsTaxonGroup2inpnDptRepository.getStatsTaxonGroup2inpnDptChilds(connection, num_dpt)
    communesSearch = vmCommunesRepository.getAllCommunes(session)
    epciSearch = vmEpciRepository.getAllEpci(session)
    departementSearch = vmDepartementRepository.getAllDepartement(session)
    if config.AFFICHAGE_MAILLE:
        observations = vmObservationsMaillesRepository.lastObservationsDptMaille(
            connection, config.NB_LAST_OBS, num_dpt
        )
    else:
        observations = vmObservationsRepository.lastObservationsDpt(
            connection, config.NB_LAST_OBS, num_dpt
        )
    orgas = vmObservationsRepository.getOrgasDpt(connection, num_dpt)
    observers = vmObservationsRepository.getObserversDpt(connection, num_dpt)

    configuration = base_configuration.copy()
    configuration.update({
        'NB_LAST_OBS': config.NB_LAST_OBS,
        'AFFICHAGE_ORGAS_OBS_FICHECOMM': config.AFFICHAGE_ORGAS_OBS_FICHECOMM,
        'AFFICHAGE_MAILLE': config.AFFICHAGE_MAILLE,
        'MAP': config.MAP,
        'MYTYPE': 0,
        'PRESSION_PROSPECTION': config.PRESSION_PROSPECTION,
        'PATRIMONIALITE': config.PATRIMONIALITE,
        'PROTECTION': config.PROTECTION
    })

    session.close()
    connection.close()

    return render_template(
        'templates/ficheDepartement.html',
        num_dpt=num_dpt,
        listTaxons=listTaxons,
        listespeces=listespeces,
        infosDpt=infosDpt,
        communesDpt=communesDpt,
        epciDpt=epciDpt,
        referenciel=dpt,
        statsorgadpt=statsorgadpt,
        statsgroup2inpndpt=statsgroup2inpndpt,
        statstaxongroup2inpndpt=statstaxongroup2inpndpt,
        communesSearch=communesSearch,
        epciSearch=epciSearch,
        departementSearch=departementSearch,
        observations=observations,
        orgas=orgas,
        observers=observers,
        configuration=configuration
    )


@main.route('/BiodivPdL_liste_commune_<insee>.pdf')
def listeTaxonCommune_pdf(insee):
    session = utils.loadSession()
    connection = utils.engine.connect()
    listTaxons = vmTaxonsRepository.getListeTaxonsCommunes(connection, insee)
    #infosCommune = vmCommunesRepository.infosCommune(connection, insee)
    #epciCommune = vmCommunesRepository.epciCommune(connection, insee)
    commune = vmCommunesRepository.getCommuneFromInsee(connection, insee)
    #statsorgacomm = vmStatsOrgaCommRepository.getStatsOrgaCommChilds(connection, insee)
    #statsgroup2inpncomm = vmStatsGroup2inpnCommRepository.getStatsGroup2inpnCommChilds(connection, insee)
    #statstaxongroup2inpncomm = vmStatsTaxonGroup2inpnCommRepository.getStatsTaxonGroup2inpnCommChilds(connection, insee)
    #communesSearch = vmCommunesRepository.getAllCommunes(session)
    #epciSearch = vmEpciRepository.getAllEpci(session)
    #departementSearch = vmDepartementRepository.getAllDepartement(session)
    #if config.AFFICHAGE_MAILLE:
    #    observations = vmObservationsMaillesRepository.lastObservationsCommuneMaille(
    #        connection, config.NB_LAST_OBS, insee
    #    )
    #else:
    #    observations = vmObservationsRepository.lastObservationsCommune(
    #        connection, config.NB_LAST_OBS, insee
    #    )
    #orgas = vmObservationsRepository.getOrgasCommunes(connection, insee)
    #observers = vmObservationsRepository.getObserversCommunes(connection, insee)

    configuration = base_configuration.copy()
    configuration.update({
      #  'NB_LAST_OBS': config.NB_LAST_OBS,
      #  'AFFICHAGE_ORGAS_OBS_FICHECOMM': config.AFFICHAGE_ORGAS_OBS_FICHECOMM,
      #  'AFFICHAGE_MAILLE': config.AFFICHAGE_MAILLE,
      #  'MAP': config.MAP,
      #  'MYTYPE': 0,
      #  'PRESSION_PROSPECTION': config.PRESSION_PROSPECTION,
        'PATRIMONIALITE': config.PATRIMONIALITE,
        'PROTECTION': config.PROTECTION
    })
    session.close()
    connection.close()
    html = render_template(
        'static/custom/templates/listeTaxonCommune_pdf.html',
        insee=insee,
        now = (datetime.now()).strftime("%d-%m-%Y"),
        listTaxons=listTaxons,
        #infosCommune=infosCommune,
        #epciCommune=epciCommune,
        referenciel=commune,
        #statsorgacomm=statsorgacomm,
        #statsgroup2inpncomm=statsgroup2inpncomm,
        #statstaxongroup2inpncomm=statstaxongroup2inpncomm,
        #communesSearch=communesSearch,
        #epciSearch=epciSearch,
        #departementSearch=departementSearch,
        #observations=observations,
        #orgas=orgas,
        #observers=observers,
        configuration=configuration
    )    # Make a PDF straight from HTML in a string.
    return render_pdf(HTML(string=html))


@main.route('/BiodivPdL_liste_epci_<nom_epci_simple>.pdf')
def listeTaxonEpci_pdf(nom_epci_simple):
    session = utils.loadSession()
    connection = utils.engine.connect()
    listTaxons = vmTaxonsRepository.getListeTaxonsEpci(connection, nom_epci_simple)
    epci = vmEpciRepository.getEpciFromNomsimple(connection, nom_epci_simple)
    configuration = base_configuration.copy()
    configuration.update({
       # 'NB_LAST_OBS': config.NB_LAST_OBS,
       # 'AFFICHAGE_ORGAS_OBS_FICHECOMM': config.AFFICHAGE_ORGAS_OBS_FICHECOMM,
       # 'AFFICHAGE_MAILLE': config.AFFICHAGE_MAILLE,
       # 'MAP': config.MAP,
       # 'MYTYPE': 0,
       # 'PRESSION_PROSPECTION': config.PRESSION_PROSPECTION,
        'PATRIMONIALITE': config.PATRIMONIALITE,
        'PROTECTION': config.PROTECTION
    })
    session.close()
    connection.close()
    html = render_template(
        'static/custom/templates/listeTaxonEpci_pdf.html',
        nom_epci_simple=nom_epci_simple,
        now = (datetime.now()).strftime("%d-%m-%Y"),
        listTaxons=listTaxons,
        referenciel=epci,
        configuration=configuration
    )    # Make a PDF straight from HTML in a string.
    return render_pdf(HTML(string=html))


@main.route('/BiodivPdL_liste_departement_<num_dpt>.pdf')
def listeTaxonDpt_pdf(num_dpt):
    session = utils.loadSession()
    connection = utils.engine.connect()
    listTaxons = vmTaxonsRepository.getListeTaxonsDpt(connection, num_dpt)
    dpt = vmDepartementRepository.getDepartementFromNumdpt(connection, num_dpt)
    configuration = base_configuration.copy()
    configuration.update({
       # 'NB_LAST_OBS': config.NB_LAST_OBS,
       # 'AFFICHAGE_ORGAS_OBS_FICHECOMM': config.AFFICHAGE_ORGAS_OBS_FICHECOMM,
       # 'AFFICHAGE_MAILLE': config.AFFICHAGE_MAILLE,
       # 'MAP': config.MAP,
       # 'MYTYPE': 0,
       # 'PRESSION_PROSPECTION': config.PRESSION_PROSPECTION,
        'PATRIMONIALITE': config.PATRIMONIALITE,
        'PROTECTION': config.PROTECTION
    })
    session.close()
    connection.close()
    html = render_template(
        'static/custom/templates/listeTaxonDpt_pdf.html',
        num_dpt=num_dpt,
        now = (datetime.now()).strftime("%d-%m-%Y"),
        listTaxons=listTaxons,
        referenciel=dpt,
        configuration=configuration
    )    # Make a PDF straight from HTML in a string.
    return render_pdf(HTML(string=html))



@main.route('/liste/<cd_ref>', methods=['GET', 'POST'])
def ficheRangTaxonomie(cd_ref):
    session = utils.loadSession()
    connection = utils.engine.connect()

    listTaxons = vmTaxonsRepository.getTaxonsChildsList(connection, cd_ref)
    referenciel = vmTaxrefRepository.getInfoFromCd_ref(session, cd_ref)
    communesSearch = vmCommunesRepository.getAllCommunes(session)
    epciSearch = vmEpciRepository.getAllEpci(session)
    departementSearch = vmDepartementRepository.getAllDepartement(session)
    taxonomyHierarchy = vmTaxrefRepository.getAllTaxonomy(session, cd_ref)
    orgas = vmObservationsRepository.getOrgasObservations(connection, cd_ref)
    observers = vmObservationsRepository.getObservers(connection, cd_ref)

    connection.close()
    session.close()

    configuration = base_configuration.copy()
    configuration.update({
        'LIMIT_FICHE_LISTE_HIERARCHY': config.LIMIT_FICHE_LISTE_HIERARCHY,
        'AFFICHAGE_ORGAS_OBS_FICHETAXO': config.AFFICHAGE_ORGAS_OBS_FICHETAXO,
        'MYTYPE': 0,
        'PATRIMONIALITE': config.PATRIMONIALITE,
        'PROTECTION': config.PROTECTION,
    })

    return render_template(
        'templates/ficheRangTaxonomique.html',
        listTaxons=listTaxons,
        referenciel=referenciel,
        communesSearch=communesSearch,
        epciSearch=epciSearch,
        departementSearch=departementSearch,
        taxonomyHierarchy=taxonomyHierarchy,
        orgas=orgas,
        observers=observers,
        configuration=configuration
    )


@main.route('/groupe/<groupe>', methods=['GET', 'POST'])
def ficheGroupe(groupe):
    session = utils.loadSession()
    connection = utils.engine.connect()

    groups = vmTaxonsRepository.getAllINPNgroup(connection)
    listTaxons = vmTaxonsRepository.getTaxonsGroup(connection, groupe)
    communesSearch = vmCommunesRepository.getAllCommunes(session)
    epciSearch = vmEpciRepository.getAllEpci(session)
    departementSearch = vmDepartementRepository.getAllDepartement(session)
    orgas = vmObservationsRepository.getGroupeOrgas(connection, groupe)
    observers = vmObservationsRepository.getGroupeObservers(connection, groupe)

    session.close()
    connection.close()

    configuration = base_configuration.copy()
    configuration.update({
        'LIMIT_FICHE_LISTE_HIERARCHY': config.LIMIT_FICHE_LISTE_HIERARCHY,
        'AFFICHAGE_ORGAS_OBS_FICHEGROUPE': config.AFFICHAGE_ORGAS_OBS_FICHEGROUPE,
        'MYTYPE': 0,
        'PATRIMONIALITE': config.PATRIMONIALITE,
        'PROTECTION': config.PROTECTION
    })

    return render_template(
        'templates/ficheGroupe.html',
        listTaxons=listTaxons,
        communesSearch=communesSearch,
        epciSearch=epciSearch,
        departementSearch=departementSearch,
        referenciel=groupe,
        groups=groups,
        orgas=orgas,
        observers=observers,
        configuration=configuration
    )


@main.route('/photos', methods=['GET', 'POST'])
def photos():
    session = utils.loadSession()
    connection = utils.engine.connect()

    groups = vmTaxonsRepository.getINPNgroupPhotos(connection)
    communesSearch = vmCommunesRepository.getAllCommunes(session)
    epciSearch = vmEpciRepository.getAllEpci(session)
    departementSearch = vmDepartementRepository.getAllDepartement(session)
    configuration = base_configuration

    session.close()
    connection.close()
    return render_template(
        'templates/galeriePhotos.html',
        communesSearch=communesSearch,
        epciSearch=epciSearch,
        departementSearch=departementSearch,
        groups=groups,
        configuration=configuration
    )


@main.route('/<page>', methods=['GET', 'POST'])
def get_staticpages(page):
    session = utils.loadSession()
    if (page not in config.STATIC_PAGES):
        abort(404)
    static_page = config.STATIC_PAGES[page]
    communesSearch = vmCommunesRepository.getAllCommunes(session)
    epciSearch = vmEpciRepository.getAllEpci(session)
    departementSearch = vmDepartementRepository.getAllDepartement(session)
    configuration = base_configuration
    session.close()
    return render_template(
        static_page['template'],
        communesSearch=communesSearch,
        epciSearch=epciSearch,
        departementSearch=departementSearch,
        configuration=configuration
    )
