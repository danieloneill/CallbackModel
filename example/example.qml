import QtQuick
import QtQuick.Controls
import QtQuick.Window
import QtWebSockets

import com.foxmoxie.CallbackModel

ApplicationWindow {
    id: exampleWindow

    width: 800
    height: 600
    visible: true
    title: 'RepairShop'

    WebSocket {
        id: socket

        // Node.js service (using 'ws' websocket module) named server_node.mjs
        // or
        // Serve service (using 'WebSocket' module) named server_serve.js
        url: 'ws://127.0.0.1:8085/'
        active: true

        // Requests provide a callback to be called upon success/failure:
        property variant callbacks: ({})

        function send(req, cb)
        {
            // Generate a unique serial id to identify the request roundtrip.
            // (Usually I use UUIDs, but the example would then require my 'hash' module)
            const serial = ''+(new Date()).getTime();
            req['serial'] = serial;

            // Store this request and callback in the callbacks hash, keyed on the serial id.
            callbacks[serial] = { 'req':req, 'callback':cb };

            // Make it JSON, send it.
            const json = JSON.stringify(req, null, 2);
            socket.sendTextMessage(json);

            // Generally useless:
            return serial;
        }

        onTextMessageReceived: function(message) {
            const obj = JSON.parse(message)
            if( obj['serial'] )
            {
                // Find the serial id, pull it from the 'callbacks' hash, and run it.
                const serial = obj['serial'];
                const cb = callbacks[serial];
                cb.callback( cb['req'], obj );

                // Remove it from the hash, don't need!
                delete callbacks[serial];
            }
            else
                console.log("Unsolicited message from server: "+message);
        }
    }

    // This is called when the criteria (text input) changes:
    function update()
    {
        const criteria = customerFilterEdit.text;

        // This is the packet that will be sent to the server:
        const req = {
            'action': 'count',
            'criteria': criteria
        };

        // Result packet should only provide a result count in 'results':
        socket.send(req, function(req, res) {
            // Invalidate, since our criteria has changed.
            customerModel.invalidate();

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

    function fetchRecords(first, last)
    {
        const criteria = customerFilterEdit.text;
        const req = {
            'type': 'customer',
            'action': 'list',
            'criteria': criteria,
            'skip': first,
            'limit': last - first + 1
        };

        // Fetch the relevant records:
        socket.send(req, function(req, res) {
            const entries = res['results'];

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
            exampleWindow.update();
        }
    }

    TableView {
        id: customerList
        clip: true
        anchors {
            top: customerFilterEdit.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            margins: 5
        }
        model: customerModel
        delegate: Rectangle {
            id: entry
            implicitWidth: customerList.width
            implicitHeight: 32
            Row {
                anchors.fill:parent

                // The model must reference the data!
                // This isn't specific to CallbackModel, but if no fields of data
                // are "displayed", the view won't request any data from the model.
                //
                // QML has a few methods of 'finding' the data, but that's up to you
                // to read up on and play with. :)
                Text { text: modelData.name || '...';	width: parent.width * 0.20 }
                Text { text: modelData.phone || '...';	width: parent.width * 0.15 }
                Text { text: modelData.email || '...';	width: parent.width * 0.35 }
                Text { text: modelData.address || '...';width: parent.width * 0.30 }
            }
        }
    }

    CallbackModel {
        id: customerModel

        // requestDelay delays the request (in ms) to allow for a potential signal storm
        // to calm down before requesting more records. This can happen if, for example,
        // the view is resized within an animation.
        //
        // Unfortunately there's no way for the model to know how fast/often the view will
        // be resized, and other models just try to keep up (resulting in jank). For my
        // purposes 20ms is fast enough that delays in input/result are imperceptible, but
        // it's important to note that if the data source is on a distant/latent network
        // that this delay will be compounded to existing latency.
        requestDelay: 20

        onRecordsRequested: function(first, last)
        {
            exampleWindow.fetchRecords(first, last);
        }
    }
}


