// SPDX-FileCopyrightText: 2021 John Gibbon <jngibbon@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later
// Entry point for the arc watchface: it loads one of the bundled arc designs
// from a stored index and exposes a settings page that steps to the next
// design on tap, so all of the author's styles live under a single store face.
import Nemo.Configuration
import QtQuick
import org.asteroid.controls

Item {
    id: root

    // The design files live in the arc/ subfolder so only this frontend lists as
    // a face. The base arc/Arc.qml renders white standard-seconds and is the
    // first entry; the other seven are its variant overrides.
    readonly property var designs: ["arc/Arc.qml", "arc/Arc-white-standard-noseconds.qml", "arc/Arc-white-pie-seconds.qml", "arc/Arc-white-pie-noseconds.qml", "arc/Arc-black-standard-seconds.qml", "arc/Arc-black-standard-noseconds.qml", "arc/Arc-black-pie-seconds.qml", "arc/Arc-black-pie-noseconds.qml"]
    property Component settingsPage: arcSettingsPage

    anchors.fill: parent

    ConfigurationValue {
        id: arcDesign

        key: "/org/asteroidos/watchfaces/arc/design"
        defaultValue: 0
    }

    Loader {
        anchors.fill: parent
        source: root.designs[arcDesign.value % root.designs.length]
    }

    Component {
        id: arcSettingsPage

        Item {
            id: settings

            anchors.fill: parent

            Loader {
                id: designPreview

                width: Math.min(parent.width, parent.height) * 0.72
                height: width
                anchors.centerIn: parent
                source: root.designs[arcDesign.value % root.designs.length]
            }

            Label {
                horizontalAlignment: Text.AlignHCenter
                text: "Tap to change the arc style"

                anchors {
                    bottom: parent.bottom
                    bottomMargin: parent.height * 0.1
                    horizontalCenter: parent.horizontalCenter
                }

            }

            MouseArea {
                anchors.fill: parent
                onClicked: arcDesign.value = (arcDesign.value + 1) % root.designs.length
            }

        }

    }

}
