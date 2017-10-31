
Plateforme de visualisation des données naturalistes des Pays de la Loire, basée sur GeoNature-atlas
===============

Projet de plateforme web permettant de visualiser les données "biodiversité" du réseau naturaliste des Pays de la Loire. Projet porté par le `Conservatoire d'espaces naturels des Pays de la Loire <http://www.cenpaysdelaloire.fr/>`_.

.. image :: docs/images/cenpdl-logo-couleur.jpg



Bases de développement
------------


Cette plateforme est développée à partir des outils de gestion de données naturalistes (voir `GeoNature <http://geonature.fr>`_) développés par le Parc National des Ecrins et le Parc national des Cévennes :

- la structure de base de données de `GeoNature <https://github.com/PnEcrins/GeoNature>`_ ;
- l'outil complet `UsersHub <https://github.com/PnEcrins/UsersHub>`_ ;
- l'outil complet `TaxHub <https://github.com/PnX-SI/TaxHub>`_ ;
- l'outil complet `Geonature-atlas <https://github.com/PnEcrins/GeoNature-atlas>`_ modifié pour les besoins du CEN Pays de la Loire.


Ces outils sont déployés sur un serveur Ubuntu 16.04 (`fichiers d'installation <https://github.com/Splendens/install_all_geonature_ubuntu16_04>`_).




La plateforme Biodiversité - Pays de la Loire
------------

La plateforme de visusalistion est basée sur `Geonature-atlas <https://github.com/PnEcrins/GeoNature-atlas>`_, en cours de modification pour permettre : 

- le moissonnage des données naturalistes dégradées (= non précises) des bases de données des partenaires naturalistes ;
- l'affichage des données par mailles, communes et intercommunalités ;
- l'affichage de graphes de synthèses sur les territoires (statistiques par groupes, statistiques par statuts...).



Modifications en cours
------------

**Bases de données**

- Ajout d'un schéma par base de données partenaires moissonnées à la DB geonaturedb
- Ajout des triggers pour l'insertion des données des partenaires dans la table de synthèse
- Ajout des fonctions de moissonnage des DB externes
- Ajout de vues matérialisées à la DB geonatureatlas pour l'affichage par communes et intercommunalités
- Modifications de la récupération des mailles (données dégradées aux centroïdes des mailles ?)


**Application**

- Modification de la page d'accueil 
- Ajout des fonctionnalités de visualisation des données par communes et intercommunalités 
- Ajout des fonctionnalités de visualisation de graphes de statistiques sur les territoires



Modifications apportées
------------

**Bases de données**

- `Modification des zonages <https://github.com/Splendens/atlas_biodiv_pdl/blob/master/modifdb/couches_reference.rst>`_ (territoire, communes) pour les Pays de la Loire


**Application**

-
