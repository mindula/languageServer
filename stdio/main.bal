import ballerina/jballerina.java;
import ballerina/io;
import ballerina/regex;

type Message record {
    string jsonrpc;
};htrhsfhfhshgsfhfs

type RequestMessage record {|
    *Message;
    int|string id;
    string method;
    anydata params?;
|};

type ResponseMessage record {|
    *Message;
    int|string|null id;
    anydata result?;
|};

type NotificationMessage record {|
    *Message;
    string method;
    anydata params;
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

type Location record {
    string uri;
    Range range;
};

type DiagnosticRelatedInformation record {
    Location location;
    string message;
};

type Position record {
    int line;
    int character;
};
 
type Range record {
    // Position start; 
    Position end; 
};

type Diagnostic record {  
    int severity;
    Range range; 
    string message;
    // string source; 
    DiagnosticRelatedInformation[] relatedInformation;  
};

type PublishDiagnosticsParams record {
    string uri;
    Diagnostic[] diagnostics;    
};

type PublishDiagnostics record {
    *NotificationMessage;
    string jsonrpc;
    "textDocument/publishDiagnostics" method;
    PublishDiagnosticsParams params;
};

type TraceValue record {
    "off"|"messages"|"verbose" trace;
};

type WorkspaceFolder record {
    string uri;
    string name;
};

type InitializeParams record {
    int|null processId;
    string clientInfo;
    string locale; 
    string|null rootPath;
    string|null rootUri;
    anydata initializationOptions;
    string capabilities;
    TraceValue trace;
    WorkspaceFolder[]|null workspaceFolders;
};

type InitializeRequest record {
    *RequestMessage;
    string jsonrpc;
    int|string id;
    "initialize" method;
    InitializeParams params;
};

public function inputStream() returns handle = @java:FieldGet {
   name:"in",
   'class:"java.lang.System"
} external;

function inputStreamReader(handle input) returns handle = @java:Constructor {
   'class: "java.io.InputStreamReader"
} external;   

function bufferConstructor(handle arr) returns handle = @java:Constructor {
   'class: "java.io.BufferedReader"
} external;

function readLine(handle receiver) returns handle | error  = @java:Method {
   'class: "java.io.BufferedReader"
} external;
 
function allocate(int capacity) returns handle  = @java:Method {
   'class: "java.nio.CharBuffer"
} external;

function array(handle receiver) returns handle  = @java:Method {
   'class: "java.nio.CharBuffer"
} external;

function read(handle obj, handle a,int off,int len) returns int|error = @java:Method {
   'class: "java.io.BufferedReader"
} external;

function String(handle input, int offset, int length) returns handle = @java:Constructor {
   'class: "java.lang.String",
   paramTypes: [{'class: "char", dimensions:1}, "int", "int"]
} external; 


int n =0;
public function main() returns error? {
   handle iStream = inputStream(); 
   handle streamReader = inputStreamReader(iStream);
   handle bufferedReader = bufferConstructor(streamReader); 

   while (n<10){
      int|error messageLength = extractContent(bufferedReader);
      handle charBuffer = allocate(check messageLength);
      handle charArray = array(charBuffer);
      int|error readArr = read(bufferedReader, charArray, 0, check messageLength);
      handle message = String(charArray, 0, check messageLength);
      string? messageContent = java:toString(message);

      check io:fileWriteString("/Users/Mindula/Desktop/testing/out.txt", messageContent ?: "error in reading", io:APPEND);  

      Message[] a = [<InitializeResult>{
      jsonrpc : "2.0",
      id : 0,
      result : { capabilities : { textDocumentSync : 2, completionProvider : { resolveProvider : true }, workspace : { workspaceFolders : { supported : true }}}}
   }, 
      
      <RegisterCapability>{
      jsonrpc : "2.0",
      id : 0,
      method : "client/registerCapability",
      params : { registrations : [{ id : "9716545a-b5e9-4b32-94e1-be674a62eb04", method : "workspace/didChangeConfiguration", registerOptions: {} }]}
   }, 
      
      <RegisterCapability>{
      jsonrpc : "2.0",
      id : 1,
      method : "client/registerCapability",
      params : { registrations : [{ id : "36b409a1-be16-4010-b7bf-a26b6f659596", method : "workspace/didChangeWorkspaceFolders", registerOptions: {} }]}
   }, 
      
      <Configuration>{
      jsonrpc : "2.0",
      id : 2,
      method : "workspace/configuration",
      params : { items : [{ scopeUri : "file:///c%3A/Users/Mindula/Desktop/vext/out.txt", section : "languageServerExample" }]}
   },
   
      <PublishDiagnostics>{
      jsonrpc : "2.0",
      method : "textDocument/publishDiagnostics",
      params : { uri : "file:///c%3A/Users/Mindula/Desktop/vext/out.txt", diagnostics : [{ severity : 2, range : { "start" : { "line" : 0, "character" : 0 }, end : { line : 0, character : 3 }}, message : "AAA is all uppercase.", "source" : "ex", relatedInformation : [{ location : { uri : "file:///c%3A/Users/Mindula/Desktop/vext/out.txt", range : { "start" : { "line" : 0, "character" : 0 }, end : { line : 0, character : 3 }}}, message : "Spelling matters" }, { location : { uri : "file:///c%3A/Users/Mindula/Desktop/vext/out.txt", range : { "start" : { "line" : 0, "character" : 0 }, end : { line : 0, character : 3 }}}, message : "Particularly for names" }]}]}
    }];

      string s = a[n].toJsonString();
      string s2 = regex:replaceAll(s, ",\\s", ",");
      string response = "Content-Length: " + (s2.length()).toString() + "\r\n\r\n" + s2;
      io:println(response);
      n += 1; 
   }
}

function extractContent(handle bufferedReader) returns int|error{
   handle|error readLn = readLine(bufferedReader);
   string? contentLength = java:toString(check readLn);
   if contentLength is string{
      string length = regex:replaceAll(contentLength, "\\D", "");
      return int:fromString(length);
   }else {
      panic error("cannot read the length");
   }
}
