##############################################
Compilation et installation de Kicad sur OS X
##############################################

Compilations
============

7 janv. 2014
------------

* Ordinateur : Macbook Pro 2013 / OS X 10.10
* OSX_MIN_TARGET : 10.7 ( Pour WXpython et Kicad)
* Libraires avec brew:

  - glew 1.11.0
  - cairo 1.14.0
  - swig 3.0.2
  - openssl 1.0.1j_1

* wxPython 3.0.2.0
* Kicad product branch rev. 5359 avec patch OS X Trackpad


Mise en place des repertoires
=============================

.. code-block:: bash

   cd ~
   mkdir Sources && cd Sources
   mkdir kicad && cd kicad

Téléchargements
===============

* Kicad depuis le dépot lp:kicad.

  .. code-block:: bash

     bzr branch lp:kicad
     cd kicad
     bzr merge lp:~gcorral/kicad/osx-trackpad-gestures

* wxPython depuis: http://www.wxpython.org/download.php#source
  et enregistré dans ~/Sources/wx-src

Installation des pré-requis
===========================

.. code-block:: bash

   brew update && brew upgrade `brew outdated`
   brew install glew cairo swig openssl bzr python
   bzr whoami "Nom Prénom <nom.prénom@domain.com>"

   # Kicad a besoin d'un version patchée de boost
   # Make télécharge, patch et compile Boost si il ne le trouve
   # pas sur le système, donc:
   brew uninstall boost

Edition du script d'installation de wx Widget
=============================================

.. code-block:: bash

   chmod +x kicad/scripts/osx_build_wx.sh
   vim kicad/scripts/osx_build_wx.sh

Il faut rajouter les patchs suivants au bon endroit:

* wxwidgets-3.0.2_macosx_yosemite.patch
* wxwidgets-3.0.0_macosx_magnify_event.patch


On lance la compilation de wxpython:

.. code-block:: bash

   kicad/scripts/osx_build_wx.sh wx-src wx-bin kicad 10.7 "-j4"

Compilation de Kicad
====================

..  code-block:: bash

    mkdir build && cd build

    cmake ../kicad \
          -DCMAKE_C_COMPILER=clang \
          -DCMAKE_CXX_COMPILER=clang++ \
          -DCMAKE_OSX_DEPLOYMENT_TARGET=10.7 \
          -DwxWidgets_CONFIG_EXECUTABLE=../wx-bin/bin/wx-config \
          -DPYTHON_EXECUTABLE=/usr/local/bin/python \
          -DPYTHON_SITE_PACKAGE_PATH=`pwd`/../wx-bin/lib/python2.7/site-packages \
          -DKICAD_SCRIPTING=ON \
          -DKICAD_SCRIPTING_MODULES=ON \
          -DKICAD_SCRIPTING_WXPYTHON=ON \
          -DCMAKE_INSTALL_PREFIX=../bin \
          -DCMAKE_BUILD_TYPE=Release \
          -DUSE_OSX_MAGNIFY_EVENT=ON \

   make

   make install

En attendant la fin de la compilation, continuer l'installation des librairies.


Installation de kicad-library
=============================

J'utilise un fork de la librairie de :
http://smisioto.no-ip.org/elettronica/kicad/kicad-en.htm

Téléchargement et installation
------------------------------

.. code-block:: bash

   cd ~/Sources
   git clone https://github.com/samdolt/kicad-library.git
   bash kicad_library/osx_setup_link.sh

Mise à jour du fork:
--------------------

.. code-block:: bash

   cd kicad_library
   git pull

   git remote add upstream git://smisioto.eu/kicad_libs.git
   git fetch upstream
   git merge upstream/master
   git push
   ./osx_setup_link.sh

Installation de KiCad
=====================

Une fois la compilation de KiCad terminée, on obtient les fichiers suivants:

.. code-block:: bash

   cd ~/Sources/kicad/bin
   ls
   # bitmap2component.app doc                  kicad.app            pl_editor.app
   # cvpcb.app            eeschema.app         pcb_calculator.app
   # demos                gerbview.app         pcbnew.app

   rm -r /Applications/kicad
   cp -r kicad.app /Applications/

   cp -r demos /Library/Application\ Support/kicad/
   cp -r doc /Library/Application\ Support/kicad/

Paramètres de Kicad
===================

Pour une bonne utilisation de cette version avec un trackpad, il faut
cocher la case "Use mousewheel to pan" dans le menu "Kicad/Preferences"

Note: Il faut le faire une fois dans eeschema et une fois dans pcbnew

Références
==========

- http://bazaar.launchpad.net/~kicad-product-committers/kicad/product/view/head:/Documentation/compiling/mac-osx.txt
- https://help.github.com/articles/syncing-a-fork/
- https://lists.launchpad.net/kicad-developers/msg15527.html
