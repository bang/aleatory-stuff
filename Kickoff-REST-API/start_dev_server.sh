export APP_NAME=Opengates
export DBIC_TRACE=1 
export TEST_MODE=0

#database
export OPENGATES_DB_NAME=carneirao
export OPENGATES_DB_USER=carneirao
export OPENGATES_DB_PASSWORD=crinus666
export OPENGATES_LOG_DIR='/tmp'
export OPENGATES_ERROR_LOG=$OPENGATES_LOG_DIR/opengates.err

#redis for Jobs
export OPENGATES_REDIS_SERVER_HOST=localhost
export OPENGATES_REDIS_SERVER_PORT=6379


#main command
perl script/api_server.pl -r -d
