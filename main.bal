import ballerina/io;
import ballerina/log;
// import ballerina/test;
import ballerina/tcp;
// import ballerina/lang.'string;
import ballerina/regex;


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
        // io:println(string:fromBytes(data));  

        string|error firststring = string:fromBytes(data);   

            if firststring is string{
                string finalstring = regex:replaceAll(firststring, "/[^ -~]+/g", "");
                int x = <int> finalstring.indexOf("{");
                int y = finalstring.length();
                string secondstring = finalstring.substring(x,y);
                
                // io:println(secondstring);

                io:Error? fileWriteString2 = io:fileWriteString("file7.json",secondstring,io:APPEND);

                // json|error j = secondstring.fromJsonString();
                // io:println(j);

            }

     // echoes back the received data to the client
     //     check caller->writeBytes(data);  
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
