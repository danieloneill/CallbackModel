TEMPLATE = lib
TARGET = CallbackModel
QT += qml quick
CONFIG += qt plugin qmltypes

TARGET = $$qtLibraryTarget($$TARGET)
uri = com.foxmoxie.CallbackModel

QML_IMPORT_NAME = com.foxmoxie.CallbackModel
QML_IMPORT_MAJOR_VERSION = 1

# Input
SOURCES += \
    callbackmodel_plugin.cpp \
    callbackmodel.cpp

HEADERS += \
    callbackmodel_plugin.h \
    callbackmodel.h

DISTFILES = qmldir
OTHER_FILES = qmldir

!equals(_PRO_FILE_PWD_, $$OUT_PWD) {
    copy_qmldir.target = $$OUT_PWD/qmldir
    copy_qmldir.depends = $$_PRO_FILE_PWD_/qmldir
    copy_qmldir.commands = $(COPY_FILE) \"$$replace(copy_qmldir.depends, /, $$QMAKE_DIR_SEP)\" \"$$replace(copy_qmldir.target, /, $$QMAKE_DIR_SEP)\"
    QMAKE_EXTRA_TARGETS += copy_qmldir
    PRE_TARGETDEPS += $$copy_qmldir.target
}

qmldir.files = qmldir callbackmodel_metatypes.json plugins.qmltypes
unix|win32 {
    installPath = $$[QT_INSTALL_QML]/$$replace(uri, \\., /)
    qmldir.path = $$installPath
    target.path = $$installPath
    INSTALLS += target qmldir
}

