# Network check

## Verify the open ports 
```
lsof -i :<port>
ss -ntulp | grep <port>
netstat -tnlp | grep <port>
```

```
----------------------------------------------------------------------------------------------------------------------------------------------------

SS(8)                                                      System Manager's Manual                                                     SS(8)

NAME
       ss - another utility to investigate sockets

SYNOPSIS
       ss [options] [ FILTER ]

DESCRIPTION
       ss  is  used to dump socket statistics. It allows showing information similar to netstat.  It can display more TCP and state informa-
       tion than other tools.
```

# Ip address of a host 
```
ip -br -4 a
```
