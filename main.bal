import ballerina/io;
import ballerina/log;
import ballerina/tcp;
import ballerina/regex;

service on new tcp:Listener(3000) {

    remote function onConnect(tcp:Caller caller) 
                            returns tcp:ConnectionService {
        io:println("Client connected to the server: ", caller.remotePort);
        return new Service();
    }
}

    type Message record {
        string jsonrpc;
    };

    type RequestMessage record {|
        *Message;
        int|string id;
        string method;
        any params?;
    |};

    type ResponseMessage record {|
        *Message;
        int|string|null id;
        any result?;
    |};

    type NotificationMessage record {|
        *Message;
        string method;
        any params;
    |};

    type CompletionOptions record {
        boolean resolveProvider?;         
    };

    type WorkSpaceFolders record {
        boolean supported?;                        
    };

    type WorkSpace record {
        WorkSpaceFolders workspaceFolders;                
    };

    type ServerCapabilities record {
        int|string textDocumentSync;
        CompletionOptions completionProvider;
        WorkSpace workspace;
    };

    type Initialize record {
        ServerCapabilities capabilities;
    };

    type InitializeResult record {
        *ResponseMessage;
        string jsonrpc;
        int|string|null id;
        Initialize result;
    };
    
    type Registration record {
        string id;
        string method;
        anydata? registerOptions?;
    };

    type RegistrationParams record {
        Registration[] registrations;
    };

    type RegisterCapability record {
        *RequestMessage;
        string jsonrpc;
        int|string id;
        "client/registerCapability" method;
        RegistrationParams params;
    };

    type ConfigurationItem record {
        string scopeUri;
        string section;
    };

    type ConfigurationParams record {
        ConfigurationItem[] items;
    };

    type Configuration record {
        *RequestMessage;
        string jsonrpc;
        int|string id;
        "workspace/configuration" method;
        ConfigurationParams params;
    };

    int n = 0;

    Message[] a = [<InitializeResult>{
        jsonrpc:"2.0",
        id:0,
        result:{capabilities:{textDocumentSync:2,completionProvider:{resolveProvider:true},workspace:{workspaceFolders:{supported:true}}}}
    },
    
    <RegisterCapability>{
        jsonrpc:"2.0",
        id:1,
        method:"client/registerCapability",
        params:{registrations:[{id:"36b409a1-be16-4010-b7bf-a26b6f659596",method:"workspace/didChangeWorkspaceFolders",registerOptions:{}}]}
    },
        
    <RegisterCapability>{
        jsonrpc:"2.0",
        id:1,
        method: "client/registerCapability",
        params:{registrations:[{id:"36b409a1-be16-4010-b7bf-a26b6f659596",method:"workspace/didChangeWorkspaceFolders",registerOptions:{}}]}
    },
    
    <Configuration>{
        jsonrpc:"2.0",
        id:2,
        method:"workspace/configuration",
        params:{items:[{scopeUri:"file:///c%3A/Users/Mindula/Desktop/vext/out.txt",section: "languageServerExample"}]}
    }];

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
    
    function handleInput(tcp:Caller caller, readonly & byte[] data) returns error? {
        string messageContent = "";

        if self.expectedLen == () {
            self.buffer = data;
            self.expectedLen = check extractContentLength(data);

        } else {
            self.buffer.push(...data);
            messageContent = check extractContent(self.buffer);
            if (self.expectedLen == messageContent.length()) {
                json jsonObject = messageContent.toJson();
                io:println(jsonObject);

                string s = a[n].toJsonString();
                string s2 = regex:replaceAll(s, " ", "");
                string response = "Content-Length: " + (s2.length()).toString() + "\r\n\r\n" + s2;
                byte[] byteMessage = response.toBytes();
                check caller->writeBytes(byteMessage);
                n += 1;

                self.expectedLen = ();
                messageContent = "";
                self.buffer.removeAll();

            } else if (<int> self.expectedLen < messageContent.length()){
                panic error("Message length exceeds the expected length");
            }   
        }
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

function extractContent(byte[] data) returns string|error {
    string|error stringOne = string:fromBytes(data);
    string finalString = "";
    if stringOne is string {
        int indexOne = <int>stringOne.indexOf("{");
        int indexTwo = stringOne.length();
        finalString = stringOne.substring(indexOne, indexTwo);
    }
    return finalString;
}
