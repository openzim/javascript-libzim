    }
    else {
        console.error('Invalid action: ' + action);
        outgoingMessagePort.postMessage('invalid action');
    }
},false);

