var _socket;
var _pingInterval;
var _verbose = false;

function connect(url) {
    log("socket connecting to: " + url);
    _socket = new WebSocket(url);
    
    if (_pingInterval != null) {
        clearInterval(_pingInterval);
    }
    
    _pingInterval = setInterval(doPing, 30000);
    
    _socket.onmessage = function(messageEvent) {
        if(messageEvent.data === "__pong__") {
            log("socket onmessage() pong response from server");
        } else {
            log("socket onmessage() called");
            window.webkit.messageHandlers.onmessage.postMessage(messageEvent.data);
        }
    };
    _socket.onclose = function(closeEvent) {
        log("socket onclose() called");
        var message = {
          wasClean: closeEvent.wasClean,
          reason: closeEvent.reason,
          closeCode: closeEvent.code
        };
        window.webkit.messageHandlers.onclose.postMessage(message);
    };
    _socket.onerror = function() {
        log("socket onerror() called");
        window.webkit.messageHandlers.onerror.postMessage('error');
    };
    _socket.onopen = function() {
        log("socket onopen() called");
        window.webkit.messageHandlers.onopen.postMessage('open');
    };
    
}

function doPing() {
    log("doPing() invoked");
    _socket.send("__ping__");
}

function disconnect() {
    log("socket closed");
    _socket.close();
}

function sendData(data) {
    log("socket sendData() called, socket state is " + _socket.readyState);
    if (_socket.readyState == 2 || _socket.readyState == 3) {
        log("socket closed when trying to send data. Please attempt to reconnect.");
    }
    _socket.send(data);
}

function log(message) {
    if (_verbose) {
        window.webkit.messageHandlers.log.postMessage(message);
    }
}
