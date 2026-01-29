#  Project TODO List

## Server

1. Build listener for UDP broadcast in discovery
2. Build code to send UDP notifications on state change.

## Client

1. Build listener for UDP notifications
2. Build UDP broadcast for projector discovery
3. Display different menus for Class 1 and Class 2 projectors in CLI

## Common Library

1. Eliminate illegal combinations of class/command in SetResponse and GetResponseFailure
2. Eliminate PJLink.Message and promote PJLink.Message.Request -> PJLink.Request
   and PJLink.Message.Response -> PJLink.Response.
