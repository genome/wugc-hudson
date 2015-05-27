echo "=> Creating test database..."
TESTDBSERVER_DB_USER="genome"
TESTDBSERVER_DB_PASS="mypassword"
export TESTDBSERVER_URL="https://apipe-test-db.gsc.wustl.edu"

eval "$(test-db database create --bash --owner $TESTDBSERVER_DB_USER --based-on cdf1e54)"
if test -z "$TESTDBSERVER_DB_NAME"
then
    echo "Failed to create test database."
    exit 1
else
    echo "Test database: $TESTDBSERVER_DB_NAME"
fi

set -o nounset
set -o errexit
TO_EVAL="$(genome config set-env ds_gmschema_server dbname=${TESTDBSERVER_DB_NAME};host=${TESTDBSERVER_DB_HOST};port=${TESTDBSERVER_DB_PORT})"
eval $TO_EVAL
TO_EVAL="$(genome config set-env ds_gmschema_login $TESTDBSERVER_DB_USER)"
eval $TO_EVAL
TO_EVAL="$(genome config set-env ds_gmschema_auth $TESTDBSERVER_DB_PASS)"
eval $TO_EVAL
set +o errexit
set +o nounset

echo "=> Migrating test database..."
(
    set -o errexit
    cd sqitch/gms
    sqitch config core.pg.host     $TESTDBSERVER_DB_HOST
    sqitch config core.pg.username $TESTDBSERVER_DB_USER
    sqitch config core.pg.password $TESTDBSERVER_DB_PASS
    sqitch config core.pg.db_name  $TESTDBSERVER_DB_NAME
    if ! sqitch status | /bin/grep -q 'Nothing to deploy'
    then
        sqitch deploy
    fi
)
