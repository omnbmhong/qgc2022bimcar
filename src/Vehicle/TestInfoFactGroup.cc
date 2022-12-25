/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/
#include "TestInfoFactGroup.h"
#include "Vehicle.h"
#include <QQmlApplicationEngine>
#include <QQmlContext>



const char* TestInfoFactGroup::_test1FactName =      "test1";
const char* TestInfoFactGroup::_test2FactName =      "test2";
const char* TestInfoFactGroup::_test3FactName =      "test3";
const char* TestInfoFactGroup::_test4FactName =      "test4";
const char* TestInfoFactGroup::_myTest5FactName =       "myTest5";

TestInfoFactGroup::TestInfoFactGroup(QObject* parent)
    : FactGroup(1000, ":/json/Vehicle/TestInfoFact.json", parent)
    , _test1Fact        (0, _test1FactName,         FactMetaData::valueTypeDouble)
    , _test2Fact        (0, _test2FactName,      FactMetaData::valueTypeDouble)
    , _test3Fact        (0, _test3FactName,         FactMetaData::valueTypeDouble)
    , _test4Fact        (0, _test4FactName,    FactMetaData::valueTypeDouble)
    , _myTest5Fact    (0, _myTest5FactName,         FactMetaData::valueTypeDouble)
{

    _addFact(&_test1Fact,       _test1FactName);
    _addFact(&_test2Fact,       _test2FactName);
    _addFact(&_test3Fact,       _test3FactName);
    _addFact(&_test4Fact,       _test4FactName);
    _addFact(&_myTest5Fact,    _myTest5FactName);
    // Start out as not available "--.--"
       _test1Fact.setRawValue(qQNaN());
       _test2Fact.setRawValue(qQNaN());
       _test3Fact.setRawValue(qQNaN());
       _test4Fact.setRawValue(qQNaN());
       _myTest5Fact.setRawValue(qQNaN());



}

void TestInfoFactGroup::handleMessage(Vehicle* /* vehicle */, mavlink_message_t& message)
{
    if (message.msgid != MAVLINK_MSG_ID_VIBRATION) {
        return;
    }

    mavlink_vibration_t vibration;
    mavlink_msg_vibration_decode(&message, &vibration);

    test1()->setRawValue(vibration.vibration_x);
    test2()->setRawValue(vibration.vibration_y);
    _setTelemetryAvailable(true);
    test4()->setRawValue(vibration.vibration_x);
    myTest5()->setRawValue(vibration.vibration_x);

    //update20221107

    //double myVibration = static_cast<double>(vibration.vibration_x);
    //_myTest5Fact.setRawValue(myVibration);
    //update20221105  函数中获取电压  vihecle.cc Reference Template:
    //double voltage = static_cast<double>(sysStatus.voltage_battery)/1000;
    //_myVoltageFact.setRawValue(voltage);

}

