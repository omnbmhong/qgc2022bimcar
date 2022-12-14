import QtQuick 2.12
import QGroundControl.Vehicle       1.0
import QGroundControl               1.0
import QGroundControl.ScreenTools 	1.0
import QGroundControl.Controls 		1.0
import QGroundControl.FactSystem    1.0
import QGroundControl.FactControls  1.0
import QtQuick.Controls 2.1
import QtQuick.Dialogs  1.2
import QtQuick.Layouts 1.3
import QtQuick.Window 2.12
import QtLocation       5.3
import QtPositioning    5.3



    Rectangle {
//        id:     gpsTrackor
//        width:   rowRoot.width + 10
//        height:  rowRoot.height + 10
//        color:   "orange"
//        opacity:  0.8
//        anchors.right:        parent.right
//        radius: 15
        id:     gpsTrackor
              width:   rowRoot.width *1.3
              height:  rowRoot.height *1.3
              color:   "orange"
              opacity:  0.8
              //anchors.top:        parent.top
              anchors.right:      parent.right
              anchors.rightMargin: 50
              //anchors.topMargin:    10
              //anchors.horizontalCenter:   parent.horizontalCenter
              radius: 15

        ///----内部使用：
        //定义变量    Updated 20221209 LEO
        property bool myPreviewClicked: false
        property bool previewControlColapsed: false
        property var    _circle
        property bool   _circleShowing:   false
        property var myPosition: ({}) // use this share location for Visual Effect of Arc planning Preview
        property var pathHistory_lon:[]
        property var pathHistory_lat:[]
        property var pathHistory_alt:[]// use to save the coodinate history for last path.
        property int i_show:0
        property int i_remove:0
        property var deleteTarget:({})
        property var  _activeVehicle:   QGroundControl.multiVehicleManager.activeVehicle ? QGroundControl.multiVehicleManager.activeVehicle : QGroundControl.multiVehicleManager.offlineEditingVehicle

        ///---另外个版本获取电压
        //property var voltageVal:                 _activeVehicle ? _activeVehicle.voltage0 :  0

        //property real voltageMax:   4.2 * 6     //6s
        //property real voltageMin:   0.01 * 6     //6s

        property string buttonText2: '打开弧线设置'

        ///--只读常量
        readonly property color      _themeColor:                "#00EC00"
        //readonly property real       _mar:                       5
        //readonly property real       defaultWidgetsWidth:        (ScreenTools.isMobile ? 50*2 : 50)
        //readonly property real       defaultWidgetsHeight:       (ScreenTools.isMobile ? 35*2 : 35)
        readonly property real       _pointSize:                 16

        ///--获取模型的颜色
           function getModelColor(fact) {
               //voltage 22.2~25.2
               //if(fact > voltageMin +  (voltageMax-voltageMin) * 0.3)          return _themeColor
               //if(fact > voltageMin +  (voltageMax-voltageMin) * 0.1)          return "yellow"
               //if(fact >= voltageMin + (voltageMax-voltageMin) * 0.0)          return "red"
               //return _themeColor
           }

        Row {
                   id:                             rowRoot
                  anchors.centerIn:               parent
                   //anchors.right:        parent.right
                   spacing:                        5


                  property Fact fact:             _activeVehicle.getFact("myVoltage");
                   property Fact factLon:             _activeVehicle.getFact("myLongitude");
                  //property Fact fact:               _activeVehicle.vibration.myTest5.rawValueString;

                   Column {

                       spacing:                        6
                       anchors.verticalCenter:         parent.verticalCenter
                       Row{
                           spacing:  2
                           QGCLabel {
                               id:                         sgLabel1
                               //color:                      getModelColor(rowRoot.fact.enumOrValueString)
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
                                   //color:                      getModelColor(rowRoot.fact.enumOrValueString)
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
                                                  if(QGroundControl.multiVehicleManager.activeVehicle){
                                                      var myLat = isNaN(rowRoot.fact.enumOrValueString) ? 0.0 : rowRoot.fact.enumOrValueString          //初步判断是否有效
                                                      var myLon= isNaN(rowRoot.factLon.enumOrValueString) ? 0.0 : rowRoot.factLon.enumOrValueString
                                                      var coordinate = editorMap.center
                                                      var nextIndex = _missionController.currentPlanViewVIIndex + 1;

                                                       //Updated 20221116 by leo, testing with  GPS data.
                                                      coordinate.latitude = myLat  //.toFixed(7)
                                                      coordinate.longitude = myLon

                                                      _missionController.insertSimpleMissionItem(coordinate, nextIndex, true /* makeCurrentItem */);
                                                      console.log('clicked when Vehicle waypoint Active OK');
                                                  }
                                                  else{  console.log('No Operation can be done, since Vehicle is Disconnected! Warning');
                                                       mainWindow.showMessageDialog(qsTr("警告"), qsTr("必须连接活动小车后才可实时取点规划"))
                                                  }
                                              }
                                          }
                 }

           Column{
                         id: curvePlanner


                      QGCButton {


                                              id:                             mavTestButton2
                                              backRadius:                     height/2
                                              text:                           qsTr(buttonText2)
                                              onClicked: {
                                                  previewControlColapsed = !previewControlColapsed;
                                                  if(previewControlColapsed) buttonText2='清除弧线设置';  //Drop out the panel manual
                                                  if(!previewControlColapsed)
                                                  {buttonText2='打开弧线设置';  //Close up the panel manual
                                                  hideCircle();
                                                  myPreviewClicked=false}
                                                 // }
                                              }
                                          }



                       Row{visible: previewControlColapsed
                               QGCLabel {
                                   id:                         tipsLabel1
                                   //anchors.verticalCenter:     protectTextField3.verticalCenter
                                   text:                       qsTr("离散角度间隔：（单位:度）")
                                   font.pointSize:             15
                                   font.bold:                  true
                                   color:                      "#B7FF4A"
                               }
                               //保护距离的输入
                               QGCTextField {
                                   id:                         protectTextField1
                                   width:                      40
                                   height:                     tipsLabel1.implicitHeight * 1.5
                                   text:                       "10"
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

                       }

                       Row{visible: previewControlColapsed
                               QGCLabel {
                                   id:                         tipsLabel2
                                   //anchors.verticalCenter:     protectTextField3.verticalCenter
                                   text:                       qsTr("离散长度间隔：（单位CM）")
                                   font.pointSize:             15
                                   font.bold:                  true
                                   color:                      "#B7FF4A"
                               }
                               //保护距离的输入
                               QGCTextField {
                                   id:                         protectTextField2
                                   width:                      40
                                   height:                     tipsLabel2.implicitHeight * 1.5
                                   text:                       "100"
                                   inputMethodHints:           Qt.ImhFormattedNumbersOnly
                                   focus:                      true
                                   onEditingFinished: {
                                       if(text > 1000) {
                                           text = 1000
                                           mainWindow.showMessageDialog(qsTr("警告"), qsTr("输入必须小于等于1000CM"))
                                       }
                                       else if(text < 0) {
                                           text = 0
                                           mainWindow.showMessageDialog(qsTr("警告"), qsTr("输入必须大于等于0"))
                                       }
                                   }
                               }

                           }


                       Row{visible: previewControlColapsed

                                      RadioButton {
                                          checked: true
                                          id: upperArc
                                          text: qsTr("上弧")
                                      }
                                      RadioButton {
                                          id: lowerArc
                                          text: qsTr("下弧")
                                      }




                       }
                       Row{visible: previewControlColapsed
                           QGCLabel {
                               id:                         tipsLabel3
                               //anchors.verticalCenter:     protectTextField3.verticalCenter
                               text:                       qsTr(" 总跨越弧度：（单位:度）")
                               font.pointSize:             15
                               font.bold:                  true
                               color:                      "#B7FF4A"
                           }
                           //保护距离的输入
                           QGCTextField {
                               id:                         protectTextField3
                               width:                      40
                               height:                     tipsLabel3.implicitHeight * 1.5
                               text:                       "60"
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


                       }

                     Row{
                         QGCButton {
    id:                             mavTestButton3
                                            backRadius:                     height/2
                                            text:                           qsTr("预览曲线轨迹")
                                            onClicked: {
                                                if(_missionController.splitSegment == null) mainWindow.showMessageDialog(qsTr("警告 尚未选取目标线段"));
                                                  if(_missionController.splitSegment != null) {
                                                             myAngularStep=parseFloat(protectTextField1.text);
                                                             myAngularSpan=parseFloat(protectTextField3.text);
                                                             myDistanceStep=parseInt(protectTextField2.text);
                                                            if(upperArc.checked){
                                                             myReverseCurve=0;}
                                                            if(lowerArc.checked){
                                                             myReverseCurve=1;}
                                                             mainWindow.showMessageDialog(qsTr("Confirm Step="), qsTr('Step Updated to:'+protectTextField1.text+'Angular='+protectTextField3.text))
                                                            hideCircle()
                                                            generatePreview()
                                                           //_planMasterController.removeAll();
                                                            myPreviewClicked=true;
                                                            mapFitFunctions.fitMapViewportToMissionItems();
                                                  }
                                                // Updated 20221216. remove preview points. and refresh new effect for new updated parameter.
                                            }

                                        }
                         QGCButton {


                                            id:                             mavTestButton4
                                            backRadius:                     height/2
                                            text:                           qsTr("确认生成该曲线航点")
                                            visible:    myPreviewClicked? true:false
                                            onClicked: {
                                                //hideCircle()
                                                mainWindow.showComponentDialog(insertCurvePromptDialog, qsTr("Insert Curve Plan"), mainWindow.showDialogDefaultWidth, StandardButton.Yes | StandardButton.No)
                                                // Updated 20221216. remove preview points. and refresh new effect for new updated parameter.
                                            }
                                        }
                         }
                   }


                   }

//                   Loader {
//                       id:                         loaderDash
//                       anchors.verticalCenter:     parent.verticalCenter
//                       sourceComponent:            canvasDash
//                   }
//                   Component.onCompleted: {
//                       loaderDash.item._text = "v"
//                   }
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

                           //loaderDash.item._value = val   //(val<0) ? 0 : val
                           //loaderDash.item._color = sgLabel1.color
                           //console.log("RealTime GPSLat=",val,"GPSLon=",val2);
                       }
                   }
               }



        //显示半径圈
         function showCircle() {
                 _circle = circleComponent.createObject(editorMap)
                 _circle.center=myPosition

                 deleteTarget[i_show]=_circle
                 editorMap.addMapItem(_circle)
                _circleShowing = true
                pathHistory_lat[i_show]=myPosition.latitude
                pathHistory_lon[i_show]=myPosition.longitude
                pathHistory_alt[i_show]=myPosition.latitude
                //console.log('Creating new EffectPreview Point:',i_show,'addMapItem=',_circle,'myCurveParam=',myCurveParam)
                //console.log('new testMyPosition=',myPosition )
                i_show++
                i_remove=i_show

         }
         function hideCircle() {
                 for(let i=i_remove-1; i>=0;i--) {

                  //deleteTarget.latitude=pathHistory_lat[i]
                  //deleteTarget.longitude=pathHistory_lon[i]
                  //deleteTarget.altitude=pathHistory_alt[i]
                  editorMap.removeMapItem(deleteTarget[i])
                  //console.log("Deleting Point=",i,deleteTarget[i])
                 //deleteTarget[i].destroy()

                 }

             _circleShowing = false
         }

         function generatePreview(){
             if(_missionController.splitSegment!==null)  // Logic Protection for Not Selecting split points situation
             {
             const start_Lat = parseFloat(_missionController.splitSegment.coordinate1.latitude);
             const start_Lon = parseFloat(_missionController.splitSegment.coordinate1.longitude);
             const end_Lat = parseFloat(_missionController.splitSegment.coordinate2.latitude);
             const end_Lon = parseFloat(_missionController.splitSegment.coordinate2.longitude);

           var coordinate = editorMap.center
           const ratio_B= (1.0/111122.19769899000); // 1meter=? degree in B ,纬度 Latitude
           const ratio_L= (1.0/96234.340763000);   //1meter=? degree in L,经度 Longitude


           var distance =Math.sqrt(Math.pow(((end_Lat-start_Lat)/ratio_B),2)+Math.pow(((end_Lon-start_Lon)/ratio_L),2));
           var realR= distance*0.5/Math.sin((myAngularSpan*0.5)*Math.PI/180.0);//Unit as in Meter.
           var delta_y= Math.abs((end_Lat-start_Lat))/ratio_B;  // Unit as in Meter(M)
           var delta_x= Math.abs((end_Lon-start_Lon))/ratio_L;  // Unit as in Meter(M)
           var Angle1=myAngularSpan;  //arc span in unit  MUST <180 degree
           var Angle2=180.0*Math.atan(delta_y/delta_x)/Math.PI;  //as definition as Positive always
           var Angle3=(180.0-Angle1)*0.5;  // another two equal angle of the key triangle.
           var keyAngle= Angle3- Angle2;
           var start_theta= 0.0;var end_theta=0.0;
           var center_B= 0.0; var RevCenter_B=0.0;// Symmetry center1 B
           var center_L= 0.0; var RevCenter_L=0.0; //Symmetry  Center1 L
           var shift_x=0.0;   var RevShift_x=0.0;
           var shift_y=0.0;   var RevShift_y=0.0;


           if((end_Lon-start_Lon)>0) {          //directing -->> Right
                  if((end_Lat-start_Lat)<0)
                       {start_theta= keyAngle+Angle1; //directing --> Down.
                          end_theta=keyAngle;
                      // to locate the Circle Center BL.
                        shift_y= realR*Math.sin((keyAngle)*Math.PI/180);
                        shift_x= realR*Math.cos((keyAngle)*Math.PI/180);
                        RevShift_y=realR*Math.sin((keyAngle)*Math.PI/180);
                        RevShift_x=realR*Math.cos((keyAngle)*Math.PI/180);
                      center_B= start_Lat-shift_y*ratio_B;// center   in B ,纬度 Latitude
                      center_L= start_Lon-shift_x*ratio_L;//  Center  in L,经度 Longitude
                      RevCenter_B= start_Lat+RevShift_y*ratio_B;//
                      RevCenter_L= start_Lon+RevShift_x*ratio_L;//
                  }

                  if((end_Lat-start_Lat)>=0)
                       {start_theta= 180.0-keyAngle;//directing --> Up .
                           end_theta=180.0-keyAngle-Angle1;
                      // to locate the Circle Center BL.
                        shift_y= realR*Math.sin((keyAngle)*Math.PI/180);
                        shift_x= realR*Math.cos((keyAngle)*Math.PI/180);
                        RevShift_y=realR*Math.sin((keyAngle)*Math.PI/180);
                        RevShift_x=realR*Math.cos((keyAngle)*Math.PI/180);
                      center_B= start_Lat-shift_y*ratio_B;// center   in B ,纬度 Latitude
                      center_L= start_Lon-shift_x*ratio_L;//  Center  in L,经度 Longitude
                      RevCenter_B= end_Lat+RevShift_y*ratio_B;//
                      RevCenter_L= end_Lon-RevShift_x*ratio_L;//
                  }
           };
           if((end_Lon-start_Lon)<=0) {  //directing -->> Left
                if((end_Lat-start_Lat)<0)//directing --> Down.
                {start_theta= 180.0-keyAngle-Angle1;
                 end_theta=start_theta+Angle1;
                    shift_y= realR*Math.sin((start_theta)*Math.PI/180);  // 180> always be positive >0
                    shift_x= realR*Math.cos((start_theta)*Math.PI/180);// 180> negative>90;  90> positive>0
                    RevShift_y=realR*Math.sin(keyAngle*Math.PI/180);
                    RevShift_x=realR*Math.cos(keyAngle*Math.PI/180);
                    center_B= start_Lat-shift_y*ratio_B;//inputed data// center B
                    center_L= start_Lon-shift_x*ratio_L;//inputed data  Center L
                    RevCenter_B= start_Lat+RevShift_y*ratio_B;//
                    RevCenter_L= start_Lon-RevShift_x*ratio_L;//
                }
                if((end_Lat-start_Lat)>0)
                {start_theta= keyAngle;//directing --> Up .
                   end_theta=start_theta+Angle1;
                    shift_y= realR*Math.sin((start_theta)*Math.PI/180);  // 180> always be positive >0
                    shift_x= realR*Math.cos((start_theta)*Math.PI/180);// 180> negative>90;  90> positive>0
                    RevShift_y=realR*Math.sin(keyAngle*Math.PI/180);
                    RevShift_x=realR*Math.cos(keyAngle*Math.PI/180);
                    center_B= start_Lat-shift_y*ratio_B;//inputed data// center B
                    center_L= start_Lon-shift_x*ratio_L;//inputed data  Center L
                    RevCenter_B=end_Lat+RevShift_y*ratio_B;//
                    RevCenter_L=end_Lon+RevShift_x*ratio_L;//
                }

           };
                           var   center_H= 99.0;//圆心的 经纬度BLH坐标
                           var cor_x=new Array(50).fill(0.0); var cor_B=new Array(50).fill(0.0);var rev_B=new Array(50).fill(0.0);
                           var cor_y=new Array(50).fill(0.0); var cor_L=new Array(50).fill(0.0);var rev_L=new Array(50).fill(0.0);
                           var N1=Math.ceil(Math.abs((end_theta - start_theta))/myAngularStep);//set to be 5 degree as default in angle.
                           var N2=Math.ceil(Math.abs((end_theta - start_theta))*Math.PI*200*realR/(360*myDistanceStep));//set to be 20cm
                           if(N1>myAngularMaximum)  N1=myAngularMaximum;
                           if(N2>myDistanceMaximum)  N2=myDistanceMaximum;
                           var N=Math.max(N1,N2);
                           console.log('N1,2=',N1,N2,'distance=',distance,'realR=',realR,'DistanceStep=',myDistanceStep);
                           var points=N;
                           const d_theta=Math.abs((end_theta- start_theta))/N;

           // test pinpoint the Center and Symmetry Center of cirle
            var nextIndex= _missionController.currentPlanViewVIIndex;
             coordinate.altitude = 6.180;
                          var anchorIndex = _missionController.currentPlanViewVIIndex-1;
                           for(let i=points-1; i>0;i--) {
                                 nextIndex= _missionController.currentPlanViewVIIndex;
                                 if((end_Lon-start_Lon)>0) {// directing Right>>>
                                   cor_L[i]=start_Lon+ratio_L*realR*(Math.cos((start_theta-i*d_theta)*Math.PI/180)-Math.cos(start_theta*Math.PI/180));
                                   cor_B[i]=start_Lat+ratio_B*realR*(Math.sin((start_theta-i*d_theta)*Math.PI/180)-Math.sin(start_theta*Math.PI/180));
                                    if((end_Lat-start_Lat)>0) {  //directing Up>>
                                         rev_B[i]=RevCenter_B-ratio_B*realR*(Math.sin((keyAngle-i*d_theta+Angle1)*Math.PI/180))  ;
                                         rev_L[i]=RevCenter_L+ratio_L*realR*(Math.cos((keyAngle-i*d_theta+Angle1)*Math.PI/180)) ;
                                               }
                                    if((end_Lat-start_Lat)<=0) {  //directing down>>
                                         rev_B[i]=RevCenter_B-ratio_B*realR*(Math.sin((keyAngle+i*d_theta)*Math.PI/180))  ;
                                         rev_L[i]=RevCenter_L-ratio_L*realR*(Math.cos((keyAngle+i*d_theta)*Math.PI/180)) ;
                                               }
                                    }
                                 if((end_Lon-start_Lon)<=0) {// directing Left >>>
                                   cor_L[i]=start_Lon+ratio_L*realR*(Math.cos((start_theta+i*d_theta)*Math.PI/180)-Math.cos(start_theta*Math.PI/180));
                                   cor_B[i]=start_Lat-ratio_B*realR*(Math.sin(start_theta*Math.PI/180)-Math.sin((start_theta+i*d_theta)*Math.PI/180));
                                     if((end_Lat-start_Lat)>0) {  //directing Up>>
                                          rev_B[i]=RevCenter_B-ratio_B*realR*(Math.sin((keyAngle-i*d_theta+Angle1)*Math.PI/180))  ;
                                          rev_L[i]=RevCenter_L-ratio_L*realR*(Math.cos((keyAngle-i*d_theta+Angle1)*Math.PI/180)) ;
                                                }
                                     if((end_Lat-start_Lat)<=0) {  //directing down>>
                                          rev_B[i]=RevCenter_B-ratio_B*realR*(Math.sin((keyAngle+i*d_theta)*Math.PI/180))  ;
                                          rev_L[i]=RevCenter_L+ratio_L*realR*(Math.cos((keyAngle+i*d_theta)*Math.PI/180)) ;
                                                }
                                 }
                                          coordinate.latitude = cor_B[i];
                                          coordinate.longitude =cor_L[i];
                                           if(myReverseCurve==1) {
                                               coordinate.latitude = rev_B[i];
                                               coordinate.longitude =rev_L[i];
                                               //console.log(cor_L[i],'comparing',rev_L[i])
                                               }
                                               //console.log('write Lat/Lon:',cor_B[i],cor_L[i],'Write Rev_lat/Lon:',rev_B[i],rev_L[i]);

                                    coordinate.altitude = 6.180;

                                     myPosition=coordinate;
                                     showCircle();

                                 }


                            i_show=0;

                               }

                          else{
                           console.log('Warnning!----Not Select the target wayPoints to insert curve into yet')}

                          }

  Component {
             id: circleComponent
                             MapCircle {
                                 opacity: 1.0
                                 color:          Qt.rgba(0,0,0,0)
                                 border.color:   "yellow"
                                 border.width:   2
                                 center:         myPosition
                                 //center:       QtPositioning.coordinate()
                                 radius:         3
                                 visible:        true
                             }
                         }


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

//         Rectangle {
//                           id:     curvePlanner
//                           width:   rowRoot.width + 10
//                           height:  rowRoot.height + 10
//                           color:   "green"
//                           opacity:  0.8

//                     }

