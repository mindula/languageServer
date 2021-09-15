import ballerina/io;
import ballerina/log;
import ballerina/tcp;

service on new tcp:Listener(3000) {

    remote function onConnect(tcp:Caller caller) 
                            returns tcp:ConnectionService {
        io:println("Client connected to the server: ", caller.remotePort);
        return new Service();
    }
}

service class Service {

    remote function onBytes(tcp:Caller caller, readonly & byte[] data) 
        returns tcp:Error? {
        error? e = self.handleInput(caller, data);

        if e is error {
            return;
        }
    }

    byte[] buffer = [];
    int? expectedLen = ();
    string messageContent = "";
    int n = 0;
    string[] array = ["Content-Length: 171\r\n\r\n{\"jsonrpc\":\"2.0\",\"id\":0,\"result\":{\"capabilities\":{\"textDocumentSync\":2,\"completionProvider\":{\"resolveProvider\":true},\"workspace\":{\"workspaceFolders\":{\"supported\":true}}}}}", 
    "Content-Length: 201\r\n\r\n{\"jsonrpc\":\"2.0\",\"id\":0,\"method\":\"client/registerCapability\",\"params\":{\"registrations\":[{\"id\":\"9716545a-b5e9-4b32-94e1-be674a62eb04\",\"method\":\"workspace/didChangeConfiguration\",\"registerOptions\":{}}]}}", 
    "Content-Length: 204\r\n\r\n{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"client/registerCapability\",\"params\":{\"registrations\":[{\"id\":\"36b409a1-be16-4010-b7bf-a26b6f659596\",\"method\":\"workspace/didChangeWorkspaceFolders\",\"registerOptions\":{}}]}}", 
    "Content-Length: 177\r\n\r\n{\"jsonrpc\":\"2.0\",\"id\":2,\"method\":\"workspace/configuration\",\"params\":{\"items\":[{\"scopeUri\":\"file:///c%3A/Users/Mindula/Desktop/vext/out.txt\",\"section\":\"languageServerExample\"}]}}", 
    "Content-Length: 144\r\n\r\n{\"jsonrpc\":\"2.0\",\"method\":\"textDocument/publishDiagnostics\",\"params\":{\"uri\":\"file:///c%3A/Users/Mindula/Desktop/vext/out.txt\",\"diagnostics\":[]}}"];

    function handleInput(tcp:Caller caller, readonly & byte[] data) returns error? {

        if self.expectedLen == () {

            self.buffer = data;
            self.expectedLen = check extractContentLength(data);

        } else {

            self.buffer.push(...data);
            self.messageContent = self.contentLengthRemover(self.buffer);
            if (self.expectedLen == self.messageContent.length()) {
                json jsonObject = self.messageContent.toJson();
                io:println(jsonObject);

                byte[] byteMessage = self.array[self.n].toBytes();
                check caller->writeBytes(byteMessage);
                self.n += 1;

                self.expectedLen = ();
                self.messageContent = "";
                self.buffer.removeAll();

            } else {
                io:println("Content Length Does not Match the Message Length");
            }

        }

        if self.buffer.length() == self.expectedLen {
            self.expectedLen = ();
            self.buffer.removeAll();
        }
    }

    function contentLengthRemover(byte[] data) returns string {
        string|error stringOne = string:fromBytes(data);
        string finalString = "";
        if stringOne is string {
            int indexOne = <int>stringOne.indexOf("{");
            int indexTwo = stringOne.length();
            finalString = stringOne.substring(indexOne, indexTwo);
        }
        return finalString;
    }

    remote function onError(tcp:Error err) returns tcp:Error? {
        log:printError("An error occurred", 'error = err);
    }

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
