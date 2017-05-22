# poshobjectslab
A PowerShell module for learning to use objects and also for the new class command of version 5.0

This module is for PowerShell newbies that might struggle to understand the concept of objects but also for experienced PowerShell users who are looking for a good example that makes use of the class command that was introduced with Version 5.0

I am doing a lot of PowerShell trainings and would like to use this module for my training classes.

You are probably wondering what's this modules is about and how to make sense of it.

The main reason for it is being able to learn to use dealing with objects inside a PowerShell console without having to use "real" object that represent process, services, AD users, network adapters etc. The objects of my modules are simple virtual servers with very few properties and methods like Start() and Stop(). The methods are encapsulated inside functions (Start-Server, Stop-Server etc).

So its possible to create a new server, than start and stop it. To make it a little bit more interesting starting a server starts a timer that generates event log messages. Each message is based on a class that defines the properties of that message. So one task would be "write a command that retrieves all messages of Server with Id 1 generated in the last 60 minutes".

How to use the module?

After download (its not on PowerShell Gallery yet) copy the zip content into a module folder.

Import the module with Import-Module.

Add a new server with Add-Server.

Query the servers with Get-Server or $DC.Serverlist.

