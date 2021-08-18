import ballerina/io;
import ballerina/log;
// import ballerina/test;
import ballerina/tcp;
// import ballerina/lang.'string;
// import ballerina/regex;


//bind the service to the port
service on new tcp:Listener(3000) {

    remote function onConnect(tcp:Caller caller)
                              returns tcp:ConnectionService {
        io:println("Client connected to the server: ", caller.remotePort);
        return new Service();
    }
}
string firstMessage = "";
string secondMessage = "";

service class Service {
//once the content is received from the client, this method is invoked

    byte[] buffer = [];
    byte[] buffer1 = [];
    int? expectedLen = ();

    remote function onBytes(tcp:Caller caller, readonly & byte[] data) 
        returns tcp:Error? { 

            // io:println(data);

            byte[] byteArray = data;
            int? lastIndex = byteArray.lastIndexOf(10);
            int lastx = <int> lastIndex;
            lastx += 1;
            foreach var i in 0...lastx{
                byte remove = byteArray.remove(i);
            }   

            io:println(byteArray);

            string|error firststring = string:fromBytes(data);

            if firststring is string {
                if (firstMessage == "") {
                    firstMessage = firststring; 
                } else {
                    secondMessage = firststring;
                }                      
            }
            io:println(firstMessage+secondMessage);
}
    

//  invokes when an error occurs during the execution of onConnect and on Bytes
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
    io:println("new line pos ",newLinePos); 
    if newLinePos == () {
        panic error("even the first tcp packet is too small to figure out the length");
    }
    else {
        int? spacePos = s.lastIndexOf(" ", newLinePos);
        io:println("spacePos =", spacePos);
        return int:fromString(s.substring((spacePos ?: 0) + 1, newLinePos));
    }
}

