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
        error? e = self.handleInput(caller,data);
    
        if e is error {
            return;
        }
    }
           
    byte[] buffer = [];
    byte[] buffer2 = [];
    int? expectedLen = ();
    int? lengthOne = ();
    int? lengthTwo = ();

    function handleInput(tcp:Caller caller,readonly & byte[] data) returns error? {
        if self.expectedLen == () {

            self.buffer = data;
            self.expectedLen = check extractContentLength(data);
            self.lengthOne = self.contentLengthRemover(self.buffer).length();
     
        } 
        else {

            self.buffer2.push(...data);
            string|error stringTwo = string:fromBytes(self.buffer2);
            if stringTwo is string{
                self.lengthTwo = stringTwo.length(); 
            }
  
        }

        int stringLength = <int>self.lengthOne + <int>self.lengthTwo;
        io:println(self.expectedLen,"52line");
        if (self.expectedLen == stringLength) {
               
            self.buffer.push(...self.buffer2);
            json jsonObject = self.contentLengthRemover(self.buffer).toJson();
            io:println(jsonObject);
            self.expectedLen = ();
            self.buffer = [];
            self.buffer2 = [];
            self.lengthOne = ();
            self.lengthTwo = ();
            
            io:println(self.expectedLen,"59thg luine");

            // string message = "Content-Length: 44\r\n\r\n{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"shutdown\"}";
            string messageTwo = "Content-Length: 46\r\n\r\n{\"jsonrpc\":\"2.0\",\"id\":0,\"method\":\"initialize\",\"Result\":{\"capabilities\":{\"textDocumentSync\":2,\"completionProvider\":{\"resolveProvider\":true},\"workspace\":{\"workspaceFolders\":{\"supported\":true}}}}}";
            byte[] byteMessage = messageTwo.toBytes();

            check caller->writeBytes(byteMessage); 

        } else {  
            io:println(self.expectedLen,"72 line");
             io:println("Content Length Does not Match the Message Length" );
        }

        if self.buffer.length() == self.expectedLen {
            self.expectedLen = ();
            self.buffer.removeAll();
        } 
       
    }

    function contentLengthRemover(byte [] data) returns string{
            string|error stringOne = string:fromBytes(data);
            string finalString = "";
            if stringOne is string{
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
