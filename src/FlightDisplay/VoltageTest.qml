import QtQuick 2.12
import QGroundControl.Vehicle       1.0
import QGroundControl               1.0
import QGroundControl.ScreenTools 	1.0
import QGroundControl.Controls 		1.0
import QGroundControl.FactSystem    1.0
import QGroundControl.FactControls  1.0
//Item {
    Rectangle {
        id:     valuesRoot
        width:   rowRoot.width + 10
        height:  rowRoot.height + 10
        color:   "black"

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
                   anchors.centerIn:               parent
                   spacing:                        5

                  property Fact fact:             _activeVehicle.getFact("myVoltage");


                   Column {
                       spacing:                        0
                       anchors.verticalCenter:         parent.verticalCenter
                       Row{
                           spacing:  2
                           QGCLabel {
                               id:                         sgLabel1
                               color:                      getModelColor(rowRoot.fact.enumOrValueString)
                               horizontalAlignment:        Text.AlignHCenter
                               text:                       qsTr("GPS经度:")
                               font.pointSize:             _pointSize
                               font.bold:                  true
                           }
                           QGCLabel {
                               horizontalAlignment:        Text.AlignHCenter
                               color:                      sgLabel1.color
                               // use original setting to get GPS
                               text:                       rowRoot.fact.valueEqualsDefault ?  " " : rowRoot.fact.value.toFixed(2)  + rowRoot.fact.units

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
                                   text:                       qsTr("GPS纬度:")
                                   font.pointSize:             _pointSize
                                   font.bold:                  true
                               }

                               QGCLabel {
                                   horizontalAlignment:        Text.AlignHCenter
                                   color:                      sgLabel2.color
                                   // pre set for Lat/Log display
                                   text:                       rowRoot.fact.valueEqualsDefault ?  " " : rowRoot.fact.value.toFixed(2)  + rowRoot.fact.units

                                   font.pointSize:             _pointSize
                                   font.bold:                  true
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
                           //var val2 = isNaN(_activeVehicle.testInfo.test2.rawValue) ? 0.0 :  _activeVehicle.testInfo.test2.rawValue
                           val = (val<0) ? 0 : val                                                         //初步判断是否为0
                           //val= (val - voltageMin) / (voltageMax - voltageMin) * 100

                           loaderDash.item._value = val   //(val<0) ? 0 : val
                           loaderDash.item._color = sgLabel1.color
                           console.log("val=",val);
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
