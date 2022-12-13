import QtQuick 2.12
import QGroundControl.Vehicle       1.0
import QGroundControl               1.0
import QGroundControl.ScreenTools 	1.0
import QGroundControl.Controls 		1.0
import QGroundControl.FactSystem    1.0
import QGroundControl.FactControls  1.0
import QtQuick.Controls 2.1
import QtQuick.Layouts 1.3
import QtQuick.Window 2.12


//Item {
    Rectangle {
        id:     valuesRoot
        width:   rowRoot.width + 10
        height:  rowRoot.height + 10
        color:   "orange"
        opacity:  0.8

        ///----内部使用：
        property var  _activeVehicle:   QGroundControl.multiVehicleManager.activeVehicle ? QGroundControl.multiVehicleManager.activeVehicle : QGroundControl.multiVehicleManager.offlineEditingVehicle

        ///---另外个版本获取电压
        property var voltageVal:                 _activeVehicle ? _activeVehicle.voltage0 :  0

        property real voltageMax:   4.2 * 6     //6s
        property real voltageMin:   0.01 * 6     //6s

        ///--只读常量
        readonly property color      _themeColor:                "#00EC00"
        readonly property real       _mar:                       5
        readonly property real       defaultWidgetsWidth:        (ScreenTools.isMobile ? 50*2 : 50)
        readonly property real       defaultWidgetsHeight:       (ScreenTools.isMobile ? 35*2 : 35)
        readonly property real       _pointSize:                 12
        ///--获取模型的颜色
           function getModelColor(fact) {
               //voltage 22.2~25.2
               if(fact > voltageMin +  (voltageMax-voltageMin) * 0.3)          return _themeColor
               if(fact > voltageMin +  (voltageMax-voltageMin) * 0.1)          return "yellow"
               if(fact >= voltageMin + (voltageMax-voltageMin) * 0.0)          return "red"
               return _themeColor
           }

         Row {
                   id:                             rowRoot
                  // anchors.centerIn:               parent
                   anchors.right:        parent.right
                   spacing:                        5

                  property Fact fact:             _activeVehicle.getFact("myVoltage");
                   property Fact factLon:             _activeVehicle.getFact("myLongitude");
                  //property Fact fact:               _activeVehicle.vibration.myTest5.rawValueString;

                   Column {
                       spacing:                        0
                       anchors.verticalCenter:         parent.verticalCenter
                       Row{
                           spacing:  2
                           QGCLabel {
                               id:                         sgLabel1
                               color:                      getModelColor(rowRoot.fact.enumOrValueString)
                               horizontalAlignment:        Text.AlignHCenter
                               text:                       qsTr("GPS纬度:")
                               font.pointSize:             _pointSize
                               font.bold:                  true
                           }
                           QGCLabel {
                               horizontalAlignment:        Text.AlignHCenter
                               color:                      sgLabel1.color
                              text:                       rowRoot.fact.valueEqualsDefault ?  " " : rowRoot.fact.value.toFixed(7)  + rowRoot.fact.units
                               //text:                       _activeVehicle.testInfo.myTest5.rawValue.toFixed(2)
                               font.pointSize:             _pointSize
                               font.bold:                  true
                           }
                       }
                       Row{
                             spacing:  2
                               QGCLabel {
                                   id:                         sgLabel2
                                   color:                      getModelColor(rowRoot.fact.enumOrValueString)
                                   horizontalAlignment:        Text.AlignHCenter
                                   text:                       qsTr("GPS经度:")
                                   font.pointSize:             _pointSize
                                   font.bold:                  true
                               }

                               QGCLabel {
                                   horizontalAlignment:        Text.AlignHCenter
                                   color:                      sgLabel2.color
                                   text:                       rowRoot.factLon.valueEqualsDefault ?  " " : rowRoot.factLon.value.toFixed(7)  + rowRoot.factLon.units
                                   //text:                       _activeVehicle.testInfo.test2.rawValue.toFixed(2)
                                    //text:                        _activeVehicle.getFact("gpsFactGroup").value.toFixed(2)  + rowRoot.fact.units
                                   font.pointSize:             _pointSize
                                   font.bold:                  true
                               }



                               QGCButton {


                                              id:                             mavTestButton
                                              backRadius:                     height/2
                                              text:                           qsTr("设定为航点")
                                              onClicked: {
                                                  var myLat = isNaN(rowRoot.fact.enumOrValueString) ? 0.0 : rowRoot.fact.enumOrValueString          //初步判断是否有效
                                                  var myLon= isNaN(rowRoot.factLon.enumOrValueString) ? 0.0 : rowRoot.factLon.enumOrValueString
                                                  var coordinate = editorMap.center
                                                   var nextIndex = _missionController.currentPlanViewVIIndex + 1;
                                                  //toolStrip.allAddClickBoolsOff() //these 2 lines are "Takeoff Logic"
                                                  //insertTakeItemAfterCurrent()

                                                   //Updated 20221116 by leo, testing with  GPS data.
                                                  coordinate.latitude = myLat  //.toFixed(7)
                                                  coordinate.longitude = myLon


                                                  //Updated 20221116 by leo, testing with Vibration data, replacing GPS data.
                                                  //coordinate.latitude =30.5637636+(_activeVehicle.testInfo.myTest5.rawValue)*0.0001
                                                  //coordinate.longitude = 114.4140066+(_activeVehicle.testInfo.test2.rawValue)*0.0001
                                                  _missionController.insertSimpleMissionItem(coordinate, nextIndex, true /* makeCurrentItem */);

                                                  // insertSimpleItemAfterCurrent(coordinate)
                                                  // addWaypointRallyPointAction.checked  //Guess ? display T label or W lable. trigger setting

                                                  console.log('clicked C++ signal=')
                                              }
                                          }

                           }

                       Row{
                               QGCLabel {
                                   id:                         tipsLabel1
                                   //anchors.verticalCenter:     protectTextField3.verticalCenter
                                   text:                       qsTr("弧度 离散角度间隔：（单位度）")
                                   font.pointSize:             15
                                   font.bold:                  true
                                   color:                      "#B7FF4A"
                               }
                               //保护距离的输入
                               QGCTextField {
                                   id:                         protectTextField1
                                   width:                      40
                                   height:                     tipsLabel1.implicitHeight * 1.5
                                   text:                       "0"
                                   inputMethodHints:           Qt.ImhFormattedNumbersOnly
                                   focus:                      true
                                   onEditingFinished: {
                                       if(text > 30) {
                                           text = 30
                                           mainWindow.showMessageDialog(qsTr("警告"), qsTr("输入必须小于等于30degree"))
                                       }
                                       else if(text < 0) {
                                           text = 0
                                           mainWindow.showMessageDialog(qsTr("警告"), qsTr("输入必须大于等于0"))
                                       }
                                   }
                               }

                       }

                       Row{
                               QGCLabel {
                                   id:                         tipsLabel2
                                   //anchors.verticalCenter:     protectTextField3.verticalCenter
                                   text:                       qsTr("弧度 离散距离间隔：（单位米）")
                                   font.pointSize:             15
                                   font.bold:                  true
                                   color:                      "#B7FF4A"
                               }
                               //保护距离的输入
                               QGCTextField {
                                   id:                         protectTextField2
                                   width:                      40
                                   height:                     tipsLabel2.implicitHeight * 1.5
                                   text:                       "0"
                                   inputMethodHints:           Qt.ImhFormattedNumbersOnly
                                   focus:                      true
                                   onEditingFinished: {
                                       if(text > 30) {
                                           text = 30
                                           mainWindow.showMessageDialog(qsTr("警告"), qsTr("输入必须小于等于30degree"))
                                       }
                                       else if(text < 0) {
                                           text = 0
                                           mainWindow.showMessageDialog(qsTr("警告"), qsTr("输入必须大于等于0"))
                                       }
                                   }
                               }

                           }
                       Row{
                               QGCLabel {
                                   id:                         tipsLabel4
                                   //anchors.verticalCenter:     protectTextField3.verticalCenter
                                   text:                       qsTr("弧度上下弧度切换 0/1 ")
                                   font.pointSize:             15
                                   font.bold:                  true
                                   color:                      "#B7FF4A"
                               }

                               //保护距离的输入
                               QGCTextField {
                                   id:                         protectTextField4
                                   width:                      40
                                   height:                     tipsLabel4.implicitHeight * 1.5
                                   text:                       "0"
                                   inputMethodHints:           Qt.ImhFormattedNumbersOnly
                                   focus:                      true
                                   onEditingFinished: {
                                       if(text > 1) {
                                           text = 0
                                           mainWindow.showMessageDialog(qsTr("警告"), qsTr("输入必须0 or 1"))
                                       }
                                       else if(text < 0) {
                                           text = 0
                                           mainWindow.showMessageDialog(qsTr("警告"), qsTr("输入必须大于等于0"))
                                       }
                                   }
                               }

                           }
                       Row{

                                      RadioButton {
                                          checked: true
                                          text: qsTr("上弧")
                                      }
                                      RadioButton {
                                          text: qsTr("下弧")
                                      }




                       }
                       Row{
                           QGCLabel {
                               id:                         tipsLabel3
                               //anchors.verticalCenter:     protectTextField3.verticalCenter
                               text:                       qsTr(" Path离散弧度：（单位米）")
                               font.pointSize:             15
                               font.bold:                  true
                               color:                      "#B7FF4A"
                           }
                           //保护距离的输入
                           QGCTextField {
                               id:                         protectTextField3
                               width:                      40
                               height:                     tipsLabel3.implicitHeight * 1.5
                               text:                       "0"
                               inputMethodHints:           Qt.ImhFormattedNumbersOnly
                               focus:                      true
                               onEditingFinished: {
                                   if(text > 90) {
                                       text = 90
                                       mainWindow.showMessageDialog(qsTr("警告"), qsTr("输入必须小于等于90degree"))
                                   }
                                   else if(text < 0) {
                                       text = 0
                                       mainWindow.showMessageDialog(qsTr("警告"), qsTr("输入必须大于等于0"))
                                   }
                               }
                           }
                           QGCButton {


                                              id:                             mavTestButton2
                                              backRadius:                     height/2
                                              text:                           qsTr("更新弧线参数Refresh")
                                              onClicked: {
                                                   myDistanceMaximum=9.9;
                                                   myAngularMaximum=6.6;
                                                  myAngularStep=parseFloat(protectTextField1.text);
                                                  myAngularSpan=parseFloat(protectTextField3.text);
                                                  myReverseCurve=parseInt(protectTextField4.text);
                                                  mainWindow.showMessageDialog(qsTr("Confirm Step="), qsTr('Step Updated to:'+protectTextField1.text+'Angular='+protectTextField3.text))
                                                  _planMasterController.removeAll();
                                              }
                                          }


                       }
                   }

                   Loader {
                       id:                         loaderDash
                       anchors.verticalCenter:     parent.verticalCenter
                       sourceComponent:            canvasDash
                   }
                   Component.onCompleted: {
                       loaderDash.item._text = "v"
                   }
                   ///--更新值和颜色

                   Timer{
                       id:             timer
                       interval:       1000
                       running:        true
                       repeat:         true
                       onTriggered: {
                           var val = isNaN(rowRoot.fact.enumOrValueString) ? 0.0 : rowRoot.fact.enumOrValueString          //初步判断是否有效

                           //var val = isNaN(_activeVehicle.testInfo.myTest5.rawValue) ? 0.0 : _activeVehicle.testInfo.myTest5.rawValue
                          var val2 = isNaN(rowRoot.factLon.enumOrValueString) ? 0.0 : rowRoot.factLon.enumOrValueString
                           val = (val<0) ? 0 : val
                           val2 = (val2<0) ? 0 : val2 //初步判断是否为0
                          // val= (val - voltageMin) / (voltageMax - voltageMin) * 100

                           loaderDash.item._value = val   //(val<0) ? 0 : val
                           loaderDash.item._color = sgLabel1.color
                           //console.log("RealTime GPSLat=",val,"GPSLon=",val2);
                       }
                   }
               }



    ///------------------ 动态小仪表 ------------------
        ///电压和油门
  Component {
        id: canvasDash
            Item {
                width:  defaultWidgetsWidth
                height: defaultWidgetsHeight
                anchors.centerIn:   parent

                property real _value                : 0
                property real _angle:               (_value * (180-10) / 100 + (180+10))
                property string _text :             ""
                property color _color:              '#01E9A9'
                property color _backgroundColor:    "white"

                on_ValueChanged: canvas.requestPaint();


                Canvas{ ///画布
                    id: canvas
                    width:  parent.width       //40
                    height: width/2            //20
                    anchors.centerIn:           parent

                    contextType:  "2d";
                    function paintGimbalYaw(ctx,x,y,r,angle1,angle2,color) {
                        ctx.fillStyle = color
                        ctx.save();
                        ctx.beginPath();
                        ctx.moveTo(x,y);
                        ctx.arc(x,y,r,angle1*Math.PI/180,angle2*Math.PI/180);
                        ctx.closePath();
                        ctx.fill()
                        ctx.restore();
                    }

                    onPaint: {
                        var ctx = getContext("2d");  ///画师
                        paintGimbalYaw(ctx,canvas.width/2, canvas.height, canvas.width/2,      180,  360,  _backgroundColor)//'#005840')
                        paintGimbalYaw(ctx,canvas.width/2, canvas.height, canvas.width/2,      180,  _angle, _color)
                        paintGimbalYaw(ctx,canvas.width/2, canvas.height, canvas.width/2*0.85,  0,    360,  "#142c29")

                        paintGimbalYaw(ctx,canvas.width/2, canvas.height, canvas.width/2*0.7, 180,  360,  _backgroundColor) //'#005840')
                        paintGimbalYaw(ctx,canvas.width/2, canvas.height, canvas.width/2*0.7, 180,_angle,  _color)
                        paintGimbalYaw(ctx,canvas.width/2, canvas.height, canvas.width/2*0.6, 0,   360,    "#142c29")
                    }
                    //文字
                    QGCLabel {
                        id:                         txt_progress
                        visible:                    true
                        anchors.bottom:             parent.bottom
                        anchors.bottomMargin:       ScreenTools.isMobile ? -7 : -2
                        anchors.horizontalCenter:   parent.horizontalCenter
                        font.pointSize:             18
                        text:                       _text       //"V"
                        color:                      "pink"    //_color
                        font.bold:                  true
                    }
                }
            }
        }


}
