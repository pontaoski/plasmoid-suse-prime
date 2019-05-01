/*
 * Copyright 2016  Daniel Faust <hessijames@gmail.com>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2 of
 * the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http: //www.gnu.org/licenses/>.
 */
import QtQuick 2.5
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.1
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponents
import org.kde.plasma.extras 2.0 as PlasmaExtras

Item {
    property real mediumSpacing: 1.5*units.smallSpacing
    property real textHeight: theme.defaultFont.pixelSize + theme.smallestFont.pixelSize + units.smallSpacing
    property real itemHeight: Math.max(units.iconSizes.medium, textHeight)

    Layout.minimumHeight: (itemHeight + 2*mediumSpacing) * listView.count

    Layout.maximumWidth: Layout.minimumWidth
    Layout.maximumHeight: Layout.minimumHeight

    Layout.preferredWidth: Layout.minimumWidth
    Layout.preferredHeight: Layout.minimumHeight

    ListModel {
        id: controlsModel
        ListElement {
            vis: "nil"
            labelMajor: "status"
            labelMinor: "Current status of drivers"
            command: "true"
        }
        ListElement {
            vis: "img"
            source: "pattern-ruby-devel"
            img: "nvidia"
            labelMajor: "Enable NVidia"
            labelMinor: "Switch to your Nvidia graphics"
            command: "kdesu /usr/sbin/prime-select nvidia"
        }
        ListElement {
            vis: "img"
            source: "pattern-ruby-devel"
            img: "intel"
            labelMajor: "Enable Intel"
            labelMinor: "Switch to your Intel graphics"
            command: "kdesu /usr/sbin/prime-select nvidia"
        }
    }

    PlasmaCore.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []
        property var callbacks: ({})
        onNewData: {
            var stdout = data["stdout"]
            
            if (callbacks[sourceName] !== undefined) {
                callbacks[sourceName](stdout);
            }
            
            exited(sourceName, stdout)
            disconnectSource(sourceName) // cmd finished
        }
        
        function exec(cmd, onNewDataCallback) {
            if (onNewDataCallback !== undefined){
                callbacks[cmd] = onNewDataCallback
            }
            connectSource(cmd)
                    
        }
        signal exited(string sourceName, string stdout)

    }
    PlasmaExtras.ScrollArea {
        anchors.fill: parent
        ListView {
            id: listView
            anchors.fill: parent

            model: controlsModel

            highlight: PlasmaComponents.Highlight {}
            highlightMoveDuration: 0
            highlightResizeDuration: 0

            delegate: Item {
                width: parent.width
                height: itemHeight + 2*mediumSpacing

                property bool isHovered: false
                property bool isEjectHovered: false

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true

                    onEntered: {
                        listView.currentIndex = index
                        isHovered = true
                    }
                    onExited: {
                        isHovered = false
                    }
                    onClicked: {
                        executable.exec(model["command"], function(){})
                        if (model["command"].toLowerCase().includes("kdesu")) {
                            executable.exec('kdialog --msgbox "To apply changes, please log out and log back into your session, or reboot."')
                        }
                    }

                    Row {
                        x: mediumSpacing
                        y: mediumSpacing
                        width: parent.width - 2*mediumSpacing
                        height: itemHeight
                        spacing: mediumSpacing

                        Item {
                            height: units.iconSizes.medium
                            width: height
                            anchors.verticalCenter: parent.verticalCenter
                            
                            Image {
                                visible: (model["vis"] !== "icon" && model["vis"] !== "nil")
                                anchors.fill: parent
                                fillMode: Image.PreserveAspectFit
                                source: "../images/" + model["img"] + ".png"
                            }
                            PlasmaCore.IconItem {
                                visible: (model["vis"] !== "img" && model["vis"] !== "nil")
                                anchors.fill: parent
                                source: model['source']
                                active: isHovered
                            }
                        }

                        Column {
                            width: parent.width - units.iconSizes.medium - mediumSpacing
                            height: textHeight
                            spacing: 0
                            anchors.verticalCenter: parent.verticalCenter

                            PlasmaComponents.Label {
                                text: (model['labelMajor'] !== "status") ? model['labelMajor'] : executable.exec(model["command"], function(stdout){return stdout;})
                                width: parent.width
                                height: theme.defaultFont.pixelSize
                                elide: Text.ElideRight
                            }
                            Item {
                                width: 1
                                height: units.smallSpacing
                            }
                            PlasmaComponents.Label {
                                text: model['labelMinor']
                                font.pointSize: theme.smallestFont.pointSize
                                opacity: isHovered ? 1.0 : 0.6
                                width: parent.width
                                height: theme.smallestFont.pixelSize
                                elide: Text.ElideRight

                                Behavior on opacity { NumberAnimation { duration: units.shortDuration * 3 } }
                            }
                        }
                    }
                }
            }
        }
    }
}