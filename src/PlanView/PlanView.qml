/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick          2.3
import QtQuick.Controls 1.2
import QtQuick.Dialogs  1.2
import QtLocation       5.3
import QtPositioning    5.3
import QtQuick.Layouts  1.2
import QtQuick.Window   2.2

import QGroundControl                   1.0
import QGroundControl.FlightMap         1.0
import QGroundControl.ScreenTools       1.0
import QGroundControl.Controls          1.0
import QGroundControl.FactSystem        1.0
import QGroundControl.FactControls      1.0
import QGroundControl.Palette           1.0
import QGroundControl.Controllers       1.0
import QGroundControl.ShapeFileHelper   1.0
import QGroundControl.Airspace          1.0
import QGroundControl.Airmap            1.0


Item {
    id: _root
  //update20221125 Leo

    property real myAngularMaximum: 5.0 // Unit degree Planning Curve  Path
    property real myDistanceMaximum: 1.0 //Unit Meter(M) Planning Curve Path
    property real myAngularSpan:60.0 //  Unit Degree in Clock-wise direction
    property real myAngularStep:5.0// Steps to increase in Angular Planning
    property real myDistanceStep:5.0//
    property int myReverseCurve: 0// to decide if we revert the curve path

    property bool planControlColapsed: false

    readonly property int   _decimalPlaces:             8
    readonly property real  _margin:                    ScreenTools.defaultFontPixelHeight * 0.5
    readonly property real  _toolsMargin:               ScreenTools.defaultFontPixelWidth * 0.75
    readonly property real  _radius:                    ScreenTools.defaultFontPixelWidth  * 0.5
    readonly property real  _rightPanelWidth:           Math.min(parent.width / 3, ScreenTools.defaultFontPixelWidth * 30)
    readonly property var   _defaultVehicleCoordinate:  QtPositioning.coordinate(37.803784, -122.462276)
    readonly property bool  _waypointsOnlyMode:         QGroundControl.corePlugin.options.missionWaypointsOnly

    property bool   _airspaceEnabled:                    QGroundControl.airmapSupported ? (QGroundControl.settingsManager.airMapSettings.enableAirMap.rawValue && QGroundControl.airspaceManager.connected): false
    property var    _missionController:                 _planMasterController.missionController
    property var    _geoFenceController:                _planMasterController.geoFenceController
    property var    _rallyPointController:              _planMasterController.rallyPointController
    property var    _visualItems:                       _missionController.visualItems
    property bool   _lightWidgetBorders:                editorMap.isSatelliteMap
    property bool   _addROIOnClick:                     false
    property bool   _singleComplexItem:                 _missionController.complexMissionItemNames.length === 1
    property int    _editingLayer:                      layerTabBar.currentIndex ? _layers[layerTabBar.currentIndex] : _layerMission
    property int    _toolStripBottom:                   toolStrip.height + toolStrip.y
    property var    _appSettings:                       QGroundControl.settingsManager.appSettings
    property var    _planViewSettings:                  QGroundControl.settingsManager.planViewSettings
    property bool   _promptForPlanUsageShowing:         false

    readonly property var       _layers:                [_layerMission, _layerGeoFence, _layerRallyPoints]

    readonly property int       _layerMission:              1
    readonly property int       _layerGeoFence:             2
    readonly property int       _layerRallyPoints:          3
    readonly property string    _armedVehicleUploadPrompt:  qsTr("Vehicle is currently armed. Do you want to upload the mission to the vehicle?")

    //定义变量    Updated 20221209 LEO
    property var map        ///< Map control to place item in
    property var vehicle    ///< Vehicle associated with this item
    property bool interactive: true

    property var    _circle
    property bool   _circleShowing:   false

//显示半径圈
    function showCircle() {
        if (!_circleShowing) {
            //_circle = circleComponent2.createObject(map)
            console.log('inPlanView map=:',map)
            //map.addMapItem(_circle)

            //_circleShowing = true
        }
    }
   Component {
               id: circleComponent2
                       MapCircle {
                           color:          Qt.rgba(0,0,0,0)
                           border.color:   "yellow"
                           border.width:   6
                           //center:         _missionController.splitSegment.coordinate1
                           center:         QtPositioning.coordinate()
                           radius:         200
                           visible:        true
                       }
                   }

   Component.onCompleted: {

       showCircle()
   }

    function mapCenter() {
        var coordinate = editorMap.center
        coordinate.latitude  = coordinate.latitude.toFixed(_decimalPlaces)
        coordinate.longitude = coordinate.longitude.toFixed(_decimalPlaces)
        coordinate.altitude  = coordinate.altitude.toFixed(_decimalPlaces)
        return coordinate
    }

    function updateAirspace(reset) {
        if(_airspaceEnabled) {
            var coordinateNW = editorMap.toCoordinate(Qt.point(0,0), false /* clipToViewPort */)
            var coordinateSE = editorMap.toCoordinate(Qt.point(width,height), false /* clipToViewPort */)
            if(coordinateNW.isValid && coordinateSE.isValid) {
                QGroundControl.airspaceManager.setROI(coordinateNW, coordinateSE, true /*planView*/, reset)
            }
        }
    }

    property bool _firstMissionLoadComplete:    false
    property bool _firstFenceLoadComplete:      false
    property bool _firstRallyLoadComplete:      false
    property bool _firstLoadComplete:           false

    MapFitFunctions {
        id:                         mapFitFunctions  // The name for this id cannot be changed without breaking references outside of this code. Beware!
        map:                        editorMap
        usePlannedHomePosition:     true
        planMasterController:       _planMasterController
    }

    on_AirspaceEnabledChanged: {
        if(QGroundControl.airmapSupported) {
            if(_airspaceEnabled) {
                planControlColapsed = QGroundControl.airspaceManager.airspaceVisible
                updateAirspace(true)
            } else {
                planControlColapsed = false
            }
        } else {
            planControlColapsed = false
        }
    }

    onVisibleChanged: {
        if(visible) {
            editorMap.zoomLevel = QGroundControl.flightMapZoom
            editorMap.center    = QGroundControl.flightMapPosition
            if (!_planMasterController.containsItems) {
                toolStrip.simulateClick(toolStrip.fileButtonIndex)
            }
        }
    }

    Connections {
        target: _appSettings ? _appSettings.defaultMissionItemAltitude : null
        function onRawValueChanged() {
            if (_visualItems.count > 1) {
                mainWindow.showComponentDialog(applyNewAltitude, qsTr("Apply new altitude"), mainWindow.showDialogDefaultWidth, StandardButton.Yes | StandardButton.No)
            }
        }
    }

    Component {
        id: applyNewAltitude
        QGCViewMessage {
            message:    qsTr("You have changed the default altitude for mission items. Would you like to apply that altitude to all the items in the current mission?")
            function accept() {
                hideDialog()
                _missionController.applyDefaultMissionAltitude()
            }
        }
    }

    Component {
        id: promptForPlanUsageOnVehicleChangePopupComponent
        QGCPopupDialog {
            title:      _planMasterController.managerVehicle.isOfflineEditingVehicle ? qsTr("Plan View - Vehicle Disconnected") : qsTr("Plan View - Vehicle Changed")
            buttons:    StandardButton.NoButton

            ColumnLayout {
                QGCLabel {
                    Layout.maximumWidth:    parent.width
                    wrapMode:               QGCLabel.WordWrap
                    text:                   _planMasterController.managerVehicle.isOfflineEditingVehicle ?
                                                qsTr("The vehicle associated with the plan in the Plan View is no longer available. What would you like to do with that plan?") :
                                                qsTr("The plan being worked on in the Plan View is not from the current vehicle. What would you like to do with that plan?")
                }

                QGCButton {
                    Layout.fillWidth:   true
                    text:               _planMasterController.dirty ?
                                            (_planMasterController.managerVehicle.isOfflineEditingVehicle ?
                                                 qsTr("Discard Unsaved Changes") :
                                                 qsTr("Discard Unsaved Changes, Load New Plan From Vehicle")) :
                                            qsTr("Load New Plan From Vehicle")
                    onClicked: {
                        _planMasterController.showPlanFromManagerVehicle()
                        _promptForPlanUsageShowing = false
                        hideDialog();
                    }
                }

                QGCButton {
                    Layout.fillWidth:   true
                    text:               _planMasterController.managerVehicle.isOfflineEditingVehicle ?
                                            qsTr("Keep Current Plan") :
                                            qsTr("Keep Current Plan, Don't Update From Vehicle")
                    onClicked: {
                        if (!_planMasterController.managerVehicle.isOfflineEditingVehicle) {
                            _planMasterController.dirty = true
                        }
                        _promptForPlanUsageShowing = false
                        hideDialog()
                    }
                }
            }
        }
    }


    Component {
        id: firmwareOrVehicleMismatchUploadDialogComponent
        QGCViewMessage {
            message: qsTr("This Plan was created for a different firmware or vehicle type than the firmware/vehicle type of vehicle you are uploading to. " +
                            "This can lead to errors or incorrect behavior. " +
                            "It is recommended to recreate the Plan for the correct firmware/vehicle type.\n\n" +
                            "Click 'Ok' to upload the Plan anyway.")

            function accept() {
                _planMasterController.sendToVehicle()
                hideDialog()
            }
        }
    }

    Connections {
        target: QGroundControl.airspaceManager
        function onAirspaceVisibleChanged() {
            planControlColapsed = QGroundControl.airspaceManager.airspaceVisible
        }
    }

    Component {
        id: noItemForKML
        QGCViewMessage {
            message:    qsTr("You need at least one item to create a KML.")
        }
    }


    TestInfoFactGroup {
        id:         _testInfoFactGroup

    }

    PlanMasterController {
        id:         _planMasterController
        flyView:    false

        Component.onCompleted: {
            _planMasterController.start()
            _missionController.setCurrentPlanViewSeqNum(0, true)
            globals.planMasterControllerPlanView = _planMasterController
        }

        onPromptForPlanUsageOnVehicleChange: {
            if (!_promptForPlanUsageShowing) {
                _promptForPlanUsageShowing = true
                mainWindow.showPopupDialogFromComponent(promptForPlanUsageOnVehicleChangePopupComponent)
            }
        }

        function waitingOnIncompleteDataMessage(save) {
            var saveOrUpload = save ? qsTr("Save") : qsTr("Upload")
            mainWindow.showMessageDialog(qsTr("Unable to %1").arg(saveOrUpload), qsTr("Plan has incomplete items. Complete all items and %1 again.").arg(saveOrUpload))
        }

        function waitingOnTerrainDataMessage(save) {
            var saveOrUpload = save ? qsTr("Save") : qsTr("Upload")
            mainWindow.showMessageDialog(qsTr("Unable to %1").arg(saveOrUpload), qsTr("Plan is waiting on terrain data from server for correct altitude values."))
        }

        function checkReadyForSaveUpload(save) {
            if (readyForSaveState() == VisualMissionItem.NotReadyForSaveData) {
                waitingOnIncompleteDataMessage(save)
                return false
            } else if (readyForSaveState() == VisualMissionItem.NotReadyForSaveTerrain) {
                waitingOnTerrainDataMessage(save)
                return false
            }
            return true
        }

        function upload() {
            if (!checkReadyForSaveUpload(false /* save */)) {
                return
            }
            switch (_missionController.sendToVehiclePreCheck()) {
                case MissionController.SendToVehiclePreCheckStateOk:
                    sendToVehicle()
                    break
                case MissionController.SendToVehiclePreCheckStateActiveMission:
                    mainWindow.showMessageDialog(qsTr("Send To Vehicle"), qsTr("Current mission must be paused prior to uploading a new Plan"))
                    break
                case MissionController.SendToVehiclePreCheckStateFirwmareVehicleMismatch:
                    mainWindow.showComponentDialog(firmwareOrVehicleMismatchUploadDialogComponent, qsTr("Plan Upload"), mainWindow.showDialogDefaultWidth, StandardButton.Ok | StandardButton.Cancel)
                    break
            }
        }

        function loadFromSelectedFile() {
            fileDialog.title =          qsTr("Select Plan File")
            fileDialog.planFiles =      true
            fileDialog.selectExisting = true
            fileDialog.nameFilters =    _planMasterController.loadNameFilters
            fileDialog.openForLoad()
        }

        function saveToSelectedFile() {
            if (!checkReadyForSaveUpload(true /* save */)) {
                return
            }
            fileDialog.title =          qsTr("Save Plan")
            fileDialog.planFiles =      true
            fileDialog.selectExisting = false
            fileDialog.nameFilters =    _planMasterController.saveNameFilters
            fileDialog.openForSave()
        }

        function fitViewportToItems() {
            mapFitFunctions.fitMapViewportToMissionItems()
        }

        function saveKmlToSelectedFile() {
            if (!checkReadyForSaveUpload(true /* save */)) {
                return
            }
            fileDialog.title =          qsTr("Save KML")
            fileDialog.planFiles =      false
            fileDialog.selectExisting = false
            fileDialog.nameFilters =    ShapeFileHelper.fileDialogKMLFilters
            fileDialog.openForSave()
        }
    }

    Connections {
        target: _missionController

        function onNewItemsFromVehicle() {
            if (_visualItems && _visualItems.count !== 1) {
                mapFitFunctions.fitMapViewportToMissionItems()
            }
            _missionController.setCurrentPlanViewSeqNum(0, true)
        }
    }

    function insertSimpleItemAfterCurrent(coordinate) {
        var nextIndex = _missionController.currentPlanViewVIIndex + 1
        _missionController.insertSimpleMissionItem(coordinate, nextIndex, true /* makeCurrentItem */)
    }


    function insertROIAfterCurrent(coordinate) {
        var nextIndex = _missionController.currentPlanViewVIIndex + 1
        _missionController.insertROIMissionItem(coordinate, nextIndex, true /* makeCurrentItem */)
    }

    function insertCancelROIAfterCurrent() {
        var nextIndex = _missionController.currentPlanViewVIIndex + 1
        _missionController.insertCancelROIMissionItem(nextIndex, true /* makeCurrentItem */)
    }

    function insertComplexItemAfterCurrent(complexItemName) {
        var nextIndex = _missionController.currentPlanViewVIIndex + 1
        _missionController.insertComplexMissionItem(complexItemName, mapCenter(), nextIndex, true /* makeCurrentItem */)
    }

    function insertTakeItemAfterCurrent() {
        var nextIndex = _missionController.currentPlanViewVIIndex + 1
        _missionController.insertTakeoffItem(mapCenter(), nextIndex, true /* makeCurrentItem */)
    }

    function insertLandItemAfterCurrent() {
        var nextIndex = _missionController.currentPlanViewVIIndex + 1
        _missionController.insertLandItem(mapCenter(), nextIndex, true /* makeCurrentItem */)
    }


    function selectNextNotReady() {
        var foundCurrent = false
        for (var i=0; i<_missionController.visualItems.count; i++) {
            var vmi = _missionController.visualItems.get(i)
            if (vmi.readyForSaveState === VisualMissionItem.NotReadyForSaveData) {
                _missionController.setCurrentPlanViewSeqNum(vmi.sequenceNumber, true)
                break
            }
        }
    }

    property int _moveDialogMissionItemIndex

    QGCFileDialog {
        id:             fileDialog
        folder:         _appSettings ? _appSettings.missionSavePath : ""

        property bool planFiles: true    ///< true: working with plan files, false: working with kml file

        onAcceptedForSave: {
            if (planFiles) {
                _planMasterController.saveToFile(file)
            } else {
                _planMasterController.saveToKml(file)
            }
            close()
        }

        onAcceptedForLoad: {
            _planMasterController.loadFromFile(file)
            _planMasterController.fitViewportToItems()
            _missionController.setCurrentPlanViewSeqNum(0, true)
            close()
        }
    }

    Component {
        id: moveDialog
        QGCViewDialog {
            function accept() {
                var toIndex = toCombo.currentIndex
                if (toIndex === 0) {
                    toIndex = 1
                }
                _missionController.moveMissionItem(_moveDialogMissionItemIndex, toIndex)
                hideDialog()
            }
            Column {
                anchors.left:   parent.left
                anchors.right:  parent.right
                spacing:        ScreenTools.defaultFontPixelHeight

                QGCLabel {
                    anchors.left:   parent.left
                    anchors.right:  parent.right
                    wrapMode:       Text.WordWrap
                    text:           qsTr("Move the selected mission item to the be after following mission item:")
                }

                QGCComboBox {
                    id:             toCombo
                    model:          _visualItems.count
                    currentIndex:   _moveDialogMissionItemIndex
                }
            }
        }
    }

    Item {
        id:             panel
        anchors.fill:   parent

        FlightMap {
            id:                         editorMap
            anchors.fill:               parent
            mapName:                    "MissionEditor"
            allowGCSLocationCenter:     true
            allowVehicleLocationCenter: true
            planView:                   true

            zoomLevel:                  QGroundControl.flightMapZoom
            center:                     QGroundControl.flightMapPosition

            // This is the center rectangle of the map which is not obscured by tools
            property rect centerViewport:   Qt.rect(_leftToolWidth + _margin,  _margin, editorMap.width - _leftToolWidth - _rightToolWidth - (_margin * 2), (terrainStatus.visible ? terrainStatus.y : height - _margin) - _margin)

            property real _leftToolWidth:       toolStrip.x + toolStrip.width
            property real _rightToolWidth:      rightPanel.width + rightPanel.anchors.rightMargin
            property real _nonInteractiveOpacity:  0.5

            // Initial map position duplicates Fly view position
            Component.onCompleted: editorMap.center = QGroundControl.flightMapPosition

            QGCMapPalette { id: mapPal; lightColors: editorMap.isSatelliteMap }

            onZoomLevelChanged: {
                QGroundControl.flightMapZoom = zoomLevel
                updateAirspace(false)
            }
            onCenterChanged: {
                QGroundControl.flightMapPosition = center
                updateAirspace(false)
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    // Take focus to close any previous editing
                    editorMap.focus = true
                    var coordinate = editorMap.toCoordinate(Qt.point(mouse.x, mouse.y), false /* clipToViewPort */)
                    coordinate.latitude = coordinate.latitude.toFixed(_decimalPlaces)
                    coordinate.longitude = coordinate.longitude.toFixed(_decimalPlaces)
                    coordinate.altitude = coordinate.altitude.toFixed(_decimalPlaces)

                    switch (_editingLayer) {
                    case _layerMission:
                        if (addWaypointRallyPointAction.checked) {
                            insertSimpleItemAfterCurrent(coordinate)
                        } else if (_addROIOnClick) {
                            insertROIAfterCurrent(coordinate)
                            _addROIOnClick = false
                        }

                        break
                    case _layerRallyPoints:
                        if (_rallyPointController.supported && addWaypointRallyPointAction.checked) {
                            _rallyPointController.addPoint(coordinate)
                        }
                        break
                    }
                }
            }

            // Add the mission item visuals to the map
            Repeater {
                model: _missionController.visualItems
                delegate: MissionItemMapVisual {
                    map:         editorMap
                    onClicked:   _missionController.setCurrentPlanViewSeqNum(sequenceNumber, false)
                    opacity:     _editingLayer == _layerMission ? 1 : editorMap._nonInteractiveOpacity
                    interactive: _editingLayer == _layerMission
                    vehicle:     _planMasterController.controllerVehicle
                }
            }

            // Add lines between waypoints
            MissionLineView {
                showSpecialVisual:  _missionController.isROIBeginCurrentItem
                model:              _missionController.simpleFlightPathSegments
                opacity:            _editingLayer == _layerMission ? 1 : editorMap._nonInteractiveOpacity
            }

            // Direction arrows in waypoint lines
            MapItemView {
                model: _editingLayer == _layerMission ? _missionController.directionArrows : undefined

                delegate: MapLineArrow {
                    fromCoord:      object ? object.coordinate1 : undefined
                    toCoord:        object ? object.coordinate2 : undefined
                    arrowPosition:  3
                    z:              QGroundControl.zOrderWaypointLines + 1
                }
            }

            // Incomplete segment lines
            MapItemView {
                model: _missionController.incompleteComplexItemLines

                delegate: MapPolyline {
                    path:       [ object.coordinate1, object.coordinate2 ]
                    line.width: 1
                    line.color: "red"
                    z:          QGroundControl.zOrderWaypointLines
                    opacity:    _editingLayer == _layerMission ? 1 : editorMap._nonInteractiveOpacity
                }
            }

            // UI for splitting the current segment
            MapQuickItem {

                id:             splitSegmentItem
                anchorPoint.x:  sourceItem.width / 2
                anchorPoint.y:  sourceItem.height / 2
                z:              QGroundControl.zOrderWaypointLines + 1
                visible:        _editingLayer == _layerMission

                sourceItem: SplitIndicator {


                    function _mapCenter() {
                        var centerPoint = Qt.point(editorMap.centerViewport.left + (editorMap.centerViewport.width / 2), editorMap.centerViewport.top + (editorMap.centerViewport.height / 2))
                        return editorMap.toCoordinate(centerPoint, false /* clipToViewPort */)
                    }
//                    onClicked:  _missionController.insertSimpleMissionItem(splitSegmentItem.coordinate,
//                                                                           _missionController.currentPlanViewVIIndex,
//                                                                           true /* makeCurrentItem */)
                    onClicked:  {
                        //console.log("P1-coor:",_missionController.splitSegment.coordinate1.longitude.toFixed(6))
                        //console.log("P2-coor:",_missionController.splitSegment.coordinate2.latitude.toFixed(6))
                        mainWindow.showComponentDialog(insertCurvePromptDialog, qsTr("Insert Curve Plan"), mainWindow.showDialogDefaultWidth, StandardButton.Yes | StandardButton.No)
                     //   mainWindow.showMessageDialog(qsTr("Confirm Step="), qsTr('Wanted Information'))
                      //  console.log("Maximum Steplean:",myAngularMaximum,myDistanceMaximum)

                         }

                }

                function _updateSplitCoord() {
                    if (_missionController.splitSegment) {
                        var distance = _missionController.splitSegment.coordinate1.distanceTo(_missionController.splitSegment.coordinate2)
                        var azimuth = _missionController.splitSegment.coordinate1.azimuthTo(_missionController.splitSegment.coordinate2)
                        splitSegmentItem.coordinate = _missionController.splitSegment.coordinate1.atDistanceAndAzimuth(distance / 2, azimuth)
                    } else {
                        coordinate = QtPositioning.coordinate()
                    }
                }

                Connections {
                    target:                 _missionController
                    function onSplitSegmentChanged()  { splitSegmentItem._updateSplitCoord() }
                }

                Connections {
                    target:                 _missionController.splitSegment
                    function onCoordinate1Changed()   { splitSegmentItem._updateSplitCoord() }
                    function onCoordinate2Changed()   { splitSegmentItem._updateSplitCoord() }
                }
            }

            // Add the vehicles to the map
            MapItemView {
                model: QGroundControl.multiVehicleManager.vehicles
                delegate: VehicleMapItem {
                    vehicle:        object
                    coordinate:     object.coordinate
                    map:            editorMap
                    size:           ScreenTools.defaultFontPixelHeight * 3
                    z:              QGroundControl.zOrderMapItems - 1
                }
            }

            GeoFenceMapVisuals {
                map:                    editorMap
                myGeoFenceController:   _geoFenceController
                interactive:            _editingLayer == _layerGeoFence
                homePosition:           _missionController.plannedHomePosition
                planView:               true
                opacity:                _editingLayer != _layerGeoFence ? editorMap._nonInteractiveOpacity : 1
            }

            RallyPointMapVisuals {
                map:                    editorMap
                myRallyPointController: _rallyPointController
                interactive:            _editingLayer == _layerRallyPoints
                planView:               true
                opacity:                _editingLayer != _layerRallyPoints ? editorMap._nonInteractiveOpacity : 1
            }

            // Airspace overlap support
            MapItemView {
                model:              _airspaceEnabled && QGroundControl.airspaceManager.airspaceVisible ? QGroundControl.airspaceManager.airspaces.circles : []
                delegate: MapCircle {
                    center:         object.center
                    radius:         object.radius
                    color:          object.color
                    border.color:   object.lineColor
                    border.width:   object.lineWidth
                }
            }

            MapItemView {
                model:              _airspaceEnabled && QGroundControl.airspaceManager.airspaceVisible ? QGroundControl.airspaceManager.airspaces.polygons : []
                delegate: MapPolygon {
                    path:           object.polygon
                    color:          object.color
                    border.color:   object.lineColor
                    border.width:   object.lineWidth
                }
            }
        }

        //-----------------------------------------------------------
        // Left tool strip
//

        ToolStrip {
            id:                 toolStrip
            anchors.margins:    _toolsMargin
            anchors.left:       parent.left
            anchors.top:        parent.top
            z:                  QGroundControl.zOrderWidgets
            maxHeight:          parent.height - toolStrip.y
            title:              qsTr("Plan")
            width:90
            color:"grey"

            readonly property int flyButtonIndex:       0
            readonly property int fileButtonIndex:      1
            readonly property int takeoffButtonIndex:   2
            readonly property int waypointButtonIndex:  3
            readonly property int roiButtonIndex:       4
            readonly property int patternButtonIndex:   5
            readonly property int landButtonIndex:      6
            readonly property int centerButtonIndex:    7

            property bool _isRallyLayer:    _editingLayer == _layerRallyPoints
            property bool _isMissionLayer:  _editingLayer == _layerMission

            ToolStripActionList {
                id: toolStripActionList
                model: [
                    ToolStripAction {
                        text:           qsTr("Fly")
                        iconSource:     "/qmlimages/PaperPlane.svg"
                        onTriggered:    mainWindow.showFlyView()
                    },
                    ToolStripAction {
                        text:       qsTr("暂停")
                        iconSource: "/res/Pause.svg"
                        enabled:    _missionController.isInsertTakeoffValid
                        visible:    toolStrip._isMissionLayer && !_planMasterController.controllerVehicle.rover
                        onTriggered: {

                        }
                    },
                    ToolStripAction {
                        text:                   qsTr("File")
                        enabled:                !_planMasterController.syncInProgress
                        visible:                true
                        showAlternateIcon:      _planMasterController.dirty
                        iconSource:             "/qmlimages/MapSync.svg"
                        alternateIconSource:    "/qmlimages/MapSyncChanged.svg"
                        dropPanelComponent:     syncDropPanel
                    },
                    ToolStripAction {
                        text:       qsTr("Takeoff")
                        iconSource: "/res/takeoff.svg"
                        enabled:    _missionController.isInsertTakeoffValid
                        //visible:    toolStrip._isMissionLayer && !_planMasterController.controllerVehicle.rover
                        visible: true
                        onTriggered: {
                            toolStrip.allAddClickBoolsOff()  //guest? enable Waypoint button.
                            insertTakeItemAfterCurrent()  // mark next fly point.
                        }
                    },

                    ToolStripAction {
                        id:                 addWaypointRallyPointAction
                        text:               _editingLayer == _layerRallyPoints ? qsTr("Rally Point") : qsTr("Waypoint")
                        iconSource:         "/qmlimages/MapAddMission.svg"
                        enabled:            toolStrip._isRallyLayer ? true : _missionController.flyThroughCommandsAllowed
                        visible:            toolStrip._isRallyLayer || toolStrip._isMissionLayer
                        checkable:          true
                    },
                    ToolStripAction {
                        text:               _missionController.isROIActive ? qsTr("Cancel ROI") : qsTr("ROI")
                        iconSource:         "/qmlimages/MapAddMission.svg"
                        enabled:            !_missionController.onlyInsertTakeoffValid
                        //visible:            toolStrip._isMissionLayer && _planMasterController.controllerVehicle.roiModeSupported
                        visible:            false
                        checkable:          !_missionController.isROIActive
                        onCheckedChanged:   _addROIOnClick = checked
                        onTriggered: {
                            if (_missionController.isROIActive) {
                                toolStrip.allAddClickBoolsOff()
                                insertCancelROIAfterCurrent()
                            }
                        }
                        property bool myAddROIOnClick: _addROIOnClick
                        onMyAddROIOnClickChanged: checked = _addROIOnClick
                    },
                    ToolStripAction {
                        text:               _singleComplexItem ? _missionController.complexMissionItemNames[0] : qsTr("Pattern")
                        iconSource:         "/qmlimages/MapDrawShape.svg"
                        enabled:            _missionController.flyThroughCommandsAllowed
                        //visible:            toolStrip._isMissionLayer
                        visible: false
                        dropPanelComponent: _singleComplexItem ? undefined : patternDropPanel
                        onTriggered: {
                            toolStrip.allAddClickBoolsOff()
                            if (_singleComplexItem) {
                                insertComplexItemAfterCurrent(_missionController.complexMissionItemNames[0])
                            }
                        }
                    },
                    ToolStripAction {
                        text:       _planMasterController.controllerVehicle.multiRotor ? qsTr("Return") : qsTr("Land")
                        iconSource: "/res/rtl.svg"
                        enabled:    _missionController.isInsertLandValid
                        //visible:    toolStrip._isMissionLayer
                        visible: false
                        onTriggered: {
                            toolStrip.allAddClickBoolsOff()
                            insertLandItemAfterCurrent()
                        }
                    },
                    ToolStripAction {
                        text:               qsTr("Center")
                        iconSource:         "/qmlimages/MapCenter.svg"
                        enabled:            true
                        visible:            true
                        dropPanelComponent: centerMapDropPanel
                    }
                ]
            }

            model: toolStripActionList.model

            function allAddClickBoolsOff() {
                _addROIOnClick =        false
                addWaypointRallyPointAction.checked = false
            }

            onDropped: allAddClickBoolsOff()
        }

        //-----------------------------------------------------------
        // Right pane for mission editing controls
        Rectangle {
            id:                 rightPanel
            height:             parent.height
            width:              _rightPanelWidth
            color:              qgcPal.window
            opacity:            layerTabBar.visible ? 0.2 : 0
            anchors.bottom:     parent.bottom
            anchors.right:      parent.right
            anchors.rightMargin: _toolsMargin
        }
        //-------------------------------------------------------
        // Right Panel Controls
        Item {
            anchors.fill:           rightPanel
            anchors.topMargin:      _toolsMargin
            DeadMouseArea {
                anchors.fill:   parent
            }
            Column {
                id:                 rightControls
                spacing:            ScreenTools.defaultFontPixelHeight * 0.5
                anchors.left:       parent.left
                anchors.right:      parent.right
                anchors.top:        parent.top
                //-------------------------------------------------------
                // Airmap Airspace Control
                AirspaceControl {
                    id:             airspaceControl
                    width:          parent.width
                    visible:        _airspaceEnabled
                    planView:       true
                    showColapse:    true
                }
                //-------------------------------------------------------
                // Mission Controls (Colapsed)
                Rectangle {
                    width:      parent.width
                    height:     planControlColapsed ? colapsedRow.height + ScreenTools.defaultFontPixelHeight : 0
                    color:      qgcPal.missionItemEditor
                    radius:     _radius
                    visible:    planControlColapsed && _airspaceEnabled
                    Row {
                        id:                     colapsedRow
                        spacing:                ScreenTools.defaultFontPixelWidth
                        anchors.left:           parent.left
                        anchors.leftMargin:     ScreenTools.defaultFontPixelWidth
                        anchors.verticalCenter: parent.verticalCenter
                        QGCColoredImage {
                            width:              height
                            height:             ScreenTools.defaultFontPixelWidth * 2.5
                            sourceSize.height:  height
                            source:             "qrc:/res/waypoint.svg"
                            color:              qgcPal.text
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        QGCLabel {
                            text:               qsTr("Plan")
                            color:              qgcPal.text
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                    QGCColoredImage {
                        width:                  height
                        height:                 ScreenTools.defaultFontPixelWidth * 2.5
                        sourceSize.height:      height
                        source:                 QGroundControl.airmapSupported ? "qrc:/airmap/expand.svg" : ""
                        color:                  "white"
                        visible:                QGroundControl.airmapSupported
                        anchors.right:          parent.right
                        anchors.rightMargin:    ScreenTools.defaultFontPixelWidth
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    MouseArea {
                        anchors.fill:   parent
                        enabled:        QGroundControl.airmapSupported
                        onClicked: {
                            QGroundControl.airspaceManager.airspaceVisible = false
                        }
                    }
                }
                //-------------------------------------------------------
                // Mission Controls (Expanded)
                QGCTabBar {
                    id:         layerTabBar
                    width:      parent.width
                    visible:    (!planControlColapsed || !_airspaceEnabled) && QGroundControl.corePlugin.options.enablePlanViewSelector
                    Component.onCompleted: currentIndex = 0
                    QGCTabButton {
                        text:       qsTr("Mission")
                    }
                    QGCTabButton {
                        text:       qsTr("Fence")
                        enabled:    _geoFenceController.supported
                    }
                    QGCTabButton {
                        text:       qsTr("Rally")
                        enabled:    _rallyPointController.supported
                    }
                }
            }
            //-------------------------------------------------------
            // Mission Item Editor
            Item {
                id:                     missionItemEditor
                anchors.left:           parent.left
                anchors.right:          parent.right
                anchors.top:            rightControls.bottom
                anchors.topMargin:      ScreenTools.defaultFontPixelHeight * 0.25
                anchors.bottom:         parent.bottom
                anchors.bottomMargin:   ScreenTools.defaultFontPixelHeight * 0.25
                visible:                _editingLayer == _layerMission && !planControlColapsed
                QGCListView {
                    id:                 missionItemEditorListView
                    anchors.fill:       parent
                    spacing:            ScreenTools.defaultFontPixelHeight / 4
                    orientation:        ListView.Vertical
                    model:              _missionController.visualItems
                    cacheBuffer:        Math.max(height * 2, 0)
                    clip:               true
                    currentIndex:       _missionController.currentPlanViewSeqNum
                    highlightMoveDuration: 250
                    visible:            _editingLayer == _layerMission && !planControlColapsed
                    //-- List Elements
                    delegate: MissionItemEditor {
                        map:            editorMap
                        masterController:  _planMasterController
                        missionItem:    object
                        width:          parent.width
                        readOnly:       false
                        onClicked:      _missionController.setCurrentPlanViewSeqNum(object.sequenceNumber, false)
                        onRemove: {
                            var removeVIIndex = index
                            _missionController.removeVisualItem(removeVIIndex)
                            if (removeVIIndex >= _missionController.visualItems.count) {
                                removeVIIndex--
                            }
                        }
                        onSelectNextNotReadyItem:   selectNextNotReady()
                    }
                }
            }
            // GeoFence Editor
            GeoFenceEditor {
                anchors.top:            rightControls.bottom
                anchors.topMargin:      ScreenTools.defaultFontPixelHeight * 0.25
                anchors.bottom:         parent.bottom
                anchors.left:           parent.left
                anchors.right:          parent.right
                myGeoFenceController:   _geoFenceController
                flightMap:              editorMap
                visible:                _editingLayer == _layerGeoFence
            }

            // Rally Point Editor
            RallyPointEditorHeader {
                id:                     rallyPointHeader
                anchors.top:            rightControls.bottom
                anchors.topMargin:      ScreenTools.defaultFontPixelHeight * 0.25
                anchors.left:           parent.left
                anchors.right:          parent.right
                visible:                _editingLayer == _layerRallyPoints
                controller:             _rallyPointController
            }
            RallyPointItemEditor {
                id:                     rallyPointEditor
                anchors.top:            rallyPointHeader.bottom
                anchors.topMargin:      ScreenTools.defaultFontPixelHeight * 0.25
                anchors.left:           parent.left
                anchors.right:          parent.right
                visible:                _editingLayer == _layerRallyPoints && _rallyPointController.points.count
                rallyPoint:             _rallyPointController.currentRallyPoint
                controller:             _rallyPointController
            }
        }

        TerrainStatus {
            id:                 terrainStatus
            anchors.margins:    _toolsMargin
            anchors.leftMargin: 0
            anchors.left:       mapScale.left
            anchors.right:      rightPanel.left
            anchors.bottom:     parent.bottom
            height:             ScreenTools.defaultFontPixelHeight * 7
            missionController:  _missionController
            visible:            _internalVisible && _editingLayer === _layerMission && QGroundControl.corePlugin.options.showMissionStatus

            onSetCurrentSeqNum: _missionController.setCurrentPlanViewSeqNum(seqNum, true)

            property bool _internalVisible: _planViewSettings.showMissionItemStatus.rawValue

            function toggleVisible() {
                _internalVisible = !_internalVisible
                _planViewSettings.showMissionItemStatus.rawValue = _internalVisible
            }
        }

        MapScale {
            id:                     mapScale
            anchors.margins:        _toolsMargin
            anchors.bottom:         terrainStatus.visible ? terrainStatus.top : parent.bottom
            anchors.left:           toolStrip.y + toolStrip.height + _toolsMargin > mapScale.y ? toolStrip.right: parent.left
            mapControl:             editorMap
            buttonsOnLeft:          true
            terrainButtonVisible:   _editingLayer === _layerMission
            terrainButtonChecked:   terrainStatus.visible
            onTerrainButtonClicked: terrainStatus.toggleVisible()
        }
    }

    Component {
        id: syncLoadFromVehicleOverwrite
        QGCViewMessage {
            id:         syncLoadFromVehicleCheck
            message:   qsTr("You have unsaved/unsent changes. Loading from the Vehicle will lose these changes. Are you sure you want to load from the Vehicle?")
            function accept() {
                hideDialog()
                _planMasterController.loadFromVehicle()
            }
        }
    }

    Component {
        id: syncLoadFromFileOverwrite
        QGCViewMessage {
            id:         syncLoadFromVehicleCheck
            message:   qsTr("You have unsaved/unsent changes. Loading from a file will lose these changes. Are you sure you want to load from a file?")
            function accept() {
                hideDialog()
                _planMasterController.loadFromSelectedFile()
            }
        }
    }

    property var createPlanRemoveAllPromptDialogMapCenter
    property var createPlanRemoveAllPromptDialogPlanCreator
    Component {
        id: createPlanRemoveAllPromptDialog
        QGCViewMessage {
            message: qsTr("Are you sure you want to remove current plan and create a new plan? ")
            function accept() {
                createPlanRemoveAllPromptDialogPlanCreator.createPlan(createPlanRemoveAllPromptDialogMapCenter)
                hideDialog()
            }
        }
    }

    //定义变量    Updated 20221209

//    property var    _circle
//    property bool   _circleShowing:   false


//Updated 20221209 LEO
//    function hideCircle() {
//        if (_circleShowing) {
//            _circle.destroy()
//            _circleShowing = false
//        }
//    }



//    function showCircle() {
//        if (!_circleShowing) {
//            _circle = circleComponent.createObject(map)
//            map.addMapItem(_circle)
//            _circleShowing = true
//        }
//    }



//   Component {
//               id: circleComponent

//                       MapCircle {
//                           color:          Qt.rgba(0,0,0,0)
//                           border.color:   "yellow"
//                           border.width:   6
//                           //center:         _missionController.splitSegment.coordinate1
//                           center:         QtPositioning.coordinate()
//                           radius:         200
//                           visible:        true
//                       }


//                   }

//   Component.onCompleted: {

//       showCircle()
//   }
//   Loader { sourceComponent: circleComponent2 }
    Component {

        id: insertCurvePromptDialog
        QGCViewMessage {
            message: qsTr("Are you sure you want to create a new curve plan between these 2 ponits? ")
            function generatePath(){
                  const start_Lat = parseFloat(_missionController.splitSegment.coordinate1.latitude);
                  const start_Lon = parseFloat(_missionController.splitSegment.coordinate1.longitude);
                  const end_Lat = parseFloat(_missionController.splitSegment.coordinate2.latitude).toFixed(6);
                  const end_Lon = parseFloat(_missionController.splitSegment.coordinate2.longitude).toFixed(6);

                var coordinate = editorMap.center
                const ratio_B= (1.0/111122.19769899000); // 1meter=? degree in B ,纬度 Latitude
                const ratio_L= (1.0/96234.340763000);   //1meter=? degree in L,经度 Longitude
                var param_A=0.0;
                var param_B=0.0;
                var param_C=0.0;// Reverse the Curve purpose.
                // Use new symmetry Arc Center C1 to draw the reverse arc
                // straight line l:  Ax+By+C=0, M(x0,y0) --->>  Symmetry Point  M(x1,y1)
                //param_A= end_Lat-start_Lat;
                //param_B=start_Lon-end_Lon;
                //param_C=(end_Lon-start_Lon)*start_Lat-(end_Lat-start_Lat)*start_Lon;

                var distance =Math.sqrt(Math.pow(((end_Lat-start_Lat)/ratio_B),2)+Math.pow(((end_Lon-start_Lon)/ratio_L),2));
                var realR= distance*0.5/Math.sin((myAngularSpan*0.5)*Math.PI/180.0);//Unit as in Meter.
                var delta_y= Math.abs((end_Lat-start_Lat))/ratio_B;  // Unit as in Meter(M)
                var delta_x= Math.abs((end_Lon-start_Lon))/ratio_L;  // Unit as in Meter(M)
                var Angle1=myAngularSpan;  //arc span in unit  MUST <180 degree
                var Angle2=180.0*Math.atan(delta_y/delta_x)/Math.PI;  //as definition as Positive always
                var Angle3=(180.0-Angle1)*0.5;  // another two equal angle of the key triangle.
                var keyAngle= Angle3- Angle2;
                var start_theta= 0.0;var end_theta=0.0;

                var   center_B= 0.0; var RevCenter_B=0.0;// Symmetry center1 B
                var   center_L= 0.0; var RevCenter_L=0.0; //Symmetry  Center1 L

                var shift_x=0.0;   var RevShift_x=0.0;
                var shift_y=0.0;   var RevShift_y=0.0;


                if((end_Lon-start_Lon)>0) {          //directing -->> Right
                    if((end_Lat-start_Lat)<0)  start_theta= keyAngle+Angle1; //directing --> Down.
                    if((end_Lat-start_Lat)>=0)  start_theta= 180.0-keyAngle;//directing --> Up .
                    end_theta=start_theta-Angle1;
                    // to locate the Circle Center BL.
                      shift_y= realR*Math.sin((start_theta)*Math.PI/180);  // 180> always be positive >0
                      shift_x= realR*Math.cos((start_theta)*Math.PI/180);// 180> negative>90;  90> positive>0
                      RevShift_y=realR*Math.cos((90.0-start_theta-Angle1)*Math.PI/180);
                      RevShift_x=realR*Math.sin((90.0-start_theta-Angle1)*Math.PI/180);
                    center_B= end_Lat-shift_y*ratio_B;// center   in B ,纬度 Latitude
                    center_L= end_Lon-shift_x*ratio_L;//  Center  in L,经度 Longitude
                    RevCenter_B= end_Lat+RevShift_y*ratio_B;//
                    RevCenter_L= end_Lon+RevShift_x*ratio_L;//
                    console.log('Radius,C1-X,Yshift=:',realR,shift_x,shift_y);

                };
                if((end_Lon-start_Lon)<=0) {  //directing -->> Left
                     if((end_Lat-start_Lat)<0)  start_theta= 180.0-keyAngle-Angle1;//directing --> Down.
                     if((end_Lat-start_Lat)>=0)  start_theta= keyAngle;//directing --> Up .
                    keyAngle=start_theta;
                    end_theta=start_theta+Angle1;
                     shift_y= realR*Math.sin((start_theta)*Math.PI/180);  // 180> always be positive >0
                     shift_x= realR*Math.cos((start_theta)*Math.PI/180);// 180> negative>90;  90> positive>0
                     RevShift_y=realR*Math.cos((90.0-start_theta-Angle1)*Math.PI/180);
                     RevShift_x=realR*Math.sin((90.0-start_theta-Angle1)*Math.PI/180);
                    center_B= start_Lat-shift_y*ratio_B;//inputed data// center B
                    center_L= start_Lon-shift_x*ratio_L;//inputed data  Center L
                     RevCenter_B= start_Lat+RevShift_y*ratio_B;//
                     RevCenter_L= start_Lon+RevShift_x*ratio_L;//
                    console.log('Radius,C1-X,Yshift=:',realR,shift_x,shift_y);

                };
                    var   center_H= 99.0;//圆心的 经纬度BLH坐标

                    console.log('ReverseCenter=',RevCenter_B,RevCenter_L)
//                        console.log('startTheta=',start_theta,'Radius=',realR,'EndTheta=',end_theta);
//                        console.log('Cor-shiftX=',shift_x*ratio_L,'Cor-shiftY=',shift_y*ratio_B);
//                        console.log('angle1,2,3=',Angle1,Angle2,Angle3);
//                        console.log('Start Lat=',start_Lat,'Start Lon=',start_Lon);
//                        console.log('End Lat=',end_Lat,'End Lon=',end_Lon);
//                        console.log('CenterLat=',center_B,'CenterLon=',center_L);
                //console.log('ParamA,B,C=',param_A,param_B,param_C);
                //console.log('EquationTest=X1',cor_B[i]-2.0*param_A*(param_A*cor_B[i]+param_B*cor_L[i]+param_C)/(param_A*param_A+param_B*param_B););
                //console.log('EquationTest=X2',param_A*end_Lon+param_B*end_Lat+param_C);

 //                               const start_x=realR*Math.cos((start_theta)*Math.PI/180.0);
 //                               const start_y=realR*Math.sin((start_theta)*Math.PI/180.0);//refer to center,  起始点的 x y z坐标and distance.in XY system.
                                var cor_x=new Array(50).fill(0.0); var cor_B=new Array(50).fill(0.0);var rev_B=new Array(50).fill(0.0);
                                var cor_y=new Array(50).fill(0.0); var cor_L=new Array(50).fill(0.0);var rev_L=new Array(50).fill(0.0);
 //                               var x_shift=0.0; var y_shift=0.0;
                                var N1=Math.ceil(Math.abs((end_theta- start_theta))/myAngularStep);//set to be 5 degree as default in angle.
                                var N2=Math.ceil(Math.abs((end_theta- start_theta))*Math.PI*2*realR/(360*myDistanceStep));//set to be 20cm
                                var N=N1; //=Math.max(N1,N2);
                                console.log('n1,n2=',N1,N2);
                                var points=N;
                                const d_theta=(end_theta- start_theta)/N;

                // pinpoint the Center and Symmetry Center of cirle
                 var nextIndex= _missionController.currentPlanViewVIIndex;
                coordinate.altitude = 6.180;
//                coordinate.latitude = center_B;
//                coordinate.longitude =center_L;
//                 _missionController.insertSimpleMissionItem(coordinate, nextIndex, true /* makeCurrentItem */);
//                coordinate.latitude = RevCenter_B;
//                coordinate.longitude =RevCenter_L;
//                 _missionController.insertSimpleMissionItem(coordinate, nextIndex, true /* makeCurrentItem */);


                               var anchorIndex = _missionController.currentPlanViewVIIndex-1;
                                for(let i=points-1; i>0;i--) {
                                      nextIndex= _missionController.currentPlanViewVIIndex;
                                      if((end_Lon-start_Lon)>0) {
                                        cor_L[i]=start_Lon+ratio_L*realR*(Math.cos((start_theta+i*d_theta)*Math.PI/180)-Math.cos(start_theta*Math.PI/180));
                                        //  console.log('SIN',(start_theta+i*d_theta),'-SIN',start_theta,'corBshift=',ratio_B*realR*(Math.sin(start_theta*Math.PI/180)-Math.sin((start_theta+i*d_theta)*Math.PI/180)));
                                        cor_B[i]=start_Lat+ratio_B*realR*(Math.sin((start_theta+i*d_theta)*Math.PI/180)-Math.sin(start_theta*Math.PI/180));
                                      }
                                      if((end_Lon-start_Lon)<=0) {
                                        cor_L[i]=start_Lon+ratio_L*realR*(Math.cos((start_theta+i*d_theta)*Math.PI/180)-Math.cos(start_theta*Math.PI/180));
                                       // console.log('SIN',(start_theta+i*d_theta),'-SIN',start_theta,'corBshift=',ratio_B*realR*(Math.sin(start_theta*Math.PI/180)-Math.sin((start_theta+i*d_theta)*Math.PI/180)));
                                        cor_B[i]=start_Lat-ratio_B*realR*(Math.sin(start_theta*Math.PI/180)-Math.sin((start_theta+i*d_theta)*Math.PI/180));
                                      }
                                       coordinate.latitude = cor_B[i];
                                       coordinate.longitude =cor_L[i];
                                                  // symmetry data come in:

                                              rev_B[i]=RevCenter_B-ratio_B*realR*(Math.sin((keyAngle-i*d_theta+Angle1)*Math.PI/180))  ;
                                              rev_L[i]=RevCenter_L-ratio_L*realR*(Math.cos((keyAngle-i*d_theta+Angle1)*Math.PI/180)) ;

                                              if(myReverseCurve==1) {
                                                  coordinate.latitude = rev_B[i];
                                                  coordinate.longitude =rev_L[i];
                                                  }
                                                   //console.log('write Lat/Lon:',cor_B[i],cor_L[i],'Write Rev_lat/Lon:',rev_B[i],rev_L[i]);

                                       coordinate.altitude = 6.180;
                                        _missionController.insertSimpleMissionItem(coordinate, nextIndex, true /* makeCurrentItem */);

                                    }
                                //set focus to last point as Visual Focus.
                                _missionController.setCurrentPlanViewSeqNum((anchorIndex+points),false);



                             }



                        function accept() {
                            //_planMasterController.removeAll()
                            generatePath()
                            //showCircle()

                            hideDialog()
                        }
        }

    }

    Component {
        id: clearVehicleMissionDialog
        QGCViewMessage {
            message: qsTr("Are you sure you want to remove all mission items and clear the mission from the vehicle?")
            function accept() {
                _planMasterController.removeAllFromVehicle()
                _missionController.setCurrentPlanViewSeqNum(0, true)
                hideDialog()
            }
        }
    }

    //- ToolStrip DropPanel Components

    Component {
        id: centerMapDropPanel

        CenterMapDropPanel {
            map:            editorMap
            fitFunctions:   mapFitFunctions
        }
    }

    Component {
        id: patternDropPanel

        ColumnLayout {
            spacing:    ScreenTools.defaultFontPixelWidth * 0.5

            QGCLabel { text: qsTr("Create complex pattern:") }

            Repeater {
                model: _missionController.complexMissionItemNames

                QGCButton {
                    text:               modelData
                    Layout.fillWidth:   true

                    onClicked: {
                        insertComplexItemAfterCurrent(modelData)
                        dropPanel.hide()
                    }
                }
            }
        } // Column
    }

    Component {
        id: syncDropPanel

        ColumnLayout {
            id:         columnHolder
            spacing:    _margin

            property string _overwriteText: (_editingLayer == _layerMission) ? qsTr("Mission overwrite") : ((_editingLayer == _layerGeoFence) ? qsTr("GeoFence overwrite") : qsTr("Rally Points overwrite"))

            QGCLabel {
                id:                 unsavedChangedLabel
                Layout.fillWidth:   true
                wrapMode:           Text.WordWrap
                text:               globals.activeVehicle ?
                                        qsTr("You have unsaved changes. You should upload to your vehicle, or save to a file.") :
                                        qsTr("You have unsaved changes.")
                visible:            _planMasterController.dirty
            }

            SectionHeader {
                id:                 createSection
                Layout.fillWidth:   true
                text:               qsTr("Create Plan")
                showSpacer:         false
            }

            GridLayout {
                columns:            2
                columnSpacing:      _margin
                rowSpacing:         _margin
                Layout.fillWidth:   true
                visible:            createSection.visible

                Repeater {
                    model: _planMasterController.planCreators

                    Rectangle {
                        id:     button
                        width:  ScreenTools.defaultFontPixelHeight * 7
                        height: planCreatorNameLabel.y + planCreatorNameLabel.height
                        color:  button.pressed || button.highlighted ? qgcPal.buttonHighlight : qgcPal.button

                        property bool highlighted: mouseArea.containsMouse
                        property bool pressed:     mouseArea.pressed

                        Image {
                            id:                 planCreatorImage
                            anchors.left:       parent.left
                            anchors.right:      parent.right
                            source:             object.imageResource
                            sourceSize.width:   width
                            fillMode:           Image.PreserveAspectFit
                            mipmap:             true
                        }

                        QGCLabel {
                            id:                     planCreatorNameLabel
                            anchors.top:            planCreatorImage.bottom
                            anchors.left:           parent.left
                            anchors.right:          parent.right
                            horizontalAlignment:    Text.AlignHCenter
                            text:                   object.name
                            color:                  button.pressed || button.highlighted ? qgcPal.buttonHighlightText : qgcPal.buttonText
                        }

                        QGCMouseArea {
                            id:                 mouseArea
                            anchors.fill:       parent
                            hoverEnabled:       true
                            preventStealing:    true
                            onClicked:          {
                                if (_planMasterController.containsItems) {
                                    createPlanRemoveAllPromptDialogMapCenter = _mapCenter()
                                    createPlanRemoveAllPromptDialogPlanCreator = object
                                    mainWindow.showComponentDialog(createPlanRemoveAllPromptDialog, qsTr("Create Plan"), mainWindow.showDialogDefaultWidth, StandardButton.Yes | StandardButton.No)
                                } else {
                                    object.createPlan(_mapCenter())
                                }
                                dropPanel.hide()
                            }

                            function _mapCenter() {
                                var centerPoint = Qt.point(editorMap.centerViewport.left + (editorMap.centerViewport.width / 2), editorMap.centerViewport.top + (editorMap.centerViewport.height / 2))
                                return editorMap.toCoordinate(centerPoint, false /* clipToViewPort */)
                            }
                        }
                    }
                }
            }

            SectionHeader {
                id:                 storageSection
                Layout.fillWidth:   true
                text:               qsTr("Storage")
            }

            GridLayout {
                columns:            3
                rowSpacing:         _margin
                columnSpacing:      ScreenTools.defaultFontPixelWidth
                visible:            storageSection.visible

                /*QGCButton {
                    text:               qsTr("New...")
                    Layout.fillWidth:   true
                    onClicked:  {
                        dropPanel.hide()
                        if (_planMasterController.containsItems) {
                            mainWindow.showComponentDialog(removeAllPromptDialog, qsTr("New Plan"), mainWindow.showDialogDefaultWidth, StandardButton.Yes | StandardButton.No)
                        }
                    }
                }*/

                QGCButton {
                    text:               qsTr("Open...")
                    Layout.fillWidth:   true
                    enabled:            !_planMasterController.syncInProgress
                    onClicked: {
                        dropPanel.hide()
                        if (_planMasterController.dirty) {
                            mainWindow.showComponentDialog(syncLoadFromFileOverwrite, columnHolder._overwriteText, mainWindow.showDialogDefaultWidth, StandardButton.Yes | StandardButton.Cancel)
                        } else {
                            _planMasterController.loadFromSelectedFile()// target 2nd develop part.  Function to load Path from File.
                        }
                    }
                }

                QGCButton {
                    text:               qsTr("Save")
                    Layout.fillWidth:   true
                    enabled:            !_planMasterController.syncInProgress && _planMasterController.currentPlanFile !== ""
                    onClicked: {
                        dropPanel.hide()
                        if(_planMasterController.currentPlanFile !== "") {
                            _planMasterController.saveToCurrent()
                        } else {
                            _planMasterController.saveToSelectedFile()
                        }
                    }
                }

                QGCButton {
                    text:               qsTr("Save As...")
                    Layout.fillWidth:   true
                    enabled:            !_planMasterController.syncInProgress && _planMasterController.containsItems
                    onClicked: {
                        dropPanel.hide()
                        _planMasterController.saveToSelectedFile()
                    }
                }

                QGCButton {
                    Layout.columnSpan:  3
                    Layout.fillWidth:   true
                    text:               qsTr("Save Mission Waypoints As KML...")
                    enabled:            !_planMasterController.syncInProgress && _visualItems.count > 1
                    onClicked: {
                        // First point does not count
                        if (_visualItems.count < 2) {
                            mainWindow.showComponentDialog(noItemForKML, qsTr("KML"), mainWindow.showDialogDefaultWidth, StandardButton.Cancel)
                            return
                        }
                        dropPanel.hide()
                        _planMasterController.saveKmlToSelectedFile()
                    }
                }
            }

            SectionHeader {
                id:                 mmtekSection
                Layout.fillWidth:   true
                text:               qsTr("MMTEK Manually Plan")
            }
            GridLayout {

                columns:            2
                rowSpacing:         _margin
                columnSpacing:      ScreenTools.defaultFontPixelWidth
                visible:            mmtekSection.visible

                        Column {
                            id:                     col
                            spacing:                3
                            //anchors.centerIn:       parent
                            QGCLabel {
                                anchors.horizontalCenter:   parent.horizontalCenter
                                text:                       "圆弧路径 发送测试！"
                                font.pointSize:             12
                                font.bold:                  true
                                color:                      "orange"
                            }
                            Row {
                                spacing:                2
                                Layout.fillWidth:   true
                                anchors.left:       parent.left
                                //anchors.right:      parent.right
                                QGCLabel {
                                    id:                         tipsLabel
                                    //anchors.verticalCenter:     protectTextField1.verticalCenter
                                    text:                       qsTr("圆心 B经度/L纬度/H高程：")
                                    font.pointSize:             8
                                    font.bold:                  true
                                    color:                      "#B7FF4A"
                                }
                                QGCTextField {
                                    id:                         protectTextField0
                                    width:                      40
                                    height:                     tipsLabel2.implicitHeight * 1.5
                                    text:                       "30.5478497"
                                    inputMethodHints:           Qt.ImhFormattedNumbersOnly
                                    focus:                      true
                                    onEditingFinished: {
                                        if(text > 10000) {
                                            text = 10000
                                            mainWindow.showMessageDialog(qsTr("警告"), qsTr("输入必须小于等于10000"))
                                        }
                                        else if(text < 0) {
                                            text = 0
                                            mainWindow.showMessageDialog(qsTr("警告"), qsTr("输入必须大于等于0"))
                                        }
                                    }
                                }
                                QGCTextField {
                                    id:                         protectTextField1
                                    width:                      40
                                    height:                     tipsLabel.implicitHeight * 1.5
                                    text:                       "114.37921215"
                                    inputMethodHints:           Qt.ImhFormattedNumbersOnly
                                    focus:                      true
                                    onEditingFinished: {
                                        if(text > 10000) {
                                            text = 10000
                                            mainWindow.showMessageDialog(qsTr("警告"), qsTr("输入必须小于等于10000"))
                                        }
                                        else if(text < 0) {
                                            text = 0
                                            mainWindow.showMessageDialog(qsTr("警告"), qsTr("输入必须大于等于0"))
                                        }
                                    }
                                }
                                QGCTextField {
                                    id:                         protectTextField2
                                    width:                      40
                                    height:                     tipsLabel.implicitHeight * 1.5
                                    text:                       "50.0"
                                    inputMethodHints:           Qt.ImhFormattedNumbersOnly
                                    focus:                      true
                                    onEditingFinished: {
                                        if(text > 1000) {
                                            text = 1000
                                            mainWindow.showMessageDialog(qsTr("警告"), qsTr("输入必须小于等于1000"))
                                        }
                                        else if(text < 0) {
                                            text = 0
                                            mainWindow.showMessageDialog(qsTr("警告"), qsTr("输入必须大于等于0"))
                                        }
                                    }
                                }
                            }
                            Row {
                                Layout.fillWidth:   true
                                //anchors.left:       parent.left
                                //anchors.right:      parent.right
                                QGCLabel {
                                    id:                         tipsLabel2
                                    //anchors.verticalCenter:     protectTextField2.verticalCenter
                                    text:                       qsTr("圆半径：(cm)")
                                    font.pointSize:             8
                                    font.bold:                  true
                                    color:                      "#B7FF4A"
                                }
                                //保护距离的输入
                                QGCTextField {
                                    id:                         protectTextField3
                                    width:                      40
                                    height:                     tipsLabel2.implicitHeight * 1.5
                                    text:                       "186871.721282235"
                                    inputMethodHints:           Qt.ImhFormattedNumbersOnly
                                    focus:                      true
                                    onEditingFinished: {
                                        if(text > 500000) {
                                            text = 500000
                                            mainWindow.showMessageDialog(qsTr("警告"), qsTr("输入必须小于等于500000CM"))
                                        }
                                        else if(text < 0) {
                                            text = 0
                                            mainWindow.showMessageDialog(qsTr("警告"), qsTr("输入必须大于等于0"))
                                        }
                                    }
                                }
                            }

                            Row {
                                //anchors.left:       parent.left
                                //anchors.right:      parent.right
                                Layout.fillWidth:   true
                                QGCLabel {
                                    id:                         tipsLabel3
                                    //anchors.verticalCenter:     protectTextField3.verticalCenter
                                    text:                       qsTr("弧度起点/终点：")
                                    font.pointSize:             8
                                    font.bold:                  true
                                    color:                      "#B7FF4A"
                                }
                                //保护距离的输入
                                QGCTextField {
                                    id:                         protectTextField4
                                    width:                      40
                                    height:                     tipsLabel3.implicitHeight * 1.5
                                    text:                       "0"
                                    inputMethodHints:           Qt.ImhFormattedNumbersOnly
                                    focus:                      true
                                    onEditingFinished: {
                                        if(text > 360) {
                                            text = 360
                                            mainWindow.showMessageDialog(qsTr("警告"), qsTr("输入必须小于等于360degree"))
                                        }
                                        else if(text < 0) {
                                            text = 0
                                            mainWindow.showMessageDialog(qsTr("警告"), qsTr("输入必须大于等于0"))
                                        }
                                    }
                                }
                                QGCTextField {
                                    id:                         protectTextField5
                                    width:                      40
                                    height:                     tipsLabel3.implicitHeight * 1.5
                                    text:                       "180"
                                    inputMethodHints:           Qt.ImhFormattedNumbersOnly
                                    focus:                      true
                                    onEditingFinished: {
                                        if(text > 360) {
                                            text = 360
                                            mainWindow.showMessageDialog(qsTr("警告"), qsTr("输入必须小于等于360"))
                                        }
                                        else if(text < 0) {
                                            text = 0
                                            mainWindow.showMessageDialog(qsTr("警告"), qsTr("输入必须大于等于0"))
                                        }
                                    }
                                }
                            }

                            Row {
                                //anchors.left:       parent.left
                                //anchors.right:      parent.right
                                Layout.fillWidth:   true
                                QGCLabel {
                                    id:                         tipsLabel4
                                    //anchors.verticalCenter:     protectTextField3.verticalCenter
                                    text:                       qsTr("离散航点密度限定(cm)/角度(°)：")
                                    font.pointSize:             8
                                    font.bold:                  true
                                    color:                      "#B7FF4A"
                                }
                                //保护距离的输入
                                QGCTextField {
                                    id:                         protectTextField6
                                    width:                      40
                                    height:                     tipsLabel4.implicitHeight * 1.5
                                    text:                       "1"
                                    inputMethodHints:           Qt.ImhFormattedNumbersOnly
                                    focus:                      true
                                    onEditingFinished: {
                                        if(text > 256) {
                                            text = 256
                                            mainWindow.showMessageDialog(qsTr("警告"), qsTr("输入必须小于等于256"))
                                        }
                                        else if(text < 0) {
                                            text = 0
                                            mainWindow.showMessageDialog(qsTr("警告"), qsTr("输入必须大于等于0"))
                                        }
                                    }
                                }
                                QGCTextField {
                                    id:                         protectTextField7
                                    width:                      40
                                    height:                     tipsLabel4.implicitHeight * 1.5
                                    text:                       "1"
                                    inputMethodHints:           Qt.ImhFormattedNumbersOnly
                                    focus:                      true
                                    onEditingFinished: {
                                        if(text > 256) {
                                            text = 256
                                            mainWindow.showMessageDialog(qsTr("警告"), qsTr("输入必须小于等于256"))
                                        }
                                        else if(text < 0) {
                                            text = 0
                                            mainWindow.showMessageDialog(qsTr("警告"), qsTr("输入必须大于等于0"))
                                        }
                                    }
                                }
                            }
                        Row {
                            spacing:8


                            Layout.fillWidth:   true

                            QGCButton {
                                //Layout.columnSpan:  3

                                Layout.fillWidth:   true

                                id:                             mavTestButton1
                                backRadius:                     height/4
                                text:                           qsTr("Delete Selected Point")
                               // enabled:                        activeVehicle

                                function blConstant(){
                                    console.log("Order a straight line Path of 10 meters to register local 经纬差")
                                    console.log("Current local 经差=96.234340763 KM")
                                    console.log("Current local 纬差=111.12219769899 KM")


                                }

                                onClicked: {
                                    var removeVIIndex = _missionController.currentPlanViewSeqNum
                                    _missionController.removeVisualItem(removeVIIndex)
                                    if (removeVIIndex >= _missionController.visualItems.count) {
                                        removeVIIndex--

//
                                }
                                    selectNextNotReady()
                              }
                            }
                            QGCButton {
                                //Layout.columnSpan:  3

                                Layout.fillWidth:   true

                                id:                             mavTestButton2
                                backRadius:                     height/4
                                text:                           qsTr("Generate")
                                //enabled:                        activeVehicle

                                //function insertMmtekItemAfterCurrent(coordinate) {
                                //    var nextIndex = _missionController.currentPlanViewVIIndex + 1
                                 //   _missionController.insertSimpleMissionItem(coordinate, nextIndex, true /* makeCurrentItem */)
                               // }

//                                function Timer() {
//                                    return Qt.createQmlObject("import QtQuick 2.0; Timer {}", root);
//                                }
                                function delay(delayTime,cb) {
                                    timer.interval = delayTime;
                                    timer.repeat = false;
                                    timer.triggered.connect(cb)
                                    timer.start();

                                }

                                Timer {id: timer}


//                                function setTimeout(callback,delayTime) {
//                                   //timer = new Timer();
//                                   timer.interval = delayTime;
//                                   timer.repeat = false;
//                                   timer.triggered.connect(callback);
//                                   timer.start();
//                                }

//                                function task_Timer(i,coordinate,nextIndex){
//                                   setTimeout(function(){
//                                       _missionController.insertSimpleMissionItem(coordinate, nextIndex, true /* makeCurrentItem */);
//                                       console.log("WritingTask Loop timer tigger: #",i);
//                                   },3000);
//                                }
                                function generatePath(){
                                                  var coordinate = editorMap.center
                                                  const  realR= parseFloat(protectTextField3.text);//inputed data
                                                  const   center_B= parseFloat(protectTextField0.text);//inputed data
                                                  const   center_H= parseFloat(protectTextField2.text);//inputed data
                                                  const   center_L= parseFloat(protectTextField1.text);//圆心的 经纬度BLH坐标
                                                  const ratio_B= (1.0/111122.19769899000); // 1meter=? degree in B ,纬度
                                                  const ratio_L= (1.0/96234.340763000);   //1meter=? degree in L,经度
                                                  const  start_theta=parseFloat(protectTextField4.text);
                                                  const  end_theta=parseFloat(protectTextField5.text);//起始和终点的圆心角 0---360度。

                                                    const start_x=realR*Math.cos((start_theta)*Math.PI/180.0);
                                                    const start_y=realR*Math.sin((start_theta)*Math.PI/180.0);//起始点的 xyz坐标系中初始化为 0,0,0
                                                    const start_B=center_B+(0.01)*ratio_B*realR*Math.sin((start_theta)*Math.PI/180.0);  //realR in CM unit.
                                                    const start_L=center_L+(0.01)*ratio_L*realR*Math.cos((start_theta)*Math.PI/180.0);//起始点的 xyz坐标系中初始化为 0,0,0
                                                    const cor_x=new Array(50).fill(0.0); const cor_B=new Array(50).fill(0.0);
                                                    const cor_y=new Array(50).fill(0.0); const cor_L=new Array(50).fill(0.0);

                                                    var x_shift=0.0; var y_shift=0.0;
                                                    const N1=Math.ceil((end_theta- start_theta)/5.0);//set to be 5 degree in angle.
                                                    const N2=Math.ceil((end_theta- start_theta)*Math.PI*2*realR/(360*20));//set to be 20cm
                                                    const N=20.0; //=Math.max(N1,N2);

                                                    const d_theta=(end_theta- start_theta)/N;
                                                    var points=N;

                                                    console.log("**Generating Arc Path......","N1=",N1,"N2=",N2,"N=",N,"D-theta=",d_theta)
                                                    console.log("**Lat=",center_B)
                                                    console.log("**Lon=",center_L)
                                                    console.log("**Height=",center_H)
                                                    console.log("**Radius=",realR)
                                                    console.log("**角度制starting from ",start_theta,"° To",end_theta,"°")
                                                    for(let i=0; i<=points;i++) {
                                                        var nextIndex = _missionController.currentPlanViewVIIndex + 1;
                                                        cor_x[i]= start_x+realR*(Math.cos((start_theta+i*d_theta)*Math.PI/180)-Math.cos(start_theta*Math.PI/180));
                                                        cor_y[i]= start_y-realR*(Math.sin(start_theta*Math.PI/180)-Math.sin((start_theta+i*d_theta)*Math.PI/180));
                                                        cor_B[i]=start_L+(0.01)*ratio_L*realR*(Math.cos((start_theta+i*d_theta)*Math.PI/180)-Math.cos(start_theta*Math.PI/180));
                                                        cor_L[i]=start_B-(0.01)*ratio_B*realR*(Math.sin(start_theta*Math.PI/180)-Math.sin((start_theta+i*d_theta)*Math.PI/180));
                                                        console.log("MainLoop#",i," point in XYZ cor:", cor_x[i].toFixed(3),cor_y[i].toFixed(3));
                                                        console.log("MainLoop#",i," waypoint in BLH cor: ",cor_L[i].toFixed(9),cor_B[i].toFixed(9));
                                                     //inster Prepare Entry point. and Setting up Prepare Entry Path Length
                                                     const entrylength=10.0; // Unit as in Meter

                                                        if(i==0){
                                                         x_shift=entrylength*Math.sin(start_theta*Math.PI/180);  //unit as in Meter
                                                         y_shift=-1.0*entrylength*Math.cos(start_theta*Math.PI/180);
                                                           coordinate.latitude = cor_L[i]+y_shift*ratio_B;
                                                            coordinate.longitude =cor_B[i]+x_shift*ratio_L;
                                                            coordinate.altitude = 6.180;
                                                            console.log("Writting in Entry P shift=", x_shift*ratio_L,y_shift*ratio_B)
                                                            _missionController.insertSimpleMissionItem(coordinate, nextIndex, true /* makeCurrentItem */);
                                                            nextIndex = _missionController.currentPlanViewVIIndex + 1;
                                                        }
                                                       coordinate.latitude = cor_L[i].toFixed(6);
                                                       coordinate.longitude = cor_B[i].toFixed(6);
                                                       coordinate.altitude = 6.180+i;
                                                       console.log("Coordinate Object upated as=",coordinate)
                                                        _missionController.insertSimpleMissionItem(coordinate, nextIndex, true /* makeCurrentItem */);
                                                        delay(5000,function(){
                                                           // console.log("I'm printed after 2second,delay tiggered for step#!",i);

                                                        }

                                                        );

                                                       //insertMmtekItemAfterCurrent(coordinate)


                                                        }
                                                    console.log("******Final Data Object of Coordinate=",coordinate);
                                                   // _planMasterController.saveToSelectedFile();


                                                 }
                                onClicked: {
                                    generatePath();
//
                                }
                            }

                         Repeater{
                            model: _planMasterController.planCreators



//                            Rectangle{

//                              width:30
//                              height:30
//                              visible:index<2?true:false
//                              color: "orange"
//                              Text{
//                                  text: index
//                              }

//                              }

                            QGCButton {

                                id:                             mavTestButton3
                               Layout.fillWidth:   true
                                backRadius:                     height/4
                                text:                           qsTr("Delete"+index)
                                visible:index<2?true:false
                                //enabled:                        activeVehicle
                                onClicked: {
                                    // simulate code to trigger the "Refresh" initialization for Creating a new Path , as copied as Line #1098.
//                                    if (_planMasterController.containsItems) {
                                    createPlanRemoveAllPromptDialogMapCenter = _mapCenter()
                                    createPlanRemoveAllPromptDialogPlanCreator = object
                                    mainWindow.showComponentDialog(createPlanRemoveAllPromptDialog, qsTr("Create Plan"), mainWindow.showDialogDefaultWidth, StandardButton.Yes | StandardButton.No)
//                                    }
//                                    else {
//                                        object.createPlan(_mapCenter())
//                                    }
                                   // _planMasterController.removeAll()
                                   //dropPanel.hide()
                                   // as blow, old code for Upload path from a file,  temporarily frezzed.
//                                    dropPanel.hide()
//                                    if (_planMasterController.dirty) {
//                                        mainWindow.showComponentDialog(syncLoadFromFileOverwrite, columnHolder._overwriteText, mainWindow.showDialogDefaultWidth, StandardButton.Yes | StandardButton.Cancel)
//                                    } else {
//                                        _planMasterController.loadFromSelectedFile()// target 2nd develop part.  Function to load Path from File.
//                                    }
                              }
                                function _mapCenter() {
                                    var centerPoint = Qt.point(editorMap.centerViewport.left + (editorMap.centerViewport.width / 2), editorMap.centerViewport.top + (editorMap.centerViewport.height / 2))
                                    return editorMap.toCoordinate(centerPoint, false /* clipToViewPort */)
                               }
                              }
                             }// for Repeater

                           } // Button layout row setting

                        }


            }


            SectionHeader {
                id:                 vehicleSection
                Layout.fillWidth:   true
                text:               qsTr("Vehicle")
            }

            RowLayout {
                Layout.fillWidth:   true
                spacing:            _margin
                visible:            vehicleSection.visible

                QGCButton {
                    text:               qsTr("Upload")
                    Layout.fillWidth:   true
                    enabled:            !_planMasterController.offline && !_planMasterController.syncInProgress && _planMasterController.containsItems
                    visible:            !QGroundControl.corePlugin.options.disableVehicleConnection
                    onClicked: {
                        dropPanel.hide()
                        _planMasterController.upload()
                    }
                }

                QGCButton {
                    text:               qsTr("Download")
                    Layout.fillWidth:   true
                    enabled:            !_planMasterController.offline && !_planMasterController.syncInProgress
                    visible:            !QGroundControl.corePlugin.options.disableVehicleConnection
                    onClicked: {
                        dropPanel.hide()
                        if (_planMasterController.dirty) {
                            mainWindow.showComponentDialog(syncLoadFromVehicleOverwrite, columnHolder._overwriteText, mainWindow.showDialogDefaultWidth, StandardButton.Yes | StandardButton.Cancel)
                        } else {
                            _planMasterController.loadFromVehicle()
                        }
                    }
                }

                QGCButton {
                    text:               qsTr("Clear")
                    Layout.fillWidth:   true
                    Layout.columnSpan:  2
                    enabled:            !_planMasterController.offline && !_planMasterController.syncInProgress
                    visible:            !QGroundControl.corePlugin.options.disableVehicleConnection

                    onClicked: {
                        dropPanel.hide()
                        mainWindow.showComponentDialog(clearVehicleMissionDialog, text, mainWindow.showDialogDefaultWidth, StandardButton.Yes | StandardButton.Cancel)
                    }
                }
            }
        }
    }

     //update20221116 add the UI for TestFact data display of myVoltage

    //update20221115 add the UI for TestFact data display of myVoltage

    GpsTest {
        anchors.right:        parent.right
        //anchors.top:                parent.BottomLeft
        anchors.rightMargin:          180
        //anchors.horizontalCenter:   parent.horizontalCenter
    }
    // update20221117 Leo add GPS real time get signal test window
    Rectangle {
            id:                         sendRect
            anchors.top:                parent.top
            anchors.topMargin:          20
            anchors.horizontalCenter:   parent.horizontalCenter
            height:                     col.height * 1.5
            width:                      col.width * 1.5
            radius:                     2
            color:                      "orange"
            visible:                    false


            Column {
                id:                     col
                spacing:               6
                anchors.centerIn:       parent
                QGCLabel {
                    anchors.horizontalCenter:   parent.horizontalCenter
                    text:                       "RealTime GPS 测试！"
                    font.pointSize:             12
                    font.bold:                  true
                    color:                      "White"

                }
                Row {
                QGCLabel {

                                   text:                       qsTr("LAT：")
                                   font.pointSize:             15
                                   font.bold:                  true
                                   color:                      "#B7FF4A"
                               }
                }
                Row {
                QGCLabel {

                                  text:                       qsTr("LON：")

                                   font.pointSize:             15
                                   font.bold:                  true
                                   color:                      "#B7FF4A"
                               }
                }
                QGCButton {
                               id:                             mavTestButton
                               backRadius:                     height/2
                               text:                           qsTr("设定为航点")
                                flat: true
                               onClicked: {
                                   toolStrip.allAddClickBoolsOff()
                                   insertTakeItemAfterCurrent()
                                   console.log('clicked C++ signal=')
                               }
                           }

                  }
             }








}  //end of item.
