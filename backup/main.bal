import ballerina/io;
import ballerina/log;
import ballerina/tcp;

//bind the service to the port
service on new tcp:Listener(3000) {

    remote function onConnect(tcp:Caller caller) 
                            returns tcp:ConnectionService {
        io:println("Client connected to the server: ", caller.remotePort);
        return new Service();
    }
}


service class Service {
    //once the content is received from the client, this method is invoked

    remote function onBytes(tcp:Caller caller, readonly & byte[] data) 
        returns tcp:Error? {
        error? e = self.handleInput(data);
        if e is error {
            // XXX should return new tcp:Error(), find why that doesn't wrok.
            return;
        }

    }

    byte[] buffer = [];
    int? expectedLen = ();
    boolean isFirstTime = false;

    function handleInput(readonly & byte[] data) returns error? {
        if self.expectedLen == () {

            self.expectedLen = check extractContentLength(data);
            self.buffer = data;
        // afterNewLineData == all the bytes after the second `\r\n` of data
        // self.buffer.push(...afterNewLineData);
        } 
        else {

            self.buffer.push(...data);

        }

        if self.buffer.length() == self.expectedLen {

            // XXX do converstion to json here

            self.expectedLen = ();
            self.buffer.removeAll();

        }

        if (self.isFirstTime) {

            
            string|error firststring = string:fromBytes(self.buffer);

            if firststring is string {

                int firstIndex = <int>firststring.indexOf("{");
                int lastIndex = firststring.length();
                string secondstring = firststring.substring(firstIndex, lastIndex);
                string jsonstring = secondstring.toJsonString();
                io:println(jsonstring);

            }
        }
        self.isFirstTime = true;

    }

    //invokes when an error occurs during the execution of onConnect and on Bytes
    remote function onError(tcp:Error err) returns tcp:Error? {
        log:printError("An error occurred", 'error = err);
    }

    //invokes when the client left    
    remote function onClose() returns tcp:Error? {
        io:println("Client left");
    }
}

function extractContentLength(readonly & byte[] data) returns int|error {
    string s = check string:fromBytes(data);
    int? newLinePos = s.indexOf("\r\n");
    if newLinePos == () {
        panic error("even the first tcp packet is too small to figure out the length");
    } 
    else {
        int? spacePos = s.lastIndexOf(" ", newLinePos);
        return int:fromString(s.substring((spacePos ?: 0) + 1, newLinePos));
    }
}

