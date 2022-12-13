/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#pragma once

#include "FactGroup.h"
#include "QGCMAVLink.h"

class TestInfoFactGroup : public FactGroup
{
    Q_OBJECT

public:
    TestInfoFactGroup(QObject* parent = nullptr);

    Q_PROPERTY(Fact* test1       READ test1       CONSTANT)
    Q_PROPERTY(Fact* test2       READ test2       CONSTANT)
    Q_PROPERTY(Fact* test3       READ test3       CONSTANT)
    Q_PROPERTY(Fact* test4       READ test4       CONSTANT)
    Q_PROPERTY(Fact* myTest5          READ myTest5               CONSTANT)



    Fact* test1 () { return &_test1Fact; }
    Fact* test2 () { return &_test2Fact; }
    Fact* test3 () { return &_test3Fact; }
    Fact* test4 () { return &_test4Fact; }
    Fact* myTest5    () { return &_myTest5Fact; }

    // Overrides from FactGroup
    void handleMessage(Vehicle* vehicle, mavlink_message_t& message) override;
    static const char* _test1FactName;
    static const char* _test2FactName;
    static const char* _test3FactName;
    static const char* _test4FactName;
    static const char* _myTest5FactName;


//signals:
//    void gpsChanged(Fact* gpsString);


private:
    Fact            _test1Fact;
    Fact            _test2Fact;
    Fact            _test3Fact;
    Fact            _test4Fact;
    Fact           _myTest5Fact;


};
