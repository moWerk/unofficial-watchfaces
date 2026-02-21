/*
 * Copyright (C) 2021-2024 - Ed Beroset <github.com/beroset>
 * All rights reserved.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as
 * published by the Free Software Foundation, either version 2.1 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.1

Item {
    // these three constants describe metric time
    readonly property int metricHoursPerStandardDay: 10
    readonly property int metricMinutesPerMetricHour: 100
    readonly property int metricSecondsPerMetricMinute: 100

    // this constant adjusts the minutes ticks on the watchface
    readonly property int majorMinuteTicksEvery: 5
    // this adjusts the number of revolutions per day 
    // (e.g. 2 twelve-hour revolutions for a standard 24 hour day)
    readonly property int revolutionsPerDay: 1

    // these are derived constants
    readonly property int metricSecondsPerStandardDay: metricHoursPerStandardDay * metricMinutesPerMetricHour * metricSecondsPerMetricMinute
    readonly property double metricSecondsScaleFactor: metricSecondsPerStandardDay / 86400.0

    function getMetricMilliseconds(t) {
        return (t.getHours() * 3600000
            + t.getMinutes() * 60000
            + t.getSeconds() * 1000
            + t.getMilliseconds()) * metricSecondsScaleFactor
    }

    function getMetricHours(metricMilli){
        return getMetricMilliseconds(wallClock.time) / metricMinutesPerMetricHour / metricSecondsPerMetricMinute / 1000
    }

    // ────────────────────────────────────────────────────────────────
    // NEW: Decimal-second-precise update logic (Approach 2)
    // ────────────────────────────────────────────────────────────────

    // We want the displayed decimal time (especially seconds part) to change
    // EXACTLY when a new decimal second begins, i.e. when the fractional
    // part of the decimal seconds crosses an integer boundary.

    property int lastShownDecimalSeconds: -1   // track last displayed integer decimal seconds to detect changes

    Timer {
        id: boundaryTimer
        repeat: false
        running: false

        onTriggered: {
            updateDecimalDisplay()
            scheduleToNextDecimalSecond()
        }
    }

    function scheduleToNextDecimalSecond() {
        var now = wallClock.time
        var metricMs = getMetricMilliseconds(now)

        // metricMs is total decimal milliseconds since midnight
        // One decimal second = 1000 decimal milliseconds
        var msIntoCurrentDecSec = metricMs % 1000

        var msToNextBoundary = 1000 - msIntoCurrentDecSec

        // Small safety margin: if we're < ~8–10 ms away, just fire soon
        // to avoid Qt timer jitter / zero/negative intervals
        if (msToNextBoundary < 10) {
            msToNextBoundary = 0
        }

        boundaryTimer.interval = msToNextBoundary
        boundaryTimer.start()
    }

    function updateDecimalDisplay() {
        var metricMs = getMetricMilliseconds(wallClock.time)
        var totalDecSeconds = Math.floor(metricMs / 1000)   // integer decimal seconds since midnight

        if (totalDecSeconds === lastShownDecimalSeconds) {
            // shouldn't happen, but guard against double-fires
            scheduleToNextDecimalSecond()
            return
        }

        lastShownDecimalSeconds = totalDecSeconds

        // Optional: you could split into h / m / s here if you want to show
        // full HH:MM:SS decimal format later — for now we keep your original
        // decimalHours logic but it will now update at exact boundaries
        decimalHours.text = getMetricHours(metricMs).toPrecision(5)
    }

    // ────────────────────────────────────────────────────────────────
    // Original components below (unchanged except decimalHours binding removed)
    // ────────────────────────────────────────────────────────────────

    component Tick: Rectangle {
        id: thisTick
        property bool outsideRing: true
        property real angle: 0
        property real radius: 0.72
        antialiasing : true
        transform: [
            Rotation {
                origin.x: thisTick.width/2
                origin.y: outsideRing 
                    ? thisTick.height + parent.width * radius / 2
                    : parent.width * radius / 2
                angle: thisTick.angle
            },
            Translate {
                x: (parent.width - thisTick.width)/2
                y: outsideRing
                ? parent.height/2 - parent.width * radius / 2  - thisTick.height
                : parent.height/2 - parent.width * radius / 2
            }
        ]
    }

    Repeater{
        id: minuteTicks
        model: metricMinutesPerMetricHour / revolutionsPerDay
        Tick {
            angle: (index)*360/minuteTicks.count
            color: "lightgreen"
            opacity: 0.6
            visible: !displayAmbient
            width: parent.width*0.005
            height: parent.width*(index % majorMinuteTicksEvery == 0 ? 0.030 : 0.015)
        }
    }

    Repeater{
        id: hourTicks
        model: metricHoursPerStandardDay / revolutionsPerDay
        Tick {
            angle: (index)*360/hourTicks.count
            color: "lightgreen"
            opacity: displayAmbient ? 0.3 : 0.6
            width: parent.width*0.01
            height: parent.width*0.03
        }
    }

    Repeater{
        id: hourLabels
        model: metricHoursPerStandardDay / revolutionsPerDay
        Text {
            font {
                pixelSize: parent.height*0.08
                family: "CPMono_v07"
                styleName: "Plain"
            }
            color: "lightblue"
            id: hourLabel
            antialiasing : true
            opacity: displayAmbient ? 0.3 : 0.6
            text: index ? index : hourLabels.count
            transform: [
                Rotation {
                    origin.x: hourLabel.width/2
                    origin.y: hourLabel.height + parent.width * 0.40
                    angle: (index)*360/ (metricHoursPerStandardDay / revolutionsPerDay)
                },
                Translate {
                    x: (parent.width - hourLabel.width)/2
                    y: parent.height/2 - parent.width * 0.40 - hourLabel.height
                }
            ]
        }
    }

    Image {
        id: logoAsteroid
        antialiasing: true
        opacity: displayAmbient ? 0.6 : 1.0
        source: "../watchfaces-img/asteroid-logo.svg"
        width: parent.width/12
        height: width
        transform : [
            Rotation {
                origin.x : logoAsteroid.width/2
                origin.y : logoAsteroid.height + parent.width * 0.275
                angle: getMetricHours(wallClock.time) * 360 * revolutionsPerDay / metricHoursPerStandardDay
            },
            Translate {
                x: (parent.width - logoAsteroid.width)/2
                y: parent.height/2 - logoAsteroid.height - parent.width * 0.275
            }
        ]
    }

    component PlainText : Text {
        font {
            pixelSize: parent.height*0.06
            family: "CPMono_v07"
            styleName: "Plain"
        }
        color: "white"
        visible: !displayAmbient
        horizontalAlignment: Text.AlignHCenter
        anchors.centerIn: parent
    }

    PlainText {
        id: conventionalTime
        anchors.verticalCenterOffset: +parent.width*0.18
        text: if (use12H.value)
                  wallClock.time.toLocaleString(Qt.locale(), "hh:mm:ss ap")
              else
                  wallClock.time.toLocaleString(Qt.locale(), "HH:mm:ss")
    }

    PlainText {
        id: conventionalDate
        anchors.verticalCenterOffset: -parent.width*0.18
        text: wallClock.time.toLocaleDateString(Qt.locale(), Locale.ShortFormat)
    }

    PlainText {
        id: decimalHours
        font.pixelSize: parent.width*0.15
        anchors.verticalCenterOffset: parent.width*0.016
        textFormat: Text.RichText
        // Was bound directly → now updated only on precise decimal-second boundaries
        // text: getMetricHours(wallClock.time).toPrecision(5)
    }

    // ────────────────────────────────────────────────────────────────
    // Kick off the precise timer chain once everything is ready
    // ────────────────────────────────────────────────────────────────

    Component.onCompleted: {
        // Show initial value immediately (using whatever time is current)
        updateDecimalDisplay()
        // Then align to the next real boundary and keep updating precisely
        scheduleToNextDecimalSecond()
    }

    // Optional: re-schedule on time zone / settings change if needed
    Connections {
        target: wallClock
        function onTimeChanged() { /* could call scheduleToNext...() if jump detected */ }
    }
}
