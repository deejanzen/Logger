# A SFDC logger

This is a small logging library. A couple of things to point out:
- Uses platform events as a transport to send logs to avoid roll backs,
- It's queryless. The logger inserts parent and child logs, log and log entry respectively, at the same time using an external ID
- There's a LoggingSetting, custom mdt object, where you can turn on or off certain system logging levels

