#!/bin/bash

curl --user activescott:123456 --data-binary '{"jsonrpc": "1.0", "id":"curltest-2", "method": "getinfo", "params": [] }' -H 'content-type: text/plain;' http://localhost:8000/

curl -v --user activescott:123456 --data-binary '{"jsonrpc": "1.0", "id":"curltest-2", "method": "getblockcount", "params": [] }' -H 'content-type: text/plain;' http://localhost:8000/