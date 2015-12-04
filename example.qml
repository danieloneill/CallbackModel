import QtQuick 2.4
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.1
import QtQuick.Window 2.0
import QtQuick.Extras 1.4
import QtWebSockets 1.0

import com.foxmoxie.CallbackModel 1.0

ApplicationWindow {
    width: 600
    height: 400
    visible: true
    title: 'RepairShop'


    WebSocket {
        id: socket

        // Node.js service (using 'ws' websocket module):
        url: 'ws://192.168.7.14:8085/'
	active: true

        // Requests provide a callback to be called upon success/failure:
        property variant callbacks: ({})

        function send(req, cb)
        {
            // Generate a unique serial id to identify the request roundtrip.
            // (Usually I use UUIDs, but the example would then require my 'hash' module)
            var serial = ''+(new Date()).getTime();
            req['serial'] = serial;

            // Store this request and callback in the callbacks hash, keyed on the serial id.
            callbacks[serial] = { 'req':req, 'callback':cb };

            // Make it JSON, send it.
            var json = JSON.stringify(req, null, 2);
            socket.sendTextMessage(json);

            // Generally useless:
            return serial;
        }

        onTextMessageReceived: {
            var obj = JSON.parse(message)
            if( obj['serial'] )
            {
                // Find the serial id, pull it from the 'callbacks' hash, and run it.
                var serial = obj['serial'];
                var cb = callbacks[serial];
                cb.callback( cb['req'], obj );

                // Remove it from the hash, don't need!
                delete callbacks[serial];
            }
            else
                console.log("Unsolicited message from server: "+message);
        }
    }


    function update()
    {
        var criteria = customerFilterEdit.text;
        var req = {
            'type': 'customer',
            'action': 'count',
            'criteria': {
                '$or': [
                    { 'uuid': { '$regex': criteria } },
                    { 'name': { '$regex': criteria } },
                    { 'email': { '$regex': criteria } },
                    { 'phone': { '$regex': criteria } },
                    { 'address': { '$regex': criteria } },
                ]
            }
        };

        // Tell the model it has zero rows. This invalidates all old data which
        // we have to do when we change the criteria:
        customerModel.rows = 0;

        // Result packet should only provide a result count in 'results':
        socket.send(req, function(req, res) {
            console.log("Response: "+JSON.stringify(res, null, 2));

            // Tell the model it "has" this many results:
            customerModel.rows = res['results'];
        });
    }

    // When the model emits a 'recordsRequested' signal, it provides 'first'
    // and 'last' variables representing the index positions of the records
    // it desires. If you have a single record, these will be 0 and 0. If
    // you have 2 records it will be 0 and 1. If you have a lot of records
    // it could be whatever.

    // There's no obligation to satisfy the request entirely (or at all),
    // but the records at those indexes will be empty until you do. It's
    // also possible to populate records without 'recordsRequested' asking
    // for them and they'll be added to the cache (to avoid asking later),
    // but they may also be removed from the cache if not needed.

    // A request will be made usually only when the View attempts to
    // display a Delegate at that index position. The views are diligent
    // in requesting data, but our data source (a websocket) isn't very fast
    // so we delay request updates by 20ms. Doing this allows the model to
    // receive a range of records needed, allowing us to request several
    // records in a single batch. See 'requestDelay'.

    function fetchRecords(first, last)
    {
        var criteria = customerFilterEdit.text;
        var req = {
            'type': 'customer',
            'action': 'list',
            'criteria': {
                $or: [
                    { 'uuid': { '$regex': criteria } },
                    { 'name': { '$regex': criteria } },
                    { 'email': { '$regex': criteria } },
                    { 'phone': { '$regex': criteria } },
                    { 'address': { '$regex': criteria } },
                ]
            },
            'skip': first,
            'limit': last - first + 1
        };

        // Fetch the relevant records:
        socket.send(req, function(req, res) {
            var entries = res['results'];

            // Set the records in the model. 'first' is the index to start from, 'entries' is an array of records:
            if( entries && entries.length > 0 )
                customerModel.setRecords( first, entries );
        });
    }

    TextField {
        id: customerFilterEdit
        placeholderText: 'Filter...'
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            margins: 5
        }
        onTextChanged: {
            editTimer.start();
        }
        Timer {
            id: editTimer
            interval: 200
            onTriggered: {
                update();
            }
        }
    }

    TableView {
        id: customerList
        anchors {
            top: customerFilterEdit.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            margins: 5
        }
        model: customerModel

        TableViewColumn {
            role: "name"
            title: "Name"
            width: 100
        }
        TableViewColumn {
            role: "phone"
            title: "Phone"
            width: 80
        }
        TableViewColumn {
            role: "address"
            title: "Address"
            width: 250
        }
        TableViewColumn {
            role: "email"
            title: "E-Mail"
            width: 150
        }

        CallbackModel {
            id: customerModel
            requestDelay: 20 // in milliseconds

            onRecordsRequested: { // first, last
                fetchRecords(first, last);
            }
        }
    }
}


